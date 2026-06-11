import '../models/file_entry.dart';

enum SortKey { name, size, date, kind, created, permissions, owner }

SortKey sortKeyFromString(String v) {
  switch (v) {
    case 'size':
      return SortKey.size;
    case 'date':
      return SortKey.date;
    case 'kind':
      return SortKey.kind;
    case 'created':
      return SortKey.created;
    case 'permissions':
      return SortKey.permissions;
    case 'owner':
      return SortKey.owner;
    default:
      return SortKey.name;
  }
}

String sortKeyToString(SortKey k) => k.name;

/// Returns a new list sorted by the given criteria.
///
/// When [foldersFirst] is true, folders are always grouped before files
/// regardless of the sort key/direction. When [sortFolders] is false, folders
/// keep their default name-ascending order and only files follow the chosen
/// key/direction. Names use a case-insensitive comparison; ties always fall
/// back to name so the order is stable.
List<FileEntry> sortEntries(
  List<FileEntry> entries, {
  required SortKey key,
  required bool ascending,
  required bool foldersFirst,
  bool naturalSort = false,
  bool sortFolders = true,
}) {
  final out = List<FileEntry>.of(entries);
  int byName(FileEntry a, FileEntry b) => naturalSort
      ? compareNatural(a.nameLower, b.nameLower)
      : a.nameLower.compareTo(b.nameLower);

  out.sort((a, b) {
    if (foldersFirst && a.type != b.type) {
      return a.type == FileItemType.folder ? -1 : 1;
    }
    if (!sortFolders &&
        a.type == FileItemType.folder &&
        b.type == FileItemType.folder) {
      return byName(a, b);
    }
    int cmp;
    switch (key) {
      case SortKey.name:
        cmp = byName(a, b);
      case SortKey.size:
        cmp = a.size.compareTo(b.size);
      case SortKey.date:
        cmp = a.modifiedMs.compareTo(b.modifiedMs);
      case SortKey.kind:
        cmp = a.kind.toLowerCase().compareTo(b.kind.toLowerCase());
      case SortKey.created:
        cmp = a.createdMs.compareTo(b.createdMs);
      case SortKey.permissions:
        cmp = a.mode.compareTo(b.mode);
      case SortKey.owner:
        cmp = a.ownerName.toLowerCase().compareTo(b.ownerName.toLowerCase());
    }
    if (cmp == 0) cmp = byName(a, b);
    return ascending ? cmp : -cmp;
  });
  return out;
}

/// Compares two strings the way a human reads them: runs of digits are
/// compared by numeric value rather than character by character, so "file2"
/// sorts before "file10". Inputs are expected to already be case-folded.
int compareNatural(String a, String b) {
  const zero = 0x30;
  const nine = 0x39;
  final la = a.length;
  final lb = b.length;
  var i = 0;
  var j = 0;
  while (i < la && j < lb) {
    final ca = a.codeUnitAt(i);
    final cb = b.codeUnitAt(j);
    final aDigit = ca >= zero && ca <= nine;
    final bDigit = cb >= zero && cb <= nine;
    if (aDigit && bDigit) {
      var si = i;
      var sj = j;
      while (si < la && a.codeUnitAt(si) == zero) {
        si++;
      }
      while (sj < lb && b.codeUnitAt(sj) == zero) {
        sj++;
      }
      var ei = si;
      var ej = sj;
      while (ei < la && a.codeUnitAt(ei) >= zero && a.codeUnitAt(ei) <= nine) {
        ei++;
      }
      while (ej < lb && b.codeUnitAt(ej) >= zero && b.codeUnitAt(ej) <= nine) {
        ej++;
      }
      final lenA = ei - si;
      final lenB = ej - sj;
      if (lenA != lenB) return lenA < lenB ? -1 : 1;
      for (var k = 0; k < lenA; k++) {
        final d = a.codeUnitAt(si + k) - b.codeUnitAt(sj + k);
        if (d != 0) return d < 0 ? -1 : 1;
      }
      final zerosA = si - i;
      final zerosB = sj - j;
      if (zerosA != zerosB) return zerosA < zerosB ? -1 : 1;
      i = ei;
      j = ej;
    } else {
      if (ca != cb) return ca < cb ? -1 : 1;
      i++;
      j++;
    }
  }
  final rest = (la - i) - (lb - j);
  return rest < 0 ? -1 : (rest > 0 ? 1 : 0);
}
