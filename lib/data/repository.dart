import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../ranking/rank_key.dart';
import 'database.dart';

/// A list with its item count, for the home screen.
class ListSummary {
  const ListSummary(this.list, this.itemCount, this.topItem);
  final RankList list;
  final int itemCount;
  final String? topItem;
}

/// All reads and writes the screens need. Screens never touch the database
/// directly, so cloud sync can be added behind this class in step 3.
class Repository {
  Repository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _clock;
  static const _uuid = Uuid();

  // ---------- Lists ----------

  Stream<List<ListSummary>> watchListSummaries() {
    final lists =
        (_db.select(_db.rankLists)
              ..where((l) => l.deletedAt.isNull())
              ..orderBy([(l) => OrderingTerm.desc(l.updatedAt)]))
            .watch();
    return lists.asyncMap((rows) async {
      final out = <ListSummary>[];
      for (final list in rows) {
        final items = await rankedItems(list.id);
        final unranked = await _unranked(list.id).get();
        out.add(
          ListSummary(
            list,
            items.length + unranked.length,
            items.firstOrNull?.name,
          ),
        );
      }
      return out;
    });
  }

  Stream<RankList?> watchList(String id) => (_db.select(
    _db.rankLists,
  )..where((l) => l.id.equals(id))).watchSingleOrNull();

  Future<String> createList(String title, {String description = ''}) async {
    final now = _clock();
    final id = _uuid.v4();
    await _db
        .into(_db.rankLists)
        .insert(
          RankListsCompanion.insert(
            id: id,
            title: title.trim(),
            description: Value(description.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> renameList(String id, String title) =>
      (_db.update(_db.rankLists)..where((l) => l.id.equals(id))).write(
        RankListsCompanion(
          title: Value(title.trim()),
          updatedAt: Value(_clock()),
        ),
      );

  Future<void> deleteList(String id) async {
    final now = _clock();
    await _db.transaction(() async {
      await (_db.update(
        _db.rankItems,
      )..where((i) => i.listId.equals(id))).write(
        RankItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await (_db.update(_db.rankLists)..where((l) => l.id.equals(id))).write(
        RankListsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
    });
  }

  // ---------- Items ----------

  SimpleSelectStatement<$RankItemsTable, RankItem> _ranked(String listId) =>
      _db.select(_db.rankItems)
        ..where(
          (i) =>
              i.listId.equals(listId) &
              i.deletedAt.isNull() &
              i.rankKey.isNotNull(),
        )
        ..orderBy([(i) => OrderingTerm.asc(i.rankKey)]);

  SimpleSelectStatement<$RankItemsTable, RankItem> _unranked(String listId) =>
      _db.select(_db.rankItems)
        ..where(
          (i) =>
              i.listId.equals(listId) &
              i.deletedAt.isNull() &
              i.rankKey.isNull(),
        )
        ..orderBy([(i) => OrderingTerm.asc(i.createdAt)]);

  /// Ranked items, best first.
  Stream<List<RankItem>> watchRanked(String listId) => _ranked(listId).watch();
  Future<List<RankItem>> rankedItems(String listId) => _ranked(listId).get();

  /// Items waiting to be ranked.
  Stream<List<RankItem>> watchUnranked(String listId) =>
      _unranked(listId).watch();

  Stream<RankItem?> watchItem(String id) => (_db.select(
    _db.rankItems,
  )..where((i) => i.id.equals(id))).watchSingleOrNull();

  Future<RankItem?> item(String id) => (_db.select(
    _db.rankItems,
  )..where((i) => i.id.equals(id))).getSingleOrNull();

  /// Adds an item as unranked. Ranking it is a separate step.
  Future<String> addItem(
    String listId,
    String name, {
    String note = '',
    Uint8List? photo,
  }) async {
    final now = _clock();
    final id = _uuid.v4();
    await _db.transaction(() async {
      await _db
          .into(_db.rankItems)
          .insert(
            RankItemsCompanion.insert(
              id: id,
              listId: listId,
              name: name.trim(),
              note: Value(note.trim()),
              photo: Value(photo),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _touchList(listId, now);
    });
    return id;
  }

  Future<void> updateItem(
    String id, {
    String? name,
    String? note,
    Uint8List? photo,
    bool clearPhoto = false,
  }) {
    return (_db.update(_db.rankItems)..where((i) => i.id.equals(id))).write(
      RankItemsCompanion(
        name: name == null ? const Value.absent() : Value(name.trim()),
        note: note == null ? const Value.absent() : Value(note.trim()),
        photo: clearPhoto
            ? const Value(null)
            : (photo == null ? const Value.absent() : Value(photo)),
        updatedAt: Value(_clock()),
      ),
    );
  }

  Future<void> deleteItem(String id) {
    final now = _clock();
    return (_db.update(_db.rankItems)..where((i) => i.id.equals(id))).write(
      RankItemsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  /// Puts [itemId] at [index] in [rankedWithoutItem] (best first, and not
  /// containing the item). Only the moved item's key changes.
  Future<void> placeAt(
    String itemId,
    List<RankItem> rankedWithoutItem,
    int index,
  ) async {
    final before = index > 0 ? rankedWithoutItem[index - 1].rankKey : null;
    final after = index < rankedWithoutItem.length
        ? rankedWithoutItem[index].rankKey
        : null;
    final key = keyBetween(before, after);
    final now = _clock();
    await _db.transaction(() async {
      final row = await item(itemId);
      await (_db.update(
        _db.rankItems,
      )..where((i) => i.id.equals(itemId))).write(
        RankItemsCompanion(rankKey: Value(key), updatedAt: Value(now)),
      );
      if (row != null) await _touchList(row.listId, now);
    });
  }

  /// Takes an item out of the order so it can be ranked again.
  Future<void> unrank(String itemId) =>
      (_db.update(_db.rankItems)..where((i) => i.id.equals(itemId))).write(
        RankItemsCompanion(
          rankKey: const Value(null),
          updatedAt: Value(_clock()),
        ),
      );

  Future<void> _touchList(String listId, DateTime now) =>
      (_db.update(_db.rankLists)..where((l) => l.id.equals(listId))).write(
        RankListsCompanion(updatedAt: Value(now)),
      );
}
