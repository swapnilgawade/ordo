import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordo/data/database.dart';
import 'package:ordo/data/repository.dart';
import 'package:ordo/ranking/insertion_session.dart';

void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
  });
  tearDown(() => db.close());

  Future<void> rankInto(
    String listId,
    String name,
    int Function(String) score,
  ) async {
    final id = await repo.addItem(listId, name);
    final ranked = await repo.rankedItems(listId);
    final s = InsertionSession(ranked);
    while (!s.isDone) {
      s.answer(
        score(name) > score(s.opponent.name)
            ? Preference.newItem
            : Preference.existingItem,
      );
    }
    await repo.placeAt(id, s.ranked, s.insertIndex);
  }

  test('items ranked by comparisons come out in order', () async {
    final listId = await repo.createList('Numbers');
    final values = [5, 1, 9, 3, 7, 2, 8, 6, 4];
    for (final v in values) {
      await rankInto(listId, 'n$v', (name) => int.parse(name.substring(1)));
    }
    final names = (await repo.rankedItems(listId)).map((i) => i.name).toList();
    expect(names, ['n9', 'n8', 'n7', 'n6', 'n5', 'n4', 'n3', 'n2', 'n1']);
  });

  test('new items start unranked and can be re-ranked', () async {
    final listId = await repo.createList('Films');
    final id = await repo.addItem(listId, 'Heat', note: 'Mann');
    expect(await repo.rankedItems(listId), isEmpty);
    await repo.placeAt(id, const [], 0);
    expect((await repo.rankedItems(listId)).single.note, 'Mann');
    await repo.unrank(id);
    expect(await repo.rankedItems(listId), isEmpty);
  });

  test('dragging changes only the moved item', () async {
    final listId = await repo.createList('Letters');
    for (final name in ['a', 'b', 'c', 'd']) {
      final id = await repo.addItem(listId, name);
      final ranked = await repo.rankedItems(listId);
      await repo.placeAt(id, ranked, ranked.length);
    }
    final before = await repo.rankedItems(listId);
    final moved = before[3];
    final rest = [...before]..removeAt(3);
    await repo.placeAt(moved.id, rest, 0);
    final after = await repo.rankedItems(listId);
    expect(after.map((i) => i.name), ['d', 'a', 'b', 'c']);
    for (final name in ['a', 'b', 'c']) {
      expect(
        after.firstWhere((i) => i.name == name).rankKey,
        before.firstWhere((i) => i.name == name).rankKey,
      );
    }
  });

  test('deleting a list hides it and its items', () async {
    final listId = await repo.createList('Temp');
    await repo.addItem(listId, 'x');
    await repo.deleteList(listId);
    final summaries = await repo.watchListSummaries().first;
    expect(summaries, isEmpty);
  });

  test('renaming a list updates its title', () async {
    final listId = await repo.createList('Old');
    await repo.renameList(listId, 'New');
    final summaries = await repo.watchListSummaries().first;
    expect(summaries.single.list.title, 'New');
  });
}
