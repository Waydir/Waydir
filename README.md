<div align="center">

# Waydir

A fast, keyboard-driven desktop file manager built with Flutter.

[![Flutter](https://img.shields.io/badge/Flutter-3.35+-02569B?logo=flutter&logoColor=white&style=flat-square)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart&logoColor=white&style=flat-square)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Linux%20%7C%20Windows%20%7C%20macOS-informational?style=flat-square)]()

</div>

![Waydir](docs/screenshots/waydir.png)

![Waydir dual pane](docs/screenshots/waydir-dual-pane.png)

## What is Waydir?

Waydir is the file manager I wanted on my own machine: hands stay on the keyboard, the UI gets out of the way, and opening a 100k-file directory doesn't lock up the window.

The interface is built with Flutter and runs natively on Linux, Windows and macOS from one codebase. The path-heavy work - directory listing, search, and delete - runs in a native Rust core, off the UI thread.

## Install

Download the latest build from the [Releases](https://github.com/Waydir/Waydir/releases) page.

Linux builds are available as `.deb`, `.rpm`, and `.tar.gz` packages. Windows builds are available as an `.exe` installer and a `.zip` archive. macOS builds are available as a `.dmg` package.

On Linux, the portable archive can be unpacked and launched directly:

```bash
tar -xzf waydir-*-linux-x64.tar.gz
./waydir
```

## Features

- Dual-pane navigation with tabs
- Keyboard-driven navigation, selection, and file operations
- Recursive search that streams results live with a scanned-entry counter
- Copy / move / delete with conflict resolution and progress tracking
- Clipboard integration
- Archive support: browse, extract, compress, and edit ZIP, TAR, and more
- Quick Look file preview with Space - images, text, and code
- Open files with a chosen app and manage defaults per file type
- Git status bar with branch switching and stash management
- Sidebar bookmarks and drive management (mount/unmount)
- Light, Dark, and Nord built-in themes, plus custom themes via JSON
- Preferences dialog for appearance, behavior, and terminal integration
- Native Rust core, with background scanning that keeps the UI responsive
- Native builds for Linux, Windows, and macOS from one codebase

## Development

Requires Flutter 3.35+, Dart 3.10+, and Rust stable ([rustup](https://rustup.rs)).
`waydir_core` (Rust) handles directory listing, search and delete - there is no
Dart fallback.

```bash
git clone https://github.com/Waydir/Waydir.git
cd waydir
flutter pub get
cargo build --release --manifest-path rust/waydir_core/Cargo.toml
flutter run -d linux
```

> The Rust build must be `--release` and commands run from the repo root.
> Rebuild and restart the app after editing `rust/waydir_core` (no hot reload).
> For packaged builds use `scripts/build_waydir_core.sh` (Windows:
> `scripts/build_waydir_core_windows.ps1`).

Run checks before opening a PR:

```bash
scripts/build_waydir_core.sh
dart format .
flutter analyze
flutter test
```

Build a release binary locally:

```bash
flutter build linux
flutter build windows
flutter build macos
```

## Contributing

PRs are welcome. Before opening one:

1. `dart format .`
2. `flutter analyze` - must be clean.
3. `flutter test` - must be green.

CI runs the same three on every PR (see `.github/workflows/`). Keep commits focused; small PRs land faster than big ones.

If you're picking up something non-trivial, open an issue first so we can sync on the approach.

## License

[MIT](LICENSE)
