const String _tagScheme = 'tag://';

String tagPathFor(int id) => '$_tagScheme$id';

bool isTagPath(String path) => path.startsWith(_tagScheme);

int? tagIdFromPath(String path) {
  if (!isTagPath(path)) return null;

  return int.tryParse(path.substring(_tagScheme.length));
}
