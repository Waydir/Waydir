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
	late final TranslationsAppEn app = TranslationsAppEn.internal(_root);
	late final TranslationsMenuEn menu = TranslationsMenuEn.internal(_root);
	late final TranslationsCompressEn compress = TranslationsCompressEn.internal(_root);
	late final TranslationsPropertiesEn properties = TranslationsPropertiesEn.internal(_root);
	late final TranslationsPreferencesEn preferences = TranslationsPreferencesEn.internal(_root);
	late final TranslationsAppMenuEn appMenu = TranslationsAppMenuEn.internal(_root);
	late final TranslationsKeybindingsEn keybindings = TranslationsKeybindingsEn.internal(_root);
	late final TranslationsCommandPaletteEn commandPalette = TranslationsCommandPaletteEn.internal(_root);
	late final TranslationsQuickLookEn quickLook = TranslationsQuickLookEn.internal(_root);
	late final TranslationsToastEn toast = TranslationsToastEn.internal(_root);
	late final TranslationsDragHintEn dragHint = TranslationsDragHintEn.internal(_root);
	late final TranslationsFileViewEn fileView = TranslationsFileViewEn.internal(_root);
	late final TranslationsSidebarEn sidebar = TranslationsSidebarEn.internal(_root);
	late final TranslationsToolbarEn toolbar = TranslationsToolbarEn.internal(_root);
	late final TranslationsNotificationsEn notifications = TranslationsNotificationsEn.internal(_root);
	late final TranslationsSearchEn search = TranslationsSearchEn.internal(_root);
	late final TranslationsStatusBarEn statusBar = TranslationsStatusBarEn.internal(_root);
	late final TranslationsDialogEn dialog = TranslationsDialogEn.internal(_root);
	late final TranslationsOperationsEn operations = TranslationsOperationsEn.internal(_root);
	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsTasksEn tasks = TranslationsTasksEn.internal(_root);
	late final TranslationsOpenWithEn openWith = TranslationsOpenWithEn.internal(_root);
}

// Path: app
class TranslationsAppEn {
	TranslationsAppEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Waydir'
	String get title => 'Waydir';
}

// Path: menu
class TranslationsMenuEn {
	TranslationsMenuEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

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
}

// Path: compress
class TranslationsCompressEn {
	TranslationsCompressEn.internal(this._root);

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

// Path: properties
class TranslationsPropertiesEn {
	TranslationsPropertiesEn.internal(this._root);

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
class TranslationsPreferencesEn {
	TranslationsPreferencesEn.internal(this._root);

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

	late final TranslationsPreferencesCategoriesEn categories = TranslationsPreferencesCategoriesEn.internal(_root);
	late final TranslationsPreferencesGeneralEn general = TranslationsPreferencesGeneralEn.internal(_root);
	late final TranslationsPreferencesAppearanceEn appearance = TranslationsPreferencesAppearanceEn.internal(_root);
	late final TranslationsPreferencesBookmarksEn bookmarks = TranslationsPreferencesBookmarksEn.internal(_root);
	late final TranslationsPreferencesDiagnosticsEn diagnostics = TranslationsPreferencesDiagnosticsEn.internal(_root);
	late final TranslationsPreferencesAboutEn about = TranslationsPreferencesAboutEn.internal(_root);
}

// Path: appMenu
class TranslationsAppMenuEn {
	TranslationsAppMenuEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Quit'
	String get quit => 'Quit';
}

// Path: keybindings
class TranslationsKeybindingsEn {
	TranslationsKeybindingsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Keyboard Shortcuts'
	String get title => 'Keyboard Shortcuts';

	/// en: 'Shortcuts'
	String get menuLabel => 'Shortcuts';

	late final TranslationsKeybindingsCategoriesEn categories = TranslationsKeybindingsCategoriesEn.internal(_root);

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
class TranslationsCommandPaletteEn {
	TranslationsCommandPaletteEn.internal(this._root);

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
class TranslationsQuickLookEn {
	TranslationsQuickLookEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No file selected'
	String get noSelection => 'No file selected';

	/// en: 'Folder'
	String get folder => 'Folder';

	/// en: 'No preview available'
	String get noPreview => 'No preview available';

	/// en: 'Binary file — no preview'
	String get binaryFile => 'Binary file — no preview';

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

	/// en: 'Lines'
	String get lines => 'Lines';

	/// en: 'Characters'
	String get characters => 'Characters';

	/// en: 'General'
	String get sectionGeneral => 'General';

	/// en: 'Image'
	String get sectionImage => 'Image';

	/// en: 'Text'
	String get sectionText => 'Text';
}

// Path: toast
class TranslationsToastEn {
	TranslationsToastEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Copied $count items'
	String copiedItems({required Object count}) => 'Copied ${count} items';

	/// en: 'Cut $count items'
	String cutItems({required Object count}) => 'Cut ${count} items';

	/// en: '$label — $count errors'
	String taskErrors({required Object label, required Object count}) => '${label} — ${count} errors';

	/// en: 'An item named '$name' already exists'
	String renameAlreadyExists({required Object name}) => 'An item named \'${name}\' already exists';

	/// en: 'Invalid name'
	String get renameInvalidName => 'Invalid name';

	/// en: 'Could not rename: $message'
	String renameError({required Object message}) => 'Could not rename: ${message}';
}

// Path: dragHint
class TranslationsDragHintEn {
	TranslationsDragHintEn.internal(this._root);

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
class TranslationsFileViewEn {
	TranslationsFileViewEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Moving $count items'
	String movingItems({required Object count}) => 'Moving ${count} items';

	/// en: 'Folder is empty'
	String get empty => 'Folder is empty';

	late final TranslationsFileViewColumnsEn columns = TranslationsFileViewColumnsEn.internal(_root);
}

// Path: sidebar
class TranslationsSidebarEn {
	TranslationsSidebarEn.internal(this._root);

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

	/// en: 'Bookmarks'
	String get bookmarks => 'Bookmarks';

	/// en: 'Drop folder to bookmark'
	String get dropBookmark => 'Drop folder to bookmark';

	/// en: 'Collapse sidebar'
	String get collapse => 'Collapse sidebar';

	/// en: 'Expand sidebar'
	String get expand => 'Expand sidebar';
}

// Path: toolbar
class TranslationsToolbarEn {
	TranslationsToolbarEn.internal(this._root);

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
}

// Path: notifications
class TranslationsNotificationsEn {
	TranslationsNotificationsEn.internal(this._root);

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
class TranslationsSearchEn {
	TranslationsSearchEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Filter…'
	String get placeholder => 'Filter…';

	/// en: 'Subfolders'
	String get subfolders => 'Subfolders';

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
}

// Path: statusBar
class TranslationsStatusBarEn {
	TranslationsStatusBarEn.internal(this._root);

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
}

// Path: dialog
class TranslationsDialogEn {
	TranslationsDialogEn.internal(this._root);

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

// Path: operations
class TranslationsOperationsEn {
	TranslationsOperationsEn.internal(this._root);

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

	/// en: 'just now'
	String get justNow => 'just now';

	/// en: '${count}s ago'
	String secondsAgo({required Object count}) => '${count}s ago';

	/// en: '${count}m ago'
	String minutesAgo({required Object count}) => '${count}m ago';

	/// en: '${count}h ago'
	String hoursAgo({required Object count}) => '${count}h ago';

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
class TranslationsErrorsEn {
	TranslationsErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Permission denied'
	String get permissionDenied => 'Permission denied';

	/// en: 'No space left on device'
	String get noSpace => 'No space left on device';

	/// en: 'Read-only file system'
	String get readOnly => 'Read-only file system';

	/// en: 'File not found'
	String get notFound => 'File not found';

	/// en: 'Directory not empty'
	String get notEmpty => 'Directory not empty';

	/// en: 'Cannot move across devices'
	String get crossDevice => 'Cannot move across devices';

	/// en: 'File appeared at destination during operation'
	String get appearedDuring => 'File appeared at destination during operation';

	/// en: 'Could not read archive'
	String get archiveError => 'Could not read archive';
}

// Path: tasks
class TranslationsTasksEn {
	TranslationsTasksEn.internal(this._root);

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

	/// en: 'Extracting $name'
	String extractingSingle({required Object name}) => 'Extracting ${name}';

	/// en: 'Extracting $count archives'
	String extractingMultiple({required Object count}) => 'Extracting ${count} archives';

	/// en: 'Compressing to $name'
	String compressingTo({required Object name}) => 'Compressing to ${name}';

	/// en: 'Updating archive'
	String get updatingArchive => 'Updating archive';

	late final TranslationsTasksStatusEn status = TranslationsTasksStatusEn.internal(_root);
}

// Path: openWith
class TranslationsOpenWithEn {
	TranslationsOpenWithEn.internal(this._root);

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
}

// Path: preferences.categories
class TranslationsPreferencesCategoriesEn {
	TranslationsPreferencesCategoriesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'General'
	String get general => 'General';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Bookmarks'
	String get bookmarks => 'Bookmarks';

	/// en: 'Diagnostics'
	String get diagnostics => 'Diagnostics';

	/// en: 'About'
	String get about => 'About';
}

// Path: preferences.general
class TranslationsPreferencesGeneralEn {
	TranslationsPreferencesGeneralEn.internal(this._root);

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

	/// en: 'Browse…'
	String get browse => 'Browse…';

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

	/// en: 'Auto-detect'
	String get terminalAuto => 'Auto-detect';

	/// en: 'Custom command…'
	String get terminalCustom => 'Custom command…';

	/// en: 'Command'
	String get terminalCustomLabel => 'Command';

	/// en: 'e.g. kitty --working-directory={dir}'
	String get terminalCustomHint => 'e.g. kitty --working-directory={dir}';

	/// en: 'Use {dir} as a placeholder for the directory path.'
	String get terminalCustomHelp => 'Use {dir} as a placeholder for the directory path.';
}

// Path: preferences.appearance
class TranslationsPreferencesAppearanceEn {
	TranslationsPreferencesAppearanceEn.internal(this._root);

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
class TranslationsPreferencesBookmarksEn {
	TranslationsPreferencesBookmarksEn.internal(this._root);

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
class TranslationsPreferencesDiagnosticsEn {
	TranslationsPreferencesDiagnosticsEn.internal(this._root);

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
}

// Path: preferences.about
class TranslationsPreferencesAboutEn {
	TranslationsPreferencesAboutEn.internal(this._root);

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

// Path: keybindings.categories
class TranslationsKeybindingsCategoriesEn {
	TranslationsKeybindingsCategoriesEn.internal(this._root);

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

// Path: fileView.columns
class TranslationsFileViewColumnsEn {
	TranslationsFileViewColumnsEn.internal(this._root);

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

// Path: tasks.status
class TranslationsTasksStatusEn {
	TranslationsTasksStatusEn.internal(this._root);

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

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Waydir',
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
			'preferences.general.browse' => 'Browse…',
			'preferences.general.fileOpsSection' => 'File operations',
			'preferences.general.confirmDelete' => 'Confirm before delete',
			'preferences.general.confirmDeleteHint' => 'Show a dialog before removing files or folders.',
			'preferences.general.confirmCopy' => 'Confirm before copy',
			'preferences.general.confirmCopyHint' => 'Show a dialog before copying files or folders.',
			'preferences.general.confirmMove' => 'Confirm before move',
			'preferences.general.confirmMoveHint' => 'Show a dialog before moving files or folders.',
			'preferences.general.deleteKeyBehavior' => 'Delete key behavior',
			'preferences.general.deleteKeyBehaviorHint' => 'What the Delete key does by default. Shift+Delete always deletes permanently.',
			'preferences.general.deleteKeyTrash' => 'Move to Trash',
			'preferences.general.deleteKeyPermanent' => 'Delete Permanently',
			'preferences.general.terminalSection' => 'Terminal',
			'preferences.general.terminalLabel' => 'Default terminal',
			'preferences.general.terminalHint' => 'Used by "Open in Terminal".',
			'preferences.general.terminalAuto' => 'Auto-detect',
			'preferences.general.terminalCustom' => 'Custom command…',
			'preferences.general.terminalCustomLabel' => 'Command',
			'preferences.general.terminalCustomHint' => 'e.g. kitty --working-directory={dir}',
			'preferences.general.terminalCustomHelp' => 'Use {dir} as a placeholder for the directory path.',
			'preferences.appearance.title' => 'Appearance',
			'preferences.appearance.subtitle' => 'Defaults for how files and the sidebar are displayed.',
			'preferences.appearance.themeSection' => 'Theme',
			'preferences.appearance.theme' => 'Theme',
			'preferences.appearance.themeHint' => 'Choose a built-in or custom theme.',
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
			'preferences.appearance.filesSection' => 'Files',
			'preferences.appearance.showHidden' => 'Show hidden files by default',
			'preferences.appearance.showHiddenHint' => 'Applies to new tabs. Existing tabs keep their setting.',
			'preferences.appearance.rowDensity' => 'Row density',
			'preferences.appearance.rowDensityComfortable' => 'Comfortable',
			'preferences.appearance.rowDensityCompact' => 'Compact',
			'preferences.appearance.dateFormat' => 'Date format',
			'preferences.appearance.dateFormatIso' => 'ISO (2026-05-14 13:45)',
			'preferences.appearance.dateFormatLocale' => 'System locale',
			'preferences.appearance.dateFormatRelative' => 'Relative (2h ago)',
			'preferences.appearance.recentDatesRelative' => 'Use relative dates for recent files',
			'preferences.appearance.recentDatesRelativeHint' => 'When System locale is selected, files modified in the last 24 hours show as relative.',
			'preferences.appearance.foldersFirst' => 'Show folders before files',
			'preferences.appearance.foldersFirstHint' => 'Group folders ahead of files regardless of the sort order.',
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
			'preferences.about.title' => 'About',
			'preferences.about.version' => 'Version',
			'preferences.about.build' => 'Build',
			'preferences.about.repository' => 'Repository',
			'preferences.about.license' => 'License',
			'preferences.about.copy' => 'Copy',
			'appMenu.quit' => 'Quit',
			'keybindings.title' => 'Keyboard Shortcuts',
			'keybindings.menuLabel' => 'Shortcuts',
			'keybindings.categories.navigation' => 'Navigation',
			'keybindings.categories.tabs' => 'Tabs',
			'keybindings.categories.panes' => 'Panes',
			'keybindings.categories.fileOps' => 'File Operations',
			'keybindings.categories.selection' => 'Selection',
			'keybindings.categories.search' => 'Search',
			'keybindings.openItem' => 'Open',
			'keybindings.goUp' => 'Go up',
			'keybindings.goBack' => 'Go back',
			'keybindings.goForward' => 'Go forward',
			'keybindings.refresh' => 'Refresh',
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
			'quickLook.noSelection' => 'No file selected',
			'quickLook.folder' => 'Folder',
			'quickLook.noPreview' => 'No preview available',
			'quickLook.binaryFile' => 'Binary file — no preview',
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
			'quickLook.lines' => 'Lines',
			'quickLook.characters' => 'Characters',
			'quickLook.sectionGeneral' => 'General',
			'quickLook.sectionImage' => 'Image',
			'quickLook.sectionText' => 'Text',
			'toast.copiedItems' => ({required Object count}) => 'Copied ${count} items',
			'toast.cutItems' => ({required Object count}) => 'Cut ${count} items',
			'toast.taskErrors' => ({required Object label, required Object count}) => '${label} — ${count} errors',
			'toast.renameAlreadyExists' => ({required Object name}) => 'An item named \'${name}\' already exists',
			'toast.renameInvalidName' => 'Invalid name',
			'toast.renameError' => ({required Object message}) => 'Could not rename: ${message}',
			'dragHint.copyTo' => ({required Object name}) => 'Copy to "${name}"',
			'dragHint.moveTo' => ({required Object name}) => 'Move to "${name}"',
			'dragHint.tabToSwitch' => '(Alt+drag to move)',
			'fileView.movingItems' => ({required Object count}) => 'Moving ${count} items',
			'fileView.empty' => 'Folder is empty',
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
			'sidebar.bookmarks' => 'Bookmarks',
			'sidebar.dropBookmark' => 'Drop folder to bookmark',
			'sidebar.collapse' => 'Collapse sidebar',
			'sidebar.expand' => 'Expand sidebar',
			'toolbar.back' => 'Back',
			'toolbar.forward' => 'Forward',
			'toolbar.up' => 'Up',
			'toolbar.refresh' => 'Refresh',
			'toolbar.viewOptions' => 'View Options',
			'toolbar.newFolder' => 'New Folder',
			'toolbar.operations' => 'Operations',
			'toolbar.notifications' => 'Notifications',
			'toolbar.search' => 'Search',
			'notifications.title' => 'Notifications',
			'notifications.empty' => 'No notifications yet',
			'notifications.clear' => 'Clear',
			'search.placeholder' => 'Filter…',
			'search.subfolders' => 'Subfolders',
			'search.close' => 'Close search',
			'search.results' => ({required Object count}) => '${count} results',
			'search.found' => ({required Object count}) => '${count} found',
			'search.scanning' => ({required Object dirs}) => '${dirs} scanned',
			'search.truncated' => ({required Object limit}) => '(first ${limit})',
			'search.noMatches' => 'No matches',
			'search.starting' => 'Starting…',
			'search.clear' => 'Clear search',
			'statusBar.items' => ({required Object count}) => '${count} items',
			'statusBar.folders' => ({required Object count}) => '${count} folders',
			'statusBar.files' => ({required Object count}) => '${count} files',
			'statusBar.selected' => ({required Object count}) => '${count} selected',
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
			'operations.title' => 'Operations',
			'operations.clear' => 'Clear',
			'operations.noActive' => 'No active operations',
			'operations.resolveConflicts' => 'Resolve Conflicts',
			'operations.errorsCount' => ({required Object count}) => '${count} errors',
			'operations.justNow' => 'just now',
			'operations.secondsAgo' => ({required Object count}) => '${count}s ago',
			'operations.minutesAgo' => ({required Object count}) => '${count}m ago',
			'operations.hoursAgo' => ({required Object count}) => '${count}h ago',
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
			'errors.noSpace' => 'No space left on device',
			'errors.readOnly' => 'Read-only file system',
			'errors.notFound' => 'File not found',
			'errors.notEmpty' => 'Directory not empty',
			'errors.crossDevice' => 'Cannot move across devices',
			'errors.appearedDuring' => 'File appeared at destination during operation',
			'errors.archiveError' => 'Could not read archive',
			'tasks.copyingSingle' => ({required Object name}) => 'Copying ${name}',
			'tasks.copyingMultiple' => ({required Object count}) => 'Copying ${count} items',
			'tasks.movingSingle' => ({required Object name}) => 'Moving ${name}',
			'tasks.movingMultiple' => ({required Object count}) => 'Moving ${count} items',
			'tasks.deletingSingle' => ({required Object name}) => 'Deleting ${name}',
			'tasks.deletingMultiple' => ({required Object count}) => 'Deleting ${count} items',
			'tasks.trashingSingle' => ({required Object name}) => 'Moving ${name} to Trash',
			'tasks.trashingMultiple' => ({required Object count}) => 'Moving ${count} items to Trash',
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
			_ => null,
		};
	}
}
