import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'database.dart';
import 'tables.dart';

part 'setlist_dao.g.dart';

/// 세트리스트 항목에 곡 정보를 붙인 것. 화면에서 바로 쓰기 위한 모양이다.
class SetlistEntry {
  const SetlistEntry({required this.item, required this.score});

  final SetlistItem item;
  final Score score;

  /// 이 항목이 차지하는 페이지 수. 구간이 없으면 곡 전체다.
  int get pageCount {
    final start = item.startPage ?? 0;
    final end = item.endPage ?? (score.pageCount - 1);
    return (end - start + 1).clamp(0, score.pageCount);
  }
}

/// 새로 써 넣을 세트리스트 항목 하나. 페이지 순서를 고친 결과를 받는다.
class SetlistItemDraft {
  const SetlistItemDraft({
    required this.scoreId,
    this.startPage,
    this.endPage,
  });

  final String scoreId;

  /// 곡의 보이는 페이지 목록 안에서의 구간. null 이면 곡 전체다.
  final int? startPage;
  final int? endPage;
}

class SetlistWithCount {
  const SetlistWithCount({required this.setlist, required this.itemCount});

  final Setlist setlist;
  final int itemCount;
}

@DriftAccessor(tables: [Setlists, SetlistItems, Scores])
class SetlistDao extends DatabaseAccessor<AppDatabase> with _$SetlistDaoMixin {
  SetlistDao(super.db);

  static const _uuid = Uuid();

  Stream<List<SetlistWithCount>> watchAll() {
    final count = setlistItems.id.count();
    final q = select(setlists).join([
      leftOuterJoin(
        setlistItems,
        setlistItems.setlistId.equalsExp(setlists.id),
        useColumns: false,
      ),
    ])
      ..addColumns([count])
      ..groupBy([setlists.id])
      ..orderBy([OrderingTerm.desc(setlists.updatedAt)]);

    return q.watch().map(
          (rows) => [
            for (final r in rows)
              SetlistWithCount(
                setlist: r.readTable(setlists),
                itemCount: r.read(count) ?? 0,
              ),
          ],
        );
  }

  Stream<Setlist?> watchById(String id) =>
      (select(setlists)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<Setlist?> findById(String id) =>
      (select(setlists)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<SetlistEntry>> watchEntries(String setlistId) {
    final q = select(setlistItems).join([
      innerJoin(scores, scores.id.equalsExp(setlistItems.scoreId)),
    ])
      ..where(setlistItems.setlistId.equals(setlistId))
      ..orderBy([OrderingTerm(expression: setlistItems.sortOrder)]);

    return q.watch().map(
          (rows) => [
            for (final r in rows)
              SetlistEntry(
                item: r.readTable(setlistItems),
                score: r.readTable(scores),
              ),
          ],
        );
  }

  Future<List<SetlistEntry>> entries(String setlistId) =>
      watchEntries(setlistId).first;

  Future<String> create(String name, List<String> scoreIds) {
    final id = _uuid.v4();
    return transaction(() async {
      await into(setlists).insert(SetlistsCompanion.insert(id: id, name: name));
      await _appendAll(id, scoreIds, startOrder: 0);
      return id;
    });
  }

  Future<void> rename(String id, String name, {String? note}) =>
      (update(setlists)..where((t) => t.id.equals(id))).write(
        SetlistsCompanion(
          name: Value(name),
          note: Value(note),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> deleteSetlist(String id) =>
      (delete(setlists)..where((t) => t.id.equals(id))).go();

  Future<void> addScores(String setlistId, List<String> scoreIds) {
    return transaction(() async {
      final last = await (selectOnly(setlistItems)
            ..addColumns([setlistItems.sortOrder.max()])
            ..where(setlistItems.setlistId.equals(setlistId)))
          .getSingle();
      final start = (last.read(setlistItems.sortOrder.max()) ?? -1) + 1;
      await _appendAll(setlistId, scoreIds, startOrder: start);
      await _touch(setlistId);
    });
  }

  /// 곡 하나를 세트리스트 끝에 붙인다.
  ///
  /// [startPage]/[endPage] 를 주면 그 구간만 담는다. 보고 있는 한 쪽만
  /// 세트에 넣을 때 쓴다. 넣은 항목의 id 를 돌려준다.
  Future<String> addScore(
    String setlistId,
    String scoreId, {
    int? startPage,
    int? endPage,
  }) {
    final itemId = _uuid.v4();
    return transaction(() async {
      final last = await (selectOnly(setlistItems)
            ..addColumns([setlistItems.sortOrder.max()])
            ..where(setlistItems.setlistId.equals(setlistId)))
          .getSingle();
      final order = (last.read(setlistItems.sortOrder.max()) ?? -1) + 1;
      await into(setlistItems).insert(
        SetlistItemsCompanion.insert(
          id: itemId,
          setlistId: setlistId,
          scoreId: scoreId,
          sortOrder: order,
          startPage: Value(startPage),
          endPage: Value(endPage),
        ),
      );
      await _touch(setlistId);
      return itemId;
    });
  }

  Future<void> _appendAll(
    String setlistId,
    List<String> scoreIds, {
    required int startOrder,
  }) {
    return batch((b) {
      for (var i = 0; i < scoreIds.length; i++) {
        b.insert(
          setlistItems,
          SetlistItemsCompanion.insert(
            id: _uuid.v4(),
            setlistId: setlistId,
            scoreId: scoreIds[i],
            sortOrder: startOrder + i,
          ),
        );
      }
    });
  }

  Future<void> removeItem(String itemId) async {
    final item = await (select(setlistItems)..where((t) => t.id.equals(itemId)))
        .getSingleOrNull();
    if (item == null) return;
    await (delete(setlistItems)..where((t) => t.id.equals(itemId))).go();
    await _touch(item.setlistId);
  }

  /// 항목 순서를 통째로 다시 매긴다. 드래그 정렬 결과를 받는다.
  Future<void> reorder(String setlistId, List<String> itemIdsInOrder) {
    return transaction(() async {
      for (var i = 0; i < itemIdsInOrder.length; i++) {
        await (update(setlistItems)
              ..where((t) => t.id.equals(itemIdsInOrder[i])))
            .write(SetlistItemsCompanion(sortOrder: Value(i)));
      }
      await _touch(setlistId);
    });
  }

  /// 항목 목록을 통째로 갈아 끼운다.
  ///
  /// 세트 전체의 페이지 순서를 고치면 한 곡이 여러 구간으로 쪼개지거나
  /// 순서가 뒤바뀔 수 있어, 항목을 다시 만드는 편이 깔끔하다.
  Future<void> replaceItems(String setlistId, List<SetlistItemDraft> items) {
    return transaction(() async {
      await (delete(setlistItems)..where((t) => t.setlistId.equals(setlistId)))
          .go();
      await batch((b) {
        for (var i = 0; i < items.length; i++) {
          b.insert(
            setlistItems,
            SetlistItemsCompanion.insert(
              id: _uuid.v4(),
              setlistId: setlistId,
              scoreId: items[i].scoreId,
              sortOrder: i,
              startPage: Value(items[i].startPage),
              endPage: Value(items[i].endPage),
            ),
          );
        }
      });
      await _touch(setlistId);
    });
  }

  /// 곡 일부 구간만 연주할 때 쓴다. null 이면 곡 전체로 돌아간다.
  Future<void> setPageRange(String itemId, int? start, int? end) =>
      (update(setlistItems)..where((t) => t.id.equals(itemId))).write(
        SetlistItemsCompanion(startPage: Value(start), endPage: Value(end)),
      );

  Future<String> duplicate(String id) {
    return transaction(() async {
      final source = await findById(id);
      if (source == null) throw StateError('세트리스트가 없습니다');
      final items = await (select(setlistItems)
            ..where((t) => t.setlistId.equals(id))
            ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
          .get();

      final newId = _uuid.v4();
      await into(setlists).insert(
        SetlistsCompanion.insert(
          id: newId,
          name: '${source.name} 복사본',
          note: Value(source.note),
        ),
      );
      await batch((b) {
        for (final item in items) {
          b.insert(
            setlistItems,
            SetlistItemsCompanion.insert(
              id: _uuid.v4(),
              setlistId: newId,
              scoreId: item.scoreId,
              sortOrder: item.sortOrder,
              startPage: Value(item.startPage),
              endPage: Value(item.endPage),
            ),
          );
        }
      });
      return newId;
    });
  }

  Future<void> _touch(String setlistId) =>
      (update(setlists)..where((t) => t.id.equals(setlistId)))
          .write(SetlistsCompanion(updatedAt: Value(DateTime.now())));
}

final setlistDaoProvider =
    Provider<SetlistDao>((ref) => SetlistDao(ref.watch(appDatabaseProvider)));

final setlistsProvider = StreamProvider<List<SetlistWithCount>>(
  (ref) => ref.watch(setlistDaoProvider).watchAll(),
);

final setlistProvider = StreamProvider.family<Setlist?, String>(
  (ref, id) => ref.watch(setlistDaoProvider).watchById(id),
);

final setlistEntriesProvider =
    StreamProvider.family<List<SetlistEntry>, String>(
  (ref, id) => ref.watch(setlistDaoProvider).watchEntries(id),
);
