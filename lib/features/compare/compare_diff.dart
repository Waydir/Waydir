import 'package:path/path.dart' as p;

import '../../core/models/file_entry.dart';

const compareMtimeToleranceMs = 2000;

enum CompareStatus { unique, newer, older, identical, differ }

class CompareCounts {
  final int identical;
  final int differ;
  final int uniqueLeft;
  final int uniqueRight;

  const CompareCounts({
    this.identical = 0,
    this.differ = 0,
    this.uniqueLeft = 0,
    this.uniqueRight = 0,
  });
}

class CompareEntryResult {
  final String relativePath;
  final String path;
  final FileItemType type;
  final CompareStatus status;

  const CompareEntryResult({
    required this.relativePath,
    required this.path,
    required this.type,
    required this.status,
  });
}

class CompareDiffResult {
  final Map<String, CompareEntryResult> left;
  final Map<String, CompareEntryResult> right;
  final CompareCounts counts;

  const CompareDiffResult({
    required this.left,
    required this.right,
    required this.counts,
  });
}

class _CompareItem {
  final String relativePath;
  final FileEntry entry;

  const _CompareItem(this.relativePath, this.entry);
}

class _FolderAggregate {
  int? leftMs;
  int? rightMs;

  void add(int? left, int? right) {
    if (left != null && (leftMs == null || left > leftMs!)) leftMs = left;
    if (right != null && (rightMs == null || right > rightMs!)) rightMs = right;
  }
}

CompareDiffResult buildCompareDiff({
  required String leftRoot,
  required String rightRoot,
  required List<FileEntry> leftEntries,
  required List<FileEntry> rightEntries,
}) {
  final left = _mapByRelativePath(leftRoot, leftEntries);
  final right = _mapByRelativePath(rightRoot, rightEntries);
  final rels = <String>{...left.keys, ...right.keys}.toList()..sort();
  final leftStatuses = <String, CompareStatus>{};
  final rightStatuses = <String, CompareStatus>{};
  final aggregates = <String, _FolderAggregate>{};

  for (final rel in rels) {
    final l = left[rel]?.entry;
    final r = right[rel]?.entry;
    if (l == null && r == null) continue;
    if (l == null) {
      rightStatuses[rel] = CompareStatus.unique;
      _addDifferenceToParents(aggregates, rel, null, r!.modifiedMs);
    } else if (r == null) {
      leftStatuses[rel] = CompareStatus.unique;
      _addDifferenceToParents(aggregates, rel, l.modifiedMs, null);
    } else if (l.type == FileItemType.folder && r.type == FileItemType.folder) {
      leftStatuses[rel] = CompareStatus.identical;
      rightStatuses[rel] = CompareStatus.identical;
    } else if (l.type != r.type) {
      final pair = _newerOlder(l.modifiedMs, r.modifiedMs);
      leftStatuses[rel] = pair.$1;
      rightStatuses[rel] = pair.$2;
      _addDifferenceToParents(aggregates, rel, l.modifiedMs, r.modifiedMs);
    } else if (_entriesIdentical(l, r)) {
      leftStatuses[rel] = CompareStatus.identical;
      rightStatuses[rel] = CompareStatus.identical;
    } else {
      final pair = _newerOlder(l.modifiedMs, r.modifiedMs);
      leftStatuses[rel] = pair.$1;
      rightStatuses[rel] = pair.$2;
      _addDifferenceToParents(aggregates, rel, l.modifiedMs, r.modifiedMs);
    }
  }

  for (final rel in rels) {
    final l = left[rel]?.entry;
    final r = right[rel]?.entry;
    if (l == null || r == null) continue;
    if (l.type != FileItemType.folder || r.type != FileItemType.folder) {
      continue;
    }
    final aggregate = aggregates[rel];
    if (aggregate == null) continue;
    final pair = _aggregateStatus(aggregate.leftMs, aggregate.rightMs);
    leftStatuses[rel] = pair.$1;
    rightStatuses[rel] = pair.$2;
  }

  final leftResults = <String, CompareEntryResult>{};
  final rightResults = <String, CompareEntryResult>{};
  var identical = 0;
  var differ = 0;
  var uniqueLeft = 0;
  var uniqueRight = 0;

  for (final rel in rels) {
    final l = left[rel]?.entry;
    final r = right[rel]?.entry;
    final ls = leftStatuses[rel];
    final rs = rightStatuses[rel];
    if (l != null && ls != null) {
      leftResults[l.path] = CompareEntryResult(
        relativePath: rel,
        path: l.path,
        type: l.type,
        status: ls,
      );
    }
    if (r != null && rs != null) {
      rightResults[r.path] = CompareEntryResult(
        relativePath: rel,
        path: r.path,
        type: r.type,
        status: rs,
      );
    }
    if (l != null && r != null) {
      if (ls == CompareStatus.identical && rs == CompareStatus.identical) {
        identical++;
      } else {
        differ++;
      }
    } else if (l != null) {
      uniqueLeft++;
    } else if (r != null) {
      uniqueRight++;
    }
  }

  return CompareDiffResult(
    left: Map.unmodifiable(leftResults),
    right: Map.unmodifiable(rightResults),
    counts: CompareCounts(
      identical: identical,
      differ: differ,
      uniqueLeft: uniqueLeft,
      uniqueRight: uniqueRight,
    ),
  );
}

Map<String, _CompareItem> _mapByRelativePath(
  String root,
  List<FileEntry> entries,
) {
  final out = <String, _CompareItem>{};
  for (final entry in entries) {
    final rel = _relativePath(root, entry.path);
    if (rel.isEmpty) continue;
    out[rel] = _CompareItem(rel, entry);
  }

  return out;
}

String _relativePath(String root, String path) {
  final rel = p.relative(path, from: root).replaceAll('\\', '/');
  if (rel == '.') return '';

  return p.posix.normalize(rel);
}

bool _entriesIdentical(FileEntry left, FileEntry right) {
  return left.size == right.size &&
      (left.modifiedMs - right.modifiedMs).abs() <= compareMtimeToleranceMs;
}

(CompareStatus, CompareStatus) _newerOlder(int leftMs, int rightMs) {
  final delta = leftMs - rightMs;
  if (delta.abs() <= compareMtimeToleranceMs) {
    return (CompareStatus.differ, CompareStatus.differ);
  }

  return delta > 0
      ? (CompareStatus.newer, CompareStatus.older)
      : (CompareStatus.older, CompareStatus.newer);
}

(CompareStatus, CompareStatus) _aggregateStatus(int? leftMs, int? rightMs) {
  if (leftMs == null && rightMs == null) {
    return (CompareStatus.identical, CompareStatus.identical);
  }
  if (leftMs == null) return (CompareStatus.older, CompareStatus.newer);
  if (rightMs == null) return (CompareStatus.newer, CompareStatus.older);

  return _newerOlder(leftMs, rightMs);
}

void _addDifferenceToParents(
  Map<String, _FolderAggregate> aggregates,
  String rel,
  int? leftMs,
  int? rightMs,
) {
  var dir = p.posix.dirname(rel);
  while (dir != '.') {
    (aggregates[dir] ??= _FolderAggregate()).add(leftMs, rightMs);
    dir = p.posix.dirname(dir);
  }
}
