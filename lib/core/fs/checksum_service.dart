import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';

enum ChecksumAlgorithm {
  md5,
  sha256;

  String get label {
    return switch (this) {
      ChecksumAlgorithm.md5 => 'MD5',
      ChecksumAlgorithm.sha256 => 'SHA-256',
    };
  }

  int get hexLength {
    return switch (this) {
      ChecksumAlgorithm.md5 => 32,
      ChecksumAlgorithm.sha256 => 64,
    };
  }
}

class ChecksumResult {
  final ChecksumAlgorithm algorithm;
  final String digest;
  final int bytes;

  const ChecksumResult({
    required this.algorithm,
    required this.digest,
    required this.bytes,
  });
}

class ChecksumService {
  static String normalizeExpected(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s:-]'), '');
  }

  static bool isExpectedFormatValid(ChecksumAlgorithm algorithm, String value) {
    final normalized = normalizeExpected(value);
    if (normalized.length != algorithm.hexLength) return false;

    return RegExp(r'^[0-9a-f]+$').hasMatch(normalized);
  }

  static bool matches({
    required ChecksumAlgorithm algorithm,
    required String expected,
    required String actual,
  }) {
    if (!isExpectedFormatValid(algorithm, expected)) return false;

    return normalizeExpected(expected) == actual.toLowerCase();
  }

  static Future<ChecksumResult> calculate(
    String path,
    ChecksumAlgorithm algorithm,
  ) {
    return Isolate.run(() => _calculateInIsolate(path, algorithm));
  }
}

Future<ChecksumResult> _calculateInIsolate(
  String path,
  ChecksumAlgorithm algorithm,
) async {
  final file = File(path);
  final output = _DigestResultSink();
  final input = switch (algorithm) {
    ChecksumAlgorithm.md5 => md5.startChunkedConversion(output),
    ChecksumAlgorithm.sha256 => sha256.startChunkedConversion(output),
  };
  var bytes = 0;
  await for (final chunk in file.openRead()) {
    bytes += chunk.length;
    input.add(chunk);
  }
  input.close();

  return ChecksumResult(
    algorithm: algorithm,
    digest: output.value.toString(),
    bytes: bytes,
  );
}

class _DigestResultSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) {
    _value = data;
  }

  @override
  void close() {}
}
