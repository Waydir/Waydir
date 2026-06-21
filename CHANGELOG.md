# Changelog

All notable changes to Waydir will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Global toolbar.

## [0.19.0] - 2026-06-20

### Added
- Quick Look: Markdown preview for `.md` and `.markdown` files.
- More shortcuts are now customizable: Delete, Rename, New Folder, and dual-pane Copy/Move.
- Customizable shortcut for permanent delete (defaults to `Ctrl+Delete`), now separate from move-to-trash.
- Resizable columns in the file list (toggle in Appearance).
- Collapsible sidebar sections.
- Terminal: configurable copy/paste modifier (Standard `Ctrl+C`/`Ctrl+V` vs. `Ctrl+Shift+C`/`Ctrl+Shift+V`, platform-aware default) in Terminal preferences.

### Fixed
- Renaming the same item repeatedly no longer loses focus.
- Spacing between list view columns cleaned up.

## [0.18.0] - 2026-06-16

### Added
- macOS: "Date added" column showing when a file appeared in its current folder. ([#173](https://github.com/Waydir/Waydir/issues/173)) ([@fwitkowski17](https://github.com/fwitkowski17))
- macOS: closing the window now keeps the app in the dock instead of quitting, and reopening it (dock click or Cmd+N) brings the window back. ([@fwitkowski17](https://github.com/fwitkowski17))
- Windows: WSL support. Browse WSL distributions from the sidebar.
- Terminal: the new-tab dropdown lets you pick any shell, or a WSL distribution, to launch the next terminal session.
- Terminal: Ctrl+Enter inserts relative paths and Ctrl+Shift+Enter inserts absolute paths for the current file selection.
- Menu bar: View menu now marks the active layout (list/grid), and a new Terminal menu toggles the panel and manages terminal tabs.
- Selection: Invert selection (`Ctrl+I`).
- Navigation: `Home`/`End` jump to the first/last item (Shift extends the selection).
- Calculate folder sizes (`Alt+S`); sizes show live in the Size column and sort with it.

### Fixed
- "Show folders before files" preference now applies; removed the duplicate toggle from the sort menu.
- Sort by size now treats folders as size 0 and keeps them name-ascending, instead of using the directory inode size.
- PDF preview crash when rapidly switching between files ([#175](https://github.com/Waydir/Waydir/issues/175)).
- "Date created" now uses real birth time instead of ctime ([#174](https://github.com/Waydir/Waydir/issues/174)).
- File operations now report a clean "Permission denied" message (instead of a raw error string) across more cases, including SFTP/SMB transfers and Windows access-denied errors.
- Quick Look: line numbers now have more room before the editor content.
- Insert now starts keyboard selection from the current file instead of clearing it on the first press.

## [0.17.0] - 2026-06-14

### Added
- Quick Look: PDF preview.
- Sort menu (status bar button and right-click), so sorting works in grid view too.
- Appearance: "Show folders before files" toggle.
- Type-ahead jump: quickly typed letters combine into a search string (toggle in General settings).
- Jump to bookmarks with Ctrl/Cmd+Shift+1..9.

### Fixed
- Grid view now supports left/right arrow navigation, drag selection, file dragging and Appearance spacing/density settings.
- Updates now verify downloaded files before installing.

## [0.16.0] - 2026-06-13

### Added
- Grid view with image thumbnails.
- Search now has a Filter mode with query suggestions for kind, extension, size, date and hidden-file filters.
- Quick Look: prompts to save, discard or cancel when closing the editor with unsaved changes.
- Quick Look: relative line numbers option, showing distance from the current line.
- Quick Look: option to turn off the statistics panel for multi-selection properties.
- The path bar now expands environment variables: `%VAR%` on Windows and `$VAR`/`${VAR}` on Linux and macOS. ([#163](https://github.com/Waydir/Waydir/issues/163))
- Command-line support: launch Waydir with folder paths and options to open straight to a location. Run `waydir --help` for details. ([#164](https://github.com/Waydir/Waydir/issues/164))

### Changed
- The file list now shows descriptive Kind labels by default, with the default column order set to Name, Kind, Size, then Date.
- Quick Look editor now uses a viewport-virtualized engine (re_editor), so editing stays fast even on very large files.
- Quick Look now previews text files up to 32 MB (was 4 MB); syntax highlighting is skipped above 1 MB to keep large files instant.
- The changelog viewer now shows only released versions with cleaner headings.
- Quick Look now shows a Created date and formats dates using your date-format preference.

### Fixed
- Terminal: text lines no longer bleed above the panel into the widgets above it.
- Terminal: Alt+letter shortcuts now send the lowercase key (for example Alt+v sends `ESC v`), so meta keybindings work.
- Terminal: Ctrl+V now passes through to the running app when the clipboard holds an image, so it can handle the image paste itself.
- Quick Look: Ctrl+S (Cmd+S) now saves edits in the editor.
- Quick Look: the line-number gutter now always widens to fit the longest number.
- Quick Look: line numbers now align with their lines on Windows.
- Windows: the Permissions and Owner columns and the Quick Look permissions row, which are POSIX-only, are no longer shown.

## [0.15.0] - 2026-06-11

### Added
- Changelog viewer: open it from the Waydir menu to read all release notes rendered as Markdown.
- Quick Look preferences: choose the editor font and line height, show line numbers, toggle line wrapping and enable a basic Vim mode for editing previews.
- File list columns can be configured: toggle Size, Date modified, Kind, Date created, Permissions and Owner on or off, and drag to reorder them. Every column is sortable.
- The path bar now expands `~` to the home folder. ([@fwitkowski17](https://github.com/fwitkowski17))
- macOS: Waydir now prompts for Full Disk Access when needed. ([@fwitkowski17](https://github.com/fwitkowski17))

### Fixed
- Copying, pasting and dragging files into an empty folder now works. ([@fwitkowski17](https://github.com/fwitkowski17))
- macOS: the Videos location now opens the Movies folder. ([@fwitkowski17](https://github.com/fwitkowski17))
- macOS: files copied in Finder can now be pasted in Waydir, and Waydir's own copies are recognized by Finder. ([@fwitkowski17](https://github.com/fwitkowski17))

## [0.14.0] - 2026-06-10

### Added
- Sidebar edit mode: reorder sections and items by dragging, and hide ones you don't use. Every item now has a right-click menu (open, copy path, properties, eject, and more).
- File and terminal tabs can now be reordered by dragging.
- One Dark is now available as a built-in theme.

### Changed
- Reworked sidebar spacing for consistent alignment, and renamed the Favorites section to Places.
- Multi Rename now appears in Operations with progress while files are being renamed.

### Fixed
- Operation cancellation no longer gets stuck in the cancelling state.
- Terminal text selection now auto-scrolls and keeps the selected range correct.

## [0.13.0] - 2026-06-10

### Added
- Debian/Ubuntu and Fedora/RHEL/openSUSE package repositories: install Waydir from an apt or dnf/zypper repository and receive new releases through your regular package manager updates.

### Changed
- deb and rpm builds no longer install updates from within the app. When Waydir runs from a package, the updater now points you to your package manager (`apt upgrade` / `dnf upgrade`), which the repository keeps up to date.

## [0.12.0] - 2026-06-09

### Added
- Quick Look shortcuts now have their own section in the keyboard shortcuts, and a hint bar at the bottom of the Quick Look window shows the available keys. The close key can be remapped (defaults to Space).
- Plugins can register global and per-pane status bars with periodically refreshed text, badges, icons and buttons.

### Fixed
- Quick Look: arrow keys keep moving between files even when an editable file is open; Ctrl/⌥ + arrows switch files while editing.
- The rename shortcut now starts multi-rename when several files are selected.
- A failing plugin action now shows an error notification instead of crashing the app.
- Plugin enable/disable state now updates immediately in Preferences.

## [0.11.0] - 2026-06-09

### Added
- Plugins can create and update custom entries in the Operations panel with `waydir.operation_start`, `waydir.operation_update`, and `waydir.operation_finish`.
- Plugin `run_task` can show long-running external commands in Operations with optional regex-based progress parsing.
- Plugins can query local file sizes with `waydir.file_size`.

## [0.10.1] - 2026-06-08

### Changed
- Plugins: `waydir.exec` now returns the command's stdout, stderr, and exit code.

## [0.10.0] - 2026-06-08

### Added
- Windows: entering a bare server (`\\computername`) now lists its shared folders, the way Explorer does.
- Confirm button in the editable path bar.
- Plugin system: extend Waydir with small Lua plugins that add context-menu, menu bar, toolbar, and keyboard-shortcut actions. Manage and configure them in Preferences → Plugins. See [docs/plugins.md](docs/plugins.md) for the guide and example plugins.
- Preferences option to sort only files and keep folders in their default order.

### Fixed
- SMB: listing a host's shares now prompts for a password when one is required.
- Restoring a session no longer hangs on startup when the last folder was a network path; on any restore failure Waydir falls back to the home folder and logs the error.
- Cancel now stops a copy or move immediately during scanning.
- Sidebar scrollbar no longer overlaps the resize edge, so both are easy to grab.
- Root path `/` now shows in the path bar.
- macOS: files and folders now show up reliably (the native core is shipped as a universal binary).
- macOS: drive size and usage in tooltips are no longer doubled.
- Linux: the AppImage now uses a gzip-compressed squashfs and a statically linked runtime, so it runs on older squashfuse / AppImageLauncher and on fuse3-only systems without libfuse2.

### Changed
- Windows: drive names now read `Local Disk (C:)`, and network drives show the share name like `share (Z:)`.
- Shortcuts modal grouped into clearer categories (separate View, Terminal, and General sections).

## [0.9.1] - 2026-06-02

### Changed
- macOS: menus moved to the native menu bar.

### Fixed
- AppImage now links to the download instead of failing an in-place update.

## [0.9.0] - 2026-06-02

### Added
- The sidebar can be resized by dragging its edge, and collapses to an icon-only rail when narrowed past a threshold; the width is remembered.
- Linux builds are now also published as an AppImage (portable, no install).
- Page Up / Page Down move the cursor by a page in the file list (Shift extends the selection).
- Shell selection for the built-in terminal.
- "Open in Terminal" lists the external terminals detected on the system instead of only auto-detect.

### Changed
- "Open in Terminal" now opens the built-in terminal by default; the external terminal stays available in Preferences.

### Fixed
- Windows network breadcrumbs split the server and share, so you can click the server to browse its shares.
- Shift + arrow keys now extend the selection in the file list.
- Terminal tabs and the new-tab/close buttons now show hover feedback.
- Resizing the terminal panel is now smooth (the drag no longer rebuilds the whole pane on every frame).
- The split between dual panes is easier to grab (wider, reliable drag target).

## [0.8.0] - 2026-06-01

### Added
- Natural sort order (enabled by default): numbers in file names sort by value, so "file2" comes before "file10". Can be toggled in Preferences → Appearance.
- Sidebar network entries now show a tooltip with the full name (and remote target) when the label is truncated.

### Fixed
- New folders no longer briefly appear twice before a refresh.
- After creating a folder you can open it with Enter right away, without clicking the list first.
- Windows network drives now show the drive letter first in the label.
- Windows: listing a bare network share root (`\\server\share`) now works.

### Changed
- Network drives no longer show an eject button (SFTP/SMB connections keep their disconnect action).

## [0.7.0] - 2026-05-31

### Added
- Features dialog with short guides and demo clips for the main features.
- Embedded terminal in each pane with remote connections support.
- Terminal preferences: font, size, line height and system font picker.
- Content search: a "Content" toggle in the search bar matches inside file contents.
- Keyboard shortcut (Ctrl+L) to focus the path bar.
- Tokyo Night built-in theme.
- Gruvbox built-in theme (dark and light).
- Dracula built-in theme.
- Solarized built-in theme (dark and light).
- Catppuccin built-in theme (Mocha and Latte).

### Changed
- Terminal keyboard shortcuts are now customizable.
- Window title now follows the active folder.

### Fixed
- Portable updates on Windows now apply correctly.
- Various small UI fixes and polish.

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

[Unreleased]: https://github.com/Waydir/Waydir/compare/v0.17.0...HEAD
[0.17.0]: https://github.com/Waydir/Waydir/compare/v0.16.0...v0.17.0
[0.16.0]: https://github.com/Waydir/Waydir/compare/v0.15.0...v0.16.0
[0.15.0]: https://github.com/Waydir/Waydir/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/Waydir/Waydir/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/Waydir/Waydir/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/Waydir/Waydir/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/Waydir/Waydir/compare/v0.10.1...v0.11.0
[0.10.1]: https://github.com/Waydir/Waydir/compare/v0.10.0...v0.10.1
[0.10.0]: https://github.com/Waydir/Waydir/compare/v0.9.1...v0.10.0
[0.9.1]: https://github.com/Waydir/Waydir/compare/v0.9.0...v0.9.1
[0.9.0]: https://github.com/Waydir/Waydir/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/Waydir/Waydir/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/Waydir/Waydir/compare/v0.6.1...v0.7.0
[0.6.1]: https://github.com/Waydir/Waydir/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/Waydir/Waydir/compare/v0.5.1...v0.6.0
[0.5.1]: https://github.com/Waydir/Waydir/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/Waydir/Waydir/compare/v0.4.1...v0.5.0
[0.4.1]: https://github.com/Waydir/Waydir/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/Waydir/Waydir/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/Waydir/Waydir/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/Waydir/Waydir/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/Waydir/Waydir/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/Waydir/Waydir/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Waydir/Waydir/releases/tag/v0.1.0
