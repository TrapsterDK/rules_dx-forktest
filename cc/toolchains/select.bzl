"""Run a test under an explicitly selected C++ toolchain."""

load("//libs/starlark:wrapper.bzl", "dx_lcov_merger_attr")

_COMPILER = str(Label("//cc/toolchains:compiler"))

_FEATURES = "//command_line_option:features"

_MODE = "//command_line_option:compilation_mode"

def _impl(settings, attr):
    features = list(settings[_FEATURES])
    for f in getattr(attr, "extra_features", []):
        if f not in features:
            features.append(f)
    return {
        _COMPILER: attr.compiler or settings[_COMPILER],
        _FEATURES: features,
        _MODE: getattr(attr, "compilation_mode", "") or settings[_MODE],
    }

toolchain_transition = transition(
    implementation = _impl,
    inputs = [_COMPILER, _FEATURES, _MODE],
    outputs = [_COMPILER, _FEATURES, _MODE],
)

def _test_impl(ctx):
    src = ctx.attr.test[0]
    inner = src[DefaultInfo].files_to_run.executable
    path = inner.short_path
    path = path[3:] if path.startswith("../") else ctx.workspace_name + "/" + path
    if ctx.target_platform_has_constraint(ctx.attr._windows_os[platform_common.ConstraintValueInfo]):
        exe = ctx.actions.declare_file(ctx.label.name + ".bat")
        content = "@echo off\r\n\"%TEST_SRCDIR%\\" + path.replace("/", "\\") + "\" %*\r\n"
    else:
        exe = ctx.actions.declare_file(ctx.label.name + ".sh")
        content = "#!/bin/bash\nexec \"${RUNFILES_DIR:-$0.runfiles}/%s\" \"$@\"\n" % path
    ctx.actions.write(output = exe, content = content, is_executable = True)
    runfiles = ctx.runfiles(files = [inner]).merge(src[DefaultInfo].default_runfiles)
    providers = [DefaultInfo(executable = exe, runfiles = runfiles)]
    if RunEnvironmentInfo in src:
        providers.append(src[RunEnvironmentInfo])
    providers.append(coverage_common.instrumented_files_info(ctx, dependency_attributes = ["test"]))
    return providers

cc_toolchain_test = rule(
    implementation = _test_impl,
    doc = "Runs a test built with the selected C++ toolchain.",
    attrs = {
        "compiler": attr.string(doc = "Compiler flag value to build with.", mandatory = True),
        "compilation_mode": attr.string(doc = "Compilation mode to build with, or empty to keep the command line value.", values = ["", "dbg", "fastbuild", "opt"]),
        "extra_features": attr.string_list(doc = "Features to enable on top of the command line features, such as asan.", default = []),
        "test": attr.label(doc = "Test to rebuild.", executable = True, cfg = toolchain_transition, mandatory = True),
        "_windows_os": attr.label(default = "@platforms//os:windows"),
    } | dx_lcov_merger_attr(),
    test = True,
)

_PLATFORMS = "//command_line_option:platforms"

def _files_transition_impl(_settings, attr):
    return {
        _COMPILER: attr.compiler,
        _PLATFORMS: attr.platforms,
    }

_files_transition = transition(
    implementation = _files_transition_impl,
    inputs = [],
    outputs = [_COMPILER, _PLATFORMS],
)

def _files_impl(ctx):
    files = depset(transitive = [src[DefaultInfo].files for src in ctx.attr.srcs])
    return [DefaultInfo(files = files, runfiles = ctx.runfiles(transitive_files = files))]

cc_toolchain_files = rule(
    implementation = _files_impl,
    doc = "Exposes the outputs of targets built with the selected compiler for the given platforms.",
    attrs = {
        "compiler": attr.string(doc = "Compiler flag value to build with.", mandatory = True),
        "platforms": attr.string_list(doc = "Target platform labels.", mandatory = True),
        "srcs": attr.label_list(doc = "Targets to build.", cfg = _files_transition),
    },
)
