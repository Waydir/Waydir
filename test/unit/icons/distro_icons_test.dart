import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/ui/icons/distro_icons.dart';

void main() {
  group('distroIconFor', () {
    test('matches common WSL distro names', () {
      expect(distroIconFor('Ubuntu'), DistroIcons.ubuntu);
      expect(distroIconFor('Ubuntu-22.04'), DistroIcons.ubuntu);
      expect(distroIconFor('Debian'), DistroIcons.debian);
      expect(distroIconFor('kali-linux'), DistroIcons.kali);
      expect(distroIconFor('Arch'), DistroIcons.archlinux);
      expect(distroIconFor('Alpine'), DistroIcons.alpine);
      expect(distroIconFor('Fedora'), DistroIcons.fedora);
      expect(distroIconFor('AlmaLinux-9'), DistroIcons.almalinux);
    });

    test('prefers specific openSUSE variants over generic', () {
      expect(distroIconFor('openSUSE-Tumbleweed'), DistroIcons.tumbleweed);
      expect(distroIconFor('openSUSE-Leap-15.5'), DistroIcons.leap);
      expect(distroIconFor('openSUSE'), DistroIcons.opensuse);
    });

    test('falls back to Tux for unknown distros', () {
      expect(distroIconFor('Pengwin'), DistroIcons.tux);
      expect(distroIconFor('my-custom-distro'), DistroIcons.tux);
    });
  });
}
