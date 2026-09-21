import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/tables.dart';
import 'package:his_score/features/annotation/data/annotation_dao.dart';
import 'package:his_score/features/annotation/data/page_ink_store.dart';
import 'package:his_score/features/annotation/domain/ink_models.dart';

/// 지우개 옵션의 "직전 필기 지우기". iOS 밖에서는 Flutter 가 그린 펜 획을 뗀다.
void main() {
  late AppDatabase db;
  late PageInkController page;

  Stroke stroke(String id, StrokeTool tool) => Stroke(
    id: id,
    tool: tool,
    color: const Color(0xFF000000),
    width: 1,
    points: const [InkPoint(0, 0, 0.5), InkPoint(1, 1, 0.5)],
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.scores)
        .insert(
          ScoresCompanion.insert(
            id: 'a',
            title: 'A',
            filePath: 'a.pdf',
            pageCount: const Value(1),
          ),
        );
    page = PageInkController(dao: AnnotationDao(db), scoreId: 'a', page: 1);
    await page.load();
  });

  tearDown(() async {
    await page.flush();
    await db.close();
  });

  List<String> ids() => [for (final s in page.ink.strokes) s.id];

  test('가장 나중에 그은 펜 획을 떼고, 도형은 건드리지 않는다', () async {
    page.addStroke(stroke('pen1', StrokeTool.pen));
    page.addStroke(stroke('pen2', StrokeTool.marker));
    page.addStroke(stroke('shape', StrokeTool.shape));

    expect(await page.removeLastPenStroke(), isTrue);
    expect(ids(), ['pen1', 'shape']);

    expect(await page.removeLastPenStroke(), isTrue);
    expect(ids(), ['shape']);
  });

  test('뗀 획은 되돌리기로 살아난다', () async {
    page.addStroke(stroke('pen1', StrokeTool.pen));
    page.addStroke(stroke('pen2', StrokeTool.pencil));
    await page.removeLastPenStroke();
    page.undo();
    expect(ids(), ['pen1', 'pen2']);
  });

  test('펜 획이 없으면 아무것도 하지 않고 거짓', () async {
    expect(page.hasPenStroke, isFalse);
    page.addStroke(stroke('shape', StrokeTool.shape));
    expect(page.hasPenStroke, isFalse);
    expect(await page.removeLastPenStroke(), isFalse);
    expect(ids(), ['shape']);
  });
}
