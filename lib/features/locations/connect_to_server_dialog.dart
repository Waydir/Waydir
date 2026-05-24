import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';

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
              child: _ProtocolChip(
                label: 'SMB',
                selected: !isSftp,
                onTap: () => _selectProtocol(ConnectProtocol.smb),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ProtocolChip(
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
                child: _Input(
                  controller: _port,
                  hint: isSftp ? '22' : '445',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Labeled(
          label: t.sidebar.connectDialog.username,
          child: _Input(
            controller: _username,
            hint: t.sidebar.connectDialog.usernameHint,
          ),
        ),
        if (!isSftp) ...[
          const SizedBox(height: 10),
          _Labeled(
            label: t.sidebar.connectDialog.share,
            child: _Input(
              controller: _share,
              hint: t.sidebar.connectDialog.shareHint,
            ),
          ),
        ],
        const SizedBox(height: 10),
        _Labeled(
          label: t.sidebar.connectDialog.pathLabel,
          child: _Input(
            controller: _path,
            hint: isSftp ? '/home/user' : t.sidebar.connectDialog.pathHint,
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

class _ProtocolChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ProtocolChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bgInput,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: context.txt.body.copyWith(
            color: selected ? AppColors.bg : AppColors.fg,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
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
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: context.txt.body,
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.bgInput,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          hintText: hint,
          hintStyle: context.txt.body.copyWith(color: AppColors.fgMuted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}
