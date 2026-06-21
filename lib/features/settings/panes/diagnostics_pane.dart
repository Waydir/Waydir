import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/fs/waydir_core_loader.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_entry.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/overlays/toast.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../../ui/widgets/app_modal.dart';
import '../preferences_view.dart';

Future<void> showDiagnosticsDialog(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final width = size.width * 0.78 > 820 ? 820.0 : size.width * 0.78;
  final height = size.height - 112 > 620 ? 620.0 : size.height - 112;

  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => AppModal(
      icon: WaydirIconsRegular.bug,
      title: t.preferences.diagnostics.title,
      width: width,
      height: height,
      onClose: () => Navigator.of(ctx).pop(),
      child: const SingleChildScrollView(child: DiagnosticsPane()),
    ),
  );
}

class DiagnosticsPane extends StatefulWidget {
  const DiagnosticsPane({super.key});

  @override
  State<DiagnosticsPane> createState() => _DiagnosticsPaneState();
}

class _DiagnosticsPaneState extends State<DiagnosticsPane> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _searchFocused = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _filtered(List<LogEntry> entries) {
    if (_query.isEmpty) return entries;
    final q = _query.toLowerCase();

    return entries
        .where(
          (e) =>
              e.message.toLowerCase().contains(q) ||
              e.tag.toLowerCase().contains(q),
        )
        .toList();
  }

  String _format(LogEntry e) {
    final ts = e.timestamp.toIso8601String();
    final base = '$ts [${e.level.label}] ${e.tag}: ${e.message}';

    return e.stackTrace == null ? base : '$base\n${e.stackTrace}';
  }

  Future<void> _copy(List<LogEntry> entries) async {
    final text = entries.map(_format).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      showToast(context: context, message: t.preferences.diagnostics.copied);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final all = log.entries.value;
        final visible = _filtered(all);

        return SettingsPaneScaffold(
          children: [
            Text(
              t.preferences.diagnostics.title,
              style: context.txt.dialogTitle,
            ),
            const SizedBox(height: 4),
            Text(t.preferences.diagnostics.subtitle, style: context.txt.muted),
            const SizedBox(height: 8),
            SelectableText(
              '${t.preferences.diagnostics.native}: ${WaydirCoreLoader.buildInfo() ?? t.preferences.diagnostics.unavailable}',
              style: context.txt.muted,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (focused) =>
                        setState(() => _searchFocused = focused),
                    child: Container(
                      height: 34,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: _searchFocused
                              ? AppColors.accent
                              : AppColors.borderColor,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        style: context.txt.body,
                        decoration: InputDecoration.collapsed(
                          hintText: t.preferences.diagnostics.search,
                          hintStyle: context.txt.body.copyWith(
                            color: AppColors.fgMuted,
                          ),
                        ),
                        cursorColor: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Btn(
                  icon: WaydirIconsRegular.copy,
                  label: t.preferences.diagnostics.copy,
                  onTap: visible.isEmpty ? null : () => _copy(visible),
                ),
                const SizedBox(width: 6),
                _Btn(
                  icon: WaydirIconsRegular.trashSimple,
                  label: t.preferences.diagnostics.clear,
                  onTap: all.isEmpty ? null : log.clear,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.borderColor),
              ),
              constraints: const BoxConstraints(minHeight: 120),
              child: visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        t.preferences.diagnostics.empty,
                        style: context.txt.muted,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = visible.length - 1; i >= 0; i--) ...[
                          if (i < visible.length - 1)
                            Container(height: 1, color: AppColors.bgDivider),
                          _LogRow(entry: visible[i]),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  WaydirIconsRegular.info,
                  size: 13,
                  color: AppColors.fgMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.preferences.diagnostics.privacyNote,
                    style: context.txt.muted,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LogRow extends StatelessWidget {
  final LogEntry entry;
  const _LogRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.level == LogLevel.error
        ? AppColors.danger
        : AppColors.warning;
    final ts = entry.timestamp.toIso8601String().substring(11, 19);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  entry.level.label,
                  style: context.txt.muted.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(entry.tag, style: context.txt.muted),
              const Spacer(),
              Text(ts, style: context.txt.muted),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(entry.message, style: context.txt.body),
        ],
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Btn({required this.icon, required this.label, this.onTap});

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final fg = !enabled
        ? AppColors.fgMuted.withValues(alpha: 0.5)
        : (_hovered ? AppColors.fg : AppColors.fgMuted);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: enabled && _hovered ? AppColors.bgHover : AppColors.bgInput,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
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
