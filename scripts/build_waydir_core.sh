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

cargo build --release --manifest-path "$crate/Cargo.toml"

out="$crate/target/release"
case "$(uname -s)" in
  Linux*)  lib="libwaydir_core.so";    plat="linux" ;;
  Darwin*) lib="libwaydir_core.dylib"; plat="macos" ;;
  *)       lib="waydir_core.dll";      plat="windows" ;;
esac

dest="$here/third_party/waydir_core/$plat"
mkdir -p "$dest"
cp -f "$out/$lib" "$dest/$lib"
echo "vendored: $dest/$lib"
