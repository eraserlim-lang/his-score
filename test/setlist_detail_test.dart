import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/setlist_dao.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/setlist/presentation/setlist_detail_page.dart';

/// 세트리스트 화면: 넓으면 두 칸, 오른쪽 악보를 누르면 왼쪽 세트에 담긴다.
void main() {
  late AppDatabase db;
  late String setlistId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final (id, title) in [('a', '아리랑'), ('b', '보리밭'), ('c', '고향의 봄')]) {
      await db
          .into(db.scores)
          .insert(
            ScoresCompanion.insert(
              id: id,
              title: title,
              filePath: 'scores/$id.pdf',
              pageCount: const Value(3),
            ),
          );
    }
    setlistId = await SetlistDao(db).create('주일 예배', ['a']);
  });

  tearDown(() => db.close());

  Future<void> open(WidgetTester tester, Size size) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // 표지를 그리려는 경로. 테스트에는 앱 폴더가 없으니 임시 폴더를 준다.
          appPathsProvider.overrideWith(
            (ref) async => AppPaths(Directory.systemTemp),
          ),
        ],
        child: MaterialApp(home: SetlistDetailPage(setlistId: setlistId)),
      ),
    );
    // DB 스트림이 첫 값을 내놓을 때까지 몇 번 밀어 준다.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
  }

  /// 화면을 내리고 DB 스트림이 정리용으로 건 타이머를 흘려보낸다.
  /// 화면이 살아 있는 채로 DB 를 닫으면 스트림이 물고 있어 닫히지 않는다.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('넓으면 세트와 전체 악보를 나란히 두고, 누르면 세트 끝에 담긴다', (tester) async {
    await open(tester, const Size(1100, 800));

    expect(find.text('전체 악보'), findsOneWidget);
    expect(find.text('1곡 · 총 3쪽'), findsOneWidget);
    expect(find.text('세트리스트 보기'), findsOneWidget);

    ListTile libraryRow(String title) => tester.widget<ListTile>(
      find
          .ancestor(of: find.text(title), matching: find.byType(ListTile))
          .last,
    );
    // 세트에 든 곡만 고른 행으로 보인다.
    expect(libraryRow('아리랑').selected, isTrue);
    expect(libraryRow('보리밭').selected, isFalse);
    // 두 칸일 때는 오른쪽 칸이 곡 추가라 위쪽 추가 단추가 없다.
    expect(find.byIcon(Icons.playlist_add), findsNothing);

    // 오른쪽의 '보리밭' 을 담는다.
    final row = find.ancestor(
      of: find.text('보리밭'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: row, matching: find.byIcon(Icons.add)));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }

    expect(find.text('2곡 · 총 6쪽'), findsOneWidget);
    // 테스트 안의 시계는 멈춰 있다. DB 를 직접 물을 때는 진짜 시간에서 묻는다.
    final items = (await tester.runAsync(
      () => SetlistDao(db).entries(setlistId),
    ))!;
    expect([for (final e in items) e.score.id], ['a', 'b']);
    // 담은 곡은 오른쪽 목록에서 몇 번 들었는지 보인다.
    expect(find.textContaining('세트에 1번'), findsNWidgets(2));
    expect(libraryRow('보리밭').selected, isTrue);

    // 이미 든 곡도 또 담을 수 있다.
    final again = find.ancestor(
      of: find.text('아리랑'),
      matching: find.byType(ListTile),
    ).last;
    await tester.tap(find.descendant(of: again, matching: find.byIcon(Icons.add)));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    expect(find.text('3곡 · 총 9쪽'), findsOneWidget);
    expect(find.textContaining('세트에 2번'), findsOneWidget);
    await close(tester);
  });

  testWidgets('좁으면 한 칸에 세트만 두고 곡 추가는 단추로 한다', (tester) async {
    await open(tester, const Size(400, 800));

    expect(find.text('전체 악보'), findsNothing);
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    await close(tester);
  });
}
