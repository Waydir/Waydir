import '../models/file_entry.dart';

enum SortKey { name, size, date }

SortKey sortKeyFromString(String v) {
  switch (v) {
    case 'size':
      return SortKey.size;
    case 'date':
      return SortKey.date;
    default:
      return SortKey.name;
  }
}

String sortKeyToString(SortKey k) => k.name;

/// Returns a new list sorted by the given criteria.
///
/// When [foldersFirst] is true, folders are always grouped before files
/// regardless of the sort key/direction. Names use a case-insensitive
/// comparison; ties always fall back to name so the order is stable.
List<FileEntry> sortEntries(
  List<FileEntry> entries, {
  required SortKey key,
  required bool ascending,
  required bool foldersFirst,
}) {
  final out = List<FileEntry>.of(entries);
  int byName(FileEntry a, FileEntry b) => a.nameLower.compareTo(b.nameLower);

  out.sort((a, b) {
    if (foldersFirst && a.type != b.type) {
      return a.type == FileItemType.folder ? -1 : 1;
    }
    int cmp;
    switch (key) {
      case SortKey.name:
        cmp = byName(a, b);
      case SortKey.size:
        cmp = a.size.compareTo(b.size);
      case SortKey.date:
        cmp = a.modified.compareTo(b.modified);
    }
    if (cmp == 0) cmp = byName(a, b);
    return ascending ? cmp : -cmp;
  });
  return out;
}
