import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';
import 'tables.dart';

part 'score_dao.g.dart';

/// 카탈로그 정렬 기준.
enum ScoreSort { recent, title, artist, added }

/// 카탈로그 조회 조건. 정렬, 검색어, 태그 필터를 한데 묶는다.
class ScoreQuery {
  const ScoreQuery({
    this.sort = ScoreSort.recent,
    this.text = '',
    this.tagIds = const {},
  });

  final ScoreSort sort;
  final String text;

  /// 여러 개면 전부 붙은 곡만 남긴다(교집합).
  final Set<String> tagIds;

  ScoreQuery copyWith({ScoreSort? sort, String? text, Set<String>? tagIds}) =>
      ScoreQuery(
        sort: sort ?? this.sort,
        text: text ?? this.text,
        tagIds: tagIds ?? this.tagIds,
      );

  @override
  bool operator ==(Object other) =>
      other is ScoreQuery &&
      other.sort == sort &&
      other.text == text &&
      other.tagIds.length == tagIds.length &&
      other.tagIds.containsAll(tagIds);

  @override
  int get hashCode => Object.hash(sort, text, tagIds.length);
}

@DriftAccessor(tables: [Scores, ScorePages, ScoreTags])
class ScoreDao extends DatabaseAccessor<AppDatabase> with _$ScoreDaoMixin {
  ScoreDao(super.db);

  Stream<List<Score>> watchScores(ScoreQuery query) {
    final q = select(scores);

    if (query.text.trim().isNotEmpty) {
      final like = '%${query.text.trim()}%';
      q.where(
        (t) => t.title.like(like) | t.artist.like(like) | t.composer.like(like),
      );
    }

    // 선택한 태그가 전부 붙은 곡만: 태그별로 곡 id 집합을 구해 교집합을 건다.
    for (final tagId in query.tagIds) {
      q.where(
        (t) => t.id.isInQuery(
          selectOnly(scoreTags)
            ..addColumns([scoreTags.scoreId])
            ..where(scoreTags.tagId.equals(tagId)),
        ),
      );
    }

    q.orderBy([
      switch (query.sort) {
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
      // 같은 값끼리는 제목으로 안정되게 정렬한다.
      (t) => OrderingTerm(expression: t.title),
    ]);

    return q.watch();
  }

  Future<Score?> findById(String id) =>
      (select(scores)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Score>> findByIds(Iterable<String> ids) =>
      (select(scores)..where((t) => t.id.isIn(ids))).get();

  Stream<Score?> watchById(String id) =>
      (select(scores)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> insertScore(ScoresCompanion score, List<ScorePagesCompanion> pages) {
    return transaction(() async {
      await into(scores).insert(score);
      await batch((b) => b.insertAll(scorePages, pages));
    });
  }

  /// 숨긴 페이지를 뺀 표시 순서대로의 페이지 목록.
  Future<List<ScorePage>> visiblePages(String scoreId) =>
      _pages(scoreId, includeHidden: false).get();

  Stream<List<ScorePage>> watchVisiblePages(String scoreId) =>
      _pages(scoreId, includeHidden: false).watch();

  /// 숨긴 페이지까지 전부. 페이지 순서 편집 화면에서 쓴다.
  Stream<List<ScorePage>> watchAllPages(String scoreId) =>
      _pages(scoreId, includeHidden: true).watch();

  Future<List<ScorePage>> allPages(String scoreId) =>
      _pages(scoreId, includeHidden: true).get();

  SimpleSelectStatement<$ScorePagesTable, ScorePage> _pages(
    String scoreId, {
    required bool includeHidden,
  }) {
    return select(scorePages)
      ..where(
        (t) => includeHidden
            ? t.scoreId.equals(scoreId)
            : t.scoreId.equals(scoreId) & t.hidden.equals(false),
      )
      ..orderBy([(t) => OrderingTerm(expression: t.displayOrder)]);
  }

  Future<void> updateScore(String id, ScoresCompanion patch) =>
      (update(scores)..where((t) => t.id.equals(id)))
          .write(patch.copyWith(updatedAt: Value(DateTime.now())));

  Future<void> updatePage(String pageId, ScorePagesCompanion patch) =>
      (update(scorePages)..where((t) => t.id.equals(pageId))).write(patch);

  /// 페이지 편집 결과를 통째로 반영한다. 순서, 숨김, 복제, 추가가 한 번에 온다.
  Future<void> replacePages(String scoreId, List<ScorePagesCompanion> pages) {
    return transaction(() async {
      await (delete(scorePages)..where((t) => t.scoreId.equals(scoreId))).go();
      await batch((b) => b.insertAll(scorePages, pages));
      // hidden 을 안 준 행은 보이는 페이지다. absent 인 Value 의 .value 는 터진다.
      final visible = pages
          .where((p) => !(p.hidden.present && p.hidden.value))
          .length;
      await updateScore(scoreId, ScoresCompanion(pageCount: Value(visible)));
    });
  }

  /// 마지막으로 본 페이지와 열람 시각. 다음에 열 때 그 자리로 돌아간다.
  Future<void> markOpened(String id, int page) =>
      (update(scores)..where((t) => t.id.equals(id))).write(
        ScoresCompanion(
          lastPage: Value(page),
          lastOpenedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteScores(List<String> ids) =>
      (delete(scores)..where((t) => t.id.isIn(ids))).go();

  Future<int> count() async {
    final c = scores.id.count();
    final row = await (selectOnly(scores)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}

final scoreDaoProvider = Provider<ScoreDao>(
  (ref) => ScoreDao(ref.watch(appDatabaseProvider)),
);

final scoreListProvider = StreamProvider.family<List<Score>, ScoreQuery>(
  (ref, query) => ref.watch(scoreDaoProvider).watchScores(query),
);

final scoreProvider = StreamProvider.family<Score?, String>(
  (ref, id) => ref.watch(scoreDaoProvider).watchById(id),
);

final scorePagesProvider = StreamProvider.family<List<ScorePage>, String>(
  (ref, id) => ref.watch(scoreDaoProvider).watchVisiblePages(id),
);

final allScorePagesProvider = StreamProvider.family<List<ScorePage>, String>(
  (ref, id) => ref.watch(scoreDaoProvider).watchAllPages(id),
);
