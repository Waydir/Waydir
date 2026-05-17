# Changelog

All notable changes to Waydir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-05-17

### Fixed
- Linux RPM no longer fails to install on Fedora and other non-Debian distros due to an unresolvable `libbz2.so.1.0` dependency. The package now bundles libarchive together with its runtime libraries, making it self-contained across distributions.

## [0.3.0] - 2026-05-17

### Added
- Archive support: browse, extract, compress, and edit archives (ZIP, TAR, 7z, RAR, and more) like regular folders.
- File preview with Space (Quick Look) for images, text, and code.
- Open files with a chosen app and manage default apps per file type.
- Sidebar bookmarks.
- Preferences dialog with General, Appearance, and About sections.
- Command palette opened with Ctrl+P for quick app actions.
- Keyboard shortcut for opening Preferences with Ctrl+,.
- Git status bar with branch switching, stash management, and repository state.
- Refresh the current folder with Ctrl+R.

### Changed
- Much faster directory listing, recursive search, and delete scans, especially in very large folders, thanks to a new native core.
- Show Hidden Files from the View menu now applies globally to all open panes and tabs.
- Simplified the sidebar collapse button to an icon-only control.

## [0.2.0] - 2026-05-13

### Added
- Dynamic drive management with real-time detection of connected drives.
- Mount and unmount drives directly from the sidebar.
- Mouse drag selection (lasso) to easily select multiple files.
- Windows support (paths, drives, breadcrumbs, system file filtering, native file opening).
- View menu with dual-pane and hidden-file toggles.
- Notification history access from the status bar.
- Active operation progress shortcut in the sidebar.

### Changed
- Polished the main layout, sidebar, status bar, title bar, and notification surfaces.
- Moved operation and notification controls out of the pane toolbar for a cleaner file view.
- Improved file operation conflict notifications with apply-to-all actions.
- Migrated settings persistence from JSON file to SQLite via Drift.
- Removed `scaled_app` and custom UI scaling system.

### Fixed
- Safer file replacement during copy operations, including Windows replace handling and temporary-file cleanup.
- More resilient filesystem worker startup, failure handling, and disposal.
- Operation conflict handling now correctly waits for user resolution and keeps conflict state in sync.
- Double title bar on Windows.
- Remove autostart from Windows installer.
- Disable macOS app sandbox to allow full filesystem access.

## [0.1.1] - 2026-05-09

### Fixed
- UI scaling across the app via `scaled_app` integration.

## [0.1.0] - 2026-05-09

### Added
- Initial public release.
- Dual-pane file browsing with tabs.
- Keyboard-driven workflow with custom shortcuts.
- File operations (copy, move, delete) with progress panel and notifications.
- Custom dark theme and custom title bar.
- Settings store with persistent user preferences.

[Unreleased]: https://github.com/mikolajbadyl/waydir/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/mikolajbadyl/waydir/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/mikolajbadyl/waydir/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/mikolajbadyl/waydir/releases/tag/v0.1.0
