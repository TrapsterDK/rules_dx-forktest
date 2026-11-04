"""Pinned Qt archives of the windows_arm64 cell."""

load(":layout_windows.bzl", "LAYOUT")

_RELEASE = "6.11.3-0-202610220312"

_SUFFIX = "-Windows-Windows_11_23H2-MSVC2022-Windows-Windows_11_23H2-AARCH64.7z"

IDENTITY = None

CELL = struct(
    archives = {
        "qtbase": struct(
            archive = _RELEASE + "qtbase" + _SUFFIX,
            sha256 = "bc9b963b0c2d2b0799ea60caf4b6c3a0819042f1b65638d16fdb429991642cf6",
        ),
        "qtdeclarative": struct(
            archive = _RELEASE + "qtdeclarative" + _SUFFIX,
            sha256 = "366e0583c087ef107af6e98f79b2d58d7ba5cf10130238cbaf3fad057a7cccad",
        ),
        "qttools": struct(
            archive = _RELEASE + "qttools" + _SUFFIX,
            sha256 = "24d2f168adf271da8218d065e2f351e75467b9c603fd8171bbbb41bd499546e7",
        ),
    },
    blocker = "MSVC arm64 toolchain and Windows arm64 probe evidence pending (#6154, #6159, #5104)",
    constraints = ["@platforms//os:windows", "@platforms//cpu:arm64"],
    directory = "windows_arm64/desktop/qt6_6113/qt6_6113/qt.qt6.6113.win64_msvc2022_arm64",
    layout = LAYOUT,
    needs = None,
    release = _RELEASE,
    runtime = None,
)
