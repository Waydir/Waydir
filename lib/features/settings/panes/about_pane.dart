import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';

import '../../../app/app_info.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/overlays/toast.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../preferences_view.dart';

class AboutPane extends StatelessWidget {
  const AboutPane({super.key});

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      showToast(context: context, message: t.preferences.about.copy);
    }
  }

  Future<void> _openUrl(String url) async {
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
    } else if (Platform.isMacOS) {
      await Process.start('open', [url], mode: ProcessStartMode.detached);
    } else if (Platform.isWindows) {
      await Process.start('cmd', [
        '/c',
        'start',
        url,
      ], mode: ProcessStartMode.detached);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPaneScaffold(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(AppInfo.iconAsset, width: 48, height: 48),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppInfo.name, style: context.txt.dialogTitle),
                  const SizedBox(height: 4),
                  Text(AppInfo.tagline, style: context.txt.muted),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            children: [
              Watch(
                (_) => _InfoRow(
                  label: t.preferences.about.version,
                  value: AppInfo.versionLabel.value,
                  onCopy: () => _copy(context, AppInfo.version.value),
                ),
              ),
              Container(height: 1, color: AppColors.bgDivider),
              _InfoRow(
                label: t.preferences.about.repository,
                value: AppInfo.repository,
                onCopy: () => _copy(context, AppInfo.repository),
                onOpen: () => _openUrl(AppInfo.homepage),
              ),
              Container(height: 1, color: AppColors.bgDivider),
              _InfoRow(
                label: t.preferences.about.license,
                value: AppInfo.license,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final VoidCallback? onOpen;

  const _InfoRow({
    required this.label,
    required this.value,
    this.onCopy,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: context.txt.body.copyWith(color: AppColors.fgMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.txt.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onOpen != null)
            _SmallIcon(
              icon: WaydirIconsRegular.arrowSquareOut,
              onTap: onOpen!,
            ),
          if (onCopy != null) ...[
            const SizedBox(width: 4),
            _SmallIcon(icon: WaydirIconsRegular.copy, onTap: onCopy!),
          ],
        ],
      ),
    );
  }
}

class _SmallIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallIcon({required this.icon, required this.onTap});

  @override
  State<_SmallIcon> createState() => _SmallIconState();
}

class _SmallIconState extends State<_SmallIcon> {
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
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgInput : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            widget.icon,
            size: 14,
            color: _hovered ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}
