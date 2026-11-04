#!/bin/sh
set -eu
binary="$1"
archs="$(lipo -archs "$binary")"
echo "$archs"
if [ "$archs" != "arm64" ]; then
    echo "binary is not arm64" >&2
    exit 1
fi
libs="$(otool -L "$binary")"
echo "$libs"
if echo "$libs" | grep 'external/'; then
    echo "binary links a library from external/" >&2
    exit 1
fi
