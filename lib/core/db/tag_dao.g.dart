// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_dao.dart';

// ignore_for_file: type=lint
mixin _$TagDaoMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $ScoresTable get scores => attachedDatabase.scores;
  $ScoreTagsTable get scoreTags => attachedDatabase.scoreTags;
  TagDaoManager get managers => TagDaoManager(this);
}

class TagDaoManager {
  final _$TagDaoMixin _db;
  TagDaoManager(this._db);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db.attachedDatabase, _db.scores);
  $$ScoreTagsTableTableManager get scoreTags =>
      $$ScoreTagsTableTableManager(_db.attachedDatabase, _db.scoreTags);
}
