import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Scores,
    ScorePages,
    Bookmarks,
    JumpButtons,
    Tags,
    ScoreTags,
    Setlists,
    SetlistItems,
    InkStrokes,
    Annotations,
    Recordings,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'hiscore'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(inkStrokes, inkStrokes.subtype);
          }
          if (from < 3) {
            await m.addColumn(scores, scores.dualStepOne);
          }
          if (from < 4) {
            await m.addColumn(annotations, annotations.boxed);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
