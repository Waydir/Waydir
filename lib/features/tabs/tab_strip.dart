import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../ui/theme/app_theme.dart';
import 'tab_chip.dart';
import 'tabs_store.dart';

class TabStrip extends StatelessWidget {
  final TabsStore tabsStore;
  final bool isActive;

  const TabStrip({super.key, required this.tabsStore, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final tabs = tabsStore.tabs.value;
        return Container(
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? AppColors.bgSidebar : AppColors.bg,
            border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  buildDefaultDragHandles: false,
                  padding: EdgeInsets.zero,
                  itemCount: tabs.length,
                  onReorderItem: tabsStore.reorderTab,
                  itemBuilder: (context, index) {
                    final tab = tabs[index];
                    return ReorderableDragStartListener(
                      key: ValueKey('tab:${tab.id}'),
                      index: index,
                      child: TabChip(
                        tab: tab,
                        index: index,
                        tabsStore: tabsStore,
                      ),
                    );
                  },
                ),
              ),
              _AddButton(
                onTap: () {
                  final activePath =
                      tabsStore.activeTab.value.store.currentPath.value;
                  tabsStore.addTab(activePath);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
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
          width: 28,
          height: 30,
          alignment: Alignment.center,
          color: _hovered ? AppColors.bgHover : Colors.transparent,
          child: Icon(
            WaydirIconsRegular.plus,
            size: 14,
            color: _hovered ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}
