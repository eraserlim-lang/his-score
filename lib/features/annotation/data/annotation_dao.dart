import 'dart:ui' show Color;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/database.dart';
import '../../../core/db/tables.dart';
import '../domain/ink_models.dart';

part 'annotation_dao.g.dart';

/// 필기와 주석의 저장소.
///
/// 페이지 단위로 통째로 읽고, 개체 단위로 쓴다. 획 하나를 그을 때마다
/// 페이지 전체를 다시 쓰면 긴 곡에서 느려진다.
@DriftAccessor(tables: [InkStrokes, Annotations])
class AnnotationDao extends DatabaseAccessor<AppDatabase>
    with _$AnnotationDaoMixin {
  AnnotationDao(super.db);

  static const _uuid = Uuid();
  static String newId() => _uuid.v4();

  Future<PageInk> loadPage(String scoreId, int page) async {
    final strokeRows = await (select(inkStrokes)
          ..where((t) => t.scoreId.equals(scoreId) & t.page.equals(page))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    final placedRows = await (select(annotations)
          ..where((t) => t.scoreId.equals(scoreId) & t.page.equals(page))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();

    Uint8List? pencilKit;
    final strokes = <Stroke>[];
    for (final row in strokeRows) {
      if (row.format == InkFormat.pencilKit) {
        pencilKit = row.data;
        continue;
      }
      strokes.add(
        Stroke(
          id: row.id,
          tool: row.tool,
          color: Color(row.color),
          width: row.width,
          preset: PenPreset.parse(row.subtype),
          shape: row.tool == StrokeTool.shape ? ShapeKind.parse(row.subtype) : null,
          sortOrder: row.sortOrder,
          points: Stroke.decodePoints(row.data),
        ),
      );
    }

    return PageInk(
      strokes: strokes,
      placed: [
        for (final row in placedRows)
          PlacedAnnotation(
            id: row.id,
            kind: row.kind == 'text' ? PlacedKind.text : PlacedKind.stamp,
            value: row.value,
            x: row.x,
            y: row.y,
            color: Color(row.color),
            scale: row.scale,
            rotation: row.rotation,
            fontSize: row.fontSize,
            sortOrder: row.sortOrder,
            boxed: row.boxed ?? false,
          ),
      ],
      pencilKitData: pencilKit,
    );
  }

  /// 곡에 필기가 있는 페이지 번호. 내보내기와 카탈로그 표시에 쓴다.
  Future<Set<int>> pagesWithInk(String scoreId) async {
    final a = await (selectOnly(inkStrokes, distinct: true)
          ..addColumns([inkStrokes.page])
          ..where(inkStrokes.scoreId.equals(scoreId)))
        .get();
    final b = await (selectOnly(annotations, distinct: true)
          ..addColumns([annotations.page])
          ..where(annotations.scoreId.equals(scoreId)))
        .get();
    return {
      for (final r in a) r.read(inkStrokes.page)!,
      for (final r in b) r.read(annotations.page)!,
    };
  }

  Future<void> upsertStroke(String scoreId, int page, Stroke stroke) =>
      into(inkStrokes).insertOnConflictUpdate(
        InkStrokesCompanion.insert(
          id: stroke.id,
          scoreId: scoreId,
          page: page,
          format: const Value(InkFormat.vector),
          tool: Value(stroke.tool),
          color: Value(stroke.color.toARGB32()),
          width: Value(stroke.width),
          subtype: Value(stroke.subtype),
          data: stroke.encodePoints(),
          sortOrder: Value(stroke.sortOrder),
        ),
      );

  Future<void> upsertStrokes(String scoreId, int page, List<Stroke> strokes) {
    return batch((b) {
      for (final s in strokes) {
        b.insert(
          inkStrokes,
          InkStrokesCompanion.insert(
            id: s.id,
            scoreId: scoreId,
            page: page,
            format: const Value(InkFormat.vector),
            tool: Value(s.tool),
            color: Value(s.color.toARGB32()),
            width: Value(s.width),
            subtype: Value(s.subtype),
            data: s.encodePoints(),
            sortOrder: Value(s.sortOrder),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> deleteStrokes(Iterable<String> ids) =>
      (delete(inkStrokes)..where((t) => t.id.isIn(ids))).go();

  Future<void> upsertPlaced(String scoreId, int page, PlacedAnnotation a) =>
      into(annotations).insertOnConflictUpdate(
        AnnotationsCompanion.insert(
          id: a.id,
          scoreId: scoreId,
          page: page,
          kind: a.kind.name,
          value: a.value,
          x: a.x,
          y: a.y,
          scale: Value(a.scale),
          rotation: Value(a.rotation),
          color: Value(a.color.toARGB32()),
          fontSize: Value(a.fontSize),
          sortOrder: Value(a.sortOrder),
          boxed: Value(a.boxed),
        ),
      );

  Future<void> deletePlaced(Iterable<String> ids) =>
      (delete(annotations)..where((t) => t.id.isIn(ids))).go();

  /// PencilKit 그림은 페이지당 한 행이다. 있으면 바꾸고 없으면 만든다.
  Future<void> savePencilKit(String scoreId, int page, Uint8List data) {
    return transaction(() async {
      await (delete(inkStrokes)
            ..where(
              (t) =>
                  t.scoreId.equals(scoreId) &
                  t.page.equals(page) &
                  t.format.equals(InkFormat.pencilKit.index),
            ))
          .go();
      if (data.isEmpty) return;
      await into(inkStrokes).insert(
        InkStrokesCompanion.insert(
          id: newId(),
          scoreId: scoreId,
          page: page,
          format: const Value(InkFormat.pencilKit),
          data: data,
        ),
      );
    });
  }

  Future<void> clearPage(String scoreId, int page) {
    return transaction(() async {
      await (delete(inkStrokes)
            ..where((t) => t.scoreId.equals(scoreId) & t.page.equals(page)))
          .go();
      await (delete(annotations)
            ..where((t) => t.scoreId.equals(scoreId) & t.page.equals(page)))
          .go();
    });
  }

  Future<void> clearScore(String scoreId) {
    return transaction(() async {
      await (delete(inkStrokes)..where((t) => t.scoreId.equals(scoreId))).go();
      await (delete(annotations)..where((t) => t.scoreId.equals(scoreId))).go();
    });
  }

  /// 페이지 전체를 한 번에 되살린다. 백업 복원과 전체 삭제 취소에 쓴다.
  Future<void> restorePage(String scoreId, int page, PageInk ink) {
    return transaction(() async {
      await clearPage(scoreId, page);
      await upsertStrokes(scoreId, page, ink.strokes);
      for (final p in ink.placed) {
        await upsertPlaced(scoreId, page, p);
      }
      if (ink.pencilKitData != null) {
        await savePencilKit(scoreId, page, ink.pencilKitData!);
      }
    });
  }
}

final annotationDaoProvider = Provider<AnnotationDao>(
  (ref) => AnnotationDao(ref.watch(appDatabaseProvider)),
);
