#!/usr/bin/env bash
# Builds the native waydir_core helper (Rust, release) and vendors the
# resulting shared library into third_party/waydir_core/<platform>/ so the
# platform CMake / Xcode bundling step copies it next to the executable.
#
# The Dart loader (WaydirCoreLoader) discovers it next to the binary; if it
# is absent the app transparently falls back to the pure-Dart path.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
crate="$here/rust/waydir_core"

WAYDIR_VERSION="$(grep '^version:' "$here/pubspec.yaml" | sed -E 's/version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/')"
export WAYDIR_VERSION

case "$(uname -s)" in
  Linux*)  lib="libwaydir_core.so";    plat="linux" ;;
  Darwin*) lib="libwaydir_core.dylib"; plat="macos" ;;
  *)       lib="waydir_core.dll";      plat="windows" ;;
esac

dest="$here/third_party/waydir_core/$plat"
mkdir -p "$dest"

if [ "$plat" = "macos" ]; then
  # Ship a universal binary so the dylib loads whether the Flutter app runs
  # as arm64 (Apple Silicon) or x86_64 (Intel / Rosetta). A single-arch dylib
  # fails to load on the other architecture with "incompatible architecture".
  rustup target add aarch64-apple-darwin x86_64-apple-darwin
  cargo build --release --manifest-path "$crate/Cargo.toml" --target aarch64-apple-darwin
  cargo build --release --manifest-path "$crate/Cargo.toml" --target x86_64-apple-darwin
  mkdir -p "$crate/target/release"
  lipo -create \
    "$crate/target/aarch64-apple-darwin/release/$lib" \
    "$crate/target/x86_64-apple-darwin/release/$lib" \
    -output "$crate/target/release/$lib"
  cp -f "$crate/target/release/$lib" "$dest/$lib"
else
  cargo build --release --manifest-path "$crate/Cargo.toml"
  cp -f "$crate/target/release/$lib" "$dest/$lib"
fi

echo "vendored: $dest/$lib"
