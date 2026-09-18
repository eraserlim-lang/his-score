// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score_dao.dart';

// ignore_for_file: type=lint
mixin _$ScoreDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScoresTable get scores => attachedDatabase.scores;
  $ScorePagesTable get scorePages => attachedDatabase.scorePages;
  ScoreDaoManager get managers => ScoreDaoManager(this);
}

class ScoreDaoManager {
  final _$ScoreDaoMixin _db;
  ScoreDaoManager(this._db);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db.attachedDatabase, _db.scores);
  $$ScorePagesTableTableManager get scorePages =>
      $$ScorePagesTableTableManager(_db.attachedDatabase, _db.scorePages);
}
