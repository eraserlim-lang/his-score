import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/tables.dart';
import 'package:his_score/features/viewer/domain/spreads.dart';

void main() {
  group('1페이지 보기', () {
    const map = SpreadMap(
      pageCount: 5,
      layout: PageLayout.single,
      startOnRight: false,
    );

    test('묶음 수가 페이지 수와 같다', () => expect(map.spreadCount, 5));
    test('묶음과 페이지가 1:1 이다', () {
      for (var i = 0; i < 5; i++) {
        expect(map.pagesOf(i), [i]);
        expect(map.spreadOf(i), i);
      }
    });
  });

  group('2페이지 보기, 왼쪽부터', () {
    const map = SpreadMap(
      pageCount: 5,
      layout: PageLayout.dual,
      startOnRight: false,
    );

    test('홀수 페이지면 마지막 묶음이 한 장이다', () {
      expect(map.spreadCount, 3);
      expect(map.pagesOf(0), [0, 1]);
      expect(map.pagesOf(1), [2, 3]);
      expect(map.pagesOf(2), [4]);
    });

    test('페이지에서 묶음을 되찾는다', () {
      expect(map.spreadOf(0), 0);
      expect(map.spreadOf(1), 0);
      expect(map.spreadOf(2), 1);
      expect(map.spreadOf(4), 2);
    });
  });

  group('2페이지 보기, 첫 장을 오른쪽에', () {
    const map = SpreadMap(
      pageCount: 5,
      layout: PageLayout.dual,
      startOnRight: true,
    );

    test('첫 장은 혼자 서고 그 뒤부터 둘씩 묶인다', () {
      expect(map.spreadCount, 3);
      expect(map.pagesOf(0), [0]);
      expect(map.pagesOf(1), [1, 2]);
      expect(map.pagesOf(2), [3, 4]);
    });

    test('페이지에서 묶음을 되찾는다', () {
      expect(map.spreadOf(0), 0);
      expect(map.spreadOf(1), 1);
      expect(map.spreadOf(2), 1);
      expect(map.spreadOf(3), 2);
      expect(map.spreadOf(4), 2);
    });

    test('왕복해도 같은 묶음으로 돌아온다', () {
      for (var page = 0; page < 5; page++) {
        final spread = map.spreadOf(page);
        expect(map.pagesOf(spread), contains(page));
      }
    });
  });

  test('빈 악보에서도 터지지 않는다', () {
    const empty = SpreadMap(
      pageCount: 0,
      layout: PageLayout.dual,
      startOnRight: true,
    );
    expect(empty.spreadCount, 0);
    expect(empty.pagesOf(0), isEmpty);
    expect(empty.spreadOf(0), 0);
    expect(empty.firstPageOf(0), 0);
  });
}
