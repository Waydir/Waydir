import 'dart:convert';

import 'package:http/http.dart' as http;

class GithubAsset {
  final String name;
  final String downloadUrl;
  final int sizeBytes;

  GithubAsset({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
  });

  factory GithubAsset.fromJson(Map<String, dynamic> json) {
    return GithubAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      sizeBytes: (json['size'] as num?)?.toInt() ?? 0,
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

  Uri get _base => Uri.parse('https://api.github.com/repos/$owner/$repo');

  Map<String, String> get _headers => const {
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'User-Agent': 'waydir-update-checker',
  };

  /// Returns the most recent stable (non-prerelease) release, or null if
  /// none exist. Uses `/releases?per_page=10` and filters locally instead
  /// of `/releases/latest`, since the latter can return prereleases on
  /// repos that have only ever published prereleases.
  Future<GithubRelease?> latestStable() async {
    final res = await _http.get(
      _base.replace(path: '${_base.path}/releases', queryParameters: {
        'per_page': '10',
      }),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw GithubReleasesException(
        'GitHub API ${res.statusCode}: ${res.reasonPhrase ?? ''}',
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
