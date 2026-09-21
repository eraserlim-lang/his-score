import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/database.dart';
import '../../../core/db/tables.dart';

part 'page_tools_dao.g.dart';

/// 북마크와 점프 버튼.
///
/// 둘 다 "원본 PDF 페이지 번호(1-based)" 를 기준으로 저장한다.
/// 표시 순서를 바꿔도 같은 악보 페이지를 가리켜야 하기 때문이다.
@DriftAccessor(tables: [Bookmarks, JumpButtons])
class PageToolsDao extends DatabaseAccessor<AppDatabase>
    with _$PageToolsDaoMixin {
  PageToolsDao(super.db);

  static const _uuid = Uuid();

  // ---- 북마크 ----

  Stream<List<Bookmark>> watchBookmarks(BookmarkScope scope) =>
      (select(bookmarks)
            ..where(scope._filter)
            ..orderBy([
              (t) => OrderingTerm(expression: t.sortOrder),
              (t) => OrderingTerm(expression: t.page),
            ]))
          .watch();

  /// 곡 북마크. 세트리스트 북마크는 빠진다.
  Future<List<Bookmark>> bookmarksOf(String scoreId) =>
      watchBookmarks(BookmarkScope.score(scoreId)).first;

  /// [setlistId] 를 주면 그 세트의 북마크, 없으면 곡 북마크로 단다.
  Future<void> addBookmark(
    String scoreId,
    int page,
    String label, {
    String? setlistId,
  }) async {
    final scope = setlistId == null
        ? BookmarkScope.score(scoreId)
        : BookmarkScope.setlist(setlistId);
    final count = await _bookmarkCount(scope);
    await into(bookmarks).insert(
      BookmarksCompanion.insert(
        id: _uuid.v4(),
        scoreId: scoreId,
        page: page,
        label: label,
        setlistId: Value(setlistId),
        sortOrder: Value(count),
      ),
    );
  }

  Future<void> renameBookmark(String id, String label) =>
      (update(bookmarks)..where((t) => t.id.equals(id))).write(
        BookmarksCompanion(label: Value(label)),
      );

  Future<void> deleteBookmark(String id) =>
      (delete(bookmarks)..where((t) => t.id.equals(id))).go();

  Future<int> _bookmarkCount(BookmarkScope scope) async {
    final c = bookmarks.id.count();
    final row =
        await (selectOnly(bookmarks)
              ..addColumns([c])
              ..where(scope._filter(bookmarks)))
            .getSingle();
    return row.read(c) ?? 0;
  }

  // ---- 점프 버튼 ----

  Stream<List<JumpButton>> watchJumps(String scoreId) =>
      (select(jumpButtons)..where((t) => t.scoreId.equals(scoreId))).watch();

  Future<void> addJump({
    required String scoreId,
    required int fromPage,
    required double x,
    required double y,
    required int toPage,
    String? label,
  }) => into(jumpButtons).insert(
    JumpButtonsCompanion.insert(
      id: _uuid.v4(),
      scoreId: scoreId,
      fromPage: fromPage,
      x: x,
      y: y,
      toPage: toPage,
      label: Value(label),
    ),
  );

  Future<void> moveJump(String id, double x, double y) =>
      (update(jumpButtons)..where((t) => t.id.equals(id))).write(
        JumpButtonsCompanion(x: Value(x), y: Value(y)),
      );

  Future<void> deleteJump(String id) =>
      (delete(jumpButtons)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllJumps(String scoreId) =>
      (delete(jumpButtons)..where((t) => t.scoreId.equals(scoreId))).go();
}

final pageToolsDaoProvider = Provider<PageToolsDao>(
  (ref) => PageToolsDao(ref.watch(appDatabaseProvider)),
);

final bookmarksProvider = StreamProvider.family<List<Bookmark>, BookmarkScope>(
  (ref, scope) => ref.watch(pageToolsDaoProvider).watchBookmarks(scope),
);

/// 북마크 주인. 곡 하나이거나 세트리스트 하나다.
///
/// 곡을 볼 때는 그 곡의 북마크만, 세트를 볼 때는 그 세트의 북마크만 보인다.
@immutable
class BookmarkScope {
  const BookmarkScope.score(String this.scoreId) : setlistId = null;
  const BookmarkScope.setlist(String this.setlistId) : scoreId = null;

  final String? scoreId;
  final String? setlistId;

  bool get isSetlist => setlistId != null;

  Expression<bool> _filter($BookmarksTable t) => isSetlist
      ? t.setlistId.equals(setlistId!)
      : t.scoreId.equals(scoreId!) & t.setlistId.isNull();

  @override
  bool operator ==(Object other) =>
      other is BookmarkScope &&
      other.scoreId == scoreId &&
      other.setlistId == setlistId;

  @override
  int get hashCode => Object.hash(scoreId, setlistId);
}

final jumpButtonsProvider = StreamProvider.family<List<JumpButton>, String>(
  (ref, scoreId) => ref.watch(pageToolsDaoProvider).watchJumps(scoreId),
);
