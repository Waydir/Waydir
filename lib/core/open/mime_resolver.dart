import 'dart:io';

import 'package:mime/mime.dart' as mime_pkg;

import '../logging/app_logger.dart';

/// A resolved content type for a file.
///
/// On Linux/Windows [value] is a MIME type (e.g. `image/png`). On macOS it is
/// a Uniform Type Identifier (e.g. `public.png`) since that is what Launch
/// Services keys on; [isUti] disambiguates.
class MimeType {
  final String value;
  final bool isUti;

  const MimeType(this.value, {this.isUti = false});

  static const unknown = MimeType('application/octet-stream');

  bool get isUnknown => value == unknown.value || value.isEmpty;

  @override
  String toString() => value;
}

/// Resolves a file path to its content type using the most authoritative
/// source available on the platform, falling back to extension-based lookup.
abstract class MimeResolver {
  Future<MimeType> resolve(String path);

  factory MimeResolver.platform() {
    if (Platform.isLinux) return _LinuxMimeResolver();
    if (Platform.isMacOS) return _MacMimeResolver();

    return _FallbackMimeResolver();
  }
}

MimeType _fromExtension(String path) {
  final m = mime_pkg.lookupMimeType(path);

  return m == null ? MimeType.unknown : MimeType(m);
}

class _FallbackMimeResolver implements MimeResolver {
  @override
  Future<MimeType> resolve(String path) async => _fromExtension(path);
}

class _LinuxMimeResolver implements MimeResolver {
  @override
  Future<MimeType> resolve(String path) async {
    try {
      final r = await Process.run('xdg-mime', ['query', 'filetype', path]);
      if (r.exitCode == 0) {
        final out = (r.stdout as String).trim();
        if (out.isNotEmpty) return MimeType(out);
      }
    } catch (e, st) {
      log.warn('open', 'linux MIME lookup failed', error: e, stack: st);
    }

    return _fromExtension(path);
  }
}

class _MacMimeResolver implements MimeResolver {
  @override
  Future<MimeType> resolve(String path) async {
    try {
      final r = await Process.run('mdls', [
        '-name',
        'kMDItemContentType',
        '-raw',
        path,
      ]);
      if (r.exitCode == 0) {
        final out = (r.stdout as String).trim();
        if (out.isNotEmpty && out != '(null)') {
          return MimeType(out, isUti: true);
        }
      }
    } catch (e, st) {
      log.warn('open', 'mac MIME lookup failed', error: e, stack: st);
    }

    return _fromExtension(path);
  }
}
