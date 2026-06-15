// Codepoints from font-logos (Unlicense / public domain).
// See third_party/font-logos/LICENSE. Base codepoint 0xF300 + glyph offset.
// Brand colors are the distributions' own; font-logos glyphs are monochrome,
// so each logo renders as a single tint.

import 'package:flutter/widgets.dart';

class DistroIcons {
  const DistroIcons();

  static const String _family = 'DistroLogos';

  static const IconData tux = IconData(0xF31A, fontFamily: _family);
  static const IconData alpine = IconData(0xF300, fontFamily: _family);
  static const IconData archlinux = IconData(0xF303, fontFamily: _family);
  static const IconData centos = IconData(0xF304, fontFamily: _family);
  static const IconData debian = IconData(0xF306, fontFamily: _family);
  static const IconData devuan = IconData(0xF307, fontFamily: _family);
  static const IconData docker = IconData(0xF308, fontFamily: _family);
  static const IconData fedora = IconData(0xF30A, fontFamily: _family);
  static const IconData gentoo = IconData(0xF30D, fontFamily: _family);
  static const IconData linuxmint = IconData(0xF30E, fontFamily: _family);
  static const IconData manjaro = IconData(0xF312, fontFamily: _family);
  static const IconData nixos = IconData(0xF313, fontFamily: _family);
  static const IconData opensuse = IconData(0xF314, fontFamily: _family);
  static const IconData redhat = IconData(0xF316, fontFamily: _family);
  static const IconData slackware = IconData(0xF318, fontFamily: _family);
  static const IconData ubuntu = IconData(0xF31B, fontFamily: _family);
  static const IconData almalinux = IconData(0xF31D, fontFamily: _family);
  static const IconData kali = IconData(0xF327, fontFamily: _family);
  static const IconData parrot = IconData(0xF329, fontFamily: _family);
  static const IconData popOs = IconData(0xF32A, fontFamily: _family);
  static const IconData rocky = IconData(0xF32B, fontFamily: _family);
  static const IconData voidLinux = IconData(0xF32E, fontFamily: _family);
  static const IconData mxlinux = IconData(0xF33F, fontFamily: _family);
  static const IconData tumbleweed = IconData(0xF37D, fontFamily: _family);
  static const IconData leap = IconData(0xF37E, fontFamily: _family);
}

class _Distro {
  final String keyword;
  final IconData icon;
  final Color? color;

  const _Distro(this.keyword, this.icon, [this.color]);
}

const List<_Distro> _distros = [
  _Distro('tumbleweed', DistroIcons.tumbleweed, Color(0xFF73BA25)),
  _Distro('leap', DistroIcons.leap, Color(0xFF73BA25)),
  _Distro('kali', DistroIcons.kali, Color(0xFF557C94)),
  _Distro('alma', DistroIcons.almalinux, Color(0xFF0F4266)),
  _Distro('rocky', DistroIcons.rocky, Color(0xFF10B981)),
  _Distro('pop', DistroIcons.popOs, Color(0xFF48B9C7)),
  _Distro('mxlinux', DistroIcons.mxlinux),
  _Distro('manjaro', DistroIcons.manjaro, Color(0xFF35BF5C)),
  _Distro('mint', DistroIcons.linuxmint, Color(0xFF87CF3E)),
  _Distro('parrot', DistroIcons.parrot, Color(0xFF15E0C8)),
  _Distro('nix', DistroIcons.nixos, Color(0xFF5277C3)),
  _Distro('void', DistroIcons.voidLinux, Color(0xFF478061)),
  _Distro('devuan', DistroIcons.devuan, Color(0xFF5C4499)),
  _Distro('gentoo', DistroIcons.gentoo, Color(0xFF54487A)),
  _Distro('slackware', DistroIcons.slackware),
  _Distro('centos', DistroIcons.centos, Color(0xFF932279)),
  _Distro('redhat', DistroIcons.redhat, Color(0xFFEE0000)),
  _Distro('rhel', DistroIcons.redhat, Color(0xFFEE0000)),
  _Distro('fedora', DistroIcons.fedora, Color(0xFF3C6EB4)),
  _Distro('suse', DistroIcons.opensuse, Color(0xFF73BA25)),
  _Distro('arch', DistroIcons.archlinux, Color(0xFF1793D1)),
  _Distro('alpine', DistroIcons.alpine, Color(0xFF0D597F)),
  _Distro('debian', DistroIcons.debian, Color(0xFFA81D33)),
  _Distro('ubuntu', DistroIcons.ubuntu, Color(0xFFE95420)),
  _Distro('docker', DistroIcons.docker, Color(0xFF2496ED)),
];

_Distro? _match(String name) {
  final lower = name.toLowerCase();
  for (final d in _distros) {
    if (lower.contains(d.keyword)) return d;
  }

  return null;
}

IconData distroIconFor(String name) => _match(name)?.icon ?? DistroIcons.tux;

Color? distroColorFor(String name) => _match(name)?.color;
