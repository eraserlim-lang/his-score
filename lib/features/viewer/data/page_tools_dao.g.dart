// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_tools_dao.dart';

// ignore_for_file: type=lint
mixin _$PageToolsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScoresTable get scores => attachedDatabase.scores;
  $SetlistsTable get setlists => attachedDatabase.setlists;
  $BookmarksTable get bookmarks => attachedDatabase.bookmarks;
  $JumpButtonsTable get jumpButtons => attachedDatabase.jumpButtons;
  PageToolsDaoManager get managers => PageToolsDaoManager(this);
}

class PageToolsDaoManager {
  final _$PageToolsDaoMixin _db;
  PageToolsDaoManager(this._db);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db.attachedDatabase, _db.scores);
  $$SetlistsTableTableManager get setlists =>
      $$SetlistsTableTableManager(_db.attachedDatabase, _db.setlists);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db.attachedDatabase, _db.bookmarks);
  $$JumpButtonsTableTableManager get jumpButtons =>
      $$JumpButtonsTableTableManager(_db.attachedDatabase, _db.jumpButtons);
}
