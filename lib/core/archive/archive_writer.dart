import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../i18n/strings.g.dart';
import '../logging/app_logger.dart';
import 'archive_reader.dart' show ArchiveReadException, ArchiveReader;

enum ArchiveFormat { zip, tar, tarGz, tarBz2, tarXz }

enum CompressionLevel { store, normal, maximum }

extension ArchiveFormatInfo on ArchiveFormat {
  String get extension => switch (this) {
    ArchiveFormat.zip => 'zip',
    ArchiveFormat.tar => 'tar',
    ArchiveFormat.tarGz => 'tar.gz',
    ArchiveFormat.tarBz2 => 'tar.bz2',
    ArchiveFormat.tarXz => 'tar.xz',
  };

  String get label => switch (this) {
    ArchiveFormat.zip => 'ZIP',
    ArchiveFormat.tar => 'TAR',
    ArchiveFormat.tarGz => 'TAR.GZ',
    ArchiveFormat.tarBz2 => 'TAR.BZ2',
    ArchiveFormat.tarXz => 'TAR.XZ',
  };
}

ArchiveFormat? archiveFormatFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
    return ArchiveFormat.tarGz;
  }
  if (lower.endsWith('.tar.bz2') ||
      lower.endsWith('.tbz2') ||
      lower.endsWith('.tbz')) {
    return ArchiveFormat.tarBz2;
  }
  if (lower.endsWith('.tar.xz') || lower.endsWith('.txz')) {
    return ArchiveFormat.tarXz;
  }
  if (lower.endsWith('.tar')) return ArchiveFormat.tar;
  if (lower.endsWith('.zip') ||
      lower.endsWith('.jar') ||
      lower.endsWith('.war') ||
      lower.endsWith('.apk') ||
      lower.endsWith('.xpi') ||
      lower.endsWith('.whl') ||
      lower.endsWith('.crx') ||
      lower.endsWith('.epub')) {
    return ArchiveFormat.zip;
  }

  return null;
}

class _PlannedEntry {
  final String absPath;
  final String archiveName;
  final bool isDir;
  final int size;
  const _PlannedEntry(this.absPath, this.archiveName, this.isDir, this.size);
}

class ArchiveWriter {
  ArchiveWriter._();

  static List<_PlannedEntry> _plan(List<String> sources) {
    final out = <_PlannedEntry>[];
    for (final src in sources) {
      final base = p.dirname(src);
      final type = FileSystemEntity.typeSync(src);
      if (type == FileSystemEntityType.notFound) continue;
      if (type == FileSystemEntityType.directory) {
        out.add(_PlannedEntry(src, p.relative(src, from: base), true, 0));
        for (final e in Directory(
          src,
        ).listSync(recursive: true, followLinks: false)) {
          final isDir = e is Directory;
          int size = 0;
          if (!isDir) {
            try {
              size = File(e.path).lengthSync();
            } catch (e, st) {
              log.warn(
                'archive',
                'failed to read file size',
                error: e,
                stack: st,
              );
              continue;
            }
          }
          out.add(
            _PlannedEntry(e.path, p.relative(e.path, from: base), isDir, size),
          );
        }
      } else {
        int size = 0;
        try {
          size = File(src).lengthSync();
        } catch (e, st) {
          log.warn(
            'archive',
            'failed to read source size',
            error: e,
            stack: st,
          );
          continue;
        }
        out.add(_PlannedEntry(src, p.relative(src, from: base), false, size));
      }
    }

    return out;
  }

  static int planCount(List<String> sources) => _plan(sources).length;

  static int planSourceBytes(List<String> sources) =>
      _plan(sources).fold(0, (sum, entry) => sum + entry.size);

  static int planWorkBytes(List<String> sources, ArchiveFormat format) {
    final planned = _plan(sources);
    final sourceBytes = planned.fold(0, (sum, entry) => sum + entry.size);

    return switch (format) {
      ArchiveFormat.zip => sourceBytes * 2,
      ArchiveFormat.tar => sourceBytes,
      ArchiveFormat.tarGz ||
      ArchiveFormat.tarBz2 ||
      ArchiveFormat.tarXz => sourceBytes + _tarSize(planned),
    };
  }

  static String _posix(String s) => p.posix.fromUri(p.toUri(s));

  static int _zipLevel(CompressionLevel level) => switch (level) {
    CompressionLevel.store => 0,
    CompressionLevel.normal => 6,
    CompressionLevel.maximum => 9,
  };

  static int _gzipLevel(CompressionLevel level) => switch (level) {
    CompressionLevel.store => 1,
    CompressionLevel.normal => 6,
    CompressionLevel.maximum => 9,
  };

  static void _streamZip(
    List<_PlannedEntry> planned,
    String destPath,
    CompressionLevel level,
    void Function(String name)? onEntry,
    void Function(String name, int bytes)? onBytes,
    bool Function()? isCancelled,
  ) {
    final levelInt = _zipLevel(level);
    final output = OutputFileStream(destPath);
    final encoder = ZipEncoder();
    encoder.startEncode(output, level: levelInt);
    var ok = false;
    try {
      for (final entry in planned) {
        if (isCancelled != null && isCancelled()) return;
        if (entry.isDir) {
          final name = _posix('${entry.archiveName}/');
          final af = ArchiveFile.directory(name);
          try {
            final stat = Directory(entry.absPath).statSync();
            af.mode = stat.mode;
            af.lastModTime = stat.modified.millisecondsSinceEpoch ~/ 1000;
          } catch (e, st) {
            log.warn(
              'archive',
              'failed to stat directory entry',
              error: e,
              stack: st,
            );
          }
          encoder.add(af);
        } else {
          final name = _posix(entry.archiveName);
          final inStream = _progressInput(
            InputFileStream(entry.absPath),
            (bytes) => onBytes?.call(entry.archiveName, bytes),
          );
          try {
            final af = ArchiveFile.stream(name, inStream);
            try {
              final stat = File(entry.absPath).statSync();
              af.mode = stat.mode;
              af.lastModTime = stat.modified.millisecondsSinceEpoch ~/ 1000;
            } catch (e, st) {
              log.warn(
                'archive',
                'failed to stat file entry',
                error: e,
                stack: st,
              );
            }
            encoder.add(af, level: levelInt);
          } finally {
            inStream.closeSync();
          }
        }
        onEntry?.call(entry.archiveName);
      }
      ok = true;
    } finally {
      try {
        encoder.endEncode();
      } catch (e, st) {
        log.warn(
          'archive',
          'failed to finish zip encoder',
          error: e,
          stack: st,
        );
      }
      try {
        output.closeSync();
      } catch (e, st) {
        log.warn('archive', 'failed to close zip output', error: e, stack: st);
      }
      if (!ok) {
        try {
          final f = File(destPath);
          if (f.existsSync()) f.deleteSync();
        } catch (e, st) {
          log.warn(
            'archive',
            'failed to remove incomplete archive',
            error: e,
            stack: st,
          );
        }
      }
    }
  }

  static void _streamTar(
    List<_PlannedEntry> planned,
    OutputFileStream output,
    void Function(String name)? onEntry,
    void Function(String name, int bytes)? onBytes,
    bool Function()? isCancelled,
  ) {
    final encoder = TarEncoder();
    encoder.start(output);
    for (final entry in planned) {
      if (isCancelled != null && isCancelled()) return;
      if (entry.isDir) {
        final name = _posix('${entry.archiveName}/');
        final af = ArchiveFile.directory(name);
        try {
          final stat = Directory(entry.absPath).statSync();
          af.mode = stat.mode;
          af.lastModTime = stat.modified.millisecondsSinceEpoch ~/ 1000;
        } catch (e, st) {
          log.warn(
            'archive',
            'failed to stat tar directory entry',
            error: e,
            stack: st,
          );
        }
        encoder.add(af);
      } else {
        final name = _posix(entry.archiveName);
        final inStream = _progressInput(
          InputFileStream(entry.absPath),
          (bytes) => onBytes?.call(entry.archiveName, bytes),
        );
        try {
          final af = ArchiveFile.stream(name, inStream);
          try {
            final stat = File(entry.absPath).statSync();
            af.mode = stat.mode;
            af.lastModTime = stat.modified.millisecondsSinceEpoch ~/ 1000;
          } catch (e, st) {
            log.warn(
              'archive',
              'failed to stat tar file entry',
              error: e,
              stack: st,
            );
          }
          encoder.add(af);
        } finally {
          inStream.closeSync();
        }
      }
      onEntry?.call(entry.archiveName);
    }
    encoder.finish();
  }

  static void create(
    List<String> sources,
    String destPath,
    ArchiveFormat format,
    CompressionLevel level, {
    void Function(String name)? onEntry,
    void Function(String label)? onPhase,
    void Function(String name, int bytes)? onBytes,
    bool Function()? isCancelled,
  }) {
    final planned = _plan(sources);

    final tmpDir = Directory(
      p.join(
        p.dirname(destPath),
        '.waydir-archive-pack-${DateTime.now().microsecondsSinceEpoch}',
      ),
    )..createSync(recursive: true);
    final stagedPath = p.join(tmpDir.path, p.basename(destPath));
    var ok = false;
    try {
      switch (format) {
        case ArchiveFormat.zip:
          _streamZip(planned, stagedPath, level, onEntry, onBytes, isCancelled);
        case ArchiveFormat.tar:
          final output = OutputFileStream(stagedPath);
          try {
            _streamTar(planned, output, onEntry, onBytes, isCancelled);
          } finally {
            try {
              output.closeSync();
            } catch (e, st) {
              log.warn(
                'archive',
                'failed to close tar output',
                error: e,
                stack: st,
              );
            }
          }
        case ArchiveFormat.tarGz:
        case ArchiveFormat.tarBz2:
        case ArchiveFormat.tarXz:
          _packTarCompressed(
            planned,
            tmpDir.path,
            stagedPath,
            format,
            level,
            onEntry,
            onPhase,
            onBytes,
            isCancelled,
          );
      }

      if (isCancelled != null && isCancelled()) return;
      File(stagedPath).renameSync(destPath);
      ok = true;
    } catch (e) {
      throw ArchiveReadException(t.errors.archiveCreateFailed(error: e));
    } finally {
      if (!ok) {
        try {
          final f = File(destPath);
          if (f.existsSync() && f.path == stagedPath) f.deleteSync();
        } catch (e, st) {
          log.warn(
            'archive',
            'failed to remove staged archive',
            error: e,
            stack: st,
          );
        }
      }
      try {
        tmpDir.deleteSync(recursive: true);
      } catch (e, st) {
        log.warn(
          'archive',
          'failed to remove archive temp dir',
          error: e,
          stack: st,
        );
      }
    }
  }

  static void _packTarCompressed(
    List<_PlannedEntry> planned,
    String tmpDirPath,
    String stagedPath,
    ArchiveFormat format,
    CompressionLevel level,
    void Function(String name)? onEntry,
    void Function(String label)? onPhase,
    void Function(String name, int bytes)? onBytes,
    bool Function()? isCancelled,
  ) {
    final tarPath = p.join(tmpDirPath, 'archive.tar');
    final tarOut = OutputFileStream(tarPath);
    try {
      _streamTar(planned, tarOut, onEntry, onBytes, isCancelled);
    } finally {
      try {
        tarOut.closeSync();
      } catch (e, st) {
        log.warn(
          'archive',
          'failed to close intermediate tar',
          error: e,
          stack: st,
        );
      }
    }
    if (isCancelled != null && isCancelled()) return;

    final phaseLabel = switch (format) {
      ArchiveFormat.tarGz => t.operations.compressingGzip,
      ArchiveFormat.tarBz2 => t.operations.compressingBzip2,
      ArchiveFormat.tarXz => t.operations.compressingXz,
      _ => t.operations.compressing,
    };
    onPhase?.call(phaseLabel);

    final input = _progressInput(
      InputFileStream(tarPath),
      (bytes) => onBytes?.call(phaseLabel, bytes),
    );
    final output = OutputFileStream(stagedPath);
    try {
      switch (format) {
        case ArchiveFormat.tarGz:
          GZipEncoder().encodeStream(input, output, level: _gzipLevel(level));
        case ArchiveFormat.tarBz2:
          BZip2Encoder().encodeStream(input, output);
        case ArchiveFormat.tarXz:
          XZEncoder().encodeStream(input, output);
        default:
          throw StateError('unreachable');
      }
    } finally {
      try {
        input.closeSync();
      } catch (e, st) {
        log.warn(
          'archive',
          'failed to close compression input',
          error: e,
          stack: st,
        );
      }
      try {
        output.closeSync();
      } catch (e, st) {
        log.warn(
          'archive',
          'failed to close compression output',
          error: e,
          stack: st,
        );
      }
      try {
        File(tarPath).deleteSync();
      } catch (e, st) {
        log.warn(
          'archive',
          'failed to delete intermediate tar',
          error: e,
          stack: st,
        );
      }
    }
  }

  static int _tarSize(List<_PlannedEntry> planned) {
    var total = 1024;
    for (final entry in planned) {
      final name = _posix(
        entry.isDir ? '${entry.archiveName}/' : entry.archiveName,
      );
      if (name.length > 100) {
        total += _tarRecordSize(name.length);
      }
      total += entry.isDir ? 512 : _tarRecordSize(entry.size);
    }

    return total;
  }

  static int _tarRecordSize(int payloadSize) {
    final blocks = (payloadSize + 511) ~/ 512;

    return 512 + blocks * 512;
  }

  static InputStream _progressInput(
    InputStream input,
    void Function(int bytes)? onBytes,
  ) {
    if (onBytes == null) return input;

    return _ProgressInputStream(input, onBytes);
  }

  static void _copyInto(String src, String destDir) {
    final type = FileSystemEntity.typeSync(src);
    final target = p.join(destDir, p.basename(src));
    if (type == FileSystemEntityType.directory) {
      Directory(target).createSync(recursive: true);
      for (final e in Directory(src).listSync(followLinks: false)) {
        _copyInto(e.path, target);
      }
    } else if (type == FileSystemEntityType.file) {
      Directory(destDir).createSync(recursive: true);
      File(src).copySync(target);
    }
  }

  static int editPlanCount(String archivePath, List<String> addSources) {
    var count = 0;
    try {
      count += ArchiveReader.listEntries(archivePath).length;
    } catch (e, st) {
      log.warn(
        'archive',
        'failed to count existing archive entries',
        error: e,
        stack: st,
      );
    }
    count += planCount(addSources);

    return count;
  }

  static void mutate(
    String archivePath, {
    List<String> addSources = const [],
    String addInner = '',
    List<String> deleteInner = const [],
    String? renameFromInner,
    String? renameToName,
    void Function(String name)? onEntry,
    void Function(String label)? onPhase,
    void Function(String name, int bytes)? onBytes,
    bool Function()? isCancelled,
  }) {
    final format = archiveFormatFromName(archivePath);
    if (format == null) {
      throw ArchiveReadException(t.errors.unsupportedArchiveFormat);
    }
    final work = Directory(
      p.join(
        p.dirname(archivePath),
        '.waydir-archive-edit-${DateTime.now().microsecondsSinceEpoch}',
      ),
    )..createSync(recursive: true);
    final tree = Directory(p.join(work.path, 'tree'))
      ..createSync(recursive: true);
    final tmpArchive = p.join(work.path, p.basename(archivePath));
    try {
      ArchiveReader.extractAll(archivePath, tree.path);

      for (final rel in deleteInner) {
        final target = p.join(tree.path, rel);
        final type = FileSystemEntity.typeSync(target);
        if (type == FileSystemEntityType.directory) {
          Directory(target).deleteSync(recursive: true);
        } else if (type != FileSystemEntityType.notFound) {
          File(target).deleteSync();
        }
      }

      if (renameFromInner != null && renameToName != null) {
        final from = p.join(tree.path, renameFromInner);
        final to = p.join(p.dirname(from), renameToName);
        final type = FileSystemEntity.typeSync(from);
        if (type == FileSystemEntityType.directory) {
          Directory(from).renameSync(to);
        } else if (type != FileSystemEntityType.notFound) {
          File(from).renameSync(to);
        }
      }

      final innerDir = addInner.isEmpty
          ? tree.path
          : p.join(tree.path, addInner);
      if (addSources.isNotEmpty) {
        Directory(innerDir).createSync(recursive: true);
        for (final s in addSources) {
          if (isCancelled != null && isCancelled()) break;
          _copyInto(s, innerDir);
        }
      }

      final roots = tree
          .listSync(followLinks: false)
          .map((e) => e.path)
          .toList();
      create(
        roots,
        tmpArchive,
        format,
        CompressionLevel.normal,
        onEntry: onEntry,
        onPhase: onPhase,
        onBytes: onBytes,
        isCancelled: isCancelled,
      );
      if (isCancelled != null && isCancelled()) return;
      try {
        File(tmpArchive).renameSync(archivePath);
      } on FileSystemException {
        File(tmpArchive).copySync(archivePath);
      }
    } finally {
      try {
        work.deleteSync(recursive: true);
      } catch (e, st) {
        log.warn(
          'archive',
          'failed to remove archive edit temp dir',
          error: e,
          stack: st,
        );
      }
    }
  }
}

class _ProgressInputStream extends InputStream {
  final InputStream _inner;
  final void Function(int bytes) _onBytes;

  _ProgressInputStream(this._inner, this._onBytes)
    : super(byteOrder: _inner.byteOrder);

  @override
  int get position => _inner.position;

  @override
  set position(int v) => _inner.position = v;

  @override
  int get length => _inner.length;

  @override
  bool get isEOS => _inner.isEOS;

  @override
  bool open() => _inner.open();

  @override
  Future<void> close() => _inner.close();

  @override
  void closeSync() => _inner.closeSync();

  @override
  void reset() => _inner.reset();

  @override
  void setPosition(int v) => _inner.setPosition(v);

  @override
  void rewind([int length = 1]) => _inner.rewind(length);

  @override
  void skip(int length) => _inner.skip(length);

  @override
  InputStream subset({int? position, int? length, int? bufferSize}) =>
      _ProgressInputStream(
        _inner.subset(
          position: position,
          length: length,
          bufferSize: bufferSize,
        ),
        _onBytes,
      );

  @override
  int readByte() {
    final hadBytes = !_inner.isEOS;
    final byte = _inner.readByte();
    if (hadBytes) _onBytes(1);

    return byte;
  }

  @override
  InputStream readBytes(int count) {
    final bytes = _inner.readBytes(count);
    final read = bytes.length;
    if (read > 0) _onBytes(read);

    return bytes;
  }

  @override
  Uint8List toUint8List([Uint8List? bytes]) {
    final out = _inner.toUint8List();
    if (out.isNotEmpty) _onBytes(out.length);

    return out;
  }
}
