# Changelog

All notable changes to Waydir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.1] - 2026-05-28

### Fixed
- Breadcrumb path suggestions now scroll to the highlighted item when navigating with arrow keys.

## [0.6.0] - 2026-05-27

### Added
- Breadcrumb path entry now suggests folders and recent paths.
- File checksums can now be calculated and verified with MD5 and SHA-256.
- File list horizontal and vertical spacing can now be adjusted in Preferences.
- Properties now shows statistics for selected files and folders.
- Leave the Share field empty when connecting to SMB to browse the server's shared folders.
- Waydir now remembers the selection, cursor and sort order for each folder. Both can be toggled off in Preferences.

### Changed
- File list scrollbar is now always visible and reserves space at the right edge.
- Breadcrumb bar rebuilt with better overflow handling for long folder names.
- Toolbar buttons collapse into a menu when the pane is narrow.

### Fixed
- Window resize hit area is now tighter on Linux and Windows.

## [0.5.1] - 2026-05-25

### Fixed
- UI fixes.
- Archive creation and browsing fixes.
- UI no longer freezes when enqueuing copy/move from mapped network drives on Windows.

## [0.5.0] - 2026-05-25

### Added
- Devices tooltip now shows numeric disk usage details.
- Trash restore and permanent delete operations now show titles and progress in the operations panel.
- Jump to files by typing a letter. Press the same letter again to cycle through matches.
- Selection and cursor position are now restored when going back/forward and preserved across file operations.
- Selection can now be saved to a text file and loaded back by matching visible item names in the current view.
- Search supports regex and glob patterns alongside substring matching. Switch between modes from the new segmented toggle in the search bar.
- File operations now show current transfer speed and ETA in the operations panel.
- Connect to network drives over SMB and SFTP from the sidebar's Network section. Browse, open, copy, move, and delete remote files like local ones.

### Changed
- UI improvements.
- Properties view no longer shows read-error messages; it always displays the available details.
- Recursive search results now use the normal file list layout with size, modified date, and a shortened location column.

### Fixed
- Pressing D no longer toggles dual pane.
- Properties for recursive search results now show correct file size and modified date.
- Dismissing a file operation while waiting for conflict resolution now skips the remaining conflicts and resumes the task instead of leaving it stuck.

## [0.4.1] - 2026-05-21

### Changed
- Removed the 5,000 result cap on recursive search. Results stream in faster on fast drives.

### Fixed
- Search result counter now updates with the query.
- Archive name no longer ends up empty at filesystem root; uses the drive letter on Windows or `archive` otherwise. Empty names are also blocked in the compress dialog.
- Cancel button now actually stops archive operations.
- Windows: maximized window no longer overflows past the screen edges.

## [0.4.0] - 2026-05-20

### Added
- Confirmation dialogs before copying and moving files, with per-action toggles in Preferences (off for copy, on for move by default).
- Confirmation dialogs can now be accepted with Enter or dismissed with Esc.
- Light and Nord built-in themes.
- Custom theme management: create, edit, and delete your own themes via JSON files in Preferences.
- Ctrl+H shortcut to toggle hidden files.
- Ctrl+S shortcut to select files by a pattern (e.g. `*.jpg`).
- Quick Look now shows a combined summary (total size and item count) when multiple files and folders are selected.
- Recursive search now streams results as they are found, with a live counter of scanned entries instead of waiting for the full scan to complete.
- Devices in the sidebar now show mounted disk usage with a thin color-coded bar.

### Changed
- Replaced old file icons with beautiful new SVG Material icons.
- Completely rebuilt Quick Look for a cleaner preview experience with better file details, image viewing, and text/code editing.
- Holding Up/Down now moves through files continuously at a controlled pace.
- Faster directory scanning in large folders thanks to improved parallel walk.

### Fixed
- Windows: entering a drive without a trailing backslash (e.g. `X:`) no longer chops the first letter from breadcrumb segments and subpaths.
- Right-click context menu on files now opens instantly instead of briefly hanging while resolving the default app.
- Cascading context submenus now close when the pointer leaves both the parent item and the submenu.
- Fixed archives not working on Windows.

### Removed
- Command palette (Ctrl+P).

## [0.3.1] - 2026-05-17

### Fixed
- Linux RPM no longer fails to install on Fedora and other non-Debian distros due to an unresolvable `libbz2.so.1.0` dependency.

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

[Unreleased]: https://github.com/Waydir/Waydir/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/Waydir/Waydir/compare/v0.5.1...v0.6.0
[0.2.0]: https://github.com/Waydir/Waydir/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/Waydir/Waydir/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Waydir/Waydir/releases/tag/v0.1.0
