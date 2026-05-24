import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../navigation/bookmark_store.dart';

class ConnectToServerResult {
  final String uri;
  final bool addBookmark;
  const ConnectToServerResult({required this.uri, required this.addBookmark});
}

class _FormSnapshot {
  String host = '';
  String port = '';
  String share = '';
  String path = '';
  bool addBookmark = false;
}

Future<ConnectToServerResult?> showConnectToServerDialog(
  BuildContext context,
) async {
  final snapshot = _FormSnapshot();
  final connectLabel = t.sidebar.connectDialog.connect;
  final cancelLabel = t.dialog.cancel;

  final clicked = await showCustomDialog<String>(
    context: context,
    title: t.sidebar.connectDialog.title,
    icon: WaydirIconsRegular.treeStructure,
    width: 380,
    body: _ConnectBody(snapshot: snapshot),
    actions: [
      DialogAction(label: cancelLabel, color: AppColors.fgMuted),
      DialogAction(label: connectLabel, color: AppColors.accent),
    ],
  );

  if (clicked != connectLabel) return null;
  if (snapshot.host.trim().isEmpty) return null;
  return ConnectToServerResult(
    uri: _buildUri(snapshot.host, snapshot.port, snapshot.share, snapshot.path),
    addBookmark: snapshot.addBookmark,
  );
}

Future<String?> openConnectToServer(BuildContext context) async {
  final res = await showConnectToServerDialog(context);
  if (res == null) return null;
  if (res.addBookmark) {
    await BookmarkStore.instance.addLocation(res.uri);
  }
  return res.uri;
}

String _buildUri(String host, String port, String share, String path) {
  final h = host.trim();
  final pt = port.trim();
  final sh = share.trim();
  final sub = path.trim().replaceAll(RegExp(r'^/+'), '');
  final buf = StringBuffer('smb://')..write(h);
  if (pt.isNotEmpty) {
    buf.write(':');
    buf.write(pt);
  }
  if (sh.isNotEmpty) {
    buf.write('/');
    buf.write(sh);
    if (sub.isNotEmpty) {
      buf.write('/');
      buf.write(sub);
    }
  }
  return buf.toString();
}

class _ConnectBody extends StatefulWidget {
  final _FormSnapshot snapshot;
  const _ConnectBody({required this.snapshot});

  @override
  State<_ConnectBody> createState() => _ConnectBodyState();
}

class _ConnectBodyState extends State<_ConnectBody> {
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _share;
  late final TextEditingController _path;
  bool _addBookmark = false;

  @override
  void initState() {
    super.initState();
    _host = TextEditingController(text: widget.snapshot.host)
      ..addListener(_sync);
    _port = TextEditingController(text: widget.snapshot.port)
      ..addListener(_sync);
    _share = TextEditingController(text: widget.snapshot.share)
      ..addListener(_sync);
    _path = TextEditingController(text: widget.snapshot.path)
      ..addListener(_sync);
    _addBookmark = widget.snapshot.addBookmark;
  }

  void _sync() {
    widget.snapshot.host = _host.text;
    widget.snapshot.port = _port.text;
    widget.snapshot.share = _share.text;
    widget.snapshot.path = _path.text;
    setState(() {});
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _share.dispose();
    _path.dispose();
    super.dispose();
  }

  void _toggleBookmark() {
    setState(() {
      _addBookmark = !_addBookmark;
      widget.snapshot.addBookmark = _addBookmark;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildUri(_host.text, _port.text, _share.text, _path.text);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Labeled(
                label: t.sidebar.connectDialog.host,
                child: _Input(
                  controller: _host,
                  hint: t.sidebar.connectDialog.hostHint,
                  autofocus: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _Labeled(
                label: t.sidebar.connectDialog.port,
                child: _Input(controller: _port, hint: '445'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Labeled(
          label: t.sidebar.connectDialog.share,
          child: _Input(
            controller: _share,
            hint: t.sidebar.connectDialog.shareHint,
          ),
        ),
        const SizedBox(height: 10),
        _Labeled(
          label: t.sidebar.connectDialog.pathLabel,
          child: _Input(
            controller: _path,
            hint: t.sidebar.connectDialog.pathHint,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          preview,
          style: context.txt.caption.copyWith(color: AppColors.fgMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: _toggleBookmark,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                _Checkbox(checked: _addBookmark),
                const SizedBox(width: 8),
                Text(
                  t.sidebar.connectDialog.addBookmark,
                  style: context.txt.body,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.txt.sectionLabel),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;
  const _Input({
    required this.controller,
    required this.hint,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: context.txt.body,
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          isDense: true,
          hintText: hint,
          hintStyle: context.txt.body.copyWith(color: AppColors.fgMuted),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: checked ? AppColors.accent : AppColors.bgInput,
        border: Border.all(
          color: checked ? AppColors.accent : AppColors.borderColor,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: checked
          ? Icon(Icons.check, size: 12, color: AppColors.fgAccent)
          : null,
    );
  }
}
