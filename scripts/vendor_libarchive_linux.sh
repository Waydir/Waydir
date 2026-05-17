#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="$ROOT_DIR/third_party/libarchive/linux"

mkdir -p "$DEST_DIR"

# Core system / toolchain libraries must be resolved from the host at runtime,
# never bundled. Everything else libarchive pulls in (bz2, lzma, zstd, lz4,
# xml2, ...) is vendored so the package is self-contained across distros whose
# sonames differ (e.g. Debian's libbz2.so.1.0 vs Fedora's libbz2.so.1).
SYSTEM_LIB_PREFIXES=(
  libc. libm. libdl. libpthread. librt. libresolv. libutil.
  ld-linux libstdc++. libgcc_s. libnsl. libcrypt.
)

is_system_lib() {
  local name="$1"
  for prefix in "${SYSTEM_LIB_PREFIXES[@]}"; do
    [[ "$name" == "$prefix"* ]] && return 0
  done
  return 1
}

mapfile -t libs < <(ldconfig -p 2>/dev/null | awk '/libarchive\.so/ {print $NF}' | sort -u)

if [[ "${#libs[@]}" -eq 0 ]]; then
  printf 'libarchive was not found by ldconfig. Install libarchive first.\n' >&2
  exit 1
fi

declare -A copied=()

vendor_lib() {
  local src="$1"
  local base
  base="$(basename "$src")"
  [[ -n "${copied[$base]:-}" ]] && return 0
  [[ -f "$src" ]] || return 0
  cp -L "$src" "$DEST_DIR/$base"
  copied[$base]=1

  while read -r dep; do
    [[ -n "$dep" ]] || continue
    is_system_lib "$(basename "$dep")" && continue
    vendor_lib "$dep"
  done < <(ldd "$src" 2>/dev/null | awk '/=>/ && $3 ~ /^\// {print $3}')
}

for lib in "${libs[@]}"; do
  vendor_lib "$lib"
done

if command -v patchelf >/dev/null 2>&1; then
  for so in "$DEST_DIR"/*.so*; do
    [[ -f "$so" ]] || continue
    patchelf --set-rpath '$ORIGIN' "$so"
  done
else
  printf 'patchelf not found; vendored libs will not be relocatable.\n' >&2
  exit 1
fi

if compgen -G "$DEST_DIR/libarchive.so*" >/dev/null; then
  printf 'Vendored libarchive bundle:\n'
  find "$DEST_DIR" -maxdepth 1 -type f -name '*.so*' -printf '  %f\n' | sort
else
  printf 'No libarchive files were copied.\n' >&2
  exit 1
fi
