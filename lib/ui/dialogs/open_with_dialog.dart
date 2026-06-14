import 'dart:io';

import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/models/file_entry.dart';
import '../../core/logging/app_logger.dart';
import '../../core/open/open_service.dart';
import '../../i18n/strings.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/app_modal.dart';

/// Shows the "Open With" chooser for [entry]. Resolves the file type, lists
/// recommended/recent/all applications, launches the chosen one and (when
/// supported and requested) sets it as the default handler.
Future<void> showOpenWithDialog({
  required BuildContext context,
  required FileEntry entry,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _OpenWithBody(entry: entry),
      ),
    ),
  );
}

class _OpenWithBody extends StatefulWidget {
  final FileEntry entry;
  const _OpenWithBody({required this.entry});

  @override
  State<_OpenWithBody> createState() => _OpenWithBodyState();
}

class _OpenWithBodyState extends State<_OpenWithBody> {
  late Future<_LoadedOptions> _future;
  AppEntry? _selected;
  bool _setDefault = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LoadedOptions> _load() async {
    final path = widget.entry.realPath;
    OpenWithOptions options;
    try {
      options = await OpenService.optionsFor(
        path,
      ).timeout(const Duration(seconds: 10));
    } catch (e, st) {
      log.warn(
        'open-with',
        'failed to load open-with options',
        error: e,
        stack: st,
      );
      options = const OpenWithOptions(
        mime: MimeType.unknown,
        recent: [],
        associated: [],
        defaultApp: null,
        isWaydirManaged: false,
      );
    }
    List<AppEntry> all;
    try {
      all = await OpenService.allApps().timeout(const Duration(seconds: 12));
    } catch (e, st) {
      log.warn('open-with', 'failed to load app list', error: e, stack: st);
      all = const [];
    }
    _selected ??=
        options.defaultApp ??
        (options.associated.isNotEmpty
            ? options.associated.first
            : (options.recent.isNotEmpty
                  ? options.recent.first
                  : (all.isNotEmpty ? all.first : null)));

    return _LoadedOptions(options, all);
  }

  Future<void> _confirm() async {
    final app = _selected;
    if (app == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_setDefault && Platform.isLinux) {
        await OpenService.setWaydirDefault(widget.entry.realPath, app);
      }
      await OpenService.openWith(app, [widget.entry.realPath]);
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      log.error(
        'open-with',
        'failed to open selected app',
        error: e,
        stack: st,
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _error = t.openWith.failed(app: app.name);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: WaydirIconsRegular.appWindow,
      title: t.openWith.title,
      width: 460,
      padding: const EdgeInsets.all(16),
      onClose: () => Navigator.of(context).pop(),
      child: FutureBuilder<_LoadedOptions>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (!snap.hasData) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  t.openWith.noApps,
                  style: context.txt.body.copyWith(color: AppColors.fgMuted),
                ),
              ),
            );
          }

          return _content(snap.data!);
        },
      ),
    );
  }

  Widget _content(_LoadedOptions loaded) {
    final o = loaded.options;
    final sections = <Widget>[];

    void section(String title, List<AppEntry> apps) {
      if (apps.isEmpty) return;
      sections.add(_SectionHeader(title));
      for (final a in apps) {
        sections.add(
          _AppTile(
            app: a,
            selected: _selected == a,
            onTap: () => setState(() => _selected = a),
            onDoubleTap: () => _confirm(),
          ),
        );
      }
    }

    section(t.openWith.recent, o.recent);
    section(t.openWith.recommended, o.associated);
    // Avoid listing apps already shown above.
    final shownIds = {
      ...o.recent.map((e) => e.id),
      ...o.associated.map((e) => e.id),
    };
    section(
      t.openWith.allApps,
      loaded.all.where((a) => !shownIds.contains(a.id)).toList(),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.openWith.subtitle(name: widget.entry.name),
          style: context.txt.captionSmall.copyWith(color: AppColors.fgMuted),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),
        Flexible(
          child: o.isEmpty && sections.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    t.openWith.noApps,
                    style: context.txt.body.copyWith(color: AppColors.fgMuted),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: sections,
                  ),
                ),
        ),
        if (Platform.isLinux) ...[
          const SizedBox(height: 12),
          _DefaultCheckbox(
            value: _setDefault,
            enabled: true,
            label: t.openWith.setDefault,
            onChanged: (v) => setState(() => _setDefault = v),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: context.txt.captionSmall.copyWith(color: AppColors.danger),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _TextButton(
              label: t.dialog.cancel,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            _PrimaryButton(
              label: t.openWith.open,
              enabled: _selected != null && !_busy,
              onTap: () => _confirm(),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoadedOptions {
  final OpenWithOptions options;
  final List<AppEntry> all;
  const _LoadedOptions(this.options, this.all);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4, left: 4),
      child: Text(
        title.toUpperCase(),
        style: context.txt.captionSmall.copyWith(
          color: AppColors.fgMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _AppTile extends StatefulWidget {
  final AppEntry app;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _AppTile({
    required this.app,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  State<_AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<_AppTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.accent.withValues(alpha: 0.18)
        : _hovered
        ? AppColors.bgHoverStrong
        : Colors.transparent;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero),
          child: Row(
            children: [
              AppIcon(path: widget.app.iconPath, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.app.name,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.body,
                ),
              ),
              if (widget.app.isDefault)
                Text(
                  t.openWith.recommended.split(' ').first,
                  style: context.txt.captionSmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultCheckbox extends StatelessWidget {
  final bool value;
  final bool enabled;
  final String label;
  final ValueChanged<bool> onChanged;

  const _DefaultCheckbox({
    required this.value,
    required this.enabled,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.fg : AppColors.fgMuted;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value && enabled ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: value && enabled
                      ? AppColors.accent
                      : AppColors.borderColor,
                ),
              ),
              child: value && enabled
                  ? const Icon(
                      WaydirIconsBold.check,
                      size: 11,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: context.txt.body.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _TextButton({required this.label, required this.onTap});

  @override
  State<_TextButton> createState() => _TextButtonState();
}

class _TextButtonState extends State<_TextButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHoverStrong : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Text(widget.label, style: context.txt.body),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered && enabled
                  ? AppColors.accent.withValues(alpha: 0.18)
                  : AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.accent),
            ),
            child: Text(
              widget.label,
              style: context.txt.rowEmphasis.copyWith(color: AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }
}
