import 'dart:io';

import 'package:path/path.dart' as p;

import 'app_entry.dart';

/// Linux-only fallback: when `xdg-mime` resolves no default handler, pick a
/// well-known app that is typical for the file's category and actually on
/// PATH, so opening still lands in a concrete, named application.
///
/// Windows and macOS defer entirely to the OS, so they need no table here.
class TypicalApps {
  TypicalApps._();

  static AppEntry? forPath(String path) {
    if (!Platform.isLinux) return null;
    final cat = _categoryFor(p.extension(path).toLowerCase());
    if (cat == null) return null;
    for (final entry in (_linux[cat] ?? const <MapEntry<String, String>>[])) {
      if (_whichOnPath(entry.key) != null) {
        return AppEntry(
          id: entry.key,
          name: entry.value,
          exec: '${entry.key} %f',
          isDefault: true,
        );
      }
    }

    return null;
  }

  static _Category? _categoryFor(String ext) {
    final e = ext.startsWith('.') ? ext.substring(1) : ext;
    if (_image.contains(e)) return _Category.image;
    if (_video.contains(e)) return _Category.video;
    if (_audio.contains(e)) return _Category.audio;
    if (e == 'pdf') return _Category.pdf;
    if (_editor.contains(e)) return _Category.editor;

    return null;
  }

  static const _image = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'webp',
    'tiff',
    'tif',
    'ico',
    'heic',
    'svg',
  };
  static const _video = {
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'wmv',
    'flv',
    'm4v',
    'mpg',
    'mpeg',
  };
  static const _audio = {
    'mp3',
    'wav',
    'flac',
    'ogg',
    'm4a',
    'aac',
    'wma',
    'opus',
  };
  static const _editor = {
    'txt',
    'md',
    'log',
    'csv',
    'json',
    'xml',
    'yaml',
    'yml',
    'ini',
    'cfg',
    'conf',
    'dart',
    'js',
    'ts',
    'py',
    'c',
    'cpp',
    'h',
    'hpp',
    'java',
    'rs',
    'go',
    'rb',
    'sh',
    'html',
    'css',
  };

  static const _linux = <_Category, List<MapEntry<String, String>>>{
    _Category.image: [
      MapEntry('eog', 'Image Viewer'),
      MapEntry('gwenview', 'Gwenview'),
      MapEntry('gthumb', 'gThumb'),
      MapEntry('feh', 'feh'),
    ],
    _Category.video: [
      MapEntry('vlc', 'VLC'),
      MapEntry('mpv', 'mpv'),
      MapEntry('totem', 'Videos'),
    ],
    _Category.audio: [
      MapEntry('vlc', 'VLC'),
      MapEntry('mpv', 'mpv'),
      MapEntry('rhythmbox', 'Rhythmbox'),
    ],
    _Category.pdf: [
      MapEntry('evince', 'Document Viewer'),
      MapEntry('okular', 'Okular'),
      MapEntry('xpdf', 'xpdf'),
    ],
    _Category.editor: [
      MapEntry('gnome-text-editor', 'Text Editor'),
      MapEntry('gedit', 'gedit'),
      MapEntry('kate', 'Kate'),
      MapEntry('mousepad', 'Mousepad'),
    ],
  };
}

enum _Category { image, video, audio, pdf, editor }

String? _whichOnPath(String cmd) {
  final pathEnv = Platform.environment['PATH'];
  if (pathEnv == null) return null;
  for (final dir in pathEnv.split(':')) {
    if (dir.isEmpty) continue;
    final f = p.join(dir, cmd);
    if (File(f).existsSync()) return f;
  }

  return null;
}
