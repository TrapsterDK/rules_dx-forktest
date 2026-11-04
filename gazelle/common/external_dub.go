package common

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/bazel-contrib/bazel-gazelle/v2/label"
)

// DubProject is the part of a dub.json that generation reads.
type DubProject struct {
	Name              string                     `json:"name"`
	TargetType        string                     `json:"targetType"`
	SourcePaths       []string                   `json:"sourcePaths"`
	ImportPaths       []string                   `json:"importPaths"`
	StringImportPaths []string                   `json:"stringImportPaths"`
	Dependencies      map[string]json.RawMessage `json:"dependencies"`
}

// ParseDubProject reads a dub.json.
func ParseDubProject(content []byte) (*DubProject, error) {
	var p DubProject
	if err := json.Unmarshal(StripBOM(content), &p); err != nil {
		return nil, err
	}
	return &p, nil
}

// ReadDubProject reads the dub.json in dir. It returns nil when there is none
// or when it does not parse.
func ReadDubProject(dir string) *DubProject {
	content, err := os.ReadFile(filepath.Join(dir, "dub.json"))
	if err != nil {
		return nil
	}
	p, err := ParseDubProject(content)
	if err != nil {
		return nil
	}
	return p
}

// Roots returns the import roots of the project: importPaths, else
// sourcePaths, else the source or src directory that exists in dir.
func (p *DubProject) Roots(dir string) []string {
	switch {
	case len(p.ImportPaths) > 0:
		return p.ImportPaths
	case len(p.SourcePaths) > 0:
		return p.SourcePaths
	}
	for _, d := range []string{"source", "src"} {
		if info, err := os.Stat(filepath.Join(dir, d)); err == nil && info.IsDir() {
			return []string{d}
		}
	}
	return nil
}

// dubManifest holds the direct dependencies of a dub.json and the versions
// dub.selections.json pins.
type dubManifest struct {
	deps   []string
	pinned map[string]bool
}

func parseDubManifest(content, sibling []byte, _ string) (externalManifest, error) {
	project, err := ParseDubProject(content)
	if err != nil {
		return nil, err
	}
	m := &dubManifest{pinned: map[string]bool{}}
	for dep := range project.Dependencies {
		base, _, _ := strings.Cut(dep, ":")
		m.deps = append(m.deps, base)
	}
	sort.Strings(m.deps)
	if sibling != nil {
		var selections struct {
			Versions map[string]json.RawMessage `json:"versions"`
		}
		if err := json.Unmarshal(StripBOM(sibling), &selections); err != nil {
			return nil, fmt.Errorf("dub.selections.json: %v", err)
		}
		for name, raw := range selections.Versions {
			var version string
			if json.Unmarshal(raw, &version) == nil {
				m.pinned[name] = true
			}
		}
	}
	return m, nil
}

// Lookup resolves a module to the hub target of the dependency whose name is
// the module's first segment, with - read as _.
func (m *dubManifest) Lookup(repo, module string) ([]label.Label, string) {
	first, _, _ := strings.Cut(module, ".")
	for _, dep := range m.deps {
		if dep != first && strings.ReplaceAll(dep, "-", "_") != first {
			continue
		}
		if !m.pinned[dep] {
			return nil, "package " + dep + " is not pinned in dub.selections.json; run dub upgrade"
		}
		return []label.Label{{Repo: repo, Pkg: dep, Name: dep}}, ""
	}
	return nil, "no dependency in dub.json is named " + first
}
