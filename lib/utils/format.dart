import 'dart:ui' as ui;

import 'package:intl/intl.dart' as intl;

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

String formatDurationShort(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds <= 0) return '<1s';
  if (seconds < 60) return '${seconds}s';

  final minutes = duration.inMinutes;
  final remainingSeconds = seconds % 60;
  if (minutes < 60) {
    return remainingSeconds == 0
        ? '${minutes}m'
        : '${minutes}m ${remainingSeconds}s';
  }

  final hours = duration.inHours;
  final remainingMinutes = minutes % 60;
  return remainingMinutes == 0 ? '${hours}h' : '${hours}h ${remainingMinutes}m';
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

/// Formats [d] according to the user's date-format preference ([mode] is one of
/// `locale`, `relative`, `iso`). When [recentDatesRelative] is set, locale mode
/// shows a relative label for dates within the last day.
String formatEntryDate(
  DateTime d,
  String mode, {
  bool recentDatesRelative = false,
}) {
  switch (mode) {
    case 'locale':
      if (recentDatesRelative && _isRecentDate(d)) {
        return _formatRelativeDate(d);
      }
      return _formatLocaleDate(d);
    case 'relative':
      return _formatRelativeDate(d);
    case 'iso':
    default:
      return _formatIsoDate(d);
  }
}

bool _isRecentDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  return !diff.isNegative && diff.inHours < 24;
}

String _formatIsoDate(DateTime d) {
  return '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

String _formatLocaleDate(DateTime d) {
  final locale = intl.Intl.canonicalizedLocale(
    ui.PlatformDispatcher.instance.locale.toLanguageTag(),
  );
  try {
    return intl.DateFormat.yMd(locale).add_jm().format(d);
  } catch (_) {
    return _formatIsoDate(d);
  }
}

String _formatRelativeDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return t.fileView.date.justNow;
  if (diff.inMinutes < 60) {
    return t.fileView.date.minutesAgo(count: diff.inMinutes);
  }
  if (diff.inHours < 24) {
    return t.fileView.date.hoursAgo(count: diff.inHours);
  }
  if (diff.inDays < 7) return t.fileView.date.daysAgo(count: diff.inDays);
  if (diff.inDays < 30) {
    return t.fileView.date.weeksAgo(count: (diff.inDays / 7).floor());
  }
  if (diff.inDays < 365) {
    return t.fileView.date.monthsAgo(count: (diff.inDays / 30).floor());
  }
  return t.fileView.date.yearsAgo(count: (diff.inDays / 365).floor());
}
