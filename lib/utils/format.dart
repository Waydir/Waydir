import '../i18n/strings.g.dart';

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond <= 0) return '';
  return '${formatBytes(bytesPerSecond.round())}/s';
}

String formatTimeAgo(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inSeconds < 10) return t.operations.justNow;
  if (diff.inMinutes < 1) {
    return t.operations.secondsAgo(count: diff.inSeconds);
  }
  if (diff.inHours < 1) {
    return t.operations.minutesAgo(count: diff.inMinutes);
  }
  if (diff.inDays < 1) {
    return t.operations.hoursAgo(count: diff.inHours);
  }
  final hh = ts.hour.toString().padLeft(2, '0');
  final mm = ts.minute.toString().padLeft(2, '0');
  return '${ts.month}/${ts.day} $hh:$mm';
}
