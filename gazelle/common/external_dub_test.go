package common

import (
	"strings"
	"testing"
)

func TestDubExternalLookup(t *testing.T) {
	cfg, root := externalConfig(t)
	dotFile(t, root, "dub.json", `{"name": "app", "dependencies": {"vibe-d": "~>0.9", "silly": "~>1.1", "unpinned": "*", "mixed:sub": "*"}}`)
	dotFile(t, root, "dub.selections.json", `{"fileVersion": 1, "versions": {"vibe-d": "0.9.5", "silly": "1.1.1", "mixed": "1.0.0"}}`)
	if errs := ConfigureExternal(cfg, "", nil); errs != nil {
		t.Fatal(errs)
	}
	for module, want := range map[string]string{
		"silly":                "@dub//silly",
		"vibe_d.core.log":      "@dub//vibe-d",
		"mixed.sub.thing":      "@dub//mixed",
		"std.stdio":            "",
		"unpinned.x":           "",
		"unknown_package.core": "",
	} {
		got, _ := ExternalLabels(cfg, "dub", module)
		if labelStrings(got) != want {
			t.Errorf("%s = %q, want %q", module, labelStrings(got), want)
		}
	}
	if _, hint := ExternalLabels(cfg, "dub", "unpinned.x"); !strings.Contains(hint, "dub upgrade") {
		t.Errorf("hint = %q", hint)
	}
	if _, hint := ExternalLabels(cfg, "dub", "other.x"); !strings.Contains(hint, "no dependency in dub.json is named other") {
		t.Errorf("hint = %q", hint)
	}
}
