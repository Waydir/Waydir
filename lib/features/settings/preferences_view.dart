import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../core/settings/settings_registry.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_dropdown.dart';
import '../../ui/widgets/app_modal.dart';
import '../../ui/widgets/app_text_field.dart';
import 'panes/appearance_pane.dart';
import 'panes/general_pane.dart';
import 'panes/quick_look_pane.dart';
import 'panes/terminal_pane.dart';

Future<void> showPreferencesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const _PreferencesDialog(),
  );
}

enum Category { general, appearance, terminal, quickLook }

class CategoryMeta {
  final Category id;
  final IconData icon;
  final String Function() label;

  const CategoryMeta(this.id, this.icon, this.label);
}

final categories = <CategoryMeta>[
  CategoryMeta(
    Category.general,
    WaydirIconsRegular.slidersHorizontal,
    () => t.preferences.categories.general,
  ),
  CategoryMeta(
    Category.appearance,
    WaydirIconsRegular.palette,
    () => t.preferences.categories.appearance,
  ),
  CategoryMeta(
    Category.terminal,
    WaydirIconsRegular.terminal,
    () => t.preferences.categories.terminal,
  ),
  CategoryMeta(
    Category.quickLook,
    WaydirIconsRegular.eye,
    () => t.preferences.categories.quickLook,
  ),
];

class PreferenceNavSection {
  final String id;
  final Category category;
  final String Function() label;

  const PreferenceNavSection({
    required this.id,
    required this.category,
    required this.label,
  });
}

final preferenceNavSections = <PreferenceNavSection>[
  PreferenceNavSection(
    id: 'general.startup',
    category: Category.general,
    label: () => t.preferences.general.startupSection,
  ),
  PreferenceNavSection(
    id: 'general.folders',
    category: Category.general,
    label: () => t.preferences.general.foldersSection,
  ),
  PreferenceNavSection(
    id: 'general.fileOps',
    category: Category.general,
    label: () => t.preferences.general.fileOpsSection,
  ),
  PreferenceNavSection(
    id: 'appearance.theme',
    category: Category.appearance,
    label: () => t.preferences.appearance.themeSection,
  ),
  PreferenceNavSection(
    id: 'appearance.files',
    category: Category.appearance,
    label: () => t.preferences.appearance.filesSection,
  ),
  PreferenceNavSection(
    id: 'terminal.appearance',
    category: Category.terminal,
    label: () => t.preferences.terminal.appearanceSection,
  ),
  PreferenceNavSection(
    id: 'terminal.behavior',
    category: Category.terminal,
    label: () => t.preferences.terminal.behaviorSection,
  ),
  PreferenceNavSection(
    id: 'terminal.shell',
    category: Category.terminal,
    label: () => t.preferences.terminal.shellSection,
  ),
  PreferenceNavSection(
    id: 'terminal.external',
    category: Category.terminal,
    label: () => t.preferences.terminal.externalSection,
  ),
  PreferenceNavSection(
    id: 'quickLook.font',
    category: Category.quickLook,
    label: () => t.preferences.quickLook.fontSection,
  ),
  PreferenceNavSection(
    id: 'quickLook.editor',
    category: Category.quickLook,
    label: () => t.preferences.quickLook.editorSection,
  ),
];

const _visibleSettingIds = <String>{
  'general.restoreSession',
  'general.defaultStartingPath',
  'general.confirmDelete',
  'general.confirmCopy',
  'general.confirmMove',
  'general.dragMovesByDefault',
  'general.rememberFolderState',
  'general.rememberFolderSort',
  'general.typeAheadBuffer',
  'general.deleteKeyBehavior',
  'terminal.shell',
  'terminal.external',
  'terminal.externalCustomCommand',
  'terminal.useSystemFont',
  'terminal.fontFamily',
  'terminal.fontSize',
  'terminal.lineHeight',
  'terminal.copyPasteMode',
  'appearance.theme',
  'appearance.showHiddenDefault',
  'appearance.rowDensity',
  'appearance.fileListHorizontalSpacing',
  'appearance.columnWidthMode',
  'appearance.fileListVerticalSpacing',
  'appearance.dateFormat',
  'appearance.recentDatesRelative',
  'appearance.foldersFirst',
  'appearance.sortFolders',
  'appearance.naturalSort',
  'quickLook.useSystemFont',
  'quickLook.fontFamily',
  'quickLook.fontSize',
  'quickLook.lineHeight',
  'quickLook.showLineNumbers',
  'quickLook.relativeLineNumbers',
  'quickLook.showStatistics',
  'quickLook.wrapLines',
  'quickLook.vimMode',
};

CategoryMeta _categoryMeta(Category category) {
  return categories.firstWhere((meta) => meta.id == category);
}

Category _categoryForSetting(SettingsCategory category) {
  return switch (category) {
    SettingsCategory.general => Category.general,
    SettingsCategory.appearance => Category.appearance,
    SettingsCategory.terminal => Category.terminal,
    SettingsCategory.quickLook => Category.quickLook,
  };
}

String? _sectionIdForSetting(String id) {
  return switch (id) {
    'general.restoreSession' ||
    'general.defaultStartingPath' => 'general.startup',
    'general.rememberFolderState' ||
    'general.rememberFolderSort' ||
    'general.typeAheadBuffer' => 'general.folders',
    'general.deleteKeyBehavior' ||
    'general.confirmDelete' ||
    'general.confirmCopy' ||
    'general.confirmMove' ||
    'general.dragMovesByDefault' => 'general.fileOps',
    'appearance.theme' => 'appearance.theme',
    'appearance.showHiddenDefault' ||
    'appearance.rowDensity' ||
    'appearance.fileListHorizontalSpacing' ||
    'appearance.columnWidthMode' ||
    'appearance.fileListVerticalSpacing' ||
    'appearance.dateFormat' ||
    'appearance.recentDatesRelative' ||
    'appearance.foldersFirst' ||
    'appearance.sortFolders' ||
    'appearance.naturalSort' => 'appearance.files',
    'terminal.useSystemFont' ||
    'terminal.fontFamily' ||
    'terminal.fontSize' ||
    'terminal.lineHeight' => 'terminal.appearance',
    'terminal.copyPasteMode' => 'terminal.behavior',
    'terminal.shell' => 'terminal.shell',
    'terminal.external' ||
    'terminal.externalCustomCommand' => 'terminal.external',
    'quickLook.useSystemFont' ||
    'quickLook.fontFamily' ||
    'quickLook.fontSize' ||
    'quickLook.lineHeight' => 'quickLook.font',
    'quickLook.showLineNumbers' ||
    'quickLook.relativeLineNumbers' ||
    'quickLook.showStatistics' ||
    'quickLook.wrapLines' ||
    'quickLook.vimMode' => 'quickLook.editor',
    _ => null,
  };
}

bool _matchesQuery(String query, Iterable<String> values) {
  final tokens = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty);
  final haystack = values.join(' ').toLowerCase();

  return tokens.every(haystack.contains);
}

class PreferenceAnchorScope extends InheritedWidget {
  final Map<String, GlobalKey> sectionKeys;
  final Map<String, GlobalKey> settingKeys;

  const PreferenceAnchorScope({
    super.key,
    required this.sectionKeys,
    required this.settingKeys,
    required super.child,
  });

  static PreferenceAnchorScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PreferenceAnchorScope>();
  }

  GlobalKey? sectionKey(String id) => sectionKeys[id];
  GlobalKey? settingKey(String id) => settingKeys[id];

  @override
  bool updateShouldNotify(PreferenceAnchorScope oldWidget) {
    return sectionKeys != oldWidget.sectionKeys ||
        settingKeys != oldWidget.settingKeys;
  }
}

class _PreferenceSearchResult {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Category category;
  final String? sectionId;
  final String? settingId;

  const _PreferenceSearchResult({
    required this.title,
    required this.icon,
    required this.category,
    this.subtitle,
    this.sectionId,
    this.settingId,
  });
}

class _PreferencesDialog extends StatefulWidget {
  const _PreferencesDialog();

  @override
  State<_PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<_PreferencesDialog> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final Map<String, GlobalKey> _sectionKeys;
  late final Map<String, GlobalKey> _settingKeys;
  Category _selected = Category.general;
  String _query = '';
  bool _showResults = false;
  int _activeResult = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _sectionKeys = {
      for (final section in preferenceNavSections) section.id: GlobalKey(),
    };
    _settingKeys = {for (final id in _visibleSettingIds) id: GlobalKey()};
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _selectCategory(Category category) {
    setState(() {
      _selected = category;
      _showResults = false;
    });
  }

  void _setQuery(String value) {
    setState(() {
      _query = value;
      _showResults = value.trim().isNotEmpty;
      _activeResult = 0;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _setQuery('');
    _searchFocusNode.requestFocus();
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    if (_query.trim().isNotEmpty) {
      setState(() => _showResults = true);
    }
  }

  KeyEventResult _handleDialogKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (AppShortcuts.matches('search', event.logicalKey)) {
      _focusSearch();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleSearchKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final results = _searchResults();
    if (!_showResults || _query.trim().isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (results.isNotEmpty) {
        setState(() {
          _activeResult++;
          if (_activeResult >= results.length) {
            _activeResult = results.length - 1;
          }
        });
      }

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (results.isNotEmpty) {
        setState(() {
          _activeResult--;
          if (_activeResult < 0) _activeResult = 0;
        });
      }

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (results.isNotEmpty) _openSearchResult(results[_activeResult]);

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _showResults = false);

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _openSearchResult(_PreferenceSearchResult result) {
    setState(() {
      _selected = result.category;
      _showResults = false;
    });
    final key = result.settingId == null
        ? _sectionKeys[result.sectionId]
        : _settingKeys[result.settingId];
    if (key == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: Duration.zero,
        alignment: 0.08,
      );
    });
  }

  List<_PreferenceSearchResult> _searchResults() {
    final query = _query.trim();
    if (query.isEmpty) return const [];
    final results = <_PreferenceSearchResult>[];

    for (final category in categories) {
      if (_matchesQuery(query, [category.label()])) {
        results.add(
          _PreferenceSearchResult(
            title: category.label(),
            icon: category.icon,
            category: category.id,
          ),
        );
      }
    }
    for (final section in preferenceNavSections) {
      final category = _categoryMeta(section.category);
      if (_matchesQuery(query, [category.label(), section.label()])) {
        results.add(
          _PreferenceSearchResult(
            title: section.label(),
            subtitle: category.label(),
            icon: category.icon,
            category: category.id,
            sectionId: section.id,
          ),
        );
      }
    }
    for (final setting in SettingsRegistry.instance.all) {
      if (!_visibleSettingIds.contains(setting.id)) continue;
      final category = _categoryMeta(_categoryForSetting(setting.category));
      final sectionId = _sectionIdForSetting(setting.id);
      final section = sectionId == null
          ? null
          : preferenceNavSections.firstWhere(
              (section) => section.id == sectionId,
            );
      if (_matchesQuery(query, [
        setting.label(),
        setting.hint?.call() ?? '',
        setting.id,
        category.label(),
        section?.label() ?? '',
        ...setting.searchTerms,
      ])) {
        results.add(
          _PreferenceSearchResult(
            title: setting.label(),
            subtitle: section == null
                ? category.label()
                : '${category.label()} / ${section.label()}',
            icon: category.icon,
            category: category.id,
            sectionId: sectionId,
            settingId: setting.id,
          ),
        );
      }
    }

    return results.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width * 0.8 > 920 ? 920.0 : size.width * 0.8;
    final dialogHeight = size.height - 96 > 640 ? 640.0 : size.height - 96;
    final results = _searchResults();
    if (_activeResult >= results.length) {
      _activeResult = results.isEmpty ? 0 : results.length - 1;
    }

    return AppModal(
      icon: WaydirIconsRegular.gearSix,
      title: t.preferences.title,
      width: dialogWidth,
      height: dialogHeight,
      onClose: () => Navigator.of(context).pop(),
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleDialogKey,
        child: Row(
          children: [
            _CategorySidebar(selected: _selected, onSelect: _selectCategory),
            Container(width: 1, color: AppColors.bgDivider),
            Expanded(
              child: Column(
                children: [
                  _PreferencesSearchBar(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    query: _query,
                    onChanged: _setQuery,
                    onClear: _clearSearch,
                    onKeyEvent: _handleSearchKey,
                    onTap: () {
                      if (_query.trim().isNotEmpty) {
                        setState(() => _showResults = true);
                      }
                    },
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        PreferenceAnchorScope(
                          sectionKeys: _sectionKeys,
                          settingKeys: _settingKeys,
                          child: _ContentPane(category: _selected),
                        ),
                        if (_showResults && _query.trim().isNotEmpty)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: _SearchResultsPanel(
                              results: results,
                              activeIndex: _activeResult,
                              onSelect: _openSearchResult,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesSearchBar extends StatelessWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final FocusOnKeyEventCallback onKeyEvent;
  final VoidCallback onTap;

  const _PreferencesSearchBar({
    required this.focusNode,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onKeyEvent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Focus(
        onKeyEvent: onKeyEvent,
        child: TextField(
          focusNode: focusNode,
          controller: controller,
          onChanged: onChanged,
          onTap: onTap,
          style: context.txt.body,
          cursorColor: AppColors.accent,
          decoration:
              appInputDecoration(
                hintText: t.preferences.searchPlaceholder,
                suffixIcon: query.isEmpty
                    ? null
                    : _SearchClearButton(onTap: onClear),
              ).copyWith(
                prefixIcon: Icon(
                  WaydirIconsRegular.magnifyingGlass,
                  size: 14,
                  color: AppColors.fgMuted,
                ),
              ),
        ),
      ),
    );
  }
}

class _SearchResultsPanel extends StatefulWidget {
  final List<_PreferenceSearchResult> results;
  final int activeIndex;
  final ValueChanged<_PreferenceSearchResult> onSelect;

  const _SearchResultsPanel({
    required this.results,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  State<_SearchResultsPanel> createState() => _SearchResultsPanelState();
}

class _SearchResultsPanelState extends State<_SearchResultsPanel> {
  final _rowKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _syncRowKeys();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureActiveVisible());
  }

  @override
  void didUpdateWidget(covariant _SearchResultsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results.length != widget.results.length) {
      _syncRowKeys();
    }
    if (oldWidget.activeIndex != widget.activeIndex ||
        oldWidget.results != widget.results) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ensureActiveVisible(),
      );
    }
  }

  void _syncRowKeys() {
    while (_rowKeys.length < widget.results.length) {
      _rowKeys.add(GlobalKey());
    }
    if (_rowKeys.length > widget.results.length) {
      _rowKeys.removeRange(widget.results.length, _rowKeys.length);
    }
  }

  void _ensureActiveVisible() {
    if (!mounted) return;
    final index = widget.activeIndex;
    if (index < 0 || index >= _rowKeys.length) return;
    final context = _rowKeys[index].currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: const Duration(milliseconds: 60),
      curve: Curves.easeOut,
    );
    Scrollable.ensureVisible(
      context,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      duration: const Duration(milliseconds: 60),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 236),
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: widget.results.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                t.preferences.searchNoResults,
                style: context.txt.muted,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              itemCount: widget.results.length,
              itemBuilder: (context, index) {
                final result = widget.results[index];

                return _SearchResultRow(
                  key: _rowKeys[index],
                  result: result,
                  selected: index == widget.activeIndex,
                  onTap: () => widget.onSelect(result),
                );
              },
            ),
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  final _PreferenceSearchResult result;
  final bool selected;
  final VoidCallback onTap;

  const _SearchResultRow({
    super.key,
    required this.result,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hovered;
    final fg = active ? AppColors.fg : AppColors.fgMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: active ? AppColors.bgHover : Colors.transparent,
          child: Row(
            children: [
              Icon(widget.result.icon, size: 14, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.result.title,
                      style: context.txt.body.copyWith(color: AppColors.fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.result.subtitle != null)
                      Text(
                        widget.result.subtitle!,
                        style: context.txt.captionSmall.copyWith(
                          color: AppColors.fgMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchClearButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SearchClearButton({required this.onTap});

  @override
  State<_SearchClearButton> createState() => _SearchClearButtonState();
}

class _SearchClearButtonState extends State<_SearchClearButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          color: _hovered ? AppColors.bgHover : Colors.transparent,
          child: Icon(WaydirIconsRegular.x, size: 13, color: AppColors.fgMuted),
        ),
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final Category selected;
  final ValueChanged<Category> onSelect;

  const _CategorySidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: ListView(
        children: [
          for (final cat in categories)
            _CategoryItem(
              meta: cat,
              selected: cat.id == selected,
              onTap: () => onSelect(cat.id),
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final CategoryMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.bgSelectedMuted
        : (_hovered ? AppColors.bgHover : Colors.transparent);
    final fg = widget.selected ? AppColors.fg : AppColors.fgMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 24,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.zero,
            border: widget.selected
                ? Border(left: BorderSide(color: AppColors.accent, width: 2))
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.meta.icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.meta.label(),
                  style: context.txt.body.copyWith(
                    color: fg,
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentPane extends StatelessWidget {
  final Category category;

  const _ContentPane({required this.category});

  @override
  Widget build(BuildContext context) {
    return switch (category) {
      Category.general => const GeneralPane(),
      Category.appearance => const AppearancePane(),
      Category.terminal => const TerminalPane(),
      Category.quickLook => const QuickLookPane(),
    };
  }
}

class SettingsPaneScaffold extends StatelessWidget {
  final List<Widget> children;

  const SettingsPaneScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: children,
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String? anchorId;
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    this.anchorId,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final anchorKey = anchorId == null
        ? null
        : PreferenceAnchorScope.maybeOf(context)?.sectionKey(anchorId!);

    return Column(
      key: anchorKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: context.txt.fieldLabel.copyWith(color: AppColors.fg),
        ),
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Container(height: 1, color: AppColors.bgDivider),
                children[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget control;

  final bool stretchControl;

  const SettingsRow({
    super.key,
    required this.label,
    this.hint,
    required this.control,
    this.stretchControl = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.txt.body),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(hint!, style: context.txt.muted),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (stretchControl)
            Flexible(
              flex: 2,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Align(alignment: Alignment.centerRight, child: control),
              ),
            )
          else
            control,
        ],
      ),
    );
  }
}

class RegistrySettingRow extends StatelessWidget {
  final AppSetting<dynamic> setting;

  const RegistrySettingRow({super.key, required this.setting});

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: PreferenceAnchorScope.maybeOf(context)?.settingKey(setting.id),
      child: SignalBuilder(
        builder: (_) {
          final stretch = setting is ChoiceSetting || setting is TextSetting;
          final control = switch (setting) {
            ToggleSetting toggle => SettingsToggle(
              value: toggle.value,
              onChanged: (value) => toggle.value = value,
            ),
            ChoiceSetting choice => AppDropdown<dynamic>(
              value: choice.value,
              items: [
                for (final option in choice.choices)
                  AppDropdownItem<dynamic>(
                    value: option.value,
                    label: option.label(),
                    icon: option.icon,
                  ),
              ],
              onChanged: (value) => choice.value = value,
            ),
            TextSetting text => SettingsTextField(setting: text),
            _ => const SizedBox.shrink(),
          };

          return SettingsRow(
            label: setting.label(),
            hint: setting.hint?.call(),
            control: control,
            stretchControl: stretch,
          );
        },
      ),
    );
  }
}

class SettingsTextField extends StatefulWidget {
  final TextSetting setting;

  const SettingsTextField({super.key, required this.setting});

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller;
  late final void Function() _disposeEffect;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.setting.value);
    _controller.addListener(() {
      if (widget.setting.value != _controller.text) {
        widget.setting.value = _controller.text;
      }
    });
    _disposeEffect = effect(() {
      final value = widget.setting.value;
      if (_controller.text == value) return;
      _controller.value = _controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
        composing: TextRange.empty,
      );
    });
  }

  @override
  void dispose() {
    _disposeEffect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: context.txt.body,
      decoration: appInputDecoration(hintText: widget.setting.hintText),
      cursorColor: AppColors.accent,
    );
  }
}

class SettingsToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SettingsToggle> createState() => _SettingsToggleState();
}

class SettingsActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SettingsActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<SettingsActionButton> createState() => _SettingsActionButtonState();
}

class _SettingsActionButtonState extends State<SettingsActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg = _hovered ? AppColors.fg : AppColors.fgMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : AppColors.bgInput,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(widget.label, style: context.txt.body.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleState extends State<SettingsToggle> {
  @override
  Widget build(BuildContext context) {
    final on = widget.value;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!on),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: 36,
          height: 20,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : AppColors.bgInput,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: on ? AppColors.accent : AppColors.borderColor,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
