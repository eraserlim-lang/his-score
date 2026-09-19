import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/setlist_dao.dart';

/// 세트리스트 항목의 페이지 구간이 저장되고 다시 읽히는지.
void main() {
  late AppDatabase db;
  late SetlistDao setlists;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    setlists = SetlistDao(db);
  });

  tearDown(() => db.close());

  Future<String> addScore(String id, {int pageCount = 5}) async {
    await db.into(db.scores).insert(
          ScoresCompanion.insert(
            id: id,
            title: id,
            filePath: '$id.pdf',
            pageCount: Value(pageCount),
          ),
        );
    for (var i = 0; i < pageCount; i++) {
      await db.into(db.scorePages).insert(
            ScorePagesCompanion.insert(
              id: '$id-$i',
              scoreId: id,
              sourceIndex: i,
              displayOrder: i,
            ),
          );
    }
    return id;
  }

  test('한 쪽만 담으면 그 구간이 그대로 저장된다', () async {
    await addScore('a');
    final setlistId = await setlists.create('테스트', const []);

    await setlists.addScore(setlistId, 'a', startPage: 2, endPage: 2);

    final entries = await setlists.entries(setlistId);
    expect(entries.length, 1);
    expect(entries.first.item.startPage, 2);
    expect(entries.first.item.endPage, 2);
    expect(entries.first.pageCount, 1);
  });

  test('구간을 주지 않으면 곡 전체다', () async {
    await addScore('b');
    final setlistId = await setlists.create('테스트', const []);

    await setlists.addScore(setlistId, 'b');

    final entries = await setlists.entries(setlistId);
    expect(entries.first.item.startPage, null);
    expect(entries.first.pageCount, 5);
  });

  test('같은 곡을 쪽마다 담으면 항목이 쪽 수만큼 생긴다', () async {
    await addScore('c');
    final setlistId = await setlists.create('테스트', const []);

    for (final page in [0, 3]) {
      await setlists.addScore(setlistId, 'c', startPage: page, endPage: page);
    }

    final entries = await setlists.entries(setlistId);
    expect(entries.length, 2);
    expect(entries.map((e) => e.item.startPage), [0, 3]);
    expect(entries.every((e) => e.pageCount == 1), isTrue);
  });
}
