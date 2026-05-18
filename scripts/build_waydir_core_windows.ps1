# Builds the native waydir_core helper (Rust, release) on Windows and
# vendors waydir_core.dll into third_party/waydir_core/windows/ so the
# Windows CMake bundling step ships it next to the executable.
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $PSScriptRoot
$crate = Join-Path $here "rust\waydir_core"

$pubspec = Get-Content (Join-Path $here "pubspec.yaml")
$verLine = $pubspec | Where-Object { $_ -match '^version:' } | Select-Object -First 1
if ($verLine -match '([0-9]+\.[0-9]+\.[0-9]+)') { $env:WAYDIR_VERSION = $Matches[1] }

cargo build --release --manifest-path (Join-Path $crate "Cargo.toml")

$out = Join-Path $crate "target\release\waydir_core.dll"
$dest = Join-Path $here "third_party\waydir_core\windows"

New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Force $out (Join-Path $dest "waydir_core.dll")
Write-Host "vendored: $dest\waydir_core.dll"
