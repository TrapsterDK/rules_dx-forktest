#!/bin/bash
set -euo pipefail

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
unzip -q "$IPA" -d "$work"
app="$(echo "$work"/Payload/*.app)"
plist="$app/Info.plist"

expect() {
  if [ "$2" != "$3" ]; then
    echo "$1: got '$2', want '$3'" >&2
    exit 1
  fi
}

read_key() { /usr/libexec/PlistBuddy -c "Print :$1" "$plist"; }

binary="$app/$(read_key CFBundleExecutable)"
expect CFBundleIdentifier "$(read_key CFBundleIdentifier)" com.example.ledger
expect MinimumOSVersion "$(read_key MinimumOSVersion)" 17.0
expect DTPlatformName "$(read_key DTPlatformName)" iphonesimulator
expect archs "$(lipo -archs "$binary")" arm64
otool -l "$binary" | grep -qE '^ +platform 7$' || { echo "platform 7 missing" >&2; exit 1; }
nm "$binary" | grep -q '_ledger_total' || { echo "_ledger_total missing" >&2; exit 1; }
