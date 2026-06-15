class WslPath {
  final String distro;
  final String root;
  final List<String> rest;

  const WslPath({required this.distro, required this.root, required this.rest});
}

WslPath? parseWslPath(String path) {
  final s = path.replaceAll('/', r'\');
  if (!s.startsWith(r'\\')) return null;
  final body = s.substring(2);
  final slash = body.indexOf('\\');
  if (slash < 0) return null;
  final host = body.substring(0, slash);
  final lower = host.toLowerCase();
  if (lower != 'wsl.localhost' && lower != r'wsl$') return null;
  final parts = body
      .substring(slash + 1)
      .split('\\')
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return null;

  return WslPath(
    distro: parts.first,
    root: '\\\\$host\\${parts.first}',
    rest: parts.sublist(1),
  );
}
