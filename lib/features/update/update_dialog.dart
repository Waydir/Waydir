import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/update/install_format.dart';
import '../../core/update/update_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../utils/format.dart';

Future<void> showUpdateDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: t.update.title,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 120),
    pageBuilder: (ctx, _, _) => const _UpdateDialog(),
    transitionBuilder: (ctx, anim, secondary, child) {
      final c = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: c,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(c),
          child: child,
        ),
      );
    },
  );
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context) {
    final store = UpdateStore.instance;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 520,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Watch((_) {
              final status = store.status.value;
              final release = store.latestRelease.value;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Header(
                    status: status,
                    version: release?.version,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Container(height: 1, color: AppColors.bgDivider),
                  _Body(store: store),
                  Container(height: 1, color: AppColors.bgDivider),
                  _Footer(store: store),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final UpdateStatus status;
  final String? version;
  final VoidCallback onClose;

  const _Header({
    required this.status,
    required this.version,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final version = this.version;
    final title = switch (status) {
      UpdateStatus.idle ||
      UpdateStatus.checking ||
      UpdateStatus.upToDate => t.update.title,
      UpdateStatus.available => t.update.available,
      UpdateStatus.downloading => t.update.downloading,
      UpdateStatus.ready => t.update.ready,
      UpdateStatus.launching => t.update.launching,
      UpdateStatus.installed => t.update.installed,
      UpdateStatus.error => t.update.error,
    };
    return Container(
      height: 48,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(WaydirIconsRegular.arrowUp, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              version == null
                  ? title
                  : t.update.titleWithVersion(title: title, version: version),
              style: context.txt.bodyEmphasis,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          color: _hover ? AppColors.bgHover : Colors.transparent,
          child: Icon(
            Icons.close,
            size: 16,
            color: _hover ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final UpdateStore store;

  const _Body({required this.store});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final status = store.status.value;
      if (status == UpdateStatus.error) {
        return _CenterMessage(
          message: store.errorMessage.value ?? t.update.unknownError,
          color: AppColors.danger,
        );
      }
      if (status == UpdateStatus.checking) {
        return _CenterMessage(message: t.update.checking);
      }
      if (status == UpdateStatus.upToDate) {
        return _CenterMessage(
          message: t.update.upToDate(version: store.currentVersion),
        );
      }
      if (status == UpdateStatus.installed) {
        final v =
            store.pendingRestartVersion.value ??
            store.latestRelease.value?.version ??
            '';
        return _CenterMessage(
          message: t.update.restartHint(version: v),
          color: AppColors.success,
        );
      }
      final release = store.latestRelease.value;
      if (release == null) {
        return _CenterMessage(message: t.update.noRelease);
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: _CurrentVersionRow(
              current: store.currentVersion,
              next: release.version,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, minHeight: 80),
            child: _ReleaseNotes(body: release.body),
          ),
          Container(height: 1, color: AppColors.bgDivider),
          _AssetRow(store: store),
          if (status == UpdateStatus.downloading ||
              status == UpdateStatus.ready) ...[
            _Progress(store: store),
          ],
        ],
      );
    });
  }
}

class _CurrentVersionRow extends StatelessWidget {
  final String current;
  final String next;

  const _CurrentVersionRow({required this.current, required this.next});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(t.update.versionLabel(version: current), style: context.txt.muted),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward, size: 14, color: AppColors.fgSubtle),
        const SizedBox(width: 8),
        Text(
          t.update.versionLabel(version: next),
          style: context.txt.bodyEmphasis.copyWith(color: AppColors.warning),
        ),
      ],
    );
  }
}

class _ReleaseNotes extends StatelessWidget {
  final String body;

  const _ReleaseNotes({required this.body});

  @override
  Widget build(BuildContext context) {
    final text = body.trim();
    if (text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
        child: Text(
          t.update.noNotes,
          style: context.txt.muted.copyWith(color: AppColors.fgSubtle),
        ),
      );
    }
    final baseFont = TextStyle(
      fontSize: 13.5,
      height: 1.5,
      color: AppColors.fg,
    );
    final mutedFont = baseFont.copyWith(color: AppColors.fgMuted);
    final monoFont = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      color: AppColors.fg,
    );
    return Markdown(
      data: text,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
      shrinkWrap: true,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href == null || href.isEmpty) return;
        final uri = Uri.tryParse(href);
        if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
          return;
        }
        final cmd = Platform.isWindows
            ? 'explorer'
            : Platform.isMacOS
            ? 'open'
            : 'xdg-open';
        Process.start(cmd, [uri.toString()], mode: ProcessStartMode.detached);
      },
      styleSheet: MarkdownStyleSheet(
        p: baseFont,
        h1: baseFont.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h2: baseFont.copyWith(
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          height: 1.3,
        ),
        h3: baseFont.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.fgMuted,
        ),
        listBullet: baseFont,
        em: baseFont.copyWith(fontStyle: FontStyle.italic),
        strong: baseFont.copyWith(fontWeight: FontWeight.w600),
        code: monoFont.copyWith(backgroundColor: AppColors.bgInput),
        codeblockDecoration: BoxDecoration(color: AppColors.bgInput),
        codeblockPadding: const EdgeInsets.all(10),
        blockSpacing: 10,
        blockquote: mutedFont,
        blockquoteDecoration: BoxDecoration(
          color: AppColors.bgInput,
          border: Border(
            left: BorderSide(color: AppColors.borderColor, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        a: baseFont.copyWith(
          color: AppColors.accent,
          decoration: TextDecoration.underline,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.bgDivider)),
        ),
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  final UpdateStore store;

  const _AssetRow({required this.store});

  @override
  Widget build(BuildContext context) {
    final asset = store.selectedAsset.value;
    final fmt = store.installFormat.value;
    if (asset == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: Text(
          t.update.noMatch,
          style: context.txt.muted.copyWith(color: AppColors.danger),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Row(
        children: [
          Icon(
            WaydirIconsRegular.downloadSimple,
            size: 14,
            color: AppColors.fgMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  asset.name,
                  style: context.txt.body.copyWith(color: AppColors.fg),
                  softWrap: true,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      formatBytes(asset.sizeBytes),
                      style: context.txt.caption.copyWith(
                        color: AppColors.fgMuted,
                      ),
                    ),
                    if (fmt != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderColor),
                        ),
                        child: Text(
                          _formatLabel(fmt),
                          style: context.txt.caption.copyWith(
                            color: AppColors.fgMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatLabel(InstallFormat fmt) => switch (fmt) {
    InstallFormat.linuxDeb => 'deb',
    InstallFormat.linuxRpm => 'rpm',
    InstallFormat.linuxPortable => 'tar.gz',
    InstallFormat.windowsInstaller => t.update.formatInstaller,
    InstallFormat.windowsPortable => t.update.formatPortable,
    InstallFormat.macDmg => 'dmg',
    InstallFormat.unknown => t.update.formatUnknown,
  };
}

class _Progress extends StatelessWidget {
  final UpdateStore store;

  const _Progress({required this.store});

  @override
  Widget build(BuildContext context) {
    final p = store.progress.value;
    final received = store.downloadedBytes.value;
    final total = store.totalBytes.value;
    final done = store.status.value == UpdateStatus.ready;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 4,
            color: AppColors.bgInput,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: p.clamp(0.0, 1.0),
              child: Container(
                color: done ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                done
                    ? t.update.downloaded
                    : total > 0
                    ? '${formatBytes(received)} / ${formatBytes(total)}'
                    : formatBytes(received),
                style: context.txt.caption.copyWith(color: AppColors.fgMuted),
              ),
              Text(
                '${(p * 100).toStringAsFixed(0)}%',
                style: context.txt.caption.copyWith(
                  color: done ? AppColors.success : AppColors.fgMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  final String message;
  final Color? color;

  const _CenterMessage({required this.message, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.txt.body.copyWith(
            color: color ?? AppColors.fgMuted,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final UpdateStore store;

  const _Footer({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.bgSidebar,
      child: Row(
        children: [
          _LinkButton(
            label: t.update.releasePage,
            onTap: store.openReleasePage,
          ),
          const Spacer(),
          _PrimaryButton(store: store),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final UpdateStore store;

  const _PrimaryButton({required this.store});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hover = false;

  Future<void> _onTap(BuildContext context) async {
    final store = widget.store;
    switch (store.status.value) {
      case UpdateStatus.available:
        await store.download();
      case UpdateStatus.ready:
        final shouldExit = await store.launchInstaller();
        if (shouldExit) {
          await Future.delayed(const Duration(milliseconds: 300));
          exit(0);
        }
      case UpdateStatus.installed:
        final ok = await store.relaunch();
        if (ok) {
          await Future.delayed(const Duration(milliseconds: 200));
          exit(0);
        }
      case UpdateStatus.error:
        await store.check(force: true);
      case UpdateStatus.upToDate:
      case UpdateStatus.idle:
        await store.check(force: true);
      case UpdateStatus.checking:
      case UpdateStatus.downloading:
      case UpdateStatus.launching:
        break;
    }
  }

  String _label(UpdateStatus status, InstallFormat? fmt) {
    if (status == UpdateStatus.available) return t.update.btnDownload;
    if (status == UpdateStatus.downloading) return t.update.btnDownloading;
    if (status == UpdateStatus.ready) {
      return switch (fmt) {
        InstallFormat.linuxDeb || InstallFormat.linuxRpm => t.update.btnInstall,
        InstallFormat.linuxPortable => t.update.btnUpdate,
        InstallFormat.windowsInstaller => t.update.btnUpdate,
        InstallFormat.windowsPortable => t.update.btnUpdate,
        InstallFormat.macDmg => t.update.btnOpenDmg,
        _ => t.update.btnInstall,
      };
    }
    if (status == UpdateStatus.checking) return t.update.checking;
    if (status == UpdateStatus.launching) return t.update.launching;
    if (status == UpdateStatus.installed) return t.update.btnRestart;
    if (status == UpdateStatus.error) return t.update.btnRetry;
    return t.update.btnCheckNow;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final status = widget.store.status.value;
      final fmt = widget.store.installFormat.value;
      final enabled =
          status != UpdateStatus.checking &&
          status != UpdateStatus.downloading &&
          status != UpdateStatus.launching;
      final bg = !enabled
          ? AppColors.bgHover
          : _hover
          ? AppColors.accentHover
          : AppColors.accent;
      return MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: enabled ? () => _onTap(context) : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            color: bg,
            child: Text(
              _label(status, fmt),
              style: context.txt.bodyEmphasis.copyWith(
                color: AppColors.bg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _LinkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkButton({required this.label, required this.onTap});

  @override
  State<_LinkButton> createState() => _LinkButtonState();
}

class _LinkButtonState extends State<_LinkButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(
          widget.label,
          style: context.txt.muted.copyWith(
            color: _hover ? AppColors.accent : AppColors.fgMuted,
            decoration: _hover ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}
