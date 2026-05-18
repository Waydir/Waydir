enum LogLevel { warn, error }

extension LogLevelName on LogLevel {
  String get label => switch (this) {
    LogLevel.warn => 'WARN',
    LogLevel.error => 'ERROR',
  };
}

class LogEntry {
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;

  Map<String, dynamic> toJson() => {
    'ts': timestamp.toIso8601String(),
    'level': level.label,
    'tag': tag,
    'msg': message,
    if (stackTrace != null) 'stack': stackTrace,
  };
}
