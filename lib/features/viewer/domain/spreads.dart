import '../../../core/db/tables.dart';

/// 한 번에 화면에 들어가는 페이지 묶음과 페이지 번호 사이의 변환.
///
/// 1페이지 보기는 묶음 하나에 한 장, 2페이지 보기는 두 장이다.
/// 2페이지 보기에서 [startOnRight] 가 참이면 첫 장이 혼자 오른쪽에 서고
/// 그 뒤부터 (2,3) (4,5) 로 묶여 실제 책의 펼침면과 맞는다.
class SpreadMap {
  const SpreadMap({
    required this.pageCount,
    required this.layout,
    required this.startOnRight,
  });

  final int pageCount;
  final PageLayout layout;
  final bool startOnRight;

  bool get _isDual => layout == PageLayout.dual;

  int get spreadCount {
    if (pageCount == 0) return 0;
    if (!_isDual) return pageCount;
    if (startOnRight) return 1 + ((pageCount - 1) / 2).ceil();
    return (pageCount / 2).ceil();
  }

  /// 묶음 번호가 품고 있는 페이지들(0-based, 화면 왼쪽부터).
  List<int> pagesOf(int spread) {
    if (pageCount == 0) return const [];
    if (!_isDual) {
      final page = spread.clamp(0, pageCount - 1);
      return [page];
    }
    if (startOnRight) {
      if (spread <= 0) return const [0];
      final left = spread * 2 - 1;
      return [
        if (left < pageCount) left,
        if (left + 1 < pageCount) left + 1,
      ];
    }
    final left = spread * 2;
    return [
      if (left < pageCount) left,
      if (left + 1 < pageCount) left + 1,
    ];
  }

  /// 페이지가 속한 묶음 번호.
  int spreadOf(int page) {
    if (pageCount == 0) return 0;
    final p = page.clamp(0, pageCount - 1);
    if (!_isDual) return p;
    if (startOnRight) return p == 0 ? 0 : ((p - 1) ~/ 2) + 1;
    return p ~/ 2;
  }

  /// 묶음의 첫 페이지. 스크롤 위치를 페이지 번호로 되돌릴 때 쓴다.
  int firstPageOf(int spread) {
    final pages = pagesOf(spread);
    return pages.isEmpty ? 0 : pages.first;
  }
}
