import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'tables.dart';

part 'tag_dao.g.dart';

/// 태그와 곡 사이의 연결.
@DriftAccessor(tables: [Tags, ScoreTags, Scores])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  static const _uuid = Uuid();

  Stream<List<Tag>> watchAll() => (select(tags)
        ..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder),
          (t) => OrderingTerm(expression: t.name),
        ]))
      .watch();

  Future<List<Tag>> all() => (select(tags)
        ..orderBy([(t) => OrderingTerm(expression: t.name)]))
      .get();

  /// 이름으로 찾고 없으면 만든다. 태그 입력창에서 바로 쓰기 위한 것이다.
  Future<Tag> findOrCreate(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) throw ArgumentError('태그 이름이 비었습니다');

    final existing = await (select(tags)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final id = _uuid.v4();
    await into(tags).insert(TagsCompanion.insert(id: id, name: name));
    return (select(tags)..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> rename(String id, String name) =>
      (update(tags)..where((t) => t.id.equals(id)))
          .write(TagsCompanion(name: Value(name.trim())));

  Future<void> deleteTag(String id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  Stream<List<Tag>> watchTagsOfScore(String scoreId) {
    final q = select(tags).join([
      innerJoin(scoreTags, scoreTags.tagId.equalsExp(tags.id)),
    ])
      ..where(scoreTags.scoreId.equals(scoreId))
      ..orderBy([OrderingTerm(expression: tags.name)]);
    return q.watch().map((rows) => rows.map((r) => r.readTable(tags)).toList());
  }

  Future<void> attach(String scoreId, String tagId) =>
      into(scoreTags).insert(
        ScoreTagsCompanion.insert(scoreId: scoreId, tagId: tagId),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> detach(String scoreId, String tagId) => (delete(scoreTags)
        ..where((t) => t.scoreId.equals(scoreId) & t.tagId.equals(tagId)))
      .go();

  /// 여러 곡에 한 번에 태그를 붙인다.
  Future<void> attachMany(Iterable<String> scoreIds, String tagId) {
    return batch((b) {
      for (final scoreId in scoreIds) {
        b.insert(
          scoreTags,
          ScoreTagsCompanion.insert(scoreId: scoreId, tagId: tagId),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// 태그에 속한 곡을 통째로 바꾼다. 태그 편집 화면에서 쓴다.
  Future<void> setScoresOfTag(String tagId, Set<String> scoreIds) {
    return transaction(() async {
      await (delete(scoreTags)..where((t) => t.tagId.equals(tagId))).go();
      await batch((b) {
        for (final scoreId in scoreIds) {
          b.insert(
            scoreTags,
            ScoreTagsCompanion.insert(scoreId: scoreId, tagId: tagId),
          );
        }
      });
    });
  }

  Future<Set<String>> scoreIdsOfTag(String tagId) async {
    final rows = await (select(scoreTags)..where((t) => t.tagId.equals(tagId)))
        .get();
    return rows.map((r) => r.scoreId).toSet();
  }

  /// 태그별 곡 수. 목록의 필터 칩에 표시한다.
  Stream<Map<String, int>> watchCounts() {
    final count = scoreTags.scoreId.count();
    final q = selectOnly(scoreTags)
      ..addColumns([scoreTags.tagId, count])
      ..groupBy([scoreTags.tagId]);
    return q.watch().map(
          (rows) => {
            for (final r in rows) r.read(scoreTags.tagId)!: r.read(count) ?? 0,
          },
        );
  }
}

final tagDaoProvider =
    Provider<TagDao>((ref) => TagDao(ref.watch(appDatabaseProvider)));

final allTagsProvider =
    StreamProvider<List<Tag>>((ref) => ref.watch(tagDaoProvider).watchAll());

final tagCountsProvider = StreamProvider<Map<String, int>>(
  (ref) => ref.watch(tagDaoProvider).watchCounts(),
);

final tagsOfScoreProvider = StreamProvider.family<List<Tag>, String>(
  (ref, scoreId) => ref.watch(tagDaoProvider).watchTagsOfScore(scoreId),
);
