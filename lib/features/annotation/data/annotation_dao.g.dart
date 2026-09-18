// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation_dao.dart';

// ignore_for_file: type=lint
mixin _$AnnotationDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScoresTable get scores => attachedDatabase.scores;
  $InkStrokesTable get inkStrokes => attachedDatabase.inkStrokes;
  $AnnotationsTable get annotations => attachedDatabase.annotations;
  AnnotationDaoManager get managers => AnnotationDaoManager(this);
}

class AnnotationDaoManager {
  final _$AnnotationDaoMixin _db;
  AnnotationDaoManager(this._db);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db.attachedDatabase, _db.scores);
  $$InkStrokesTableTableManager get inkStrokes =>
      $$InkStrokesTableTableManager(_db.attachedDatabase, _db.inkStrokes);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db.attachedDatabase, _db.annotations);
}
