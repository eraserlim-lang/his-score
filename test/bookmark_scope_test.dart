import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/setlist_dao.dart';
import 'package:his_score/features/viewer/data/page_tools_dao.dart';

/// 곡 북마크와 세트리스트 북마크가 서로 섞이지 않는지.
void main() {
  late AppDatabase db;
  late PageToolsDao tools;
  late SetlistDao setlists;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tools = PageToolsDao(db);
    setlists = SetlistDao(db);
    await db
        .into(db.scores)
        .insert(
          ScoresCompanion.insert(
            id: 'a',
            title: 'A',
            filePath: 'a.pdf',
            pageCount: const Value(5),
          ),
        );
  });

  tearDown(() => db.close());

  Future<List<String>> labels(BookmarkScope scope) async => [
    for (final b in await tools.watchBookmarks(scope).first) b.label,
  ];

  test('곡 북마크는 곡에서만, 세트 북마크는 그 세트에서만 보인다', () async {
    final set1 = await setlists.create('1부', const []);
    final set2 = await setlists.create('2부', const []);

    await tools.addBookmark('a', 2, '곡에서 단 것');
    await tools.addBookmark('a', 3, '1부에서 단 것', setlistId: set1);
    await tools.addBookmark('a', 4, '2부에서 단 것', setlistId: set2);

    expect(await labels(const BookmarkScope.score('a')), ['곡에서 단 것']);
    expect(await labels(BookmarkScope.setlist(set1)), ['1부에서 단 것']);
    expect(await labels(BookmarkScope.setlist(set2)), ['2부에서 단 것']);
    expect(
      [for (final b in await tools.bookmarksOf('a')) b.label],
      ['곡에서 단 것'],
    );
  });

  test('세트 북마크도 어느 곡의 몇 쪽인지 기억한다', () async {
    final set1 = await setlists.create('1부', const []);
    await tools.addBookmark('a', 3, '앙코르', setlistId: set1);
    final b =
        (await tools.watchBookmarks(BookmarkScope.setlist(set1)).first).single;
    expect(b.scoreId, 'a');
    expect(b.page, 3);
    expect(b.setlistId, set1);
  });

  test('세트를 지우면 그 세트의 북마크만 사라진다', () async {
    final set1 = await setlists.create('1부', const []);
    await tools.addBookmark('a', 2, '곡');
    await tools.addBookmark('a', 3, '세트', setlistId: set1);

    await setlists.deleteSetlist(set1);

    expect(await labels(const BookmarkScope.score('a')), ['곡']);
    expect(await labels(BookmarkScope.setlist(set1)), isEmpty);
  });

  test('곡 북마크와 세트 북마크는 순서 번호를 따로 센다', () async {
    final set1 = await setlists.create('1부', const []);
    await tools.addBookmark('a', 1, '곡1');
    await tools.addBookmark('a', 2, '곡2');
    await tools.addBookmark('a', 3, '세트1', setlistId: set1);
    final b =
        (await tools.watchBookmarks(BookmarkScope.setlist(set1)).first).single;
    expect(b.sortOrder, 0);
  });
}
