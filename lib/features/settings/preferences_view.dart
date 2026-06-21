import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';

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

bool _matches(String query, Iterable<String> values) {
  final tokens = query
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
  final haystack = values.join(' ').toLowerCase();

  return tokens.every(haystack.contains);
}

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

PreferenceNavSection _sectionById(String id) {
  return preferenceNavSections.firstWhere((section) => section.id == id);
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

class _PreferenceNavSelection {
  final Category category;
  final String? sectionId;

  const _PreferenceNavSelection({required this.category, this.sectionId});
}

class _PreferencesDialog extends StatefulWidget {
  const _PreferencesDialog();

  @override
  State<_PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<_PreferencesDialog> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  late final ValueNotifier<_PreferenceNavSelection> _navSelection;
  late final GlobalKey _contentKey;
  late final Map<String, GlobalKey> _sectionKeys;
  late final Map<String, GlobalKey> _settingKeys;
  final _sectionOffsets = <String, double>{};
  bool _offsetRefreshScheduled = false;
  String _searchQuery = '';
  bool _searchResultsVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_syncSelectionToScroll);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _navSelection = ValueNotifier(
      const _PreferenceNavSelection(category: Category.general),
    );
    _contentKey = GlobalKey();
    _sectionKeys = {
      for (final section in preferenceNavSections) section.id: GlobalKey(),
    };
    _settingKeys = {for (final id in _visibleSettingIds) id: GlobalKey()};
    _scheduleOffsetRefresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _navSelection.dispose();
    super.dispose();
  }

  void _scrollToCategory(Category category) {
    final section = preferenceNavSections.firstWhere(
      (section) => section.category == category,
    );
    _scrollToSection(section);
  }

  void _scrollToSection(PreferenceNavSection section) {
    _setNavSelection(section.category, section.id);
    _scrollToSectionId(section.id);
  }

  void _scrollToSearchResult(_PreferenceSearchResult result) {
    _setNavSelection(result.category, result.sectionId);
    setState(() {
      _searchResultsVisible = false;
    });
    _scrollToKey(
      result.settingId == null
          ? result.sectionId == null
                ? _sectionKeys[preferenceNavSections
                      .firstWhere(
                        (section) => section.category == result.category,
                      )
                      .id]
                : _sectionKeys[result.sectionId]
          : _settingKeys[result.settingId],
    );
  }

  void _scrollToKey(GlobalKey? key) {
    if (!_scrollController.hasClients) return;
    final top = _anchorTop(key);
    if (top == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToKey(key));

      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    final target = (_scrollController.offset + top).clamp(0.0, max);
    _scrollController.jumpTo(target);
  }

  void _scrollToSectionId(String id) {
    if (!_scrollController.hasClients) return;
    final offset = _sectionOffsets[id];
    if (offset == null) {
      _scheduleOffsetRefresh();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToSectionId(id),
      );

      return;
    }
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(offset.clamp(0.0, max));
  }

  void _syncSelectionToScroll() {
    _updateSelectionFromScrollOffset();
  }

  void _updateSelectionFromScrollOffset() {
    if (!_scrollController.hasClients || _sectionOffsets.isEmpty) return;
    final currentOffset = _scrollController.offset + 18;
    PreferenceNavSection? active;
    for (final section in preferenceNavSections) {
      final offset = _sectionOffsets[section.id];
      if (offset == null) continue;
      if (offset <= currentOffset) {
        active = section;
      } else {
        break;
      }
    }
    if (active == null) return;
    _setNavSelection(active.category, active.id);
  }

  void _scheduleOffsetRefresh() {
    if (_offsetRefreshScheduled) return;
    _offsetRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offsetRefreshScheduled = false;
      if (!mounted) return;
      _refreshSectionOffsets();
      _updateSelectionFromScrollOffset();
    });
  }

  void _refreshSectionOffsets() {
    if (!_scrollController.hasClients) return;
    final next = <String, double>{};
    for (final section in preferenceNavSections) {
      final top = _anchorTop(_sectionKeys[section.id]);
      if (top == null) continue;
      next[section.id] = _scrollController.offset + top;
    }
    if (next.isNotEmpty) {
      _sectionOffsets
        ..clear()
        ..addAll(next);
    }
  }

  void _setNavSelection(Category category, String? sectionId) {
    final current = _navSelection.value;
    if (current.category == category && current.sectionId == sectionId) return;
    _navSelection.value = _PreferenceNavSelection(
      category: category,
      sectionId: sectionId,
    );
  }

  double? _anchorTop(GlobalKey? key) {
    final viewportBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final context = key?.currentContext;
    final box = context?.findRenderObject() as RenderBox?;
    if (box == null ||
        viewportBox == null ||
        !box.attached ||
        !viewportBox.attached) {
      return null;
    }
    return box.localToGlobal(Offset.zero).dy -
        viewportBox.localToGlobal(Offset.zero).dy;
  }

  void _setSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
      _searchResultsVisible = value.trim().isNotEmpty;
    });
  }

  void _setSearchFocused(bool focused) {
    if (!focused) return;
    if (_searchQuery.trim().isEmpty) return;
    setState(() => _searchResultsVisible = true);
  }

  void _clearSearch() {
    _searchController.clear();
    _setSearchQuery('');
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
    if (_searchQuery.trim().isNotEmpty) {
      setState(() => _searchResultsVisible = true);
    }
  }

  KeyEventResult _handleDialogKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (AppShortcuts.matches('search', event.logicalKey)) {
      _focusSearch();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  List<_PreferenceSearchResult> _searchResults() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final results = <_PreferenceSearchResult>[];

    for (final cat in categories) {
      if (_matches(query, [cat.label()])) {
        results.add(
          _PreferenceSearchResult(
            title: cat.label(),
            icon: cat.icon,
            category: cat.id,
          ),
        );
      }
    }
    for (final section in preferenceNavSections) {
      final category = _categoryMeta(section.category);
      if (_matches(query, [section.label(), category.label()])) {
        results.add(
          _PreferenceSearchResult(
            title: section.label(),
            subtitle: category.label(),
            icon: category.icon,
            category: section.category,
            sectionId: section.id,
          ),
        );
      }
    }
    for (final setting in SettingsRegistry.instance.all) {
      if (!_visibleSettingIds.contains(setting.id)) continue;
      final category = _categoryMeta(_categoryForSetting(setting.category));
      final sectionId = _sectionIdForSetting(setting.id);
      final section = sectionId == null ? null : _sectionById(sectionId);
      if (_matches(query, [
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

    return AppModal(
      icon: WaydirIconsRegular.gearSix,
      title: t.preferences.title,
      width: dialogWidth,
      height: dialogHeight,
      onClose: () => Navigator.of(context).pop(),
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleDialogKeyEvent,
        child: Row(
          children: [
            ValueListenableBuilder<_PreferenceNavSelection>(
              valueListenable: _navSelection,
              builder: (context, selection, child) {
                return _CategorySidebar(
                  selectedCategory: selection.category,
                  selectedSectionId: selection.sectionId,
                  onSelectCategory: _scrollToCategory,
                  onSelectSection: _scrollToSection,
                );
              },
            ),
            Container(width: 1, color: AppColors.bgDivider),
            Expanded(
              child: Column(
                children: [
                  _PreferencesSearchBar(
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    query: _searchQuery,
                    results: _searchResults(),
                    resultsVisible: _searchResultsVisible,
                    onChanged: _setSearchQuery,
                    onFocusChanged: _setSearchFocused,
                    onClear: _clearSearch,
                    onSelect: _scrollToSearchResult,
                  ),
                  Expanded(
                    child: _ContentPane(
                      contentKey: _contentKey,
                      scrollController: _scrollController,
                      sectionKeys: _sectionKeys,
                      settingKeys: _settingKeys,
                      onLayoutChanged: _scheduleOffsetRefresh,
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

class _PreferencesSearchBar extends StatefulWidget {
  final FocusNode focusNode;
  final TextEditingController controller;
  final String query;
  final List<_PreferenceSearchResult> results;
  final bool resultsVisible;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onFocusChanged;
  final VoidCallback onClear;
  final ValueChanged<_PreferenceSearchResult> onSelect;

  const _PreferencesSearchBar({
    required this.focusNode,
    required this.controller,
    required this.query,
    required this.results,
    required this.resultsVisible,
    required this.onChanged,
    required this.onFocusChanged,
    required this.onClear,
    required this.onSelect,
  });

  @override
  State<_PreferencesSearchBar> createState() => _PreferencesSearchBarState();
}

class _PreferencesSearchBarState extends State<_PreferencesSearchBar> {
  final _layerLink = LayerLink();
  OverlayEntry? _resultsOverlay;
  bool _focused = false;
  bool _resultsSuppressed = false;
  int _activeResult = 0;

  @override
  void didUpdateWidget(covariant _PreferencesSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _activeResult = 0;
      _resultsSuppressed = false;
    }
    if (_activeResult >= widget.results.length) {
      _activeResult = widget.results.isEmpty ? 0 : widget.results.length - 1;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncResultsOverlay());
  }

  @override
  void dispose() {
    _removeResultsOverlay();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!widget.resultsVisible || widget.query.trim().isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (widget.results.isNotEmpty) {
        setState(() {
          _activeResult++;
          if (_activeResult >= widget.results.length) {
            _activeResult = widget.results.length - 1;
          }
        });
        _syncResultsOverlay();
      }

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (widget.results.isNotEmpty) {
        setState(() {
          _activeResult--;
          if (_activeResult < 0) _activeResult = 0;
        });
        _syncResultsOverlay();
      }

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (widget.results.isNotEmpty) {
        _resultsSuppressed = true;
        widget.onSelect(widget.results[_activeResult]);
        _removeResultsOverlay();
      }

      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _resultsSuppressed = true;
      _removeResultsOverlay();

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _syncResultsOverlay() {
    if (!mounted) return;
    final showResults =
        widget.resultsVisible &&
        !_resultsSuppressed &&
        widget.query.trim().isNotEmpty;
    if (!showResults) {
      _removeResultsOverlay();

      return;
    }
    if (_resultsOverlay == null) {
      _resultsOverlay = OverlayEntry(builder: _buildResultsOverlay);
      Overlay.of(context).insert(_resultsOverlay!);
    } else {
      _resultsOverlay!.markNeedsBuild();
    }
  }

  void _removeResultsOverlay() {
    final overlay = _resultsOverlay;
    _resultsOverlay = null;
    overlay?.remove();
  }

  Widget _buildResultsOverlay(BuildContext context) {
    final box = this.context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 480;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: Material(
                type: MaterialType.transparency,
                child: _PreferenceSearchResults(
                  results: widget.results,
                  activeIndex: _activeResult,
                  onSelect: (result) {
                    _resultsSuppressed = true;
                    widget.onSelect(result);
                    _removeResultsOverlay();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncResultsOverlay());

    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Focus(
                onFocusChange: (focused) {
                  setState(() {
                    _focused = focused;
                    if (focused) _resultsSuppressed = false;
                  });
                  widget.onFocusChanged(focused);
                },
                onKeyEvent: _handleKeyEvent,
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: _focused
                          ? AppColors.accent
                          : AppColors.borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        WaydirIconsRegular.magnifyingGlass,
                        size: 14,
                        color: AppColors.fgMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          focusNode: widget.focusNode,
                          controller: widget.controller,
                          onChanged: widget.onChanged,
                          onSubmitted: (_) {
                            if (widget.results.isNotEmpty) {
                              _resultsSuppressed = true;
                              widget.onSelect(widget.results[_activeResult]);
                              _removeResultsOverlay();
                            }
                          },
                          style: context.txt.body,
                          decoration: InputDecoration.collapsed(
                            hintText: t.preferences.searchPlaceholder,
                            hintStyle: context.txt.body.copyWith(
                              color: AppColors.fgMuted,
                            ),
                          ),
                          cursorColor: AppColors.accent,
                        ),
                      ),
                      if (widget.query.isNotEmpty)
                        _SearchClearButton(onTap: widget.onClear),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSearchResults extends StatelessWidget {
  final List<_PreferenceSearchResult> results;
  final int activeIndex;
  final ValueChanged<_PreferenceSearchResult> onSelect;

  const _PreferenceSearchResults({
    required this.results,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 236),
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        border: Border(top: BorderSide(color: AppColors.bgDivider)),
      ),
      child: results.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.preferences.searchNoResults,
                  style: context.txt.muted,
                ),
              ),
            )
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final result in results)
                  _PreferenceSearchResultRow(
                    result: result,
                    selected: results.indexOf(result) == activeIndex,
                    onTap: () => onSelect(result),
                  ),
              ],
            ),
    );
  }
}

class _PreferenceSearchResultRow extends StatefulWidget {
  final _PreferenceSearchResult result;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceSearchResultRow({
    required this.result,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PreferenceSearchResultRow> createState() =>
      _PreferenceSearchResultRowState();
}

class _PreferenceSearchResultRowState
    extends State<_PreferenceSearchResultRow> {
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
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Icon(WaydirIconsRegular.x, size: 13, color: AppColors.fgMuted),
        ),
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final Category selectedCategory;
  final String? selectedSectionId;
  final ValueChanged<Category> onSelectCategory;
  final ValueChanged<PreferenceNavSection> onSelectSection;

  const _CategorySidebar({
    required this.selectedCategory,
    required this.selectedSectionId,
    required this.onSelectCategory,
    required this.onSelectSection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: ListView(
        children: [
          for (final cat in categories)
            _CategoryTreeItem(
              meta: cat,
              sections: preferenceNavSections
                  .where((section) => section.category == cat.id)
                  .toList(),
              selectedCategory: selectedCategory,
              selectedSectionId: selectedSectionId,
              onSelectCategory: onSelectCategory,
              onSelectSection: onSelectSection,
            ),
        ],
      ),
    );
  }
}

class _CategoryTreeItem extends StatelessWidget {
  final CategoryMeta meta;
  final List<PreferenceNavSection> sections;
  final Category selectedCategory;
  final String? selectedSectionId;
  final ValueChanged<Category> onSelectCategory;
  final ValueChanged<PreferenceNavSection> onSelectSection;

  const _CategoryTreeItem({
    required this.meta,
    required this.sections,
    required this.selectedCategory,
    required this.selectedSectionId,
    required this.onSelectCategory,
    required this.onSelectSection,
  });

  @override
  Widget build(BuildContext context) {
    final categorySelected = meta.id == selectedCategory;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CategoryItem(
          meta: meta,
          selected: categorySelected && selectedSectionId == null,
          expanded: sections.isNotEmpty,
          onTap: () => onSelectCategory(meta.id),
        ),
        for (final section in sections)
          _SectionItem(
            section: section,
            selected: selectedSectionId == section.id,
            onTap: () => onSelectSection(section),
          ),
      ],
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final CategoryMeta meta;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.meta,
    required this.selected,
    required this.expanded,
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
          height: 28,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.zero,
            border: widget.selected
                ? Border(left: BorderSide(color: AppColors.accent, width: 2))
                : null,
          ),
          child: Row(
            children: [
              if (widget.expanded)
                Icon(WaydirIconsRegular.caretDown, size: 12, color: fg)
              else
                const SizedBox(width: 12),
              const SizedBox(width: 6),
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

class _SectionItem extends StatefulWidget {
  final PreferenceNavSection section;
  final bool selected;
  final VoidCallback onTap;

  const _SectionItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SectionItem> createState() => _SectionItemState();
}

class _SectionItemState extends State<_SectionItem> {
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
          height: 25,
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.only(left: 24, right: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.zero,
            border: widget.selected
                ? Border(left: BorderSide(color: AppColors.accent, width: 2))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 1,
                height: 25,
                color: widget.selected ? AppColors.accent : AppColors.bgDivider,
              ),
              const SizedBox(width: 9),
              Container(
                width: 4,
                height: 4,
                color: widget.selected
                    ? AppColors.accent
                    : AppColors.fgMuted.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.section.label(),
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
  final GlobalKey contentKey;
  final ScrollController scrollController;
  final Map<String, GlobalKey> sectionKeys;
  final Map<String, GlobalKey> settingKeys;
  final VoidCallback onLayoutChanged;

  const _ContentPane({
    required this.contentKey,
    required this.scrollController,
    required this.sectionKeys,
    required this.settingKeys,
    required this.onLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PreferenceAnchorScope(
      sectionKeys: sectionKeys,
      settingKeys: settingKeys,
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          onLayoutChanged();

          return false;
        },
        child: SizeChangedLayoutNotifier(
          child: ListView(
            key: contentKey,
            controller: scrollController,
            children: [
              const GeneralPane(),
              const AppearancePane(),
              const TerminalPane(),
              const QuickLookPane(),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPaneScaffold extends StatelessWidget {
  final List<Widget> children;

  const SettingsPaneScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
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
