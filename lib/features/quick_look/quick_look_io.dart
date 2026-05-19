import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';

import '../../core/models/file_entry.dart';
import '../../i18n/strings.g.dart';
import 'quick_look_common.dart';

typedef QlSection = ({String title, List<MapEntry<String, String>> rows});

class FolderStats {
  final int bytes;
  final int items;
  final bool done;

  const FolderStats(this.bytes, this.items, {required this.done});
}

enum QlKind { text, binary, tooLarge, error }

class Probe {
  final QlKind kind;
  final String text;
  final String? note;

  const Probe(this.kind, {this.text = '', this.note});
}

Future<Uint8List> readHead(String path, int maxBytes) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in File(path).openRead(0, maxBytes)) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}

Future<QlSection?> imageInfo(FileEntry e) async {
  if (e.type == FileItemType.folder) return null;
  if (!imageExts.contains(e.extension)) return null;
  final rows = <MapEntry<String, String>>[];
  try {
    final bytes = await readHead(e.realPath, 512 * 1024);
    final tags = await readExifFromBytes(bytes);
    String? tag(String k) {
      final v = tags[k]?.printable.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    final w = tag('EXIF ExifImageWidth') ?? tag('Image ImageWidth');
    final h = tag('EXIF ExifImageLength') ?? tag('Image ImageLength');
    if (w != null && h != null) {
      rows.add(MapEntry(t.quickLook.dimensions, '$w × $h'));
    }
    final make = tag('Image Make');
    final model = tag('Image Model');
    final cam = [make, model].whereType<String>().join(' ');
    if (cam.isNotEmpty) rows.add(MapEntry(t.quickLook.camera, cam));
    final lens = tag('EXIF LensModel');
    if (lens != null) rows.add(MapEntry(t.quickLook.lens, lens));
    final exp = tag('EXIF ExposureTime');
    if (exp != null) rows.add(MapEntry(t.quickLook.exposure, '$exp s'));
    final fnum = tag('EXIF FNumber');
    if (fnum != null) rows.add(MapEntry(t.quickLook.aperture, 'f/$fnum'));
    final iso = tag('EXIF ISOSpeedRatings');
    if (iso != null) rows.add(MapEntry(t.quickLook.iso, iso));
    final fl = tag('EXIF FocalLength');
    if (fl != null) rows.add(MapEntry(t.quickLook.focalLength, '$fl mm'));
    final dt = tag('EXIF DateTimeOriginal');
    if (dt != null) rows.add(MapEntry(t.quickLook.dateTaken, dt));
  } catch (_) {
    return null;
  }
  if (rows.isEmpty) return null;
  return (title: t.quickLook.sectionImage, rows: rows);
}

Future<Probe> probeFile(FileEntry entry) async {
  try {
    final file = File(entry.realPath);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, maxTextBytes + 1)) {
      builder.add(chunk);
      if (builder.length > maxTextBytes) break;
    }
    final bytes = builder.takeBytes();
    if (bytes.length > maxTextBytes) {
      return Probe(QlKind.tooLarge, note: t.quickLook.tooLarge);
    }
    final scanLen = bytes.length > 8000 ? 8000 : bytes.length;
    var suspicious = 0;
    for (var i = 0; i < scanLen; i++) {
      final b = bytes[i];
      if (b == 0) return const Probe(QlKind.binary);
      if (b < 9 || (b > 13 && b < 32) || b == 127) suspicious++;
    }
    if (scanLen > 0 && suspicious / scanLen > 0.1) {
      return const Probe(QlKind.binary);
    }
    return Probe(QlKind.text, text: utf8.decode(bytes, allowMalformed: true));
  } catch (_) {
    return Probe(QlKind.error, note: t.quickLook.readError);
  }
}
