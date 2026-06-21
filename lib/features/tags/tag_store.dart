import 'package:flutter/material.dart';
import 'package:signals/signals.dart';

import '../../core/database/app_database.dart';

class TagDef {
  final int id;
  final String name;
  final Color color;
  final int orderIndex;

  const TagDef({
    required this.id,
    required this.name,
    required this.color,
    required this.orderIndex,
  });
}

class TagStore {
  static final TagStore instance = TagStore._();

  TagStore._();

  final tags = signal<List<TagDef>>([]);

  late final byId = computed<Map<int, TagDef>>(
    () => {for (final tag in tags.value) tag.id: tag},
  );

  late final AppDatabase _db;
  bool _loaded = false;

  Future<void> load(AppDatabase db) async {
    if (_loaded) return;
    _db = db;
    await refresh();
    _loaded = true;
  }

  Future<void> refresh() async {
    final rows = await _db.getTags();
    tags.value = [
      for (final row in rows)
        TagDef(
          id: row.id,
          name: row.name,
          color: Color(row.color),
          orderIndex: row.orderIndex,
        ),
    ];
  }

  Future<void> createTag(String name, Color color) async {
    await _db.createTag(name, color.toARGB32(), tags.value.length);
    await refresh();
  }

  Future<void> updateTag(int id, {String? name, Color? color}) async {
    await _db.updateTag(id, name: name, color: color?.toARGB32());
    await refresh();
  }

  Future<void> deleteTag(int id) async {
    await _db.deleteTag(id);
    await refresh();
  }

  Future<void> reorder(List<int> idsInOrder) async {
    await _db.setTagOrder(idsInOrder);
    await refresh();
  }
}
