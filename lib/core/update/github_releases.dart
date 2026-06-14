import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;

import '../../i18n/strings.g.dart';

class GithubAsset {
  final String name;
  final String downloadUrl;
  final int sizeBytes;
  final String digest;

  GithubAsset({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.digest,
  });

  factory GithubAsset.fromJson(Map<String, dynamic> json) {
    return GithubAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      sizeBytes: (json['size'] as num?)?.toInt() ?? 0,
      digest: json['digest'] as String? ?? '',
    );
  }
}

class GithubRelease {
  final String tag;
  final String version;
  final String name;
  final String body;
  final bool prerelease;
  final DateTime publishedAt;
  final List<GithubAsset> assets;
  final String htmlUrl;

  GithubRelease({
    required this.tag,
    required this.version,
    required this.name,
    required this.body,
    required this.prerelease,
    required this.publishedAt,
    required this.assets,
    required this.htmlUrl,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    return GithubRelease(
      tag: tag,
      version: _stripV(tag),
      name: json['name'] as String? ?? tag,
      body: json['body'] as String? ?? '',
      prerelease: json['prerelease'] as bool? ?? false,
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      assets:
          (json['assets'] as List?)
              ?.cast<Map<String, dynamic>>()
              .map(GithubAsset.fromJson)
              .toList() ??
          const [],
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }

  static String _stripV(String tag) {
    if (tag.startsWith('v') || tag.startsWith('V')) return tag.substring(1);
    return tag;
  }
}

class GithubReleasesClient {
  final String owner;
  final String repo;
  final http.Client _http;

  GithubReleasesClient({
    required this.owner,
    required this.repo,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  static String get _apiOrigin {
    const compiled = String.fromEnvironment('WAYDIR_GITHUB_API_BASE');
    if (compiled.isNotEmpty) return _stripTrailingSlash(compiled);
    final env = Platform.environment['WAYDIR_GITHUB_API_BASE'];
    if (env != null && env.isNotEmpty) return _stripTrailingSlash(env);
    return 'https://api.github.com';
  }

  static String _stripTrailingSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  Uri get _base => Uri.parse('$_apiOrigin/repos/$owner/$repo');

  Map<String, String> get _headers => const {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'waydir-update-checker',
  };

  Future<GithubRelease?> latestStable() async {
    final res = await _http.get(
      _base.replace(
        path: '${_base.path}/releases',
        queryParameters: {'per_page': '10'},
      ),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw GithubReleasesException(
        t.update.githubApiError(
          statusCode: res.statusCode,
          reason: res.reasonPhrase ?? '',
        ),
      );
    }
    final list = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    for (final j in list) {
      final r = GithubRelease.fromJson(j);
      if (!r.prerelease) return r;
    }
    return null;
  }

  void dispose() => _http.close();
}

class GithubReleasesException implements Exception {
  final String message;
  GithubReleasesException(this.message);
  @override
  String toString() => message;
}
