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

# Vendor the Pdfium shared library that pdfium-render binds to at runtime.
# Quick Look's PDF preview loads it from the same directory as waydir_core.
# Downloaded from bblanchon/pdfium-binaries (BSD/Apache, redistributable).
pdfium_release="https://github.com/bblanchon/pdfium-binaries/releases/latest/download"
fetch_pdfium() {
  # $1 = bblanchon archive name, $2 = path inside archive, $3 = output file
  local tmp
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/pdfium.tgz" "$pdfium_release/$1"
  tar xzf "$tmp/pdfium.tgz" -C "$tmp"
  cp -f "$tmp/$2" "$3"
  rm -rf "$tmp"
}

case "$plat" in
  linux)
    pdfium="libpdfium.so"
    fetch_pdfium "pdfium-linux-x64.tgz" "lib/libpdfium.so" "$dest/$pdfium"
    ;;
  windows)
    pdfium="pdfium.dll"
    fetch_pdfium "pdfium-win-x64.tgz" "bin/pdfium.dll" "$dest/$pdfium"
    ;;
  macos)
    pdfium="libpdfium.dylib"
    tmp_arm="$(mktemp -d)"; tmp_x64="$(mktemp -d)"
    curl -fsSL -o "$tmp_arm/p.tgz" "$pdfium_release/pdfium-mac-arm64.tgz"
    curl -fsSL -o "$tmp_x64/p.tgz" "$pdfium_release/pdfium-mac-x64.tgz"
    tar xzf "$tmp_arm/p.tgz" -C "$tmp_arm"; tar xzf "$tmp_x64/p.tgz" -C "$tmp_x64"
    lipo -create "$tmp_arm/lib/libpdfium.dylib" "$tmp_x64/lib/libpdfium.dylib" \
      -output "$dest/$pdfium"
    rm -rf "$tmp_arm" "$tmp_x64"
    ;;
esac

# Mirror it next to the dev build so the FFI loader finds it during
# `flutter run` without a packaging step.
cp -f "$dest/$pdfium" "$crate/target/release/$pdfium"
echo "vendored: $dest/$pdfium"
