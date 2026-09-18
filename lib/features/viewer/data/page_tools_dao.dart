import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
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

  Stream<List<Bookmark>> watchBookmarks(String scoreId) => (select(bookmarks)
        ..where((t) => t.scoreId.equals(scoreId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.sortOrder),
          (t) => OrderingTerm(expression: t.page),
        ]))
      .watch();

  Future<List<Bookmark>> bookmarksOf(String scoreId) =>
      watchBookmarks(scoreId).first;

  Future<void> addBookmark(String scoreId, int page, String label) async {
    final count = await _bookmarkCount(scoreId);
    await into(bookmarks).insert(
      BookmarksCompanion.insert(
        id: _uuid.v4(),
        scoreId: scoreId,
        page: page,
        label: label,
        sortOrder: Value(count),
      ),
    );
  }

  Future<void> renameBookmark(String id, String label) =>
      (update(bookmarks)..where((t) => t.id.equals(id)))
          .write(BookmarksCompanion(label: Value(label)));

  Future<void> deleteBookmark(String id) =>
      (delete(bookmarks)..where((t) => t.id.equals(id))).go();

  Future<int> _bookmarkCount(String scoreId) async {
    final c = bookmarks.id.count();
    final row = await (selectOnly(bookmarks)
          ..addColumns([c])
          ..where(bookmarks.scoreId.equals(scoreId)))
        .getSingle();
    return row.read(c) ?? 0;
  }

  /// PDF 목차를 북마크로 들여온다. 기존 북마크 뒤에 붙는다.
  /// 들여온 개수를 돌려준다.
  Future<int> importOutline(String scoreId, PdfDocument document) async {
    final nodes = await document.loadOutline();
    final flat = <(int depth, PdfOutlineNode node)>[];
    void walk(List<PdfOutlineNode> list, int depth) {
      for (final n in list) {
        flat.add((depth, n));
        walk(n.children, depth + 1);
      }
    }

    walk(nodes, 0);
    if (flat.isEmpty) return 0;

    var order = await _bookmarkCount(scoreId);
    await batch((b) {
      for (final (depth, node) in flat) {
        final page = node.dest?.pageNumber;
        if (page == null) continue;
        b.insert(
          bookmarks,
          BookmarksCompanion.insert(
            id: _uuid.v4(),
            scoreId: scoreId,
            page: page,
            label: node.title.trim().isEmpty ? '$page쪽' : node.title.trim(),
            depth: Value(depth),
            sortOrder: Value(order++),
          ),
        );
      }
    });
    return flat.where((e) => e.$2.dest?.pageNumber != null).length;
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
  }) =>
      into(jumpButtons).insert(
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
      (update(jumpButtons)..where((t) => t.id.equals(id)))
          .write(JumpButtonsCompanion(x: Value(x), y: Value(y)));

  Future<void> deleteJump(String id) =>
      (delete(jumpButtons)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAllJumps(String scoreId) =>
      (delete(jumpButtons)..where((t) => t.scoreId.equals(scoreId))).go();
}

final pageToolsDaoProvider = Provider<PageToolsDao>(
  (ref) => PageToolsDao(ref.watch(appDatabaseProvider)),
);

final bookmarksProvider = StreamProvider.family<List<Bookmark>, String>(
  (ref, scoreId) => ref.watch(pageToolsDaoProvider).watchBookmarks(scoreId),
);

final jumpButtonsProvider = StreamProvider.family<List<JumpButton>, String>(
  (ref, scoreId) => ref.watch(pageToolsDaoProvider).watchJumps(scoreId),
);
