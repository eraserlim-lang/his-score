// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist_dao.dart';

// ignore_for_file: type=lint
mixin _$SetlistDaoMixin on DatabaseAccessor<AppDatabase> {
  $SetlistsTable get setlists => attachedDatabase.setlists;
  $ScoresTable get scores => attachedDatabase.scores;
  $SetlistItemsTable get setlistItems => attachedDatabase.setlistItems;
  SetlistDaoManager get managers => SetlistDaoManager(this);
}

class SetlistDaoManager {
  final _$SetlistDaoMixin _db;
  SetlistDaoManager(this._db);
  $$SetlistsTableTableManager get setlists =>
      $$SetlistsTableTableManager(_db.attachedDatabase, _db.setlists);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db.attachedDatabase, _db.scores);
  $$SetlistItemsTableTableManager get setlistItems =>
      $$SetlistItemsTableTableManager(_db.attachedDatabase, _db.setlistItems);
}
