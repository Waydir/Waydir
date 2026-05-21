# Waydir

Desktop file manager built with Flutter/Dart. Fast, minimal, dark theme, keyboard-driven navigation. Targets: Linux, macOS, Windows.

## Project structure

Feature-driven structure:

- `lib/core/` - models, FS services, keyboard, clipboard
- `lib/features/` - features (navigation, operations, files)
- `lib/ui/` - shared UI components (theme, dialogs, overlays)
- `lib/app/` - main app widget and page
- `lib/i18n/` - translations (slang)
- `test/` - tests (mirrors `lib/` structure)

Each feature has its own folder with views and store.

## Key patterns

- **Signals** (`signals` package) - all reactive state via `signal()`, `computed()`, `batch()`
- **Isolated operations** - copy/move/delete run in separate Isolates, never block UI
- **FsWorkerPool** - isolate pool for simple FS ops (list, stat, exists, etc.)
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

## Git

- NEVER push
- Each feature on a separate branch
- Conventional commits: `feat:`, `fix:`, `refactor:`, `chore:`, `test:`
- Short, clear commit messages

## Styling

- Never hardcode `TextStyle(fontSize: …)` in widgets. Use roles from `AppTextStyles` via `context.txt.<role>` (e.g. `context.txt.row`, `context.txt.dialogTitle`, `context.txt.keyCap`)
- For per-instance overrides (color, fontStyle), use `context.txt.row.copyWith(color: …)`
- If no existing role fits, add a new one to `lib/ui/theme/app_text_styles.dart` (don't inline)
- Colors: use `AppColors.*` from `lib/ui/theme/app_theme.dart`, never raw `Color(0x…)` in widgets

## Rules

- No code comments
- No unnecessary dependencies
- Tests mirror `lib/` structure
- Translation keys in English
