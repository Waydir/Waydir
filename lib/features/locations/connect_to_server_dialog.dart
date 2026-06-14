import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_text_field.dart';
import '../../ui/widgets/app_toggle_chip.dart';

enum ConnectProtocol { smb, sftp }

class _FormSnapshot {
  ConnectProtocol protocol = ConnectProtocol.smb;
  String username = '';
  String host = '';
  String port = '';
  String share = '';
  String path = '';
}

Future<String?> showConnectToServerDialog(BuildContext context) async {
  final snapshot = _FormSnapshot();
  final connectLabel = t.sidebar.connectDialog.connect;
  final cancelLabel = t.dialog.cancel;

  final clicked = await showCustomDialog<String>(
    context: context,
    title: t.sidebar.connectDialog.title,
    icon: WaydirIconsRegular.treeStructure,
    width: 400,
    body: _ConnectBody(snapshot: snapshot),
    actions: [
      DialogAction(label: cancelLabel, color: AppColors.fgMuted),
      DialogAction(label: connectLabel, color: AppColors.accent),
    ],
  );

  if (clicked != connectLabel) return null;
  if (snapshot.host.trim().isEmpty) return null;

  return _buildUri(
    snapshot.protocol,
    snapshot.username,
    snapshot.host,
    snapshot.port,
    snapshot.share,
    snapshot.path,
  );
}

Future<String?> openConnectToServer(BuildContext context) async {
  return showConnectToServerDialog(context);
}

String _buildUri(
  ConnectProtocol protocol,
  String username,
  String host,
  String port,
  String share,
  String path,
) {
  final user = username.trim();
  final h = host.trim();
  final pt = port.trim();
  final sh = share.trim();
  final sub = path.trim().replaceAll(RegExp(r'^/+'), '');
  final scheme = protocol == ConnectProtocol.sftp ? 'sftp://' : 'smb://';
  final buf = StringBuffer(scheme);
  if (user.isNotEmpty) {
    buf.write(Uri.encodeComponent(user));
    buf.write('@');
  }
  buf.write(h);
  if (pt.isNotEmpty) {
    buf.write(':');
    buf.write(pt);
  }
  if (protocol == ConnectProtocol.sftp) {
    if (sub.isNotEmpty) {
      buf.write('/');
      buf.write(sub);
    }
  } else {
    if (sh.isNotEmpty) {
      buf.write('/');
      buf.write(sh);
      if (sub.isNotEmpty) {
        buf.write('/');
        buf.write(sub);
      }
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
  late final TextEditingController _username;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _share;
  late final TextEditingController _path;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.snapshot.username)
      ..addListener(_sync);
    _host = TextEditingController(text: widget.snapshot.host)
      ..addListener(_sync);
    _port = TextEditingController(text: widget.snapshot.port)
      ..addListener(_sync);
    _share = TextEditingController(text: widget.snapshot.share)
      ..addListener(_sync);
    _path = TextEditingController(text: widget.snapshot.path)
      ..addListener(_sync);
  }

  void _sync() {
    widget.snapshot.username = _username.text;
    widget.snapshot.host = _host.text;
    widget.snapshot.port = _port.text;
    widget.snapshot.share = _share.text;
    widget.snapshot.path = _path.text;
    setState(() {});
  }

  void _selectProtocol(ConnectProtocol p) {
    setState(() {
      widget.snapshot.protocol = p;
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _host.dispose();
    _port.dispose();
    _share.dispose();
    _path.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _buildUri(
      widget.snapshot.protocol,
      _username.text,
      _host.text,
      _port.text,
      _share.text,
      _path.text,
    );
    final isSftp = widget.snapshot.protocol == ConnectProtocol.sftp;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppToggleChip(
                label: 'SMB',
                selected: !isSftp,
                onTap: () => _selectProtocol(ConnectProtocol.smb),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppToggleChip(
                label: 'SFTP',
                selected: isSftp,
                onTap: () => _selectProtocol(ConnectProtocol.sftp),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _Labeled(
                label: t.sidebar.connectDialog.host,
                child: AppTextField(
                  controller: _host,
                  hintText: t.sidebar.connectDialog.hostHint,
                  autofocus: true,
                  height: 34,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: _Labeled(
                label: t.sidebar.connectDialog.port,
                child: AppTextField(
                  controller: _port,
                  hintText: isSftp ? '22' : '445',
                  height: 34,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Labeled(
          label: t.sidebar.connectDialog.username,
          child: AppTextField(
            controller: _username,
            hintText: t.sidebar.connectDialog.usernameHint,
            height: 34,
          ),
        ),
        if (!isSftp) ...[
          const SizedBox(height: 10),
          _Labeled(
            label: t.sidebar.connectDialog.share,
            child: AppTextField(
              controller: _share,
              hintText: t.sidebar.connectDialog.shareHint,
              height: 34,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _Labeled(
          label: t.sidebar.connectDialog.pathLabel,
          child: AppTextField(
            controller: _path,
            hintText: isSftp ? '/home/user' : t.sidebar.connectDialog.pathHint,
            height: 34,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          preview,
          style: context.txt.caption.copyWith(color: AppColors.fgMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
