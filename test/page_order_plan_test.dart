import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/features/viewer/domain/page_order_plan.dart';

/// 편집 화면의 항목 대신 쓰는 최소한의 모형.
class _P implements OrderedPage {
  _P(
    this.id,
    this.scoreId, {
    this.added = false,
    this.savedHidden = false,
    this.excludedFromSet = false,
  });

  @override
  final String id;
  @override
  final String scoreId;
  @override
  final bool added;
  @override
  final bool savedHidden;
  @override
  final bool excludedFromSet;

  @override
  String toString() => id;
}

List<String> _ids(List<_P> pages) => [for (final p in pages) p.id];

void main() {
  group('곡별 페이지 다시 세우기', () {
    test('한 곡 안에서 바꾼 순서가 그대로 남는다', () {
      final a = _P('a', 's');
      final b = _P('b', 's');
      final c = _P('c', 's');

      final rebuilt = rebuildScorePages([c, a, b], {
        's': [a, b, c],
      });

      expect(_ids(rebuilt['s']!), ['c', 'a', 'b']);
    });

    test('편집 화면이 다루지 않은 페이지는 자리를 지킨다', () {
      // 세트에는 가운데 두 장만 들어 있다.
      final p0 = _P('p0', 's');
      final p1 = _P('p1', 's');
      final p2 = _P('p2', 's');
      final p3 = _P('p3', 's');

      final rebuilt = rebuildScorePages([p2, p1], {
        's': [p0, p1, p2, p3],
      });

      expect(_ids(rebuilt['s']!), ['p0', 'p2', 'p1', 'p3']);
    });

    test('새로 넣은 빈 페이지와 복제본이 함께 자리를 잡는다', () {
      final p0 = _P('p0', 's');
      final p1 = _P('p1', 's');
      final blank = _P('new', 's', added: true);

      final rebuilt = rebuildScorePages([p0, blank, p1], {
        's': [p0, p1],
      });

      expect(_ids(rebuilt['s']!), ['p0', 'new', 'p1']);
    });

    test('곡을 넘나들어도 곡마다 제 페이지만 모인다', () {
      final a0 = _P('a0', 'A');
      final a1 = _P('a1', 'A');
      final b0 = _P('b0', 'B');
      final b1 = _P('b1', 'B');

      final rebuilt = rebuildScorePages([a0, b0, a1, b1], {
        'A': [a0, a1],
        'B': [b0, b1],
      });

      expect(_ids(rebuilt['A']!), ['a0', 'a1']);
      expect(_ids(rebuilt['B']!), ['b0', 'b1']);
    });
  });

  group('세트리스트 항목 다시 나누기', () {
    test('곡 하나를 통째로 쓰면 구간을 비운다', () {
      final a0 = _P('a0', 'A');
      final a1 = _P('a1', 'A');
      final entries = [a0, a1];
      final rebuilt = rebuildScorePages(entries, {
        'A': [a0, a1],
      });

      final items = draftSetlistItems(entries, rebuilt);
      expect(items.length, 1);
      expect(items.first.scoreId, 'A');
      expect(items.first.startPage, isNull);
      expect(items.first.endPage, isNull);
    });

    test('곡에 숨긴 페이지가 있어도 통째로 쓰는 것으로 본다', () {
      final a0 = _P('a0', 'A');
      final hidden = _P('a1', 'A', savedHidden: true);
      final a2 = _P('a2', 'A');
      final entries = [a0, a2];
      final rebuilt = rebuildScorePages(entries, {
        'A': [a0, hidden, a2],
      });

      final items = draftSetlistItems(entries, rebuilt);
      expect(items.length, 1);
      expect(items.first.startPage, isNull);
      expect(items.first.endPage, isNull);
    });

    test('곡을 넘나들며 섞으면 토막마다 항목이 생긴다', () {
      final a0 = _P('a0', 'A');
      final a1 = _P('a1', 'A');
      final b0 = _P('b0', 'B');
      final b1 = _P('b1', 'B');
      final entries = [a0, b0, a1, b1];
      final rebuilt = rebuildScorePages(entries, {
        'A': [a0, a1],
        'B': [b0, b1],
      });

      final items = draftSetlistItems(entries, rebuilt);
      expect([for (final i in items) i.scoreId], ['A', 'B', 'A', 'B']);
      expect([for (final i in items) i.startPage], [0, 0, 1, 1]);
      expect([for (final i in items) i.endPage], [0, 0, 1, 1]);
    });

    test('세트에서 뺀 페이지는 구간에서 빠지고 곡에는 남는다', () {
      final a0 = _P('a0', 'A');
      final a1 = _P('a1', 'A', excludedFromSet: true);
      final a2 = _P('a2', 'A');
      final entries = [a0, a1, a2];
      final rebuilt = rebuildScorePages(entries, {
        'A': [a0, a1, a2],
      });

      // 곡에서는 세 장 그대로다.
      expect(_ids(rebuilt['A']!), ['a0', 'a1', 'a2']);

      final items = draftSetlistItems(entries, rebuilt);
      expect([for (final i in items) i.startPage], [0, 2]);
      expect([for (final i in items) i.endPage], [0, 2]);
    });

    test('세트에 남은 페이지가 없으면 항목도 없다', () {
      final a0 = _P('a0', 'A', excludedFromSet: true);
      final entries = [a0];
      final rebuilt = rebuildScorePages(entries, {
        'A': [a0],
      });

      expect(draftSetlistItems(entries, rebuilt), isEmpty);
    });

    test('곡 순서를 통째로 뒤집으면 항목 순서만 바뀐다', () {
      final a0 = _P('a0', 'A');
      final a1 = _P('a1', 'A');
      final b0 = _P('b0', 'B');
      final entries = [b0, a0, a1];
      final rebuilt = rebuildScorePages(entries, {
        'A': [a0, a1],
        'B': [b0],
      });

      final items = draftSetlistItems(entries, rebuilt);
      expect([for (final i in items) i.scoreId], ['B', 'A']);
      // 둘 다 곡 전체라 구간이 비어 있다.
      expect([for (final i in items) i.startPage], [null, null]);
    });
  });
}
