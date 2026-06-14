class DriveSpace {
  final int totalBytes;
  final int freeBytes;

  const DriveSpace({required this.totalBytes, required this.freeBytes});

  int get usedBytes => totalBytes - freeBytes;
  double get usedFraction {
    if (totalBytes <= 0) return 0;

    return (usedBytes / totalBytes).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DriveSpace &&
          runtimeType == other.runtimeType &&
          totalBytes == other.totalBytes &&
          freeBytes == other.freeBytes;

  @override
  int get hashCode => totalBytes.hashCode ^ freeBytes.hashCode;
}

class Drive {
  final String id;
  final String label;
  final String? mountPoint;
  final bool isRemovable;
  final bool isNetwork;
  final String? remoteTarget;
  final String? fsType;
  final DriveSpace? space;

  const Drive({
    required this.id,
    required this.label,
    this.mountPoint,
    required this.isRemovable,
    this.isNetwork = false,
    this.remoteTarget,
    this.fsType,
    this.space,
  });

  bool get isMounted => mountPoint != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Drive &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          mountPoint == other.mountPoint &&
          isRemovable == other.isRemovable &&
          isNetwork == other.isNetwork &&
          remoteTarget == other.remoteTarget &&
          fsType == other.fsType &&
          space == other.space;

  @override
  int get hashCode =>
      id.hashCode ^
      label.hashCode ^
      mountPoint.hashCode ^
      isRemovable.hashCode ^
      isNetwork.hashCode ^
      remoteTarget.hashCode ^
      fsType.hashCode ^
      space.hashCode;
}
