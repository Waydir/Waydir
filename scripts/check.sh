#!/usr/bin/env bash
# Full local check: format, static analysis and the whole test suite.
# Run this after making changes before committing.
#
# Integration tests need the native waydir_core library; if it is missing
# this script builds and vendors it first via build_waydir_core.sh.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$here"

case "$(uname -s)" in
  Linux*)  lib="third_party/waydir_core/linux/libwaydir_core.so" ;;
  Darwin*) lib="third_party/waydir_core/macos/libwaydir_core.dylib" ;;
  *)       lib="third_party/waydir_core/windows/waydir_core.dll" ;;
esac

if [ ! -f "$lib" ]; then
  echo "==> native waydir_core missing, building it"
  scripts/build_waydir_core.sh
fi

echo "==> dart format"
dart format .

echo "==> flutter analyze"
flutter analyze

echo "==> flutter test (unit)"
flutter test --exclude-tags=integration

echo "==> flutter test (integration)"
flutter test --tags=integration --concurrency=1

echo "==> all checks passed"
