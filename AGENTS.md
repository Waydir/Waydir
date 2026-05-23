# Waydir

Desktop file manager built with Flutter/Dart. Fast, minimal, dark theme, keyboard-driven navigation. Targets: Linux, macOS, Windows.

Linux and Windows are the primary development and testing targets. macOS builds come from the same codebase but are not regularly tested - treat parity as best-effort and flag macOS-specific risks rather than assuming they work.

## Project structure

Feature-driven structure:

- `lib/core/` - cross-cutting services: `archive`, `clipboard`, `database`, `fs`, `keyboard`, `logging`, `models`, `open`, `platform`, `settings`, `terminal`
- `lib/features/` - feature modules: `drives`, `files`, `git`, `navigation`, `operations`, `panes`, `quick_look`, `settings`, `tabs`
- `lib/ui/` - shared UI: `chrome`, `dialogs`, `icons`, `overlays`, `theme`, `widgets`, `window`
- `lib/app/` - main app widget and page
- `lib/i18n/` - translations (slang); currently English only
- `rust/waydir_core/` - native Rust core (cdylib) for path-heavy work (listing, search, trash)
- `third_party/waydir_core/{linux,windows,macos}/` - vendored prebuilt native libs loaded at runtime via `lib/core/fs/waydir_core_loader.dart`
- `test/unit/`, `test/integration/`, `test/support/` - tests split by kind, not a strict mirror of `lib/`

Each feature has its own folder with views and store.

## Key patterns

- **Signals** (`signals` package) - all reactive state via `signal()`, `computed()`, `batch()`
- **Isolated operations** - copy/move/delete run in separate Isolates, never block UI
- **FsWorkerPool** - isolate pool for simple FS ops (list, stat, exists, etc.)
- **Native Rust core** - heavy FS work (recursive list, search, trash) goes through `rust/waydir_core` via FFI, off the UI thread
- **drift + sqlite3** - persistent state in `lib/core/database/app_database.dart`; regenerate with build_runner after schema changes
- **Custom window chrome** - `bitsdojo_window`-based custom title bar in `lib/ui/chrome/` and `lib/ui/window/`
- **slang** for i18n - translations in `lib/i18n/*.i18n.json`, generated via `slang_build_runner`

## Signals usage

- All signals live in store classes (e.g. `NavigationStore`, `OperationStore`), never in widgets
- Stores are passed to widgets via constructor params
- Consume signals in UI with `Watch((context) => ...)` from `signals_flutter`
- `setState` is only for purely local widget state (_hovered, _dragging, etc.)
- Do NOT use: `StreamBuilder`, `ValueNotifier`, `ChangeNotifier`, `InheritedWidget` for state

## Commands

- `dart format .` - format code
- `flutter analyze` - static analysis
- `flutter test` - run tests
- `flutter test --exclude-tags=integration` - run fast unit tests only
- `flutter test --tags=integration` - run integration tests only
- `dart run slang` - regenerate translations after JSON changes
- `dart run build_runner build --delete-conflicting-outputs` - regenerate drift code after DB schema changes
- `scripts/build_waydir_core.sh` / `scripts/build_waydir_core_windows.ps1` - build and vendor the native Rust core
- `fastforge package --platform <linux|windows|macos> --targets <deb|rpm|appimage|exe|zip|dmg>` - build installable artifacts (config in `distribute_options.yaml` and `*/packaging/`). Windows `exe` target requires Inno Setup installed.

## Git

- NEVER push
- Each feature on a separate branch
- Conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`
- Commit messages: title only, no body

## Styling

- Never hardcode `TextStyle(fontSize: …)` in widgets. Use roles from `AppTextStyles` via `context.txt.<role>` (e.g. `context.txt.row`, `context.txt.dialogTitle`, `context.txt.keyCap`)
- For per-instance overrides (color, fontStyle), use `context.txt.row.copyWith(color: …)`
- If no existing role fits, add a new one to `lib/ui/theme/app_text_styles.dart` (don't inline)
- Colors: use `AppColors.*` from `lib/ui/theme/app_theme.dart`, never raw `Color(0x…)` in widgets

## Rules

- No code comments
- No unnecessary dependencies
- Tests split into `unit/` and `integration/` under `test/`
- Translation keys in English
