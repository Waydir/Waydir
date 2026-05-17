#!/usr/bin/env bash
# Builds the optional native waydir_core helper (Rust) in release mode.
# The Dart loader (WaydirCoreLoader) discovers it next to the executable
# (lib/), in the dev target dir, or on the loader search path; if it is
# absent the app transparently falls back to the pure-Dart implementation.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
crate="$here/rust/waydir_core"

cargo build --release --manifest-path "$crate/Cargo.toml"

out="$crate/target/release"
case "$(uname -s)" in
  Linux*)  lib="libwaydir_core.so" ;;
  Darwin*) lib="libwaydir_core.dylib" ;;
  *)       lib="waydir_core.dll" ;;
esac

echo "built: $out/$lib"
