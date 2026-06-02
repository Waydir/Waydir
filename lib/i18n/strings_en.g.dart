///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en app = Translations$app$en.internal(_root);
	late final Translations$terminal$en terminal = Translations$terminal$en.internal(_root);
	late final Translations$menu$en menu = Translations$menu$en.internal(_root);
	late final Translations$multiRename$en multiRename = Translations$multiRename$en.internal(_root);
	late final Translations$compress$en compress = Translations$compress$en.internal(_root);
	late final Translations$checksum$en checksum = Translations$checksum$en.internal(_root);
	late final Translations$properties$en properties = Translations$properties$en.internal(_root);
	late final Translations$preferences$en preferences = Translations$preferences$en.internal(_root);
	late final Translations$update$en update = Translations$update$en.internal(_root);
	late final Translations$appMenu$en appMenu = Translations$appMenu$en.internal(_root);
	late final Translations$help$en help = Translations$help$en.internal(_root);
	late final Translations$keybindings$en keybindings = Translations$keybindings$en.internal(_root);
	late final Translations$commandPalette$en commandPalette = Translations$commandPalette$en.internal(_root);
	late final Translations$quickLook$en quickLook = Translations$quickLook$en.internal(_root);
	late final Translations$toast$en toast = Translations$toast$en.internal(_root);
	late final Translations$selectionFile$en selectionFile = Translations$selectionFile$en.internal(_root);
	late final Translations$dragHint$en dragHint = Translations$dragHint$en.internal(_root);
	late final Translations$fileView$en fileView = Translations$fileView$en.internal(_root);
	late final Translations$sidebar$en sidebar = Translations$sidebar$en.internal(_root);
	late final Translations$trash$en trash = Translations$trash$en.internal(_root);
	late final Translations$toolbar$en toolbar = Translations$toolbar$en.internal(_root);
	late final Translations$notifications$en notifications = Translations$notifications$en.internal(_root);
	late final Translations$search$en search = Translations$search$en.internal(_root);
	late final Translations$statusBar$en statusBar = Translations$statusBar$en.internal(_root);
	late final Translations$dialog$en dialog = Translations$dialog$en.internal(_root);
	late final Translations$password$en password = Translations$password$en.internal(_root);
	late final Translations$selectPattern$en selectPattern = Translations$selectPattern$en.internal(_root);
	late final Translations$operations$en operations = Translations$operations$en.internal(_root);
	late final Translations$errors$en errors = Translations$errors$en.internal(_root);
	late final Translations$tasks$en tasks = Translations$tasks$en.internal(_root);
	late final Translations$git$en git = Translations$git$en.internal(_root);
	late final Translations$openWith$en openWith = Translations$openWith$en.internal(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Waydir'
	String get title => 'Waydir';

	/// en: 'Navigate your files. Your way.'
	String get tagline => 'Navigate your files. Your way.';

	/// en: 'A fast, keyboard-driven desktop file manager built with Flutter.'
	String get description => 'A fast, keyboard-driven desktop file manager built with Flutter.';
}

// Path: terminal
class Translations$terminal$en {
	Translations$terminal$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Terminal'
	String get title => 'Terminal';
}

// Path: menu
class Translations$menu$en {
	Translations$menu$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'View'
	String get view => 'View';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Open $count Items'
	String openItems({required Object count}) => 'Open ${count} Items';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Cut'
	String get cut => 'Cut';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Copy Path'
	String get copyPath => 'Copy Path';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Delete $count Items'
	String deleteItems({required Object count}) => 'Delete ${count} Items';

	/// en: 'Move to Trash'
	String get moveToTrash => 'Move to Trash';

	/// en: 'Move $count Items to Trash'
	String moveToTrashItems({required Object count}) => 'Move ${count} Items to Trash';

	/// en: 'Delete Permanently'
	String get deletePermanently => 'Delete Permanently';

	/// en: 'Delete $count Items Permanently'
	String deletePermanentlyItems({required Object count}) => 'Delete ${count} Items Permanently';

	/// en: 'Restore'
	String get restore => 'Restore';

	/// en: 'Restore $count Items'
	String restoreItems({required Object count}) => 'Restore ${count} Items';

	/// en: 'Show Hidden Files'
	String get showHidden => 'Show Hidden Files';

	/// en: 'Select All'
	String get selectAll => 'Select All';

	/// en: 'Select by Pattern…'
	String get selectByPattern => 'Select by Pattern…';

	/// en: 'Deselect All'
	String get deselectAll => 'Deselect All';

	/// en: 'Save Selection to File…'
	String get saveSelection => 'Save Selection to File…';

	/// en: 'Load Selection from File…'
	String get loadSelection => 'Load Selection from File…';

	/// en: 'Open in Terminal'
	String get openInTerminal => 'Open in Terminal';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Open Location'
	String get openLocation => 'Open Location';

	/// en: 'Open in New Tab'
	String get openInNewTab => 'Open in New Tab';

	/// en: 'Remove Bookmark'
	String get removeBookmark => 'Remove Bookmark';

	/// en: 'Dual Pane Mode'
	String get dualPaneMode => 'Dual Pane Mode';

	/// en: 'Properties'
	String get properties => 'Properties';

	/// en: 'Open With'
	String get openWith => 'Open With';

	/// en: 'Open With $app'
	String openWithApp({required Object app}) => 'Open With ${app}';

	/// en: 'Other Application…'
	String get openWithChoose => 'Other Application…';

	/// en: 'Extract'
	String get extract => 'Extract';

	/// en: 'Extract Here'
	String get extractHere => 'Extract Here';

	/// en: 'Extract to $name/'
	String extractToFolder({required Object name}) => 'Extract to ${name}/';

	/// en: 'Extract Each to Its Own Folder'
	String get extractEach => 'Extract Each to Its Own Folder';

	/// en: 'Compress'
	String get compress => 'Compress';

	/// en: 'Compress to $name'
	String compressTo({required Object name}) => 'Compress to ${name}';

	/// en: 'Add to Archive…'
	String get compressOptions => 'Add to Archive…';

	/// en: 'Multi Rename…'
	String get multiRename => 'Multi Rename…';

	/// en: 'Verify Checksum…'
	String get verifyChecksum => 'Verify Checksum…';
}

// Path: multiRename
class Translations$multiRename$en {
	Translations$multiRename$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Multi Rename'
	String get title => 'Multi Rename';

	/// en: '$count items selected'
	String subtitle({required Object count}) => '${count} items selected';

	/// en: 'Template'
	String get modeTemplate => 'Template';

	/// en: 'Find & Replace'
	String get modeFindReplace => 'Find & Replace';

	/// en: 'Name pattern'
	String get namePattern => 'Name pattern';

	/// en: 'Tokens'
	String get tokens => 'Tokens';

	/// en: 'Original name without extension'
	String get tokenFilename => 'Original name without extension';

	/// en: 'Original extension (with dot)'
	String get tokenExt => 'Original extension (with dot)';

	/// en: 'Sequence number (starts at 1)'
	String get tokenN => 'Sequence number (starts at 1)';

	/// en: 'Sequence index (starts at 0)'
	String get tokenIndex => 'Sequence index (starts at 0)';

	/// en: 'Today's date (YYYY-MM-DD)'
	String get tokenDate => 'Today\'s date (YYYY-MM-DD)';

	/// en: 'Find'
	String get find => 'Find';

	/// en: 'Replace with'
	String get replaceWith => 'Replace with';

	/// en: 'Regular expression'
	String get useRegex => 'Regular expression';

	/// en: 'Case sensitive'
	String get caseSensitive => 'Case sensitive';

	/// en: 'Preview'
	String get preview => 'Preview';

	/// en: 'Before'
	String get columnBefore => 'Before';

	/// en: 'After'
	String get columnAfter => 'After';

	/// en: 'Show only changed'
	String get showOnlyChanged => 'Show only changed';

	/// en: '$changed of $total will change'
	String changedOfTotal({required Object changed, required Object total}) => '${changed} of ${total} will change';

	/// en: '$count conflicts'
	String errorCount({required Object count}) => '${count} conflicts';

	/// en: 'No files will be renamed'
	String get noChanges => 'No files will be renamed';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Rename $count files'
	String renameCount({required Object count}) => 'Rename ${count} files';

	/// en: 'invalid name'
	String get errorInvalid => 'invalid name';

	/// en: 'duplicate'
	String get errorDuplicate => 'duplicate';
}

// Path: compress
class Translations$compress$en {
	Translations$compress$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Add to Archive'
	String get title => 'Add to Archive';

	/// en: 'Archive name'
	String get archiveName => 'Archive name';

	/// en: 'Format'
	String get format => 'Format';

	/// en: 'Compression'
	String get level => 'Compression';

	/// en: 'Destination'
	String get destination => 'Destination';

	/// en: 'Store (no compression)'
	String get levelStore => 'Store (no compression)';

	/// en: 'Normal'
	String get levelNormal => 'Normal';

	/// en: 'Maximum'
	String get levelMaximum => 'Maximum';

	/// en: 'Create'
	String get create => 'Create';

	/// en: 'Cancel'
	String get cancel => 'Cancel';
}

// Path: checksum
class Translations$checksum$en {
	Translations$checksum$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Verify Checksum'
	String get title => 'Verify Checksum';

	/// en: 'MD5'
	String get md5 => 'MD5';

	/// en: 'SHA-256'
	String get sha256 => 'SHA-256';

	/// en: 'Expected checksum'
	String get expected => 'Expected checksum';

	/// en: '$algorithm digest'
	String expectedHint({required Object algorithm}) => '${algorithm} digest';

	/// en: 'Verify'
	String get verify => 'Verify';

	/// en: 'Calculating…'
	String get calculating => 'Calculating…';

	/// en: 'Checksum matches'
	String get match => 'Checksum matches';

	/// en: 'Checksum does not match'
	String get mismatch => 'Checksum does not match';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Copied'
	String get copied => 'Copied';

	/// en: '$algorithm checksum must be $length hexadecimal characters'
	String invalidExpected({required Object algorithm, required Object length}) => '${algorithm} checksum must be ${length} hexadecimal characters';

	/// en: 'Could not read file'
	String get readError => 'Could not read file';
}

// Path: properties
class Translations$properties$en {
	Translations$properties$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Properties'
	String get title => 'Properties';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Type'
	String get type => 'Type';

	/// en: 'Location'
	String get location => 'Location';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'Modified'
	String get modified => 'Modified';

	/// en: 'Accessed'
	String get accessed => 'Accessed';

	/// en: 'Changed'
	String get changed => 'Changed';

	/// en: 'Permissions'
	String get permissions => 'Permissions';

	/// en: 'Contains'
	String get contains => 'Contains';

	/// en: 'Folder'
	String get typeFolder => 'Folder';

	/// en: 'File'
	String get typeFile => 'File';

	/// en: '$formatted ($count bytes)'
	String sizeDetail({required Object formatted, required Object count}) => '${formatted} (${count} bytes)';

	/// en: '$count items'
	String containsItems({required Object count}) => '${count} items';

	/// en: 'Calculating…'
	String get calculating => 'Calculating…';

	/// en: 'Close'
	String get close => 'Close';
}

// Path: preferences
class Translations$preferences$en {
	Translations$preferences$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Preferences'
	String get title => 'Preferences';

	/// en: 'Preferences…'
	String get menuLabel => 'Preferences…';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Coming soon'
	String get comingSoon => 'Coming soon';

	late final Translations$preferences$categories$en categories = Translations$preferences$categories$en.internal(_root);
	late final Translations$preferences$general$en general = Translations$preferences$general$en.internal(_root);
	late final Translations$preferences$terminal$en terminal = Translations$preferences$terminal$en.internal(_root);
	late final Translations$preferences$appearance$en appearance = Translations$preferences$appearance$en.internal(_root);
	late final Translations$preferences$bookmarks$en bookmarks = Translations$preferences$bookmarks$en.internal(_root);
	late final Translations$preferences$diagnostics$en diagnostics = Translations$preferences$diagnostics$en.internal(_root);
	late final Translations$preferences$about$en about = Translations$preferences$about$en.internal(_root);
}

// Path: update
class Translations$update$en {
	Translations$update$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Updates'
	String get title => 'Updates';

	/// en: 'Update available'
	String get available => 'Update available';

	/// en: 'Downloading update'
	String get downloading => 'Downloading update';

	/// en: 'Ready to install'
	String get ready => 'Ready to install';

	/// en: 'Launching installer...'
	String get launching => 'Launching installer...';

	/// en: 'Update error'
	String get error => 'Update error';

	/// en: 'Checking for updates...'
	String get checking => 'Checking for updates...';

	/// en: 'Unknown error'
	String get unknownError => 'Unknown error';

	/// en: 'You're on the latest version (v${version}).'
	String upToDate({required Object version}) => 'You\'re on the latest version (v${version}).';

	/// en: 'No release information.'
	String get noRelease => 'No release information.';

	/// en: 'No matching download for this platform.'
	String get noMatch => 'No matching download for this platform.';

	/// en: 'No release notes provided.'
	String get noNotes => 'No release notes provided.';

	/// en: 'v$version'
	String versionLabel({required Object version}) => 'v${version}';

	/// en: '$title - v$version'
	String titleWithVersion({required Object title, required Object version}) => '${title} - v${version}';

	/// en: 'Update available - v${version}'
	String tooltipAvailable({required Object version}) => 'Update available - v${version}';

	/// en: 'Up to date'
	String get tooltipUpToDate => 'Up to date';

	/// en: 'Check for updates'
	String get checkForUpdates => 'Check for updates';

	/// en: 'Release page'
	String get releasePage => 'Release page';

	/// en: 'Downloaded'
	String get downloaded => 'Downloaded';

	/// en: 'Download'
	String get btnDownload => 'Download';

	/// en: 'Get the update'
	String get btnGetUpdate => 'Get the update';

	/// en: 'AppImages don't update themselves. Download the new version and replace this file.'
	String get appImageManual => 'AppImages don\'t update themselves. Download the new version and replace this file.';

	/// en: 'Downloading...'
	String get btnDownloading => 'Downloading...';

	/// en: 'Check now'
	String get btnCheckNow => 'Check now';

	/// en: 'Retry'
	String get btnRetry => 'Retry';

	/// en: 'Install'
	String get btnInstall => 'Install';

	/// en: 'Update'
	String get btnUpdate => 'Update';

	/// en: 'Open DMG'
	String get btnOpenDmg => 'Open DMG';

	/// en: 'Restart Waydir'
	String get btnRestart => 'Restart Waydir';

	/// en: 'Update installed'
	String get installed => 'Update installed';

	/// en: 'Restart Waydir to start using v${version}.'
	String restartHint({required Object version}) => 'Restart Waydir to start using v${version}.';

	/// en: 'checking...'
	String get statusCheckingInline => 'checking...';

	/// en: 'up to date'
	String get statusUpToDateInline => 'up to date';

	/// en: 'installer'
	String get formatInstaller => 'installer';

	/// en: 'portable'
	String get formatPortable => 'portable';

	/// en: 'unknown'
	String get formatUnknown => 'unknown';

	/// en: 'Download failed: HTTP $statusCode'
	String downloadFailed({required Object statusCode}) => 'Download failed: HTTP ${statusCode}';

	/// en: 'GitHub API $statusCode: $reason'
	String githubApiError({required Object statusCode, required Object reason}) => 'GitHub API ${statusCode}: ${reason}';

	/// en: 'Could not launch package installer. Open the file manually: $path'
	String packageInstallerLaunchFailed({required Object path}) => 'Could not launch package installer. Open the file manually: ${path}';

	/// en: 'Cannot write to bundle directory. Install the new version manually.'
	String get bundleNotWritable => 'Cannot write to bundle directory. Install the new version manually.';

	/// en: 'Failed to launch installer: $error'
	String installerLaunchFailed({required Object error}) => 'Failed to launch installer: ${error}';

	/// en: 'Failed to relaunch: $error'
	String relaunchFailed({required Object error}) => 'Failed to relaunch: ${error}';

	/// en: '--- Install OK. Press Enter to close ---'
	String get terminalInstallOk => '--- Install OK. Press Enter to close ---';

	/// en: '--- Install failed (exit $status). Press Enter to close ---'
	String terminalInstallFailed({required Object status}) => '--- Install failed (exit ${status}). Press Enter to close ---';
}

// Path: appMenu
class Translations$appMenu$en {
	Translations$appMenu$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Help'
	String get help => 'Help';

	/// en: 'Star on GitHub'
	String get starOnGithub => 'Star on GitHub';

	/// en: 'Quit'
	String get quit => 'Quit';
}

// Path: help
class Translations$help$en {
	Translations$help$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Features'
	String get title => 'Features';

	/// en: 'Features'
	String get menuLabel => 'Features';

	/// en: 'Demo coming soon'
	String get demoComingSoon => 'Demo coming soon';

	late final Translations$help$pages$en pages = Translations$help$pages$en.internal(_root);
}

// Path: keybindings
class Translations$keybindings$en {
	Translations$keybindings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Keyboard Shortcuts'
	String get title => 'Keyboard Shortcuts';

	/// en: 'Shortcuts'
	String get menuLabel => 'Shortcuts';

	late final Translations$keybindings$categories$en categories = Translations$keybindings$categories$en.internal(_root);

	/// en: 'or'
	String get or => 'or';

	/// en: 'Fixed shortcut'
	String get fixed => 'Fixed shortcut';

	/// en: 'Change shortcut'
	String get change => 'Change shortcut';

	/// en: 'Reset shortcut'
	String get reset => 'Reset shortcut';

	/// en: 'Press a shortcut'
	String get pressShortcut => 'Press a shortcut';

	/// en: 'Esc cancels'
	String get escapeToCancel => 'Esc cancels';

	/// en: 'Already used by $action'
	String conflict({required Object action}) => 'Already used by ${action}';

	/// en: 'dual'
	String get dualHint => 'dual';

	/// en: 'Open'
	String get openItem => 'Open';

	/// en: 'Go up'
	String get goUp => 'Go up';

	/// en: 'Go back'
	String get goBack => 'Go back';

	/// en: 'Go forward'
	String get goForward => 'Go forward';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Focus path bar'
	String get focusPath => 'Focus path bar';

	/// en: 'Quick look'
	String get quickLook => 'Quick look';

	/// en: 'Move up'
	String get cursorUp => 'Move up';

	/// en: 'Move down'
	String get cursorDown => 'Move down';

	/// en: 'New tab'
	String get newTab => 'New tab';

	/// en: 'Close tab'
	String get closeTab => 'Close tab';

	/// en: 'Next tab'
	String get nextTab => 'Next tab';

	/// en: 'Previous tab'
	String get prevTab => 'Previous tab';

	/// en: 'Switch to tab'
	String get switchTab => 'Switch to tab';

	/// en: 'Toggle dual pane'
	String get toggleDual => 'Toggle dual pane';

	/// en: 'Switch active pane'
	String get switchPane => 'Switch active pane';

	/// en: 'Open / focus terminal'
	String get focusTerminal => 'Open / focus terminal';

	/// en: 'Toggle terminal'
	String get toggleTerminal => 'Toggle terminal';

	/// en: 'New terminal tab'
	String get newTerminalTab => 'New terminal tab';

	/// en: 'Close terminal tab'
	String get closeTerminalTab => 'Close terminal tab';

	/// en: 'Increase terminal font'
	String get terminalFontIncrease => 'Increase terminal font';

	/// en: 'Decrease terminal font'
	String get terminalFontDecrease => 'Decrease terminal font';

	/// en: 'Reset terminal font'
	String get terminalFontReset => 'Reset terminal font';

	/// en: 'Zoom in file list'
	String get fileListZoomIn => 'Zoom in file list';

	/// en: 'Zoom out file list'
	String get fileListZoomOut => 'Zoom out file list';

	/// en: 'Reset file list zoom'
	String get fileListZoomReset => 'Reset file list zoom';

	/// en: 'Toggle sidebar'
	String get toggleSidebar => 'Toggle sidebar';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Cut'
	String get cut => 'Cut';

	/// en: 'Paste'
	String get paste => 'Paste';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'New folder'
	String get newFolder => 'New folder';

	/// en: 'Copy to other pane'
	String get dualCopy => 'Copy to other pane';

	/// en: 'Move to other pane'
	String get dualMove => 'Move to other pane';

	/// en: 'Select all'
	String get selectAll => 'Select all';

	/// en: 'Select by pattern'
	String get selectPattern => 'Select by pattern';

	/// en: 'Deselect all'
	String get deselectAll => 'Deselect all';

	/// en: 'Toggle select'
	String get toggleSelect => 'Toggle select';

	/// en: 'Save selection to file'
	String get saveSelection => 'Save selection to file';

	/// en: 'Load selection from file'
	String get loadSelection => 'Load selection from file';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Recursive search'
	String get recursiveSearch => 'Recursive search';

	/// en: 'Close search'
	String get closeSearch => 'Close search';

	/// en: 'Command palette'
	String get commandPalette => 'Command palette';

	/// en: 'Preferences'
	String get preferences => 'Preferences';
}

// Path: commandPalette
class Translations$commandPalette$en {
	Translations$commandPalette$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Command Palette'
	String get title => 'Command Palette';

	/// en: 'Type a command or setting…'
	String get placeholder => 'Type a command or setting…';

	/// en: 'No matching commands'
	String get empty => 'No matching commands';

	/// en: 'Open Preferences'
	String get openPreferences => 'Open Preferences';

	/// en: 'Open the full settings dialog'
	String get preferencesSubtitle => 'Open the full settings dialog';

	/// en: 'Enabled'
	String get enabled => 'Enabled';

	/// en: 'Disabled'
	String get disabled => 'Disabled';
}

// Path: quickLook
class Translations$quickLook$en {
	Translations$quickLook$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Quick Look'
	String get title => 'Quick Look';

	/// en: 'No file selected'
	String get noSelection => 'No file selected';

	/// en: 'Folder'
	String get folder => 'Folder';

	/// en: 'No preview available'
	String get noPreview => 'No preview available';

	/// en: 'Binary file - no preview'
	String get binaryFile => 'Binary file - no preview';

	/// en: 'File too large to preview'
	String get tooLarge => 'File too large to preview';

	/// en: 'Could not read file'
	String get readError => 'Could not read file';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Saved'
	String get saved => 'Saved';

	/// en: 'Unsaved'
	String get unsaved => 'Unsaved';

	/// en: 'Could not save file'
	String get saveError => 'Could not save file';

	/// en: 'Accessed'
	String get accessed => 'Accessed';

	/// en: 'Changed'
	String get changed => 'Changed';

	/// en: 'Permissions'
	String get permissions => 'Permissions';

	/// en: 'Contains'
	String get contains => 'Contains';

	/// en: 'Calculating…'
	String get calculating => 'Calculating…';

	/// en: '$count items'
	String items({required Object count}) => '${count} items';

	/// en: 'Details'
	String get sectionDetails => 'Details';

	/// en: 'Information'
	String get info => 'Information';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Type'
	String get type => 'Type';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'Path'
	String get path => 'Path';

	/// en: 'Location'
	String get location => 'Location';

	/// en: 'Modified'
	String get modified => 'Modified';

	/// en: 'Folder'
	String get typeFolder => 'Folder';

	/// en: 'File'
	String get typeFile => 'File';

	/// en: 'Dimensions'
	String get dimensions => 'Dimensions';

	/// en: 'Camera'
	String get camera => 'Camera';

	/// en: 'Lens'
	String get lens => 'Lens';

	/// en: 'Exposure'
	String get exposure => 'Exposure';

	/// en: 'Aperture'
	String get aperture => 'Aperture';

	/// en: 'ISO'
	String get iso => 'ISO';

	/// en: 'Focal length'
	String get focalLength => 'Focal length';

	/// en: 'Date taken'
	String get dateTaken => 'Date taken';

	/// en: 'Ln $line / $count'
	String linePosition({required Object line, required Object count}) => 'Ln ${line} / ${count}';

	/// en: 'Lines'
	String get lines => 'Lines';

	/// en: 'Characters'
	String get characters => 'Characters';

	/// en: 'General'
	String get sectionGeneral => 'General';

	/// en: 'Statistics'
	String get sectionStatistics => 'Statistics';

	/// en: 'Size breakdown'
	String get sizeBreakdown => 'Size breakdown';

	/// en: 'Type breakdown'
	String get typeBreakdown => 'Type breakdown';

	/// en: 'no extension'
	String get noExtension => 'no extension';

	/// en: 'Image'
	String get sectionImage => 'Image';

	/// en: 'Text'
	String get sectionText => 'Text';
}

// Path: toast
class Translations$toast$en {
	Translations$toast$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copied $count items'
	String copiedItems({required Object count}) => 'Copied ${count} items';

	/// en: 'Cut $count items'
	String cutItems({required Object count}) => 'Cut ${count} items';

	/// en: 'Saved $count names to $path'
	String selectionSaved({required Object count, required Object path}) => 'Saved ${count} names to ${path}';

	/// en: 'Selected $count visible items'
	String selectionLoaded({required Object count}) => 'Selected ${count} visible items';

	/// en: 'No visible items matched'
	String get selectionLoadEmpty => 'No visible items matched';

	/// en: 'Terminal is unavailable: native core not loaded'
	String get terminalUnavailable => 'Terminal is unavailable: native core not loaded';

	/// en: 'Selection file error: $message'
	String selectionFileError({required Object message}) => 'Selection file error: ${message}';

	/// en: '$label - $count errors'
	String taskErrors({required Object label, required Object count}) => '${label} - ${count} errors';

	/// en: 'An item named '$name' already exists'
	String renameAlreadyExists({required Object name}) => 'An item named \'${name}\' already exists';

	/// en: 'Invalid name'
	String get renameInvalidName => 'Invalid name';

	/// en: 'Could not rename: $message'
	String renameError({required Object message}) => 'Could not rename: ${message}';

	/// en: 'Renamed $count files'
	String multiRenameSuccess({required Object count}) => 'Renamed ${count} files';

	/// en: 'Renamed $succeeded of $total ($details)'
	String multiRenamePartial({required Object succeeded, required Object total, required Object details}) => 'Renamed ${succeeded} of ${total} (${details})';

	/// en: '$count already existed'
	String multiRenameCollisions({required Object count}) => '${count} already existed';

	/// en: '$count invalid names'
	String multiRenameInvalid({required Object count}) => '${count} invalid names';

	/// en: '$count errors'
	String multiRenameOtherErrors({required Object count}) => '${count} errors';

	/// en: 'Multi rename is not available in trash'
	String get multiRenameTrashBlocked => 'Multi rename is not available in trash';
}

// Path: selectionFile
class Translations$selectionFile$en {
	Translations$selectionFile$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Save Selection'
	String get saveTitle => 'Save Selection';

	/// en: 'Load Selection'
	String get loadTitle => 'Load Selection';

	/// en: 'Text file'
	String get pathLabel => 'Text file';

	/// en: 'selection.txt'
	String get pathHint => 'selection.txt';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Load'
	String get load => 'Load';
}

// Path: dragHint
class Translations$dragHint$en {
	Translations$dragHint$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copy to "$name"'
	String copyTo({required Object name}) => 'Copy to "${name}"';

	/// en: 'Move to "$name"'
	String moveTo({required Object name}) => 'Move to "${name}"';

	/// en: '(Alt+drag to move)'
	String get tabToSwitch => '(Alt+drag to move)';
}

// Path: fileView
class Translations$fileView$en {
	Translations$fileView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Moving $count items'
	String movingItems({required Object count}) => 'Moving ${count} items';

	/// en: 'Folder is empty'
	String get empty => 'Folder is empty';

	late final Translations$fileView$date$en date = Translations$fileView$date$en.internal(_root);
	late final Translations$fileView$columns$en columns = Translations$fileView$columns$en.internal(_root);
}

// Path: sidebar
class Translations$sidebar$en {
	Translations$sidebar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Favorites'
	String get favorites => 'Favorites';

	/// en: 'Devices'
	String get devices => 'Devices';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Desktop'
	String get desktop => 'Desktop';

	/// en: 'Documents'
	String get documents => 'Documents';

	/// en: 'Downloads'
	String get downloads => 'Downloads';

	/// en: 'Pictures'
	String get pictures => 'Pictures';

	/// en: 'Music'
	String get music => 'Music';

	/// en: 'Videos'
	String get videos => 'Videos';

	/// en: 'Trash'
	String get trash => 'Trash';

	/// en: 'Root'
	String get root => 'Root';

	/// en: 'Network'
	String get network => 'Network';

	/// en: 'Bookmarks'
	String get bookmarks => 'Bookmarks';

	/// en: 'Drop folder to bookmark'
	String get dropBookmark => 'Drop folder to bookmark';

	/// en: 'Connect to server'
	String get connectToServer => 'Connect to server';

	late final Translations$sidebar$connectDialog$en connectDialog = Translations$sidebar$connectDialog$en.internal(_root);
	late final Translations$sidebar$driveSpace$en driveSpace = Translations$sidebar$driveSpace$en.internal(_root);
	late final Translations$sidebar$drives$en drives = Translations$sidebar$drives$en.internal(_root);

	/// en: 'Collapse sidebar'
	String get collapse => 'Collapse sidebar';

	/// en: 'Expand sidebar'
	String get expand => 'Expand sidebar';
}

// Path: trash
class Translations$trash$en {
	Translations$trash$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Trash needs Full Disk Access'
	String get accessDeniedTitle => 'Trash needs Full Disk Access';

	/// en: 'macOS protects the Trash folder. Grant Waydir Full Disk Access in System Settings, then relaunch the app.'
	String get accessDeniedBody => 'macOS protects the Trash folder. Grant Waydir Full Disk Access in System Settings, then relaunch the app.';

	/// en: 'Open System Settings'
	String get openSystemSettings => 'Open System Settings';
}

// Path: toolbar
class Translations$toolbar$en {
	Translations$toolbar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Forward'
	String get forward => 'Forward';

	/// en: 'Up'
	String get up => 'Up';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'View Options'
	String get viewOptions => 'View Options';

	/// en: 'New Folder'
	String get newFolder => 'New Folder';

	/// en: 'Operations'
	String get operations => 'Operations';

	/// en: 'Notifications'
	String get notifications => 'Notifications';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'More'
	String get more => 'More';
}

// Path: notifications
class Translations$notifications$en {
	Translations$notifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notifications'
	String get title => 'Notifications';

	/// en: 'No notifications yet'
	String get empty => 'No notifications yet';

	/// en: 'Clear'
	String get clear => 'Clear';
}

// Path: search
class Translations$search$en {
	Translations$search$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Filter…'
	String get placeholder => 'Filter…';

	/// en: 'Subfolders'
	String get subfolders => 'Subfolders';

	/// en: 'Subfolders (Ctrl+Shift+F)'
	String get subfoldersShortcut => 'Subfolders (Ctrl+Shift+F)';

	/// en: 'Content'
	String get content => 'Content';

	/// en: 'Search inside file contents'
	String get contentSearch => 'Search inside file contents';

	/// en: 'Content search is not available over SFTP'
	String get contentSftpUnsupported => 'Content search is not available over SFTP';

	/// en: 'Close search'
	String get close => 'Close search';

	/// en: '$count results'
	String results({required Object count}) => '${count} results';

	/// en: '$count found'
	String found({required Object count}) => '${count} found';

	/// en: '$dirs scanned'
	String scanning({required Object dirs}) => '${dirs} scanned';

	/// en: '(first $limit)'
	String truncated({required Object limit}) => '(first ${limit})';

	/// en: 'No matches'
	String get noMatches => 'No matches';

	/// en: 'Starting…'
	String get starting => 'Starting…';

	/// en: 'Clear search'
	String get clear => 'Clear search';

	/// en: 'Substring'
	String get modeSubstring => 'Substring';

	/// en: 'Glob'
	String get modeGlob => 'Glob';

	/// en: 'Regex'
	String get modeRegex => 'Regex';

	/// en: 'Invalid glob pattern'
	String get invalidGlob => 'Invalid glob pattern';

	/// en: 'Invalid regex'
	String get invalidRegex => 'Invalid regex';

	/// en: 'complete'
	String get complete => 'complete';

	/// en: 'go'
	String get go => 'go';
}

// Path: statusBar
class Translations$statusBar$en {
	Translations$statusBar$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '$count items'
	String items({required Object count}) => '${count} items';

	/// en: '$count folders'
	String folders({required Object count}) => '${count} folders';

	/// en: '$count files'
	String files({required Object count}) => '${count} files';

	/// en: '$count selected'
	String selected({required Object count}) => '${count} selected';

	/// en: 'Zoom out'
	String get zoomOut => 'Zoom out';

	/// en: 'Zoom in'
	String get zoomIn => 'Zoom in';

	/// en: 'Reset zoom'
	String get zoomReset => 'Reset zoom';
}

// Path: dialog
class Translations$dialog$en {
	Translations$dialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create'
	String get create => 'Create';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Folder name'
	String get folderNameHint => 'Folder name';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Move to Trash'
	String get moveToTrash => 'Move to Trash';

	/// en: 'Delete permanently?'
	String get confirmDeleteTitle => 'Delete permanently?';

	/// en: 'Delete "$name"? This cannot be undone.'
	String confirmDeleteSingle({required Object name}) => 'Delete "${name}"? This cannot be undone.';

	/// en: 'Delete $count items? This cannot be undone.'
	String confirmDeleteMultiple({required Object count}) => 'Delete ${count} items? This cannot be undone.';

	/// en: 'Move to Trash?'
	String get confirmTrashTitle => 'Move to Trash?';

	/// en: 'Move "$name" to Trash?'
	String confirmTrashSingle({required Object name}) => 'Move "${name}" to Trash?';

	/// en: 'Move $count items to Trash?'
	String confirmTrashMultiple({required Object count}) => 'Move ${count} items to Trash?';

	/// en: 'Copy'
	String get copy => 'Copy';

	/// en: 'Move'
	String get move => 'Move';

	/// en: 'Copy items?'
	String get confirmCopyTitle => 'Copy items?';

	/// en: 'Copy "$name" here?'
	String confirmCopySingle({required Object name}) => 'Copy "${name}" here?';

	/// en: 'Copy $count items here?'
	String confirmCopyMultiple({required Object count}) => 'Copy ${count} items here?';

	/// en: 'Move items?'
	String get confirmMoveTitle => 'Move items?';

	/// en: 'Move "$name" here?'
	String confirmMoveSingle({required Object name}) => 'Move "${name}" here?';

	/// en: 'Move $count items here?'
	String confirmMoveMultiple({required Object count}) => 'Move ${count} items here?';
}

// Path: password
class Translations$password$en {
	Translations$password$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Authentication Required'
	String get authenticationRequired => 'Authentication Required';

	/// en: 'Dismiss'
	String get dismiss => 'Dismiss';

	/// en: 'Enter your password to mount this drive.'
	String get mountPrompt => 'Enter your password to mount this drive.';

	/// en: 'Enter credentials for this network share.'
	String get smbPrompt => 'Enter credentials for this network share.';

	/// en: 'SSH/SFTP authentication'
	String get sftpPrompt => 'SSH/SFTP authentication';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Private key'
	String get privateKey => 'Private key';

	/// en: 'Private key path'
	String get privateKeyPath => 'Private key path';

	/// en: 'Passphrase (optional)'
	String get passphraseOptional => 'Passphrase (optional)';

	/// en: 'Unlock'
	String get unlock => 'Unlock';
}

// Path: selectPattern
class Translations$selectPattern$en {
	Translations$selectPattern$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Select by pattern'
	String get title => 'Select by pattern';

	/// en: '*.jpg, *.png'
	String get hint => '*.jpg, *.png';

	/// en: 'Wildcards: * (any), ? (one char). Separate patterns with commas.'
	String get help => 'Wildcards: * (any), ? (one char). Separate patterns with commas.';

	/// en: 'Select'
	String get select => 'Select';
}

// Path: operations
class Translations$operations$en {
	Translations$operations$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Operations'
	String get title => 'Operations';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'No active operations'
	String get noActive => 'No active operations';

	/// en: 'Resolve Conflicts'
	String get resolveConflicts => 'Resolve Conflicts';

	/// en: '$count errors'
	String errorsCount({required Object count}) => '${count} errors';

	/// en: 'Compressing…'
	String get compressing => 'Compressing…';

	/// en: 'Compressing (gzip)…'
	String get compressingGzip => 'Compressing (gzip)…';

	/// en: 'Compressing (bzip2)…'
	String get compressingBzip2 => 'Compressing (bzip2)…';

	/// en: 'Compressing (xz)…'
	String get compressingXz => 'Compressing (xz)…';

	/// en: 'just now'
	String get justNow => 'just now';

	/// en: '${count}s ago'
	String secondsAgo({required Object count}) => '${count}s ago';

	/// en: '${count}m ago'
	String minutesAgo({required Object count}) => '${count}m ago';

	/// en: '${count}h ago'
	String hoursAgo({required Object count}) => '${count}h ago';

	/// en: 'ETA $time'
	String eta({required Object time}) => 'ETA ${time}';

	/// en: 'Conflicts Detected'
	String get conflictsDetected => 'Conflicts Detected';

	/// en: '$count files already exist at the destination.'
	String filesExist({required Object count}) => '${count} files already exist at the destination.';

	/// en: 'Overwrite All'
	String get overwriteAll => 'Overwrite All';

	/// en: 'Skip All'
	String get skipAll => 'Skip All';

	/// en: 'Review'
	String get review => 'Review';

	/// en: 'File Conflict ($index/$total)'
	String fileConflict({required Object index, required Object total}) => 'File Conflict (${index}/${total})';

	/// en: 'Replace'
	String get replace => 'Replace';

	/// en: 'Keep Both'
	String get keepBoth => 'Keep Both';

	/// en: 'Skip'
	String get skip => 'Skip';

	/// en: 'Errors ($count)'
	String errors({required Object count}) => 'Errors (${count})';

	/// en: '$processed / $count files'
	String filesCount({required Object processed, required Object count}) => '${processed} / ${count} files';

	/// en: 'A file with this name already exists:'
	String get fileExists => 'A file with this name already exists:';

	/// en: 'Source: $size · $date'
	String source({required Object size, required Object date}) => 'Source:  ${size} · ${date}';

	/// en: 'Target: $size · $date'
	String target({required Object size, required Object date}) => 'Target:  ${size} · ${date}';

	/// en: ' ← newer'
	String get newer => '  ← newer';

	/// en: 'Apply to all remaining conflicts ($count)'
	String applyToAll({required Object count}) => 'Apply to all remaining conflicts (${count})';
}

// Path: errors
class Translations$errors$en {
	Translations$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Permission denied'
	String get permissionDenied => 'Permission denied';

	/// en: 'Authentication required'
	String get authenticationRequired => 'Authentication required';

	/// en: 'No space left on device'
	String get noSpace => 'No space left on device';

	/// en: 'Read-only file system'
	String get readOnly => 'Read-only file system';

	/// en: 'File not found'
	String get notFound => 'File not found';

	/// en: 'Source not found'
	String get sourceNotFound => 'Source not found';

	/// en: 'Path not found'
	String get pathNotFound => 'Path not found';

	/// en: 'Missing host in smb:// URI'
	String get missingSmbHost => 'Missing host in smb:// URI';

	/// en: 'Missing server in smb:// URI'
	String get missingSmbServer => 'Missing server in smb:// URI';

	/// en: 'Missing share in smb:// URI'
	String get missingSmbShare => 'Missing share in smb:// URI';

	/// en: 'Missing host in sftp:// URI'
	String get missingSftpHost => 'Missing host in sftp:// URI';

	/// en: 'Invalid smb:// URI'
	String get invalidSmbUri => 'Invalid smb:// URI';

	/// en: 'SMB ports are not supported on Windows'
	String get smbPortsNotSupportedOnWindows => 'SMB ports are not supported on Windows';

	/// en: 'SMB share not mounted'
	String get smbShareNotMounted => 'SMB share not mounted';

	/// en: 'smbclient unavailable: $message'
	String smbClientUnavailable({required Object message}) => 'smbclient unavailable: ${message}';

	/// en: 'smbclient failed ($code)'
	String smbClientFailed({required Object code}) => 'smbclient failed (${code})';

	/// en: 'smbutil unavailable: $message'
	String smbutilUnavailable({required Object message}) => 'smbutil unavailable: ${message}';

	/// en: 'smbutil failed ($code)'
	String smbutilFailed({required Object code}) => 'smbutil failed (${code})';

	/// en: 'net unavailable: $message'
	String netUnavailable({required Object message}) => 'net unavailable: ${message}';

	/// en: 'net view failed ($code)'
	String netViewFailed({required Object code}) => 'net view failed (${code})';

	/// en: 'Mounted share could not be located in gvfs'
	String get smbMountedShareNotFound => 'Mounted share could not be located in gvfs';

	/// en: 'Failed to create $path: $error'
	String failedToCreatePath({required Object path, required Object error}) => 'Failed to create ${path}: ${error}';

	/// en: 'gio mount failed'
	String get gioMountFailed => 'gio mount failed';

	/// en: 'mount_smbfs failed ($code)'
	String mountSmbfsFailed({required Object code}) => 'mount_smbfs failed (${code})';

	/// en: 'Directory not empty'
	String get notEmpty => 'Directory not empty';

	/// en: 'Cannot move across devices'
	String get crossDevice => 'Cannot move across devices';

	/// en: 'Target exists'
	String get targetExists => 'Target exists';

	/// en: 'SFTP not supported'
	String get sftpNotSupported => 'SFTP not supported';

	/// en: 'SFTP connect failed'
	String get sftpConnectFailed => 'SFTP connect failed';

	/// en: 'SFTP: $error'
	String sftpError({required Object error}) => 'SFTP: ${error}';

	/// en: 'No active SFTP session'
	String get sftpNoActiveSession => 'No active SFTP session';

	/// en: 'No active SFTP session for $path'
	String sftpNoActiveSessionFor({required Object path}) => 'No active SFTP session for ${path}';

	/// en: 'SFTP listing failed'
	String get sftpListingFailed => 'SFTP listing failed';

	/// en: 'SFTP read failed'
	String get sftpReadFailed => 'SFTP read failed';

	/// en: 'SFTP write failed'
	String get sftpWriteFailed => 'SFTP write failed';

	/// en: 'SFTP mkdir failed'
	String get sftpMkdirFailed => 'SFTP mkdir failed';

	/// en: 'SFTP remove failed'
	String get sftpRemoveFailed => 'SFTP remove failed';

	/// en: 'SFTP rename failed'
	String get sftpRenameFailed => 'SFTP rename failed';

	/// en: 'SFTP open reader failed'
	String get sftpOpenReaderFailed => 'SFTP open reader failed';

	/// en: 'SFTP open writer failed'
	String get sftpOpenWriterFailed => 'SFTP open writer failed';

	/// en: 'SFTP close failed'
	String get sftpCloseFailed => 'SFTP close failed';

	/// en: 'Directory not readable'
	String get directoryNotReadable => 'Directory not readable';

	/// en: 'Cannot copy or move a folder into itself.'
	String get transferIntoSelf => 'Cannot copy or move a folder into itself.';

	/// en: 'Worker exited unexpectedly'
	String get workerExitedUnexpectedly => 'Worker exited unexpectedly';

	/// en: 'File appeared at destination during operation'
	String get appearedDuring => 'File appeared at destination during operation';

	/// en: 'Could not read archive'
	String get archiveError => 'Could not read archive';

	/// en: 'Could not create archive: $error'
	String archiveCreateFailed({required Object error}) => 'Could not create archive: ${error}';

	/// en: 'Archive error: $error'
	String archiveReadFailed({required Object error}) => 'Archive error: ${error}';

	/// en: 'Archive entry not found: $path'
	String archiveEntryNotFound({required Object path}) => 'Archive entry not found: ${path}';

	/// en: 'Unsupported archive format'
	String get unsupportedArchiveFormat => 'Unsupported archive format';

	/// en: 'Native waydir_core not found; searched: $paths'
	String nativeCoreNotFound({required Object paths}) => 'Native waydir_core not found; searched: ${paths}';

	/// en: 'MoveFileEx failed with Windows error $error'
	String moveFileExFailed({required Object error}) => 'MoveFileEx failed with Windows error ${error}';

	/// en: 'Native trash list failed'
	String get nativeTrashListFailed => 'Native trash list failed';

	/// en: 'Native trash list failed: $message'
	String nativeTrashListFailedWithMessage({required Object message}) => 'Native trash list failed: ${message}';

	/// en: 'Network shares (smb://) are not supported on this platform yet.'
	String get smbNotSupportedOnPlatform => 'Network shares (smb://) are not supported on this platform yet.';
}

// Path: tasks
class Translations$tasks$en {
	Translations$tasks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copying $name'
	String copyingSingle({required Object name}) => 'Copying ${name}';

	/// en: 'Copying $count items'
	String copyingMultiple({required Object count}) => 'Copying ${count} items';

	/// en: 'Moving $name'
	String movingSingle({required Object name}) => 'Moving ${name}';

	/// en: 'Moving $count items'
	String movingMultiple({required Object count}) => 'Moving ${count} items';

	/// en: 'Deleting $name'
	String deletingSingle({required Object name}) => 'Deleting ${name}';

	/// en: 'Deleting $count items'
	String deletingMultiple({required Object count}) => 'Deleting ${count} items';

	/// en: 'Moving $name to Trash'
	String trashingSingle({required Object name}) => 'Moving ${name} to Trash';

	/// en: 'Moving $count items to Trash'
	String trashingMultiple({required Object count}) => 'Moving ${count} items to Trash';

	/// en: 'Restoring $name from Trash'
	String restoringTrashSingle({required Object name}) => 'Restoring ${name} from Trash';

	/// en: 'Restoring $count items from Trash'
	String restoringTrashMultiple({required Object count}) => 'Restoring ${count} items from Trash';

	/// en: 'Deleting $name from Trash'
	String deletingTrashSingle({required Object name}) => 'Deleting ${name} from Trash';

	/// en: 'Deleting $count items from Trash'
	String deletingTrashMultiple({required Object count}) => 'Deleting ${count} items from Trash';

	/// en: 'Extracting $name'
	String extractingSingle({required Object name}) => 'Extracting ${name}';

	/// en: 'Extracting $count archives'
	String extractingMultiple({required Object count}) => 'Extracting ${count} archives';

	/// en: 'Compressing to $name'
	String compressingTo({required Object name}) => 'Compressing to ${name}';

	/// en: 'Updating archive'
	String get updatingArchive => 'Updating archive';

	late final Translations$tasks$status$en status = Translations$tasks$status$en.internal(_root);
}

// Path: git
class Translations$git$en {
	Translations$git$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'clean'
	String get clean => 'clean';

	/// en: 'detached HEAD'
	String get detachedHead => 'detached HEAD';

	/// en: 'MERGING'
	String get merging => 'MERGING';

	/// en: 'REBASING'
	String get rebasing => 'REBASING';

	/// en: 'CHERRY-PICK'
	String get cherryPicking => 'CHERRY-PICK';

	/// en: 'REVERTING'
	String get reverting => 'REVERTING';

	/// en: 'BISECTING'
	String get bisecting => 'BISECTING';

	/// en: 'Checkout failed: $message'
	String checkoutFailed({required Object message}) => 'Checkout failed: ${message}';

	/// en: 'Uncommitted changes'
	String get uncommittedChanges => 'Uncommitted changes';

	/// en: 'Your local changes would be overwritten by switching to '$branch'. Stash them now? They stay saved in a stash you can restore later on this branch.'
	String stashPrompt({required Object branch}) => 'Your local changes would be overwritten by switching to \'${branch}\'.\n\nStash them now? They stay saved in a stash you can restore later on this branch.';

	/// en: 'Stash & Switch'
	String get stashSwitch => 'Stash & Switch';

	/// en: 'Stash & switch failed: $message'
	String stashSwitchFailed({required Object message}) => 'Stash & switch failed: ${message}';

	/// en: 'stash@{$index} · $message'
	String stashEntry({required Object index, required Object message}) => 'stash@{${index}} · ${message}';

	/// en: 'Pop (apply & remove)'
	String get stashPop => 'Pop (apply & remove)';

	/// en: 'Apply (keep stash)'
	String get stashApply => 'Apply (keep stash)';

	/// en: 'Drop'
	String get stashDrop => 'Drop';

	/// en: 'Stash failed: $message'
	String stashFailed({required Object message}) => 'Stash failed: ${message}';

	/// en: 'No repository'
	String get noRepository => 'No repository';

	/// en: 'git checkout failed'
	String get gitCheckoutFailed => 'git checkout failed';

	/// en: 'git stash failed'
	String get gitStashFailed => 'git stash failed';

	/// en: 'Changes stashed, but switch failed: $message'
	String changesStashedSwitchFailed({required Object message}) => 'Changes stashed, but switch failed: ${message}';
}

// Path: openWith
class Translations$openWith$en {
	Translations$openWith$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Open With'
	String get title => 'Open With';

	/// en: 'Choose an application to open "$name"'
	String subtitle({required Object name}) => 'Choose an application to open "${name}"';

	/// en: 'Recent'
	String get recent => 'Recent';

	/// en: 'Recommended Applications'
	String get recommended => 'Recommended Applications';

	/// en: 'All Applications'
	String get allApps => 'All Applications';

	/// en: 'No applications found for this file type.'
	String get noApps => 'No applications found for this file type.';

	/// en: 'Always use for this file type'
	String get setDefault => 'Always use for this file type';

	/// en: 'Default cannot be changed on this platform'
	String get setDefaultUnavailable => 'Default cannot be changed on this platform';

	/// en: 'More applications…'
	String get moreApps => 'More applications…';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Could not open the file with $app'
	String failed({required Object app}) => 'Could not open the file with ${app}';

	/// en: 'Could not set the default application'
	String get setDefaultFailed => 'Could not set the default application';

	/// en: 'Unsupported platform'
	String get unsupportedPlatform => 'Unsupported platform';

	/// en: 'xdg-mime failed'
	String get xdgMimeFailed => 'xdg-mime failed';

	/// en: 'Setting the default app on macOS requires the "duti" tool'
	String get dutiRequired => 'Setting the default app on macOS requires the "duti" tool';

	/// en: 'Could not read app bundle id'
	String get bundleIdReadFailed => 'Could not read app bundle id';

	/// en: 'Use the system "Open with" dialog to change the default on Windows'
	String get windowsDefaultDialogRequired => 'Use the system "Open with" dialog to change the default on Windows';
}

// Path: preferences.categories
class Translations$preferences$categories$en {
	Translations$preferences$categories$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'General'
	String get general => 'General';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Terminal'
	String get terminal => 'Terminal';

	/// en: 'Bookmarks'
	String get bookmarks => 'Bookmarks';

	/// en: 'Diagnostics'
	String get diagnostics => 'Diagnostics';

	/// en: 'About'
	String get about => 'About';
}

// Path: preferences.general
class Translations$preferences$general$en {
	Translations$preferences$general$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'General'
	String get title => 'General';

	/// en: 'Startup, file operations and terminal integration.'
	String get subtitle => 'Startup, file operations and terminal integration.';

	/// en: 'Startup'
	String get startupSection => 'Startup';

	/// en: 'Restore last session'
	String get restoreSession => 'Restore last session';

	/// en: 'Reopen previously open tabs and panes on launch.'
	String get restoreSessionHint => 'Reopen previously open tabs and panes on launch.';

	/// en: 'Default starting path'
	String get defaultPath => 'Default starting path';

	/// en: 'Used when session restore is disabled or empty.'
	String get defaultPathHint => 'Used when session restore is disabled or empty.';

	/// en: '/home/user'
	String get defaultPathPlaceholder => '/home/user';

	/// en: 'Browse…'
	String get browse => 'Browse…';

	/// en: 'Folders'
	String get foldersSection => 'Folders';

	/// en: 'File operations'
	String get fileOpsSection => 'File operations';

	/// en: 'Confirm before delete'
	String get confirmDelete => 'Confirm before delete';

	/// en: 'Show a dialog before removing files or folders.'
	String get confirmDeleteHint => 'Show a dialog before removing files or folders.';

	/// en: 'Confirm before copy'
	String get confirmCopy => 'Confirm before copy';

	/// en: 'Show a dialog before copying files or folders.'
	String get confirmCopyHint => 'Show a dialog before copying files or folders.';

	/// en: 'Confirm before move'
	String get confirmMove => 'Confirm before move';

	/// en: 'Show a dialog before moving files or folders.'
	String get confirmMoveHint => 'Show a dialog before moving files or folders.';

	/// en: 'Remember selection per folder'
	String get rememberFolderState => 'Remember selection per folder';

	/// en: 'Restore the cursor and selected files when you return to a folder.'
	String get rememberFolderStateHint => 'Restore the cursor and selected files when you return to a folder.';

	/// en: 'Remember sort per folder'
	String get rememberFolderSort => 'Remember sort per folder';

	/// en: 'Save and reuse the sort column and direction for each folder.'
	String get rememberFolderSortHint => 'Save and reuse the sort column and direction for each folder.';

	/// en: 'Delete key behavior'
	String get deleteKeyBehavior => 'Delete key behavior';

	/// en: 'What the Delete key does by default. Shift+Delete always deletes permanently.'
	String get deleteKeyBehaviorHint => 'What the Delete key does by default. Shift+Delete always deletes permanently.';

	/// en: 'Move to Trash'
	String get deleteKeyTrash => 'Move to Trash';

	/// en: 'Delete Permanently'
	String get deleteKeyPermanent => 'Delete Permanently';

	/// en: 'Terminal'
	String get terminalSection => 'Terminal';

	/// en: 'Default terminal'
	String get terminalLabel => 'Default terminal';

	/// en: 'Used by "Open in Terminal".'
	String get terminalHint => 'Used by "Open in Terminal".';

	/// en: 'Built-in terminal'
	String get terminalBuiltin => 'Built-in terminal';

	/// en: 'External (auto-detect)'
	String get terminalAuto => 'External (auto-detect)';

	/// en: 'Custom command…'
	String get terminalCustom => 'Custom command…';

	/// en: 'Command'
	String get terminalCustomLabel => 'Command';

	/// en: 'e.g. kitty --working-directory={dir}'
	String get terminalCustomHint => 'e.g. kitty --working-directory={dir}';

	/// en: 'Use {dir} as a placeholder for the directory path.'
	String get terminalCustomHelp => 'Use {dir} as a placeholder for the directory path.';
}

// Path: preferences.terminal
class Translations$preferences$terminal$en {
	Translations$preferences$terminal$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Terminal'
	String get title => 'Terminal';

	/// en: 'Embedded terminal font and external terminal integration.'
	String get subtitle => 'Embedded terminal font and external terminal integration.';

	/// en: 'Appearance'
	String get appearanceSection => 'Appearance';

	/// en: 'Use system font'
	String get useSystemFont => 'Use system font';

	/// en: 'Render the terminal with the system monospace font.'
	String get useSystemFontHint => 'Render the terminal with the system monospace font.';

	/// en: 'Font family'
	String get fontFamily => 'Font family';

	/// en: 'Pick an installed monospace font.'
	String get fontFamilyHint => 'Pick an installed monospace font.';

	/// en: 'Font size'
	String get fontSize => 'Font size';

	/// en: 'Adjust on the fly with Ctrl++, Ctrl+- and Ctrl+0.'
	String get fontSizeHint => 'Adjust on the fly with Ctrl++, Ctrl+- and Ctrl+0.';

	/// en: 'Line height'
	String get lineHeight => 'Line height';

	/// en: 'Vertical spacing between terminal rows.'
	String get lineHeightHint => 'Vertical spacing between terminal rows.';

	/// en: 'Shell'
	String get shellSection => 'Shell';

	/// en: 'Shell'
	String get shellLabel => 'Shell';

	/// en: 'Program the built-in terminal launches.'
	String get shellHint => 'Program the built-in terminal launches.';

	/// en: 'System default'
	String get shellSystem => 'System default';

	/// en: 'Open in Terminal'
	String get externalSection => 'Open in Terminal';
}

// Path: preferences.appearance
class Translations$preferences$appearance$en {
	Translations$preferences$appearance$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Appearance'
	String get title => 'Appearance';

	/// en: 'Defaults for how files and the sidebar are displayed.'
	String get subtitle => 'Defaults for how files and the sidebar are displayed.';

	/// en: 'Theme'
	String get themeSection => 'Theme';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Choose a built-in or custom theme.'
	String get themeHint => 'Choose a built-in or custom theme.';

	/// en: 'Dark'
	String get themeDark => 'Dark';

	/// en: 'Light'
	String get themeLight => 'Light';

	/// en: 'Nord'
	String get themeNord => 'Nord';

	/// en: 'Custom themes'
	String get customThemes => 'Custom themes';

	/// en: 'Place theme JSON files in this folder. Changes are loaded when you switch themes.'
	String get customThemesHint => 'Place theme JSON files in this folder. Changes are loaded when you switch themes.';

	/// en: 'Add theme'
	String get addTheme => 'Add theme';

	/// en: 'New Custom Theme'
	String get addThemeTitle => 'New Custom Theme';

	/// en: 'Theme name'
	String get addThemeNameHint => 'Theme name';

	/// en: 'Create'
	String get addThemeCreate => 'Create';

	/// en: 'Cancel'
	String get addThemeCancel => 'Cancel';

	/// en: 'Edit'
	String get editTheme => 'Edit';

	/// en: 'Delete'
	String get deleteTheme => 'Delete';

	/// en: 'Delete Theme?'
	String get deleteThemeTitle => 'Delete Theme?';

	/// en: 'Delete "$name"? This cannot be undone.'
	String deleteThemeMessage({required Object name}) => 'Delete "${name}"? This cannot be undone.';

	/// en: 'Loading themes…'
	String get loadingThemes => 'Loading themes…';

	/// en: 'No custom themes yet.'
	String get noCustomThemes => 'No custom themes yet.';

	/// en: 'Invalid theme JSON'
	String get invalidTheme => 'Invalid theme JSON';

	/// en: 'Theme file must contain a JSON object'
	String get themeFileMustContainJsonObject => 'Theme file must contain a JSON object';

	/// en: 'Missing theme id'
	String get missingThemeId => 'Missing theme id';

	/// en: 'Missing theme name'
	String get missingThemeName => 'Missing theme name';

	/// en: 'Missing theme brightness'
	String get missingThemeBrightness => 'Missing theme brightness';

	/// en: 'Missing theme palette'
	String get missingThemePalette => 'Missing theme palette';

	/// en: 'Invalid theme brightness'
	String get invalidThemeBrightness => 'Invalid theme brightness';

	/// en: 'Missing color "$key"'
	String missingColor({required Object key}) => 'Missing color "${key}"';

	/// en: 'Invalid color "$key"'
	String invalidColor({required Object key}) => 'Invalid color "${key}"';

	/// en: 'Could not load custom themes'
	String get couldNotLoadCustomThemes => 'Could not load custom themes';

	/// en: 'Unknown theme "$id", using $theme'
	String unknownThemeUsingDefault({required Object id, required Object theme}) => 'Unknown theme "${id}", using ${theme}';

	/// en: 'Skipping theme "$id" from $path: duplicate id'
	String skippingDuplicateTheme({required Object id, required Object path}) => 'Skipping theme "${id}" from ${path}: duplicate id';

	/// en: 'Skipping theme file $path'
	String skippingThemeFile({required Object path}) => 'Skipping theme file ${path}';

	/// en: 'Files'
	String get filesSection => 'Files';

	/// en: 'Show hidden files by default'
	String get showHidden => 'Show hidden files by default';

	/// en: 'Applies to new tabs. Existing tabs keep their setting.'
	String get showHiddenHint => 'Applies to new tabs. Existing tabs keep their setting.';

	/// en: 'Row density'
	String get rowDensity => 'Row density';

	/// en: 'Comfortable'
	String get rowDensityComfortable => 'Comfortable';

	/// en: 'Compact'
	String get rowDensityCompact => 'Compact';

	/// en: 'Horizontal spacing'
	String get fileListHorizontalSpacing => 'Horizontal spacing';

	/// en: 'Vertical spacing'
	String get fileListVerticalSpacing => 'Vertical spacing';

	/// en: 'Date format'
	String get dateFormat => 'Date format';

	/// en: 'ISO (2026-05-14 13:45)'
	String get dateFormatIso => 'ISO (2026-05-14 13:45)';

	/// en: 'System locale'
	String get dateFormatLocale => 'System locale';

	/// en: 'Relative (2h ago)'
	String get dateFormatRelative => 'Relative (2h ago)';

	/// en: 'Use relative dates for recent files'
	String get recentDatesRelative => 'Use relative dates for recent files';

	/// en: 'When System locale is selected, files modified in the last 24 hours show as relative.'
	String get recentDatesRelativeHint => 'When System locale is selected, files modified in the last 24 hours show as relative.';

	/// en: 'Show folders before files'
	String get foldersFirst => 'Show folders before files';

	/// en: 'Group folders ahead of files regardless of the sort order.'
	String get foldersFirstHint => 'Group folders ahead of files regardless of the sort order.';

	/// en: 'Natural sort order'
	String get naturalSort => 'Natural sort order';

	/// en: 'Sort numbers in names by value, so "file2" comes before "file10".'
	String get naturalSortHint => 'Sort numbers in names by value, so "file2" comes before "file10".';

	/// en: 'Sort files by'
	String get sortKey => 'Sort files by';

	/// en: 'Name'
	String get sortKeyName => 'Name';

	/// en: 'Size'
	String get sortKeySize => 'Size';

	/// en: 'Date modified'
	String get sortKeyDate => 'Date modified';

	/// en: 'Sort direction'
	String get sortDirection => 'Sort direction';

	/// en: 'Ascending'
	String get sortAscending => 'Ascending';

	/// en: 'Descending'
	String get sortDescending => 'Descending';

	/// en: 'Sidebar'
	String get sidebarSection => 'Sidebar';

	/// en: 'Collapsed by default'
	String get sidebarCollapsed => 'Collapsed by default';
}

// Path: preferences.bookmarks
class Translations$preferences$bookmarks$en {
	Translations$preferences$bookmarks$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Bookmarks'
	String get title => 'Bookmarks';

	/// en: 'Manage folders pinned to the sidebar.'
	String get subtitle => 'Manage folders pinned to the sidebar.';

	/// en: 'No bookmarks yet. Drop a folder onto the sidebar to add one.'
	String get empty => 'No bookmarks yet. Drop a folder onto the sidebar to add one.';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Remove'
	String get remove => 'Remove';
}

// Path: preferences.diagnostics
class Translations$preferences$diagnostics$en {
	Translations$preferences$diagnostics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Diagnostics'
	String get title => 'Diagnostics';

	/// en: 'Recent warnings and errors. Logs are written to disk for bug reports.'
	String get subtitle => 'Recent warnings and errors. Logs are written to disk for bug reports.';

	/// en: 'No warnings or errors logged this session.'
	String get empty => 'No warnings or errors logged this session.';

	/// en: 'Filter logs…'
	String get search => 'Filter logs…';

	/// en: 'Export current log'
	String get export => 'Export current log';

	/// en: 'Copy visible'
	String get copy => 'Copy visible';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Copied to clipboard'
	String get copied => 'Copied to clipboard';

	/// en: 'Logs may contain file paths. Review before sharing.'
	String get privacyNote => 'Logs may contain file paths. Review before sharing.';

	/// en: 'Native'
	String get native => 'Native';

	/// en: 'unavailable'
	String get unavailable => 'unavailable';
}

// Path: preferences.about
class Translations$preferences$about$en {
	Translations$preferences$about$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About'
	String get title => 'About';

	/// en: 'Version'
	String get version => 'Version';

	/// en: 'Build'
	String get build => 'Build';

	/// en: 'Repository'
	String get repository => 'Repository';

	/// en: 'License'
	String get license => 'License';

	/// en: 'Copy'
	String get copy => 'Copy';
}

// Path: help.pages
class Translations$help$pages$en {
	Translations$help$pages$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$help$pages$navigation$en navigation = Translations$help$pages$navigation$en.internal(_root);
	late final Translations$help$pages$tabs$en tabs = Translations$help$pages$tabs$en.internal(_root);
	late final Translations$help$pages$dualPane$en dualPane = Translations$help$pages$dualPane$en.internal(_root);
	late final Translations$help$pages$selection$en selection = Translations$help$pages$selection$en.internal(_root);
	late final Translations$help$pages$fileOps$en fileOps = Translations$help$pages$fileOps$en.internal(_root);
	late final Translations$help$pages$quickLook$en quickLook = Translations$help$pages$quickLook$en.internal(_root);
	late final Translations$help$pages$search$en search = Translations$help$pages$search$en.internal(_root);
	late final Translations$help$pages$multiRename$en multiRename = Translations$help$pages$multiRename$en.internal(_root);
	late final Translations$help$pages$archives$en archives = Translations$help$pages$archives$en.internal(_root);
	late final Translations$help$pages$remote$en remote = Translations$help$pages$remote$en.internal(_root);
	late final Translations$help$pages$terminal$en terminal = Translations$help$pages$terminal$en.internal(_root);
}

// Path: keybindings.categories
class Translations$keybindings$categories$en {
	Translations$keybindings$categories$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Navigation'
	String get navigation => 'Navigation';

	/// en: 'Tabs'
	String get tabs => 'Tabs';

	/// en: 'Panes'
	String get panes => 'Panes';

	/// en: 'File Operations'
	String get fileOps => 'File Operations';

	/// en: 'Selection'
	String get selection => 'Selection';

	/// en: 'Search'
	String get search => 'Search';
}

// Path: fileView.date
class Translations$fileView$date$en {
	Translations$fileView$date$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'just now'
	String get justNow => 'just now';

	/// en: '${count}m ago'
	String minutesAgo({required Object count}) => '${count}m ago';

	/// en: '${count}h ago'
	String hoursAgo({required Object count}) => '${count}h ago';

	/// en: '${count}d ago'
	String daysAgo({required Object count}) => '${count}d ago';

	/// en: '${count}w ago'
	String weeksAgo({required Object count}) => '${count}w ago';

	/// en: '${count}mo ago'
	String monthsAgo({required Object count}) => '${count}mo ago';

	/// en: '${count}y ago'
	String yearsAgo({required Object count}) => '${count}y ago';
}

// Path: fileView.columns
class Translations$fileView$columns$en {
	Translations$fileView$columns$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Size'
	String get size => 'Size';

	/// en: 'Date modified'
	String get dateModified => 'Date modified';

	/// en: 'Location'
	String get location => 'Location';
}

// Path: sidebar.connectDialog
class Translations$sidebar$connectDialog$en {
	Translations$sidebar$connectDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Connect to server'
	String get title => 'Connect to server';

	/// en: 'Server'
	String get host => 'Server';

	/// en: 'e.g. 192.168.1.10 or nas.local'
	String get hostHint => 'e.g. 192.168.1.10 or nas.local';

	/// en: 'Port'
	String get port => 'Port';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'optional'
	String get usernameHint => 'optional';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'optional'
	String get shareHint => 'optional';

	/// en: 'Path'
	String get pathLabel => 'Path';

	/// en: 'optional'
	String get pathHint => 'optional';

	/// en: 'Add bookmark'
	String get addBookmark => 'Add bookmark';

	/// en: 'Connect'
	String get connect => 'Connect';

	/// en: 'Enter a server address'
	String get invalidHost => 'Enter a server address';
}

// Path: sidebar.driveSpace
class Translations$sidebar$driveSpace$en {
	Translations$sidebar$driveSpace$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Used'
	String get used => 'Used';

	/// en: 'Free'
	String get free => 'Free';

	/// en: 'Total'
	String get total => 'Total';
}

// Path: sidebar.drives
class Translations$sidebar$drives$en {
	Translations$sidebar$drives$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Local Disk'
	String get localDisk => 'Local Disk';

	/// en: 'USB Drive'
	String get usbDrive => 'USB Drive';

	/// en: 'Unknown Drive'
	String get unknownDrive => 'Unknown Drive';

	/// en: 'Network Drive'
	String get networkDrive => 'Network Drive';

	/// en: 'Macintosh HD'
	String get macintoshHd => 'Macintosh HD';

	/// en: '$letter: $name'
	String windowsDriveLabel({required Object letter, required Object name}) => '${letter}: ${name}';

	/// en: 'Mount $name'
	String mountTitle({required Object name}) => 'Mount ${name}';
}

// Path: tasks.status
class Translations$tasks$status$en {
	Translations$tasks$status$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Waiting...'
	String get waiting => 'Waiting...';

	/// en: 'Scanning files...'
	String get scanning => 'Scanning files...';

	/// en: '$count conflicts'
	String conflicts({required Object count}) => '${count} conflicts';

	/// en: '$current ($processed/$total)'
	String running({required Object current, required Object processed, required Object total}) => '${current} (${processed}/${total})';

	/// en: 'Cancelling...'
	String get cancelling => 'Cancelling...';

	/// en: 'Completed with $count errors'
	String completedWithErrors({required Object count}) => 'Completed with ${count} errors';

	/// en: 'Completed'
	String get completed => 'Completed';

	/// en: 'Failed'
	String get failed => 'Failed';

	/// en: 'Cancelled'
	String get cancelled => 'Cancelled';
}

// Path: help.pages.navigation
class Translations$help$pages$navigation$en {
	Translations$help$pages$navigation$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Navigation'
	String get title => 'Navigation';

	/// en: 'Browse without reaching for the mouse. Waydir keeps the cursor, selection and history close to the main file list. - `↑` / `↓` move the cursor through visible files. - `Enter` opens the selected item; double-click does the same. - `Backspace` goes to the parent folder. - `Alt+←` / `Alt+→` step back and forward through folder history. - `Ctrl+R` refreshes the current folder. - `Ctrl+B` shows or hides the sidebar; `Ctrl+H` toggles hidden files. - Click a segment in the breadcrumb bar to jump straight to that folder.'
	String get body => 'Browse without reaching for the mouse. Waydir keeps the cursor, selection and history close to the main file list.\n\n- `↑` / `↓` move the cursor through visible files.\n- `Enter` opens the selected item; double-click does the same.\n- `Backspace` goes to the parent folder.\n- `Alt+←` / `Alt+→` step back and forward through folder history.\n- `Ctrl+R` refreshes the current folder.\n- `Ctrl+B` shows or hides the sidebar; `Ctrl+H` toggles hidden files.\n- Click a segment in the breadcrumb bar to jump straight to that folder.';
}

// Path: help.pages.tabs
class Translations$help$pages$tabs$en {
	Translations$help$pages$tabs$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Tabs'
	String get title => 'Tabs';

	/// en: 'Keep several folders open at once and switch between them instantly. Each tab remembers its own folder, selection and history. - `Ctrl+T` opens a new tab. - `Ctrl+W` closes the current tab. - `Ctrl+Tab` / `Ctrl+Shift+Tab` cycle to the next or previous tab. - `Ctrl+1`…`Ctrl+9` jump straight to a tab by position. - The `+` button on the tab strip opens a new tab in the current folder.'
	String get body => 'Keep several folders open at once and switch between them instantly. Each tab remembers its own folder, selection and history.\n\n- `Ctrl+T` opens a new tab.\n- `Ctrl+W` closes the current tab.\n- `Ctrl+Tab` / `Ctrl+Shift+Tab` cycle to the next or previous tab.\n- `Ctrl+1`…`Ctrl+9` jump straight to a tab by position.\n- The `+` button on the tab strip opens a new tab in the current folder.';
}

// Path: help.pages.dualPane
class Translations$help$pages$dualPane$en {
	Translations$help$pages$dualPane$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Dual Pane'
	String get title => 'Dual Pane';

	/// en: 'Show a source and a destination side by side. The active pane owns keyboard focus, and the copy / move shortcuts target the opposite pane. - `F9` (or `Ctrl+D`) toggles dual pane mode. - `Tab` switches the active pane. - `F5` copies the selected files to the other pane. - `F6` moves the selected files to the other pane. - Drag the divider to change how the space is split.'
	String get body => 'Show a source and a destination side by side. The active pane owns keyboard focus, and the copy / move shortcuts target the opposite pane.\n\n- `F9` (or `Ctrl+D`) toggles dual pane mode.\n- `Tab` switches the active pane.\n- `F5` copies the selected files to the other pane.\n- `F6` moves the selected files to the other pane.\n- Drag the divider to change how the space is split.';
}

// Path: help.pages.selection
class Translations$help$pages$selection$en {
	Translations$help$pages$selection$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Selection'
	String get title => 'Selection';

	/// en: 'Build up exactly the set of files you want before acting on them. - `Ctrl+A` selects everything in the folder. - `Insert` toggles the current item and moves down. - `Ctrl+S` selects by pattern (wildcards like `*.png`). - `Esc` clears the selection. - Click, `Shift+Click` for a range and `Ctrl+Click` to add or remove single items. - `Ctrl+Shift+S` saves the current selection to a file; `Ctrl+Shift+L` loads it back.'
	String get body => 'Build up exactly the set of files you want before acting on them.\n\n- `Ctrl+A` selects everything in the folder.\n- `Insert` toggles the current item and moves down.\n- `Ctrl+S` selects by pattern (wildcards like `*.png`).\n- `Esc` clears the selection.\n- Click, `Shift+Click` for a range and `Ctrl+Click` to add or remove single items.\n- `Ctrl+Shift+S` saves the current selection to a file; `Ctrl+Shift+L` loads it back.';
}

// Path: help.pages.fileOps
class Translations$help$pages$fileOps$en {
	Translations$help$pages$fileOps$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'File Operations'
	String get title => 'File Operations';

	/// en: 'Standard clipboard and file actions work everywhere, including across panes and tabs. - `Ctrl+C` / `Ctrl+X` / `Ctrl+V` copy, cut and paste. - `F2` renames the current item; `F7` creates a new folder. - `Delete` moves the selection to the Trash; use the context menu to delete permanently. - **Copy Path** is available from the context menu. - Long copies, moves and deletes run in the operations panel, and a conflict prompt appears when names collide.'
	String get body => 'Standard clipboard and file actions work everywhere, including across panes and tabs.\n\n- `Ctrl+C` / `Ctrl+X` / `Ctrl+V` copy, cut and paste.\n- `F2` renames the current item; `F7` creates a new folder.\n- `Delete` moves the selection to the Trash; use the context menu to delete permanently.\n- **Copy Path** is available from the context menu.\n- Long copies, moves and deletes run in the operations panel, and a conflict prompt appears when names collide.';
}

// Path: help.pages.quickLook
class Translations$help$pages$quickLook$en {
	Translations$help$pages$quickLook$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Quick Look'
	String get title => 'Quick Look';

	/// en: 'Inspect a file without opening another app. Quick Look handles images, text, code and other supported types. - `Space` opens Quick Look for the current selection. - `↑` / `↓` step to the previous or next file without leaving the preview. - `Esc` closes the preview. - Text and code previews are editable - `Ctrl+S` saves changes in place. - The info panel shows size, dates and permissions alongside the preview.'
	String get body => 'Inspect a file without opening another app. Quick Look handles images, text, code and other supported types.\n\n- `Space` opens Quick Look for the current selection.\n- `↑` / `↓` step to the previous or next file without leaving the preview.\n- `Esc` closes the preview.\n- Text and code previews are editable - `Ctrl+S` saves changes in place.\n- The info panel shows size, dates and permissions alongside the preview.';
}

// Path: help.pages.search
class Translations$help$pages$search$en {
	Translations$help$pages$search$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search'
	String get title => 'Search';

	/// en: 'Filter the current folder or sweep through everything beneath it. - `Ctrl+F` filters the current folder by name as you type. - `Ctrl+Shift+F` extends the search into all subfolders. - Turn on **Content** to search inside file contents (local folders only - not over SFTP). - Switch between **Substring**, **Glob** and **Regex** matching. - `Esc` closes the search and restores the full list.'
	String get body => 'Filter the current folder or sweep through everything beneath it.\n\n- `Ctrl+F` filters the current folder by name as you type.\n- `Ctrl+Shift+F` extends the search into all subfolders.\n- Turn on **Content** to search inside file contents (local folders only - not over SFTP).\n- Switch between **Substring**, **Glob** and **Regex** matching.\n- `Esc` closes the search and restores the full list.';
}

// Path: help.pages.multiRename
class Translations$help$pages$multiRename$en {
	Translations$help$pages$multiRename$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Multi Rename'
	String get title => 'Multi Rename';

	/// en: 'Rename many files at once with a live before / after preview. Select several items, then choose **Multi Rename** from the context menu. - **Template** mode builds names from tokens: `{name}`, `{ext}`, `{n}` (sequence from 1), `{index}` (from 0) and `{date}`. - **Find & Replace** mode swaps text, with optional regular expressions and case sensitivity. - The preview lists every result before you commit, and *Show only changed* hides untouched rows.'
	String get body => 'Rename many files at once with a live before / after preview. Select several items, then choose **Multi Rename** from the context menu.\n\n- **Template** mode builds names from tokens: `{name}`, `{ext}`, `{n}` (sequence from 1), `{index}` (from 0) and `{date}`.\n- **Find & Replace** mode swaps text, with optional regular expressions and case sensitivity.\n- The preview lists every result before you commit, and *Show only changed* hides untouched rows.';
}

// Path: help.pages.archives
class Translations$help$pages$archives$en {
	Translations$help$pages$archives$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Archives'
	String get title => 'Archives';

	/// en: 'Archives behave like browsable folders, so you can look inside before extracting anything. - `Enter` opens a supported archive and lets you walk its contents. - The context menu can extract here, extract into a named folder, or extract each archive separately. - **Compress** builds a new archive from the selection - pick the format and compression level. - Extraction and compression run in the background, so the file list stays responsive.'
	String get body => 'Archives behave like browsable folders, so you can look inside before extracting anything.\n\n- `Enter` opens a supported archive and lets you walk its contents.\n- The context menu can extract here, extract into a named folder, or extract each archive separately.\n- **Compress** builds a new archive from the selection - pick the format and compression level.\n- Extraction and compression run in the background, so the file list stays responsive.';
}

// Path: help.pages.remote
class Translations$help$pages$remote$en {
	Translations$help$pages$remote$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Remote Locations'
	String get title => 'Remote Locations';

	/// en: 'Work with SFTP servers right next to your local folders. - Use **Connect to Server** from the sidebar to add a remote location. - Once connected, open and browse remote folders exactly like local ones. - Bookmark folders you visit often so they stay one click away. - Selection, the context menu and file operations all behave the same as locally - only content search is unavailable over SFTP.'
	String get body => 'Work with SFTP servers right next to your local folders.\n\n- Use **Connect to Server** from the sidebar to add a remote location.\n- Once connected, open and browse remote folders exactly like local ones.\n- Bookmark folders you visit often so they stay one click away.\n- Selection, the context menu and file operations all behave the same as locally - only content search is unavailable over SFTP.';
}

// Path: help.pages.terminal
class Translations$help$pages$terminal$en {
	Translations$help$pages$terminal$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Terminal'
	String get title => 'Terminal';

	/// en: 'Each pane has its own embedded terminal that opens in the folder you are viewing. - `Ctrl` + backtick opens or focuses the terminal (`Ctrl+J` on macOS). - `Ctrl+Shift` + backtick shows or hides the terminal panel. - `Ctrl+Shift+T` opens a new terminal tab; `Ctrl+Shift+W` closes one. - `Ctrl++` / `Ctrl+-` adjust the font size and `Ctrl+0` resets it.'
	String get body => 'Each pane has its own embedded terminal that opens in the folder you are viewing.\n\n- `Ctrl` + backtick opens or focuses the terminal (`Ctrl+J` on macOS).\n- `Ctrl+Shift` + backtick shows or hides the terminal panel.\n- `Ctrl+Shift+T` opens a new terminal tab; `Ctrl+Shift+W` closes one.\n- `Ctrl++` / `Ctrl+-` adjust the font size and `Ctrl+0` resets it.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Waydir',
			'app.tagline' => 'Navigate your files. Your way.',
			'app.description' => 'A fast, keyboard-driven desktop file manager built with Flutter.',
			'terminal.title' => 'Terminal',
			'menu.view' => 'View',
			'menu.open' => 'Open',
			'menu.openItems' => ({required Object count}) => 'Open ${count} Items',
			'menu.copy' => 'Copy',
			'menu.cut' => 'Cut',
			'menu.paste' => 'Paste',
			'menu.copyPath' => 'Copy Path',
			'menu.delete' => 'Delete',
			'menu.deleteItems' => ({required Object count}) => 'Delete ${count} Items',
			'menu.moveToTrash' => 'Move to Trash',
			'menu.moveToTrashItems' => ({required Object count}) => 'Move ${count} Items to Trash',
			'menu.deletePermanently' => 'Delete Permanently',
			'menu.deletePermanentlyItems' => ({required Object count}) => 'Delete ${count} Items Permanently',
			'menu.restore' => 'Restore',
			'menu.restoreItems' => ({required Object count}) => 'Restore ${count} Items',
			'menu.showHidden' => 'Show Hidden Files',
			'menu.selectAll' => 'Select All',
			'menu.selectByPattern' => 'Select by Pattern…',
			'menu.deselectAll' => 'Deselect All',
			'menu.saveSelection' => 'Save Selection to File…',
			'menu.loadSelection' => 'Load Selection from File…',
			'menu.openInTerminal' => 'Open in Terminal',
			'menu.rename' => 'Rename',
			'menu.openLocation' => 'Open Location',
			'menu.openInNewTab' => 'Open in New Tab',
			'menu.removeBookmark' => 'Remove Bookmark',
			'menu.dualPaneMode' => 'Dual Pane Mode',
			'menu.properties' => 'Properties',
			'menu.openWith' => 'Open With',
			'menu.openWithApp' => ({required Object app}) => 'Open With ${app}',
			'menu.openWithChoose' => 'Other Application…',
			'menu.extract' => 'Extract',
			'menu.extractHere' => 'Extract Here',
			'menu.extractToFolder' => ({required Object name}) => 'Extract to ${name}/',
			'menu.extractEach' => 'Extract Each to Its Own Folder',
			'menu.compress' => 'Compress',
			'menu.compressTo' => ({required Object name}) => 'Compress to ${name}',
			'menu.compressOptions' => 'Add to Archive…',
			'menu.multiRename' => 'Multi Rename…',
			'menu.verifyChecksum' => 'Verify Checksum…',
			'multiRename.title' => 'Multi Rename',
			'multiRename.subtitle' => ({required Object count}) => '${count} items selected',
			'multiRename.modeTemplate' => 'Template',
			'multiRename.modeFindReplace' => 'Find & Replace',
			'multiRename.namePattern' => 'Name pattern',
			'multiRename.tokens' => 'Tokens',
			'multiRename.tokenFilename' => 'Original name without extension',
			'multiRename.tokenExt' => 'Original extension (with dot)',
			'multiRename.tokenN' => 'Sequence number (starts at 1)',
			'multiRename.tokenIndex' => 'Sequence index (starts at 0)',
			'multiRename.tokenDate' => 'Today\'s date (YYYY-MM-DD)',
			'multiRename.find' => 'Find',
			'multiRename.replaceWith' => 'Replace with',
			'multiRename.useRegex' => 'Regular expression',
			'multiRename.caseSensitive' => 'Case sensitive',
			'multiRename.preview' => 'Preview',
			'multiRename.columnBefore' => 'Before',
			'multiRename.columnAfter' => 'After',
			'multiRename.showOnlyChanged' => 'Show only changed',
			'multiRename.changedOfTotal' => ({required Object changed, required Object total}) => '${changed} of ${total} will change',
			'multiRename.errorCount' => ({required Object count}) => '${count} conflicts',
			'multiRename.noChanges' => 'No files will be renamed',
			'multiRename.cancel' => 'Cancel',
			'multiRename.rename' => 'Rename',
			'multiRename.renameCount' => ({required Object count}) => 'Rename ${count} files',
			'multiRename.errorInvalid' => 'invalid name',
			'multiRename.errorDuplicate' => 'duplicate',
			'compress.title' => 'Add to Archive',
			'compress.archiveName' => 'Archive name',
			'compress.format' => 'Format',
			'compress.level' => 'Compression',
			'compress.destination' => 'Destination',
			'compress.levelStore' => 'Store (no compression)',
			'compress.levelNormal' => 'Normal',
			'compress.levelMaximum' => 'Maximum',
			'compress.create' => 'Create',
			'compress.cancel' => 'Cancel',
			'checksum.title' => 'Verify Checksum',
			'checksum.md5' => 'MD5',
			'checksum.sha256' => 'SHA-256',
			'checksum.expected' => 'Expected checksum',
			'checksum.expectedHint' => ({required Object algorithm}) => '${algorithm} digest',
			'checksum.verify' => 'Verify',
			'checksum.calculating' => 'Calculating…',
			'checksum.match' => 'Checksum matches',
			'checksum.mismatch' => 'Checksum does not match',
			'checksum.copy' => 'Copy',
			'checksum.copied' => 'Copied',
			'checksum.invalidExpected' => ({required Object algorithm, required Object length}) => '${algorithm} checksum must be ${length} hexadecimal characters',
			'checksum.readError' => 'Could not read file',
			'properties.title' => 'Properties',
			'properties.name' => 'Name',
			'properties.type' => 'Type',
			'properties.location' => 'Location',
			'properties.size' => 'Size',
			'properties.modified' => 'Modified',
			'properties.accessed' => 'Accessed',
			'properties.changed' => 'Changed',
			'properties.permissions' => 'Permissions',
			'properties.contains' => 'Contains',
			'properties.typeFolder' => 'Folder',
			'properties.typeFile' => 'File',
			'properties.sizeDetail' => ({required Object formatted, required Object count}) => '${formatted} (${count} bytes)',
			'properties.containsItems' => ({required Object count}) => '${count} items',
			'properties.calculating' => 'Calculating…',
			'properties.close' => 'Close',
			'preferences.title' => 'Preferences',
			'preferences.menuLabel' => 'Preferences…',
			'preferences.close' => 'Close',
			'preferences.comingSoon' => 'Coming soon',
			'preferences.categories.general' => 'General',
			'preferences.categories.appearance' => 'Appearance',
			'preferences.categories.terminal' => 'Terminal',
			'preferences.categories.bookmarks' => 'Bookmarks',
			'preferences.categories.diagnostics' => 'Diagnostics',
			'preferences.categories.about' => 'About',
			'preferences.general.title' => 'General',
			'preferences.general.subtitle' => 'Startup, file operations and terminal integration.',
			'preferences.general.startupSection' => 'Startup',
			'preferences.general.restoreSession' => 'Restore last session',
			'preferences.general.restoreSessionHint' => 'Reopen previously open tabs and panes on launch.',
			'preferences.general.defaultPath' => 'Default starting path',
			'preferences.general.defaultPathHint' => 'Used when session restore is disabled or empty.',
			'preferences.general.defaultPathPlaceholder' => '/home/user',
			'preferences.general.browse' => 'Browse…',
			'preferences.general.foldersSection' => 'Folders',
			'preferences.general.fileOpsSection' => 'File operations',
			'preferences.general.confirmDelete' => 'Confirm before delete',
			'preferences.general.confirmDeleteHint' => 'Show a dialog before removing files or folders.',
			'preferences.general.confirmCopy' => 'Confirm before copy',
			'preferences.general.confirmCopyHint' => 'Show a dialog before copying files or folders.',
			'preferences.general.confirmMove' => 'Confirm before move',
			'preferences.general.confirmMoveHint' => 'Show a dialog before moving files or folders.',
			'preferences.general.rememberFolderState' => 'Remember selection per folder',
			'preferences.general.rememberFolderStateHint' => 'Restore the cursor and selected files when you return to a folder.',
			'preferences.general.rememberFolderSort' => 'Remember sort per folder',
			'preferences.general.rememberFolderSortHint' => 'Save and reuse the sort column and direction for each folder.',
			'preferences.general.deleteKeyBehavior' => 'Delete key behavior',
			'preferences.general.deleteKeyBehaviorHint' => 'What the Delete key does by default. Shift+Delete always deletes permanently.',
			'preferences.general.deleteKeyTrash' => 'Move to Trash',
			'preferences.general.deleteKeyPermanent' => 'Delete Permanently',
			'preferences.general.terminalSection' => 'Terminal',
			'preferences.general.terminalLabel' => 'Default terminal',
			'preferences.general.terminalHint' => 'Used by "Open in Terminal".',
			'preferences.general.terminalBuiltin' => 'Built-in terminal',
			'preferences.general.terminalAuto' => 'External (auto-detect)',
			'preferences.general.terminalCustom' => 'Custom command…',
			'preferences.general.terminalCustomLabel' => 'Command',
			'preferences.general.terminalCustomHint' => 'e.g. kitty --working-directory={dir}',
			'preferences.general.terminalCustomHelp' => 'Use {dir} as a placeholder for the directory path.',
			'preferences.terminal.title' => 'Terminal',
			'preferences.terminal.subtitle' => 'Embedded terminal font and external terminal integration.',
			'preferences.terminal.appearanceSection' => 'Appearance',
			'preferences.terminal.useSystemFont' => 'Use system font',
			'preferences.terminal.useSystemFontHint' => 'Render the terminal with the system monospace font.',
			'preferences.terminal.fontFamily' => 'Font family',
			'preferences.terminal.fontFamilyHint' => 'Pick an installed monospace font.',
			'preferences.terminal.fontSize' => 'Font size',
			'preferences.terminal.fontSizeHint' => 'Adjust on the fly with Ctrl++, Ctrl+- and Ctrl+0.',
			'preferences.terminal.lineHeight' => 'Line height',
			'preferences.terminal.lineHeightHint' => 'Vertical spacing between terminal rows.',
			'preferences.terminal.shellSection' => 'Shell',
			'preferences.terminal.shellLabel' => 'Shell',
			'preferences.terminal.shellHint' => 'Program the built-in terminal launches.',
			'preferences.terminal.shellSystem' => 'System default',
			'preferences.terminal.externalSection' => 'Open in Terminal',
			'preferences.appearance.title' => 'Appearance',
			'preferences.appearance.subtitle' => 'Defaults for how files and the sidebar are displayed.',
			'preferences.appearance.themeSection' => 'Theme',
			'preferences.appearance.theme' => 'Theme',
			'preferences.appearance.themeHint' => 'Choose a built-in or custom theme.',
			'preferences.appearance.themeDark' => 'Dark',
			'preferences.appearance.themeLight' => 'Light',
			'preferences.appearance.themeNord' => 'Nord',
			'preferences.appearance.customThemes' => 'Custom themes',
			'preferences.appearance.customThemesHint' => 'Place theme JSON files in this folder. Changes are loaded when you switch themes.',
			'preferences.appearance.addTheme' => 'Add theme',
			'preferences.appearance.addThemeTitle' => 'New Custom Theme',
			'preferences.appearance.addThemeNameHint' => 'Theme name',
			'preferences.appearance.addThemeCreate' => 'Create',
			'preferences.appearance.addThemeCancel' => 'Cancel',
			'preferences.appearance.editTheme' => 'Edit',
			'preferences.appearance.deleteTheme' => 'Delete',
			'preferences.appearance.deleteThemeTitle' => 'Delete Theme?',
			'preferences.appearance.deleteThemeMessage' => ({required Object name}) => 'Delete "${name}"? This cannot be undone.',
			'preferences.appearance.loadingThemes' => 'Loading themes…',
			'preferences.appearance.noCustomThemes' => 'No custom themes yet.',
			'preferences.appearance.invalidTheme' => 'Invalid theme JSON',
			'preferences.appearance.themeFileMustContainJsonObject' => 'Theme file must contain a JSON object',
			'preferences.appearance.missingThemeId' => 'Missing theme id',
			'preferences.appearance.missingThemeName' => 'Missing theme name',
			'preferences.appearance.missingThemeBrightness' => 'Missing theme brightness',
			'preferences.appearance.missingThemePalette' => 'Missing theme palette',
			'preferences.appearance.invalidThemeBrightness' => 'Invalid theme brightness',
			'preferences.appearance.missingColor' => ({required Object key}) => 'Missing color "${key}"',
			'preferences.appearance.invalidColor' => ({required Object key}) => 'Invalid color "${key}"',
			'preferences.appearance.couldNotLoadCustomThemes' => 'Could not load custom themes',
			'preferences.appearance.unknownThemeUsingDefault' => ({required Object id, required Object theme}) => 'Unknown theme "${id}", using ${theme}',
			'preferences.appearance.skippingDuplicateTheme' => ({required Object id, required Object path}) => 'Skipping theme "${id}" from ${path}: duplicate id',
			'preferences.appearance.skippingThemeFile' => ({required Object path}) => 'Skipping theme file ${path}',
			'preferences.appearance.filesSection' => 'Files',
			'preferences.appearance.showHidden' => 'Show hidden files by default',
			'preferences.appearance.showHiddenHint' => 'Applies to new tabs. Existing tabs keep their setting.',
			'preferences.appearance.rowDensity' => 'Row density',
			'preferences.appearance.rowDensityComfortable' => 'Comfortable',
			'preferences.appearance.rowDensityCompact' => 'Compact',
			'preferences.appearance.fileListHorizontalSpacing' => 'Horizontal spacing',
			'preferences.appearance.fileListVerticalSpacing' => 'Vertical spacing',
			'preferences.appearance.dateFormat' => 'Date format',
			'preferences.appearance.dateFormatIso' => 'ISO (2026-05-14 13:45)',
			'preferences.appearance.dateFormatLocale' => 'System locale',
			'preferences.appearance.dateFormatRelative' => 'Relative (2h ago)',
			'preferences.appearance.recentDatesRelative' => 'Use relative dates for recent files',
			'preferences.appearance.recentDatesRelativeHint' => 'When System locale is selected, files modified in the last 24 hours show as relative.',
			'preferences.appearance.foldersFirst' => 'Show folders before files',
			'preferences.appearance.foldersFirstHint' => 'Group folders ahead of files regardless of the sort order.',
			'preferences.appearance.naturalSort' => 'Natural sort order',
			'preferences.appearance.naturalSortHint' => 'Sort numbers in names by value, so "file2" comes before "file10".',
			'preferences.appearance.sortKey' => 'Sort files by',
			'preferences.appearance.sortKeyName' => 'Name',
			'preferences.appearance.sortKeySize' => 'Size',
			'preferences.appearance.sortKeyDate' => 'Date modified',
			'preferences.appearance.sortDirection' => 'Sort direction',
			'preferences.appearance.sortAscending' => 'Ascending',
			'preferences.appearance.sortDescending' => 'Descending',
			'preferences.appearance.sidebarSection' => 'Sidebar',
			'preferences.appearance.sidebarCollapsed' => 'Collapsed by default',
			'preferences.bookmarks.title' => 'Bookmarks',
			'preferences.bookmarks.subtitle' => 'Manage folders pinned to the sidebar.',
			'preferences.bookmarks.empty' => 'No bookmarks yet. Drop a folder onto the sidebar to add one.',
			'preferences.bookmarks.rename' => 'Rename',
			'preferences.bookmarks.remove' => 'Remove',
			'preferences.diagnostics.title' => 'Diagnostics',
			'preferences.diagnostics.subtitle' => 'Recent warnings and errors. Logs are written to disk for bug reports.',
			'preferences.diagnostics.empty' => 'No warnings or errors logged this session.',
			'preferences.diagnostics.search' => 'Filter logs…',
			'preferences.diagnostics.export' => 'Export current log',
			'preferences.diagnostics.copy' => 'Copy visible',
			'preferences.diagnostics.clear' => 'Clear',
			'preferences.diagnostics.copied' => 'Copied to clipboard',
			'preferences.diagnostics.privacyNote' => 'Logs may contain file paths. Review before sharing.',
			'preferences.diagnostics.native' => 'Native',
			'preferences.diagnostics.unavailable' => 'unavailable',
			'preferences.about.title' => 'About',
			'preferences.about.version' => 'Version',
			'preferences.about.build' => 'Build',
			'preferences.about.repository' => 'Repository',
			'preferences.about.license' => 'License',
			'preferences.about.copy' => 'Copy',
			'update.title' => 'Updates',
			'update.available' => 'Update available',
			'update.downloading' => 'Downloading update',
			'update.ready' => 'Ready to install',
			'update.launching' => 'Launching installer...',
			'update.error' => 'Update error',
			'update.checking' => 'Checking for updates...',
			'update.unknownError' => 'Unknown error',
			'update.upToDate' => ({required Object version}) => 'You\'re on the latest version (v${version}).',
			'update.noRelease' => 'No release information.',
			'update.noMatch' => 'No matching download for this platform.',
			'update.noNotes' => 'No release notes provided.',
			'update.versionLabel' => ({required Object version}) => 'v${version}',
			'update.titleWithVersion' => ({required Object title, required Object version}) => '${title} - v${version}',
			'update.tooltipAvailable' => ({required Object version}) => 'Update available - v${version}',
			'update.tooltipUpToDate' => 'Up to date',
			'update.checkForUpdates' => 'Check for updates',
			'update.releasePage' => 'Release page',
			'update.downloaded' => 'Downloaded',
			'update.btnDownload' => 'Download',
			'update.btnGetUpdate' => 'Get the update',
			'update.appImageManual' => 'AppImages don\'t update themselves. Download the new version and replace this file.',
			'update.btnDownloading' => 'Downloading...',
			'update.btnCheckNow' => 'Check now',
			'update.btnRetry' => 'Retry',
			'update.btnInstall' => 'Install',
			'update.btnUpdate' => 'Update',
			'update.btnOpenDmg' => 'Open DMG',
			'update.btnRestart' => 'Restart Waydir',
			'update.installed' => 'Update installed',
			'update.restartHint' => ({required Object version}) => 'Restart Waydir to start using v${version}.',
			'update.statusCheckingInline' => 'checking...',
			'update.statusUpToDateInline' => 'up to date',
			'update.formatInstaller' => 'installer',
			'update.formatPortable' => 'portable',
			'update.formatUnknown' => 'unknown',
			'update.downloadFailed' => ({required Object statusCode}) => 'Download failed: HTTP ${statusCode}',
			'update.githubApiError' => ({required Object statusCode, required Object reason}) => 'GitHub API ${statusCode}: ${reason}',
			'update.packageInstallerLaunchFailed' => ({required Object path}) => 'Could not launch package installer. Open the file manually: ${path}',
			'update.bundleNotWritable' => 'Cannot write to bundle directory. Install the new version manually.',
			'update.installerLaunchFailed' => ({required Object error}) => 'Failed to launch installer: ${error}',
			'update.relaunchFailed' => ({required Object error}) => 'Failed to relaunch: ${error}',
			'update.terminalInstallOk' => '--- Install OK. Press Enter to close ---',
			'update.terminalInstallFailed' => ({required Object status}) => '--- Install failed (exit ${status}). Press Enter to close ---',
			'appMenu.help' => 'Help',
			'appMenu.starOnGithub' => 'Star on GitHub',
			'appMenu.quit' => 'Quit',
			'help.title' => 'Features',
			'help.menuLabel' => 'Features',
			'help.demoComingSoon' => 'Demo coming soon',
			'help.pages.navigation.title' => 'Navigation',
			'help.pages.navigation.body' => 'Browse without reaching for the mouse. Waydir keeps the cursor, selection and history close to the main file list.\n\n- `↑` / `↓` move the cursor through visible files.\n- `Enter` opens the selected item; double-click does the same.\n- `Backspace` goes to the parent folder.\n- `Alt+←` / `Alt+→` step back and forward through folder history.\n- `Ctrl+R` refreshes the current folder.\n- `Ctrl+B` shows or hides the sidebar; `Ctrl+H` toggles hidden files.\n- Click a segment in the breadcrumb bar to jump straight to that folder.',
			'help.pages.tabs.title' => 'Tabs',
			'help.pages.tabs.body' => 'Keep several folders open at once and switch between them instantly. Each tab remembers its own folder, selection and history.\n\n- `Ctrl+T` opens a new tab.\n- `Ctrl+W` closes the current tab.\n- `Ctrl+Tab` / `Ctrl+Shift+Tab` cycle to the next or previous tab.\n- `Ctrl+1`…`Ctrl+9` jump straight to a tab by position.\n- The `+` button on the tab strip opens a new tab in the current folder.',
			'help.pages.dualPane.title' => 'Dual Pane',
			'help.pages.dualPane.body' => 'Show a source and a destination side by side. The active pane owns keyboard focus, and the copy / move shortcuts target the opposite pane.\n\n- `F9` (or `Ctrl+D`) toggles dual pane mode.\n- `Tab` switches the active pane.\n- `F5` copies the selected files to the other pane.\n- `F6` moves the selected files to the other pane.\n- Drag the divider to change how the space is split.',
			'help.pages.selection.title' => 'Selection',
			'help.pages.selection.body' => 'Build up exactly the set of files you want before acting on them.\n\n- `Ctrl+A` selects everything in the folder.\n- `Insert` toggles the current item and moves down.\n- `Ctrl+S` selects by pattern (wildcards like `*.png`).\n- `Esc` clears the selection.\n- Click, `Shift+Click` for a range and `Ctrl+Click` to add or remove single items.\n- `Ctrl+Shift+S` saves the current selection to a file; `Ctrl+Shift+L` loads it back.',
			'help.pages.fileOps.title' => 'File Operations',
			'help.pages.fileOps.body' => 'Standard clipboard and file actions work everywhere, including across panes and tabs.\n\n- `Ctrl+C` / `Ctrl+X` / `Ctrl+V` copy, cut and paste.\n- `F2` renames the current item; `F7` creates a new folder.\n- `Delete` moves the selection to the Trash; use the context menu to delete permanently.\n- **Copy Path** is available from the context menu.\n- Long copies, moves and deletes run in the operations panel, and a conflict prompt appears when names collide.',
			'help.pages.quickLook.title' => 'Quick Look',
			'help.pages.quickLook.body' => 'Inspect a file without opening another app. Quick Look handles images, text, code and other supported types.\n\n- `Space` opens Quick Look for the current selection.\n- `↑` / `↓` step to the previous or next file without leaving the preview.\n- `Esc` closes the preview.\n- Text and code previews are editable - `Ctrl+S` saves changes in place.\n- The info panel shows size, dates and permissions alongside the preview.',
			'help.pages.search.title' => 'Search',
			'help.pages.search.body' => 'Filter the current folder or sweep through everything beneath it.\n\n- `Ctrl+F` filters the current folder by name as you type.\n- `Ctrl+Shift+F` extends the search into all subfolders.\n- Turn on **Content** to search inside file contents (local folders only - not over SFTP).\n- Switch between **Substring**, **Glob** and **Regex** matching.\n- `Esc` closes the search and restores the full list.',
			'help.pages.multiRename.title' => 'Multi Rename',
			'help.pages.multiRename.body' => 'Rename many files at once with a live before / after preview. Select several items, then choose **Multi Rename** from the context menu.\n\n- **Template** mode builds names from tokens: `{name}`, `{ext}`, `{n}` (sequence from 1), `{index}` (from 0) and `{date}`.\n- **Find & Replace** mode swaps text, with optional regular expressions and case sensitivity.\n- The preview lists every result before you commit, and *Show only changed* hides untouched rows.',
			'help.pages.archives.title' => 'Archives',
			'help.pages.archives.body' => 'Archives behave like browsable folders, so you can look inside before extracting anything.\n\n- `Enter` opens a supported archive and lets you walk its contents.\n- The context menu can extract here, extract into a named folder, or extract each archive separately.\n- **Compress** builds a new archive from the selection - pick the format and compression level.\n- Extraction and compression run in the background, so the file list stays responsive.',
			'help.pages.remote.title' => 'Remote Locations',
			'help.pages.remote.body' => 'Work with SFTP servers right next to your local folders.\n\n- Use **Connect to Server** from the sidebar to add a remote location.\n- Once connected, open and browse remote folders exactly like local ones.\n- Bookmark folders you visit often so they stay one click away.\n- Selection, the context menu and file operations all behave the same as locally - only content search is unavailable over SFTP.',
			'help.pages.terminal.title' => 'Terminal',
			'help.pages.terminal.body' => 'Each pane has its own embedded terminal that opens in the folder you are viewing.\n\n- `Ctrl` + backtick opens or focuses the terminal (`Ctrl+J` on macOS).\n- `Ctrl+Shift` + backtick shows or hides the terminal panel.\n- `Ctrl+Shift+T` opens a new terminal tab; `Ctrl+Shift+W` closes one.\n- `Ctrl++` / `Ctrl+-` adjust the font size and `Ctrl+0` resets it.',
			'keybindings.title' => 'Keyboard Shortcuts',
			'keybindings.menuLabel' => 'Shortcuts',
			'keybindings.categories.navigation' => 'Navigation',
			'keybindings.categories.tabs' => 'Tabs',
			'keybindings.categories.panes' => 'Panes',
			'keybindings.categories.fileOps' => 'File Operations',
			'keybindings.categories.selection' => 'Selection',
			'keybindings.categories.search' => 'Search',
			'keybindings.or' => 'or',
			'keybindings.fixed' => 'Fixed shortcut',
			'keybindings.change' => 'Change shortcut',
			'keybindings.reset' => 'Reset shortcut',
			'keybindings.pressShortcut' => 'Press a shortcut',
			'keybindings.escapeToCancel' => 'Esc cancels',
			'keybindings.conflict' => ({required Object action}) => 'Already used by ${action}',
			'keybindings.dualHint' => 'dual',
			'keybindings.openItem' => 'Open',
			'keybindings.goUp' => 'Go up',
			'keybindings.goBack' => 'Go back',
			'keybindings.goForward' => 'Go forward',
			'keybindings.refresh' => 'Refresh',
			'keybindings.focusPath' => 'Focus path bar',
			'keybindings.quickLook' => 'Quick look',
			'keybindings.cursorUp' => 'Move up',
			'keybindings.cursorDown' => 'Move down',
			'keybindings.newTab' => 'New tab',
			'keybindings.closeTab' => 'Close tab',
			'keybindings.nextTab' => 'Next tab',
			'keybindings.prevTab' => 'Previous tab',
			'keybindings.switchTab' => 'Switch to tab',
			'keybindings.toggleDual' => 'Toggle dual pane',
			'keybindings.switchPane' => 'Switch active pane',
			'keybindings.focusTerminal' => 'Open / focus terminal',
			'keybindings.toggleTerminal' => 'Toggle terminal',
			'keybindings.newTerminalTab' => 'New terminal tab',
			'keybindings.closeTerminalTab' => 'Close terminal tab',
			'keybindings.terminalFontIncrease' => 'Increase terminal font',
			'keybindings.terminalFontDecrease' => 'Decrease terminal font',
			'keybindings.terminalFontReset' => 'Reset terminal font',
			'keybindings.fileListZoomIn' => 'Zoom in file list',
			'keybindings.fileListZoomOut' => 'Zoom out file list',
			'keybindings.fileListZoomReset' => 'Reset file list zoom',
			'keybindings.toggleSidebar' => 'Toggle sidebar',
			'keybindings.copy' => 'Copy',
			'keybindings.cut' => 'Cut',
			'keybindings.paste' => 'Paste',
			'keybindings.delete' => 'Delete',
			'keybindings.rename' => 'Rename',
			'keybindings.newFolder' => 'New folder',
			'keybindings.dualCopy' => 'Copy to other pane',
			'keybindings.dualMove' => 'Move to other pane',
			'keybindings.selectAll' => 'Select all',
			'keybindings.selectPattern' => 'Select by pattern',
			'keybindings.deselectAll' => 'Deselect all',
			'keybindings.toggleSelect' => 'Toggle select',
			'keybindings.saveSelection' => 'Save selection to file',
			'keybindings.loadSelection' => 'Load selection from file',
			'keybindings.search' => 'Search',
			'keybindings.recursiveSearch' => 'Recursive search',
			'keybindings.closeSearch' => 'Close search',
			'keybindings.commandPalette' => 'Command palette',
			'keybindings.preferences' => 'Preferences',
			'commandPalette.title' => 'Command Palette',
			'commandPalette.placeholder' => 'Type a command or setting…',
			'commandPalette.empty' => 'No matching commands',
			'commandPalette.openPreferences' => 'Open Preferences',
			'commandPalette.preferencesSubtitle' => 'Open the full settings dialog',
			'commandPalette.enabled' => 'Enabled',
			'commandPalette.disabled' => 'Disabled',
			'quickLook.title' => 'Quick Look',
			'quickLook.noSelection' => 'No file selected',
			'quickLook.folder' => 'Folder',
			'quickLook.noPreview' => 'No preview available',
			'quickLook.binaryFile' => 'Binary file - no preview',
			'quickLook.tooLarge' => 'File too large to preview',
			'quickLook.readError' => 'Could not read file',
			'quickLook.save' => 'Save',
			'quickLook.saved' => 'Saved',
			'quickLook.unsaved' => 'Unsaved',
			'quickLook.saveError' => 'Could not save file',
			'quickLook.accessed' => 'Accessed',
			'quickLook.changed' => 'Changed',
			'quickLook.permissions' => 'Permissions',
			'quickLook.contains' => 'Contains',
			'quickLook.calculating' => 'Calculating…',
			'quickLook.items' => ({required Object count}) => '${count} items',
			'quickLook.sectionDetails' => 'Details',
			'quickLook.info' => 'Information',
			'quickLook.name' => 'Name',
			'quickLook.type' => 'Type',
			'quickLook.size' => 'Size',
			'quickLook.path' => 'Path',
			'quickLook.location' => 'Location',
			'quickLook.modified' => 'Modified',
			'quickLook.typeFolder' => 'Folder',
			'quickLook.typeFile' => 'File',
			'quickLook.dimensions' => 'Dimensions',
			'quickLook.camera' => 'Camera',
			'quickLook.lens' => 'Lens',
			'quickLook.exposure' => 'Exposure',
			'quickLook.aperture' => 'Aperture',
			'quickLook.iso' => 'ISO',
			'quickLook.focalLength' => 'Focal length',
			'quickLook.dateTaken' => 'Date taken',
			'quickLook.linePosition' => ({required Object line, required Object count}) => 'Ln ${line} / ${count}',
			'quickLook.lines' => 'Lines',
			'quickLook.characters' => 'Characters',
			'quickLook.sectionGeneral' => 'General',
			'quickLook.sectionStatistics' => 'Statistics',
			'quickLook.sizeBreakdown' => 'Size breakdown',
			'quickLook.typeBreakdown' => 'Type breakdown',
			'quickLook.noExtension' => 'no extension',
			'quickLook.sectionImage' => 'Image',
			'quickLook.sectionText' => 'Text',
			'toast.copiedItems' => ({required Object count}) => 'Copied ${count} items',
			'toast.cutItems' => ({required Object count}) => 'Cut ${count} items',
			'toast.selectionSaved' => ({required Object count, required Object path}) => 'Saved ${count} names to ${path}',
			'toast.selectionLoaded' => ({required Object count}) => 'Selected ${count} visible items',
			'toast.selectionLoadEmpty' => 'No visible items matched',
			'toast.terminalUnavailable' => 'Terminal is unavailable: native core not loaded',
			'toast.selectionFileError' => ({required Object message}) => 'Selection file error: ${message}',
			'toast.taskErrors' => ({required Object label, required Object count}) => '${label} - ${count} errors',
			'toast.renameAlreadyExists' => ({required Object name}) => 'An item named \'${name}\' already exists',
			'toast.renameInvalidName' => 'Invalid name',
			'toast.renameError' => ({required Object message}) => 'Could not rename: ${message}',
			'toast.multiRenameSuccess' => ({required Object count}) => 'Renamed ${count} files',
			'toast.multiRenamePartial' => ({required Object succeeded, required Object total, required Object details}) => 'Renamed ${succeeded} of ${total} (${details})',
			'toast.multiRenameCollisions' => ({required Object count}) => '${count} already existed',
			'toast.multiRenameInvalid' => ({required Object count}) => '${count} invalid names',
			'toast.multiRenameOtherErrors' => ({required Object count}) => '${count} errors',
			'toast.multiRenameTrashBlocked' => 'Multi rename is not available in trash',
			'selectionFile.saveTitle' => 'Save Selection',
			'selectionFile.loadTitle' => 'Load Selection',
			'selectionFile.pathLabel' => 'Text file',
			'selectionFile.pathHint' => 'selection.txt',
			'selectionFile.save' => 'Save',
			'selectionFile.load' => 'Load',
			'dragHint.copyTo' => ({required Object name}) => 'Copy to "${name}"',
			'dragHint.moveTo' => ({required Object name}) => 'Move to "${name}"',
			'dragHint.tabToSwitch' => '(Alt+drag to move)',
			'fileView.movingItems' => ({required Object count}) => 'Moving ${count} items',
			'fileView.empty' => 'Folder is empty',
			'fileView.date.justNow' => 'just now',
			'fileView.date.minutesAgo' => ({required Object count}) => '${count}m ago',
			'fileView.date.hoursAgo' => ({required Object count}) => '${count}h ago',
			'fileView.date.daysAgo' => ({required Object count}) => '${count}d ago',
			'fileView.date.weeksAgo' => ({required Object count}) => '${count}w ago',
			'fileView.date.monthsAgo' => ({required Object count}) => '${count}mo ago',
			'fileView.date.yearsAgo' => ({required Object count}) => '${count}y ago',
			'fileView.columns.name' => 'Name',
			'fileView.columns.size' => 'Size',
			'fileView.columns.dateModified' => 'Date modified',
			'fileView.columns.location' => 'Location',
			'sidebar.favorites' => 'Favorites',
			'sidebar.devices' => 'Devices',
			'sidebar.home' => 'Home',
			'sidebar.desktop' => 'Desktop',
			'sidebar.documents' => 'Documents',
			'sidebar.downloads' => 'Downloads',
			'sidebar.pictures' => 'Pictures',
			'sidebar.music' => 'Music',
			'sidebar.videos' => 'Videos',
			'sidebar.trash' => 'Trash',
			'sidebar.root' => 'Root',
			'sidebar.network' => 'Network',
			'sidebar.bookmarks' => 'Bookmarks',
			'sidebar.dropBookmark' => 'Drop folder to bookmark',
			'sidebar.connectToServer' => 'Connect to server',
			'sidebar.connectDialog.title' => 'Connect to server',
			'sidebar.connectDialog.host' => 'Server',
			'sidebar.connectDialog.hostHint' => 'e.g. 192.168.1.10 or nas.local',
			'sidebar.connectDialog.port' => 'Port',
			'sidebar.connectDialog.username' => 'Username',
			'sidebar.connectDialog.usernameHint' => 'optional',
			'sidebar.connectDialog.share' => 'Share',
			'sidebar.connectDialog.shareHint' => 'optional',
			'sidebar.connectDialog.pathLabel' => 'Path',
			'sidebar.connectDialog.pathHint' => 'optional',
			'sidebar.connectDialog.addBookmark' => 'Add bookmark',
			'sidebar.connectDialog.connect' => 'Connect',
			'sidebar.connectDialog.invalidHost' => 'Enter a server address',
			'sidebar.driveSpace.used' => 'Used',
			'sidebar.driveSpace.free' => 'Free',
			'sidebar.driveSpace.total' => 'Total',
			'sidebar.drives.localDisk' => 'Local Disk',
			'sidebar.drives.usbDrive' => 'USB Drive',
			'sidebar.drives.unknownDrive' => 'Unknown Drive',
			_ => null,
		} ?? switch (path) {
			'sidebar.drives.networkDrive' => 'Network Drive',
			'sidebar.drives.macintoshHd' => 'Macintosh HD',
			'sidebar.drives.windowsDriveLabel' => ({required Object letter, required Object name}) => '${letter}: ${name}',
			'sidebar.drives.mountTitle' => ({required Object name}) => 'Mount ${name}',
			'sidebar.collapse' => 'Collapse sidebar',
			'sidebar.expand' => 'Expand sidebar',
			'trash.accessDeniedTitle' => 'Trash needs Full Disk Access',
			'trash.accessDeniedBody' => 'macOS protects the Trash folder. Grant Waydir Full Disk Access in System Settings, then relaunch the app.',
			'trash.openSystemSettings' => 'Open System Settings',
			'toolbar.back' => 'Back',
			'toolbar.forward' => 'Forward',
			'toolbar.up' => 'Up',
			'toolbar.refresh' => 'Refresh',
			'toolbar.viewOptions' => 'View Options',
			'toolbar.newFolder' => 'New Folder',
			'toolbar.operations' => 'Operations',
			'toolbar.notifications' => 'Notifications',
			'toolbar.search' => 'Search',
			'toolbar.more' => 'More',
			'notifications.title' => 'Notifications',
			'notifications.empty' => 'No notifications yet',
			'notifications.clear' => 'Clear',
			'search.placeholder' => 'Filter…',
			'search.subfolders' => 'Subfolders',
			'search.subfoldersShortcut' => 'Subfolders (Ctrl+Shift+F)',
			'search.content' => 'Content',
			'search.contentSearch' => 'Search inside file contents',
			'search.contentSftpUnsupported' => 'Content search is not available over SFTP',
			'search.close' => 'Close search',
			'search.results' => ({required Object count}) => '${count} results',
			'search.found' => ({required Object count}) => '${count} found',
			'search.scanning' => ({required Object dirs}) => '${dirs} scanned',
			'search.truncated' => ({required Object limit}) => '(first ${limit})',
			'search.noMatches' => 'No matches',
			'search.starting' => 'Starting…',
			'search.clear' => 'Clear search',
			'search.modeSubstring' => 'Substring',
			'search.modeGlob' => 'Glob',
			'search.modeRegex' => 'Regex',
			'search.invalidGlob' => 'Invalid glob pattern',
			'search.invalidRegex' => 'Invalid regex',
			'search.complete' => 'complete',
			'search.go' => 'go',
			'statusBar.items' => ({required Object count}) => '${count} items',
			'statusBar.folders' => ({required Object count}) => '${count} folders',
			'statusBar.files' => ({required Object count}) => '${count} files',
			'statusBar.selected' => ({required Object count}) => '${count} selected',
			'statusBar.zoomOut' => 'Zoom out',
			'statusBar.zoomIn' => 'Zoom in',
			'statusBar.zoomReset' => 'Reset zoom',
			'dialog.create' => 'Create',
			'dialog.cancel' => 'Cancel',
			'dialog.folderNameHint' => 'Folder name',
			'dialog.close' => 'Close',
			'dialog.delete' => 'Delete',
			'dialog.moveToTrash' => 'Move to Trash',
			'dialog.confirmDeleteTitle' => 'Delete permanently?',
			'dialog.confirmDeleteSingle' => ({required Object name}) => 'Delete "${name}"? This cannot be undone.',
			'dialog.confirmDeleteMultiple' => ({required Object count}) => 'Delete ${count} items? This cannot be undone.',
			'dialog.confirmTrashTitle' => 'Move to Trash?',
			'dialog.confirmTrashSingle' => ({required Object name}) => 'Move "${name}" to Trash?',
			'dialog.confirmTrashMultiple' => ({required Object count}) => 'Move ${count} items to Trash?',
			'dialog.copy' => 'Copy',
			'dialog.move' => 'Move',
			'dialog.confirmCopyTitle' => 'Copy items?',
			'dialog.confirmCopySingle' => ({required Object name}) => 'Copy "${name}" here?',
			'dialog.confirmCopyMultiple' => ({required Object count}) => 'Copy ${count} items here?',
			'dialog.confirmMoveTitle' => 'Move items?',
			'dialog.confirmMoveSingle' => ({required Object name}) => 'Move "${name}" here?',
			'dialog.confirmMoveMultiple' => ({required Object count}) => 'Move ${count} items here?',
			'password.authenticationRequired' => 'Authentication Required',
			'password.dismiss' => 'Dismiss',
			'password.mountPrompt' => 'Enter your password to mount this drive.',
			'password.smbPrompt' => 'Enter credentials for this network share.',
			'password.sftpPrompt' => 'SSH/SFTP authentication',
			'password.username' => 'Username',
			'password.password' => 'Password',
			'password.privateKey' => 'Private key',
			'password.privateKeyPath' => 'Private key path',
			'password.passphraseOptional' => 'Passphrase (optional)',
			'password.unlock' => 'Unlock',
			'selectPattern.title' => 'Select by pattern',
			'selectPattern.hint' => '*.jpg, *.png',
			'selectPattern.help' => 'Wildcards: * (any), ? (one char). Separate patterns with commas.',
			'selectPattern.select' => 'Select',
			'operations.title' => 'Operations',
			'operations.clear' => 'Clear',
			'operations.noActive' => 'No active operations',
			'operations.resolveConflicts' => 'Resolve Conflicts',
			'operations.errorsCount' => ({required Object count}) => '${count} errors',
			'operations.compressing' => 'Compressing…',
			'operations.compressingGzip' => 'Compressing (gzip)…',
			'operations.compressingBzip2' => 'Compressing (bzip2)…',
			'operations.compressingXz' => 'Compressing (xz)…',
			'operations.justNow' => 'just now',
			'operations.secondsAgo' => ({required Object count}) => '${count}s ago',
			'operations.minutesAgo' => ({required Object count}) => '${count}m ago',
			'operations.hoursAgo' => ({required Object count}) => '${count}h ago',
			'operations.eta' => ({required Object time}) => 'ETA ${time}',
			'operations.conflictsDetected' => 'Conflicts Detected',
			'operations.filesExist' => ({required Object count}) => '${count} files already exist at the destination.',
			'operations.overwriteAll' => 'Overwrite All',
			'operations.skipAll' => 'Skip All',
			'operations.review' => 'Review',
			'operations.fileConflict' => ({required Object index, required Object total}) => 'File Conflict (${index}/${total})',
			'operations.replace' => 'Replace',
			'operations.keepBoth' => 'Keep Both',
			'operations.skip' => 'Skip',
			'operations.errors' => ({required Object count}) => 'Errors (${count})',
			'operations.filesCount' => ({required Object processed, required Object count}) => '${processed} / ${count} files',
			'operations.fileExists' => 'A file with this name already exists:',
			'operations.source' => ({required Object size, required Object date}) => 'Source:  ${size} · ${date}',
			'operations.target' => ({required Object size, required Object date}) => 'Target:  ${size} · ${date}',
			'operations.newer' => '  ← newer',
			'operations.applyToAll' => ({required Object count}) => 'Apply to all remaining conflicts (${count})',
			'errors.permissionDenied' => 'Permission denied',
			'errors.authenticationRequired' => 'Authentication required',
			'errors.noSpace' => 'No space left on device',
			'errors.readOnly' => 'Read-only file system',
			'errors.notFound' => 'File not found',
			'errors.sourceNotFound' => 'Source not found',
			'errors.pathNotFound' => 'Path not found',
			'errors.missingSmbHost' => 'Missing host in smb:// URI',
			'errors.missingSmbServer' => 'Missing server in smb:// URI',
			'errors.missingSmbShare' => 'Missing share in smb:// URI',
			'errors.missingSftpHost' => 'Missing host in sftp:// URI',
			'errors.invalidSmbUri' => 'Invalid smb:// URI',
			'errors.smbPortsNotSupportedOnWindows' => 'SMB ports are not supported on Windows',
			'errors.smbShareNotMounted' => 'SMB share not mounted',
			'errors.smbClientUnavailable' => ({required Object message}) => 'smbclient unavailable: ${message}',
			'errors.smbClientFailed' => ({required Object code}) => 'smbclient failed (${code})',
			'errors.smbutilUnavailable' => ({required Object message}) => 'smbutil unavailable: ${message}',
			'errors.smbutilFailed' => ({required Object code}) => 'smbutil failed (${code})',
			'errors.netUnavailable' => ({required Object message}) => 'net unavailable: ${message}',
			'errors.netViewFailed' => ({required Object code}) => 'net view failed (${code})',
			'errors.smbMountedShareNotFound' => 'Mounted share could not be located in gvfs',
			'errors.failedToCreatePath' => ({required Object path, required Object error}) => 'Failed to create ${path}: ${error}',
			'errors.gioMountFailed' => 'gio mount failed',
			'errors.mountSmbfsFailed' => ({required Object code}) => 'mount_smbfs failed (${code})',
			'errors.notEmpty' => 'Directory not empty',
			'errors.crossDevice' => 'Cannot move across devices',
			'errors.targetExists' => 'Target exists',
			'errors.sftpNotSupported' => 'SFTP not supported',
			'errors.sftpConnectFailed' => 'SFTP connect failed',
			'errors.sftpError' => ({required Object error}) => 'SFTP: ${error}',
			'errors.sftpNoActiveSession' => 'No active SFTP session',
			'errors.sftpNoActiveSessionFor' => ({required Object path}) => 'No active SFTP session for ${path}',
			'errors.sftpListingFailed' => 'SFTP listing failed',
			'errors.sftpReadFailed' => 'SFTP read failed',
			'errors.sftpWriteFailed' => 'SFTP write failed',
			'errors.sftpMkdirFailed' => 'SFTP mkdir failed',
			'errors.sftpRemoveFailed' => 'SFTP remove failed',
			'errors.sftpRenameFailed' => 'SFTP rename failed',
			'errors.sftpOpenReaderFailed' => 'SFTP open reader failed',
			'errors.sftpOpenWriterFailed' => 'SFTP open writer failed',
			'errors.sftpCloseFailed' => 'SFTP close failed',
			'errors.directoryNotReadable' => 'Directory not readable',
			'errors.transferIntoSelf' => 'Cannot copy or move a folder into itself.',
			'errors.workerExitedUnexpectedly' => 'Worker exited unexpectedly',
			'errors.appearedDuring' => 'File appeared at destination during operation',
			'errors.archiveError' => 'Could not read archive',
			'errors.archiveCreateFailed' => ({required Object error}) => 'Could not create archive: ${error}',
			'errors.archiveReadFailed' => ({required Object error}) => 'Archive error: ${error}',
			'errors.archiveEntryNotFound' => ({required Object path}) => 'Archive entry not found: ${path}',
			'errors.unsupportedArchiveFormat' => 'Unsupported archive format',
			'errors.nativeCoreNotFound' => ({required Object paths}) => 'Native waydir_core not found; searched: ${paths}',
			'errors.moveFileExFailed' => ({required Object error}) => 'MoveFileEx failed with Windows error ${error}',
			'errors.nativeTrashListFailed' => 'Native trash list failed',
			'errors.nativeTrashListFailedWithMessage' => ({required Object message}) => 'Native trash list failed: ${message}',
			'errors.smbNotSupportedOnPlatform' => 'Network shares (smb://) are not supported on this platform yet.',
			'tasks.copyingSingle' => ({required Object name}) => 'Copying ${name}',
			'tasks.copyingMultiple' => ({required Object count}) => 'Copying ${count} items',
			'tasks.movingSingle' => ({required Object name}) => 'Moving ${name}',
			'tasks.movingMultiple' => ({required Object count}) => 'Moving ${count} items',
			'tasks.deletingSingle' => ({required Object name}) => 'Deleting ${name}',
			'tasks.deletingMultiple' => ({required Object count}) => 'Deleting ${count} items',
			'tasks.trashingSingle' => ({required Object name}) => 'Moving ${name} to Trash',
			'tasks.trashingMultiple' => ({required Object count}) => 'Moving ${count} items to Trash',
			'tasks.restoringTrashSingle' => ({required Object name}) => 'Restoring ${name} from Trash',
			'tasks.restoringTrashMultiple' => ({required Object count}) => 'Restoring ${count} items from Trash',
			'tasks.deletingTrashSingle' => ({required Object name}) => 'Deleting ${name} from Trash',
			'tasks.deletingTrashMultiple' => ({required Object count}) => 'Deleting ${count} items from Trash',
			'tasks.extractingSingle' => ({required Object name}) => 'Extracting ${name}',
			'tasks.extractingMultiple' => ({required Object count}) => 'Extracting ${count} archives',
			'tasks.compressingTo' => ({required Object name}) => 'Compressing to ${name}',
			'tasks.updatingArchive' => 'Updating archive',
			'tasks.status.waiting' => 'Waiting...',
			'tasks.status.scanning' => 'Scanning files...',
			'tasks.status.conflicts' => ({required Object count}) => '${count} conflicts',
			'tasks.status.running' => ({required Object current, required Object processed, required Object total}) => '${current} (${processed}/${total})',
			'tasks.status.cancelling' => 'Cancelling...',
			'tasks.status.completedWithErrors' => ({required Object count}) => 'Completed with ${count} errors',
			'tasks.status.completed' => 'Completed',
			'tasks.status.failed' => 'Failed',
			'tasks.status.cancelled' => 'Cancelled',
			'git.clean' => 'clean',
			'git.detachedHead' => 'detached HEAD',
			'git.merging' => 'MERGING',
			'git.rebasing' => 'REBASING',
			'git.cherryPicking' => 'CHERRY-PICK',
			'git.reverting' => 'REVERTING',
			'git.bisecting' => 'BISECTING',
			'git.checkoutFailed' => ({required Object message}) => 'Checkout failed: ${message}',
			'git.uncommittedChanges' => 'Uncommitted changes',
			'git.stashPrompt' => ({required Object branch}) => 'Your local changes would be overwritten by switching to \'${branch}\'.\n\nStash them now? They stay saved in a stash you can restore later on this branch.',
			'git.stashSwitch' => 'Stash & Switch',
			'git.stashSwitchFailed' => ({required Object message}) => 'Stash & switch failed: ${message}',
			'git.stashEntry' => ({required Object index, required Object message}) => 'stash@{${index}} · ${message}',
			'git.stashPop' => 'Pop (apply & remove)',
			'git.stashApply' => 'Apply (keep stash)',
			'git.stashDrop' => 'Drop',
			'git.stashFailed' => ({required Object message}) => 'Stash failed: ${message}',
			'git.noRepository' => 'No repository',
			'git.gitCheckoutFailed' => 'git checkout failed',
			'git.gitStashFailed' => 'git stash failed',
			'git.changesStashedSwitchFailed' => ({required Object message}) => 'Changes stashed, but switch failed: ${message}',
			'openWith.title' => 'Open With',
			'openWith.subtitle' => ({required Object name}) => 'Choose an application to open "${name}"',
			'openWith.recent' => 'Recent',
			'openWith.recommended' => 'Recommended Applications',
			'openWith.allApps' => 'All Applications',
			'openWith.noApps' => 'No applications found for this file type.',
			'openWith.setDefault' => 'Always use for this file type',
			'openWith.setDefaultUnavailable' => 'Default cannot be changed on this platform',
			'openWith.moreApps' => 'More applications…',
			'openWith.open' => 'Open',
			'openWith.failed' => ({required Object app}) => 'Could not open the file with ${app}',
			'openWith.setDefaultFailed' => 'Could not set the default application',
			'openWith.unsupportedPlatform' => 'Unsupported platform',
			'openWith.xdgMimeFailed' => 'xdg-mime failed',
			'openWith.dutiRequired' => 'Setting the default app on macOS requires the "duti" tool',
			'openWith.bundleIdReadFailed' => 'Could not read app bundle id',
			'openWith.windowsDefaultDialogRequired' => 'Use the system "Open with" dialog to change the default on Windows',
			_ => null,
		};
	}
}
