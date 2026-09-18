import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/ink_models.dart';
import 'annotation_dao.dart';

/// 되돌릴 수 있는 편집 하나.
///
/// 앞뒤 상태를 통째로 들고 있는 대신 무엇이 바뀌었는지만 기록해
/// 획이 수백 개인 페이지에서도 실행 취소가 가볍다.
abstract class _InkEdit {
  const _InkEdit();
  PageInk apply(PageInk ink);
  PageInk revert(PageInk ink);
  Future<void> persist(AnnotationDao dao, String scoreId, int page);
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page);
}

class _AddStrokes extends _InkEdit {
  const _AddStrokes(this.strokes);
  final List<Stroke> strokes;

  @override
  PageInk apply(PageInk ink) => ink.copyWith(strokes: [...ink.strokes, ...strokes]);

  @override
  PageInk revert(PageInk ink) {
    final ids = strokes.map((s) => s.id).toSet();
    return ink.copyWith(
      strokes: ink.strokes.where((s) => !ids.contains(s.id)).toList(),
    );
  }

  @override
  Future<void> persist(AnnotationDao dao, String scoreId, int page) =>
      dao.upsertStrokes(scoreId, page, strokes);

  @override
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page) =>
      dao.deleteStrokes(strokes.map((s) => s.id));
}

/// 지우개 한 번. 지운 획과 그 자리에 남은 조각들을 함께 기억한다.
class _ReplaceStrokes extends _InkEdit {
  const _ReplaceStrokes({required this.removed, required this.added});
  final List<Stroke> removed;
  final List<Stroke> added;

  @override
  PageInk apply(PageInk ink) {
    final ids = removed.map((s) => s.id).toSet();
    return ink.copyWith(
      strokes: [
        ...ink.strokes.where((s) => !ids.contains(s.id)),
        ...added,
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  @override
  PageInk revert(PageInk ink) {
    final ids = added.map((s) => s.id).toSet();
    return ink.copyWith(
      strokes: [
        ...ink.strokes.where((s) => !ids.contains(s.id)),
        ...removed,
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  @override
  Future<void> persist(AnnotationDao dao, String scoreId, int page) async {
    await dao.deleteStrokes(removed.map((s) => s.id));
    await dao.upsertStrokes(scoreId, page, added);
  }

  @override
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page) async {
    await dao.deleteStrokes(added.map((s) => s.id));
    await dao.upsertStrokes(scoreId, page, removed);
  }
}

class _AddPlaced extends _InkEdit {
  const _AddPlaced(this.item);
  final PlacedAnnotation item;

  @override
  PageInk apply(PageInk ink) => ink.copyWith(placed: [...ink.placed, item]);

  @override
  PageInk revert(PageInk ink) =>
      ink.copyWith(placed: ink.placed.where((p) => p.id != item.id).toList());

  @override
  Future<void> persist(AnnotationDao dao, String scoreId, int page) =>
      dao.upsertPlaced(scoreId, page, item);

  @override
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page) =>
      dao.deletePlaced([item.id]);
}

class _UpdatePlaced extends _InkEdit {
  const _UpdatePlaced({required this.before, required this.after});
  final PlacedAnnotation before;
  final PlacedAnnotation after;

  @override
  PageInk apply(PageInk ink) => ink.copyWith(
        placed: [for (final p in ink.placed) p.id == after.id ? after : p],
      );

  @override
  PageInk revert(PageInk ink) => ink.copyWith(
        placed: [for (final p in ink.placed) p.id == before.id ? before : p],
      );

  @override
  Future<void> persist(AnnotationDao dao, String scoreId, int page) =>
      dao.upsertPlaced(scoreId, page, after);

  @override
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page) =>
      dao.upsertPlaced(scoreId, page, before);
}

class _RemovePlaced extends _InkEdit {
  const _RemovePlaced(this.item);
  final PlacedAnnotation item;

  @override
  PageInk apply(PageInk ink) =>
      ink.copyWith(placed: ink.placed.where((p) => p.id != item.id).toList());

  @override
  PageInk revert(PageInk ink) => ink.copyWith(placed: [...ink.placed, item]);

  @override
  Future<void> persist(AnnotationDao dao, String scoreId, int page) =>
      dao.deletePlaced([item.id]);

  @override
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page) =>
      dao.upsertPlaced(scoreId, page, item);
}

class _ClearPage extends _InkEdit {
  const _ClearPage(this.before);
  final PageInk before;

  @override
  PageInk apply(PageInk ink) => const PageInk();

  @override
  PageInk revert(PageInk ink) => before;

  @override
  Future<void> persist(AnnotationDao dao, String scoreId, int page) =>
      dao.clearPage(scoreId, page);

  @override
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page) =>
      dao.restorePage(scoreId, page, before);
}

class _SetPencilKit extends _InkEdit {
  const _SetPencilKit({required this.before, required this.after});
  final Uint8List? before;
  final Uint8List? after;

  @override
  PageInk apply(PageInk ink) =>
      ink.copyWith(pencilKitData: after, clearPencilKit: after == null);

  @override
  PageInk revert(PageInk ink) =>
      ink.copyWith(pencilKitData: before, clearPencilKit: before == null);

  @override
  Future<void> persist(AnnotationDao dao, String scoreId, int page) =>
      dao.savePencilKit(scoreId, page, after ?? Uint8List(0));

  @override
  Future<void> unpersist(AnnotationDao dao, String scoreId, int page) =>
      dao.savePencilKit(scoreId, page, before ?? Uint8List(0));
}

/// 페이지 하나의 필기 상태와 실행 취소 기록.
class PageInkController extends ChangeNotifier {
  PageInkController({
    required this.dao,
    required this.scoreId,
    required this.page,
  });

  final AnnotationDao dao;
  final String scoreId;
  final int page;

  PageInk _ink = const PageInk();
  PageInk get ink => _ink;

  bool _loaded = false;
  bool get loaded => _loaded;

  final _undo = <_InkEdit>[];
  final _redo = <_InkEdit>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// 저장은 순서대로 한 줄로 흘려보낸다. 지우개 뒤에 되돌리기가 바로 오면
  /// DB 쓰기 순서가 꼬일 수 있어 큐로 직렬화한다.
  Future<void> _queue = Future.value();

  Future<void> load() async {
    if (_loaded) return;
    _ink = await dao.loadPage(scoreId, page);
    _loaded = true;
    notifyListeners();
  }

  void _commit(_InkEdit edit) {
    _ink = edit.apply(_ink);
    _undo.add(edit);
    _redo.clear();
    notifyListeners();
    _queue = _queue.then((_) => edit.persist(dao, scoreId, page));
  }

  void undo() {
    if (_undo.isEmpty) return;
    final edit = _undo.removeLast();
    _ink = edit.revert(_ink);
    _redo.add(edit);
    notifyListeners();
    _queue = _queue.then((_) => edit.unpersist(dao, scoreId, page));
  }

  void redo() {
    if (_redo.isEmpty) return;
    final edit = _redo.removeLast();
    _ink = edit.apply(_ink);
    _undo.add(edit);
    notifyListeners();
    _queue = _queue.then((_) => edit.persist(dao, scoreId, page));
  }

  Future<void> flush() => _queue;

  void addStroke(Stroke stroke) =>
      _commit(_AddStrokes([stroke.copyWith(sortOrder: _ink.nextOrder)]));

  /// 지우개가 한 번 지나간 결과. 아무것도 안 닿았으면 기록하지 않는다.
  void erase(List<Stroke> removed, List<Stroke> added) {
    if (removed.isEmpty) return;
    _commit(_ReplaceStrokes(removed: removed, added: added));
  }

  void addPlaced(PlacedAnnotation item) =>
      _commit(_AddPlaced(item.copyWith(sortOrder: _ink.nextOrder)));

  void updatePlaced(PlacedAnnotation before, PlacedAnnotation after) =>
      _commit(_UpdatePlaced(before: before, after: after));

  void removePlaced(PlacedAnnotation item) => _commit(_RemovePlaced(item));

  void clear() {
    if (_ink.isEmpty) return;
    _commit(_ClearPage(_ink));
  }

  /// PencilKit 이 그림을 바꿀 때마다 부른다. 획 단위가 아니라 그림 전체다.
  void setPencilKit(Uint8List? data) {
    final before = _ink.pencilKitData;
    if (listEquals(before, data)) return;
    _commit(_SetPencilKit(before: before, after: data));
  }
}

/// 세션 동안 페이지별 컨트롤러를 보관한다.
///
/// 뷰어가 페이지를 넘기며 만든 컨트롤러를 버리지 않아야 뒤로 돌아왔을 때
/// 실행 취소 기록이 살아 있다.
class InkStore {
  InkStore(this.dao);

  final AnnotationDao dao;
  final _controllers = <(String, int), PageInkController>{};

  PageInkController of(String scoreId, int page) {
    return _controllers.putIfAbsent((scoreId, page), () {
      final c = PageInkController(dao: dao, scoreId: scoreId, page: page);
      unawaited(c.load());
      return c;
    });
  }

  /// 전체 삭제. 열린 페이지는 컨트롤러로, 나머지는 DB 로 지운다.
  Future<void> clearScore(String scoreId) async {
    for (final entry in _controllers.entries) {
      if (entry.key.$1 == scoreId) entry.value.clear();
    }
    await Future.wait(_controllers.values.map((c) => c.flush()));
    await dao.clearScore(scoreId);
  }

  Future<void> flushAll() =>
      Future.wait(_controllers.values.map((c) => c.flush()));

  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }
}
