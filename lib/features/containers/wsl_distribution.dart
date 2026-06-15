class WslDistribution {
  final String name;
  final bool isRunning;

  const WslDistribution({required this.name, this.isRunning = false});

  String get uncPath => '\\\\wsl.localhost\\$name\\';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WslDistribution &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          isRunning == other.isRunning;

  @override
  int get hashCode => name.hashCode ^ isRunning.hashCode;
}
