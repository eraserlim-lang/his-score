import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'tables.dart';

part 'score_dao.g.dart';

/// 카탈로그 정렬 기준.
enum ScoreSort { recent, title, artist, added }

@DriftAccessor(tables: [Scores, ScorePages])
class ScoreDao extends DatabaseAccessor<AppDatabase> with _$ScoreDaoMixin {
  ScoreDao(super.db);

  /// 카탈로그 목록. 정렬과 제목 검색을 함께 처리한다.
  Stream<List<Score>> watchScores({
    ScoreSort sort = ScoreSort.recent,
    String? query,
  }) {
    final q = select(scores);

    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      q.where(
        (t) =>
            t.title.like(like) |
            t.artist.like(like) |
            t.composer.like(like),
      );
    }

    q.orderBy([
      switch (sort) {
        // 한 번도 열지 않은 곡이 뒤로 가도록 null 을 마지막에 둔다.
        ScoreSort.recent => (t) => OrderingTerm(
              expression: t.lastOpenedAt,
              mode: OrderingMode.desc,
              nulls: NullsOrder.last,
            ),
        ScoreSort.title => (t) => OrderingTerm(expression: t.title),
        ScoreSort.artist => (t) => OrderingTerm(
              expression: t.artist,
              nulls: NullsOrder.last,
            ),
        ScoreSort.added => (t) => OrderingTerm(
              expression: t.createdAt,
              mode: OrderingMode.desc,
            ),
      },
    ]);

    return q.watch();
  }

  Future<Score?> findById(String id) =>
      (select(scores)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<Score?> watchById(String id) =>
      (select(scores)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> insertScore(ScoresCompanion score, List<ScorePagesCompanion> pages) {
    return transaction(() async {
      await into(scores).insert(score);
      await batch((b) => b.insertAll(scorePages, pages));
    });
  }

  /// 숨긴 페이지를 뺀 표시 순서대로의 페이지 목록.
  Future<List<ScorePage>> visiblePages(String scoreId) {
    return (select(scorePages)
          ..where((t) => t.scoreId.equals(scoreId) & t.hidden.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.displayOrder)]))
        .get();
  }

  Stream<List<ScorePage>> watchVisiblePages(String scoreId) {
    return (select(scorePages)
          ..where((t) => t.scoreId.equals(scoreId) & t.hidden.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.displayOrder)]))
        .watch();
  }

  Future<void> updateScore(String id, ScoresCompanion patch) {
    return (update(scores)..where((t) => t.id.equals(id)))
        .write(patch.copyWith(updatedAt: Value(DateTime.now())));
  }

  /// 마지막으로 본 페이지와 열람 시각. 다음에 열 때 그 자리로 돌아간다.
  Future<void> markOpened(String id, int page) {
    return (update(scores)..where((t) => t.id.equals(id))).write(
      ScoresCompanion(
        lastPage: Value(page),
        lastOpenedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteScores(List<String> ids) =>
      (delete(scores)..where((t) => t.id.isIn(ids))).go();
}

final scoreDaoProvider = Provider<ScoreDao>(
  (ref) => ScoreDao(ref.watch(appDatabaseProvider)),
);

final scoreListProvider =
    StreamProvider.family<List<Score>, ({ScoreSort sort, String? query})>(
  (ref, args) => ref
      .watch(scoreDaoProvider)
      .watchScores(sort: args.sort, query: args.query),
);

final scoreProvider = StreamProvider.family<Score?, String>(
  (ref, id) => ref.watch(scoreDaoProvider).watchById(id),
);

final scorePagesProvider = StreamProvider.family<List<ScorePage>, String>(
  (ref, id) => ref.watch(scoreDaoProvider).watchVisiblePages(id),
);
