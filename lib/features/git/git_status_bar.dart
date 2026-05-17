import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../ui/dialogs/dialog.dart';
import '../../ui/overlays/context_menu.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'git_status_store.dart';

class GitStatusBar extends StatefulWidget {
  final GitStatus status;
  final GitStatusStore store;

  const GitStatusBar({super.key, required this.status, required this.store});

  @override
  State<GitStatusBar> createState() => _GitStatusBarState();
}

class _GitStatusBarState extends State<GitStatusBar>
    with WidgetsBindingObserver {
  GitStatus get status => widget.status;
  GitStatusStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Catches git changes made outside the app (terminal commit/checkout)
    // while it was unfocused — the directory watcher can't see those.
    if (state == AppLifecycleState.resumed) {
      store.refreshCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateLabel = _stateLabel(status.state);

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.bgStatus,
        border: Border(top: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          _BranchButton(status: status, store: store),
          if (stateLabel != null) ...[
            const SizedBox(width: 8),
            _StateBadge(stateLabel),
          ],
          if (status.ahead > 0) _GitCount('↑${status.ahead}'),
          if (status.behind > 0) _GitCount('↓${status.behind}'),
          // Real line stats: green +inserted / red -deleted. Plain edits no
          // longer flash as alarming red.
          if (status.insertions > 0)
            _GitCount('+${status.insertions}', color: AppColors.success),
          if (status.deletions > 0)
            _GitCount('-${status.deletions}', color: AppColors.danger),
          // New files have no diff vs HEAD — show them separately, muted.
          if (status.untracked > 0)
            _GitCount('?${status.untracked}'),
          if (status.stash > 0) _StashButton(status: status, store: store),
          if (!status.hasChanges &&
              status.ahead == 0 &&
              status.behind == 0 &&
              status.state == RepoState.clean) ...[
            const SizedBox(width: 8),
            Text('clean', style: context.txt.muted),
          ],
        ],
      ),
    );
  }

  static String? _stateLabel(RepoState state) {
    switch (state) {
      case RepoState.clean:
        return null;
      case RepoState.merging:
        return 'MERGING';
      case RepoState.rebasing:
        return 'REBASING';
      case RepoState.cherryPicking:
        return 'CHERRY-PICK';
      case RepoState.reverting:
        return 'REVERTING';
      case RepoState.bisecting:
        return 'BISECTING';
    }
  }
}

class _BranchButton extends StatelessWidget {
  final GitStatus status;
  final GitStatusStore store;

  const _BranchButton({required this.status, required this.store});

  Future<void> _openSwitcher(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);

    final branches = await store.branches();
    if (!context.mounted) return;
    if (branches.isEmpty) return;

    showContextMenu(
      context: context,
      // PopupOverlay clamps on-screen, so anchoring at the button's top edge
      // makes the menu open upward, above the status bar.
      position: Offset(origin.dx, origin.dy),
      items: [
        for (final name in branches)
          ContextMenuItem(
            icon: name == status.branch
                ? PhosphorIconsFill.check
                : PhosphorIconsRegular.gitBranch,
            label: name,
            action: name,
          ),
      ],
      onSelect: (action) async {
        if (action == status.branch) return;
        final result = await store.checkout(action);
        if (!context.mounted) return;
        switch (result.outcome) {
          case CheckoutOutcome.ok:
            return;
          case CheckoutOutcome.failed:
            _snack(context, 'Checkout failed: ${result.message}');
          case CheckoutOutcome.needsStash:
            await _confirmStashAndSwitch(context, action);
        }
      },
    );
  }

  Future<void> _confirmStashAndSwitch(
    BuildContext context,
    String branch,
  ) async {
    final choice = await showCustomDialog<String>(
      context: context,
      title: 'Uncommitted changes',
      icon: PhosphorIconsRegular.warning,
      iconColor: AppColors.warning,
      body: Text(
        "Your local changes would be overwritten by switching to '$branch'.\n\n"
        'Stash them now? They stay saved in a stash you can restore later '
        'on this branch.',
        style: context.txt.body,
      ),
      actions: const [
        DialogAction(label: 'Cancel', color: AppColors.bgHoverStrong),
        DialogAction(label: 'Stash & Switch', color: AppColors.accent),
      ],
    );
    if (choice != 'Stash & Switch' || !context.mounted) return;
    final error = await store.stashAndCheckout(branch);
    if (error != null && context.mounted) {
      _snack(context, 'Stash & switch failed: $error');
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detached HEAD is easy to commit into and lose — flag it clearly.
    final color = status.detached ? AppColors.warning : AppColors.fgAccent;
    return Flexible(
      fit: FlexFit.loose,
      child: InkWell(
        onTap: () => _openSwitcher(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                status.detached
                    ? PhosphorIconsRegular.warning
                    : PhosphorIconsRegular.gitBranch,
                size: 13,
                color: color,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  status.detached ? 'detached HEAD' : status.branch,
                  style: context.txt.rowEmphasis.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 3),
              PhosphorIcon(
                PhosphorIconsRegular.caretUpDown,
                size: 11,
                color: AppColors.fgMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StashButton extends StatelessWidget {
  final GitStatus status;
  final GitStatusStore store;

  const _StashButton({required this.status, required this.store});

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);

    final stashes = await store.stashes();
    if (!context.mounted || stashes.isEmpty) return;

    showContextMenu(
      context: context,
      position: Offset(origin.dx, origin.dy),
      items: [
        for (final s in stashes)
          ContextMenuItem(
            icon: PhosphorIconsRegular.archive,
            label: 'stash@{${s.index}} · ${s.message}',
            action: 'stash:${s.index}',
            children: [
              ContextMenuItem(
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                label: 'Pop (apply & remove)',
                action: 'pop:${s.index}',
              ),
              ContextMenuItem(
                icon: PhosphorIconsRegular.copy,
                label: 'Apply (keep stash)',
                action: 'apply:${s.index}',
              ),
              ContextMenuItem(
                icon: PhosphorIconsRegular.trash,
                label: 'Drop',
                action: 'drop:${s.index}',
                danger: true,
              ),
            ],
          ),
      ],
      onSelect: (action) async {
        final parts = action.split(':');
        if (parts.length != 2) return;
        final index = int.tryParse(parts[1]);
        if (index == null) return;
        final String? error;
        switch (parts[0]) {
          case 'pop':
            error = await store.popStash(index);
          case 'apply':
            error = await store.applyStash(index);
          case 'drop':
            error = await store.dropStash(index);
          default:
            return;
        }
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Stash failed: $error'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.archive,
                size: 12,
                color: AppColors.warning,
              ),
              const SizedBox(width: 4),
              Text(
                '${status.stash}',
                style: context.txt.muted.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String label;

  const _StateBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: context.txt.muted.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GitCount extends StatelessWidget {
  final String text;
  final Color? color;

  const _GitCount(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text,
        style: color == null
            ? context.txt.muted
            : context.txt.muted.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
      ),
    );
  }
}
