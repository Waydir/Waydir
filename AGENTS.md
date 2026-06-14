# Waydir

Desktop file manager built with Flutter/Dart. Fast, minimal, dark theme, keyboard-driven navigation. Targets: Linux, macOS, Windows.

## Project structure

Feature-driven structure:

- `lib/core/` - cross-cutting services: `archive`, `clipboard`, `database`, `fs`, `keyboard`, `logging`, `models`, `open`, `platform`, `settings`, `terminal`
- `lib/features/` - feature modules: `drives`, `files`, `git`, `navigation`, `operations`, `panes`, `plugins`, `quick_look`, `settings`, `tabs`
- `lib/ui/` - shared UI: `chrome`, `dialogs`, `icons`, `overlays`, `theme`, `widgets`, `window`
- `lib/app/` - main app widget and page
- `lib/utils/` - small helpers: `drag_drop`, `format`
- `lib/i18n/` - translations (slang); currently English only
- `docs/` - `plugins.md` plugin authoring guide, plus `examples/`, `screenshots/`, `gifs/`
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
- **FFI plugins** - `lib/features/plugins/` loads plugins through the native core via FFI (`plugin_ffi.dart`); authoring guide in `docs/plugins.md`

## Signals usage

- All signals live in store classes (e.g. `NavigationStore`, `OperationStore`), never in widgets
- Stores are passed to widgets via constructor params
- Consume signals in UI with `Watch((context) => ...)` from `signals_flutter`
- `setState` is only for purely local widget state (_hovered, _dragging, etc.)
- Do NOT use: `StreamBuilder`, `ValueNotifier`, `ChangeNotifier`, `InheritedWidget` for state

## Commands

- `scripts/check.sh` - **run after every change**: builds native core if missing, then `dart format` + `flutter analyze` + full `flutter test`
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

- After any change: run `dart format .` to reformat, then `scripts/check.sh` and make sure it passes
- No code comments
- No unnecessary dependencies
- Tests split into `unit/` and `integration/` under `test/`
- Integration tests must start with `@Tags(<String>['integration'])` on line 1 so they pick up the 2x timeout from `dart_test.yaml` and the tag filters
- Integration tests need the native `waydir_core` library; build it with `scripts/build_waydir_core.sh` (or just run `scripts/check.sh`) or they fail with "Native waydir_core not found"
- Translation keys in English
