import 'dart:io' show Platform, Process, ProcessStartMode;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_modal.dart';

Future<void> showChangelogDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const _ChangelogDialog(),
  );
}

void _openLink(String url) {
  final cmd = Platform.isWindows
      ? 'explorer'
      : Platform.isMacOS
      ? 'open'
      : 'xdg-open';
  Process.start(cmd, [url], mode: ProcessStartMode.detached);
}

class _ChangelogDialog extends StatelessWidget {
  const _ChangelogDialog();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.clamp(620.0, 860.0).toDouble();
    final height = (size.height * 0.86).clamp(480.0, 760.0).toDouble();

    return AppModal(
      icon: WaydirIconsRegular.notebook,
      title: t.changelog.title,
      width: width,
      height: height,
      onClose: () => Navigator.of(context).pop(),
      child: FutureBuilder<String>(
        future: rootBundle.loadString('CHANGELOG.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Text(t.changelog.loadError, style: context.txt.bodyMuted),
            );
          }
          return _ChangelogMarkdown(data: snapshot.data!);
        },
      ),
    );
  }
}

class _ChangelogMarkdown extends StatelessWidget {
  final String data;

  const _ChangelogMarkdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final base = context.txt.bodyMuted.copyWith(height: 1.45);
    final emphasis = context.txt.bodyEmphasis.copyWith(height: 1.45);
    final mono = context.txt.keyCap.copyWith(
      color: AppColors.fg,
      backgroundColor: AppColors.bgInput,
    );
    final h1 = context.txt.dialogTitle.copyWith(color: AppColors.fg);
    final h2 = context.txt.heading.copyWith(color: AppColors.fg);
    final h3 = context.txt.bodyEmphasis.copyWith(color: AppColors.fgMuted);

    return Markdown(
      data: data,
      selectable: true,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      onTapLink: (text, href, title) {
        if (href != null) _openLink(href);
      },
      styleSheet: MarkdownStyleSheet(
        p: base,
        listBullet: base,
        strong: emphasis,
        em: base.copyWith(fontStyle: FontStyle.italic),
        code: mono,
        a: base.copyWith(color: AppColors.accent),
        h1: h1,
        h2: h2,
        h3: h3,
        h1Padding: const EdgeInsets.only(top: 4, bottom: 4),
        h2Padding: const EdgeInsets.only(top: 16, bottom: 4),
        h3Padding: const EdgeInsets.only(top: 10, bottom: 2),
        blockSpacing: 8,
      ),
    );
  }
}
