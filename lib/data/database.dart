import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// A ranked list, such as "Best films".
@DataClassName('RankList')
class RankLists extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Set instead of removing the row, so deletes can sync later.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One entry in a list.
@DataClassName('RankItem')
class RankItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text().references(RankLists, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// A resized photo, stored with the item so it works on every platform.
  BlobColumn get photo => blob().nullable()();

  /// Sortable position key. Null means the item is not ranked yet.
  TextColumn get rankKey => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [RankLists, RankItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openDefault() {
    return driftDatabase(
      name: 'ordo',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
