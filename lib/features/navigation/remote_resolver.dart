import 'dart:io';

import '../../core/fs/smb_share_discovery.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../locations/location_resolver.dart';
import '../locations/location_uri.dart';

class RemoteResolver {
  final Future<SmbCredentials?> Function(String logical) requestSmbCredentials;
  final Future<SftpCredentials?> Function(String logical)
  requestSftpCredentials;
  final void Function(String message) setLoadError;

  const RemoteResolver({
    required this.requestSmbCredentials,
    required this.requestSftpCredentials,
    required this.setLoadError,
  });

  String physical(String path) {
    return LocationResolver.logicalToPhysical(path) ?? path;
  }

  List<String> physicalList(Iterable<String> paths) {
    return paths.map(physical).toList();
  }

  Future<String?> resolvePhysicalDestination(String logical) async {
    if (PlatformPaths.isSftpUri(logical)) {
      final result = await resolveSftp(logical);
      switch (result) {
        case ResolveSuccess():
          return result.physicalPath;
        case ResolveError(:final message):
          setLoadError(message);

          return null;
        case ResolveUnsupported():
          setLoadError(t.errors.sftpNotSupported);

          return null;
        case ResolveAuthenticationRequired():
          setLoadError(t.errors.authenticationRequired);

          return null;
      }
    }
    if (!PlatformPaths.isSmbUri(logical)) return logical;
    final existing = LocationResolver.logicalToPhysical(logical);
    if (existing != null) return existing;
    final result = await resolveSmb(logical);
    switch (result) {
      case ResolveSuccess():
        return result.physicalPath;
      case ResolveError(:final message):
        setLoadError(message);

        return null;
      case ResolveUnsupported():
        setLoadError(t.errors.smbNotSupportedOnPlatform);

        return null;
      case ResolveAuthenticationRequired():
        setLoadError(t.errors.authenticationRequired);

        return null;
    }
  }

  Future<ResolveResult> resolveSmb(String logical) async {
    final result = await LocationResolver.resolve(logical);
    if (result is! ResolveAuthenticationRequired) return result;
    final credentials = await requestSmbCredentials(logical);
    if (credentials == null ||
        credentials.username.trim().isEmpty ||
        credentials.password.isEmpty) {
      return result;
    }

    return LocationResolver.resolveWithCredentials(logical, credentials);
  }

  Future<ResolveResult> resolveSftp(String logical) async {
    final result = await LocationResolver.resolve(logical);
    if (result is! ResolveAuthenticationRequired) return result;
    final credentials = await requestSftpCredentials(logical);
    if (credentials == null || credentials.username.trim().isEmpty) {
      return result;
    }

    return LocationResolver.resolveSftpWithCredentials(logical, credentials);
  }

  Future<List<FileEntry>> listSmbHostShares(
    String logical,
    LocationUri uri,
  ) async {
    final host = uri.host ?? '';
    if (host.isEmpty) {
      throw FileSystemException(t.errors.missingSmbHost, logical);
    }
    SmbShareListResult result = await SmbShareDiscovery.list(
      host: host,
      port: uri.port,
      credentials: uri.username != null && uri.username!.isNotEmpty
          ? SmbCredentials(username: uri.username!, password: '')
          : null,
    );
    if (result is SmbShareListAuthRequired) {
      final credentials = await requestSmbCredentials(logical);
      if (credentials != null &&
          credentials.username.trim().isNotEmpty &&
          credentials.password.isNotEmpty) {
        result = await SmbShareDiscovery.list(
          host: host,
          port: uri.port,
          credentials: credentials,
        );
      }
    }

    return _shareEntries(result, logical, (share) => '$logical/$share');
  }

  Future<List<FileEntry>> listWindowsUncShares(String path, String host) async {
    final result = await SmbShareDiscovery.list(host: host);

    return _shareEntries(
      result,
      path,
      (share) => PlatformPaths.join(path, share),
    );
  }

  List<FileEntry> _shareEntries(
    SmbShareListResult result,
    String logical,
    String Function(String share) pathForShare,
  ) {
    switch (result) {
      case SmbShareListOk(:final shares):
        final now = DateTime.now();

        return [
          for (final share in shares)
            FileEntry(
              name: share.name,
              path: pathForShare(share.name),
              type: FileItemType.folder,
              size: 0,
              modified: now,
            ),
        ];
      case SmbShareListAuthRequired():
        throw FileSystemException(t.errors.authenticationRequired, logical);
      case SmbShareListError(:final message):
        throw FileSystemException(message, logical);
      case SmbShareListUnsupported():
        throw FileSystemException(t.errors.smbNotSupportedOnPlatform, logical);
    }
  }
}
