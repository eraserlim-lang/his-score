import '../../../core/db/setlist_dao.dart';

/// 페이지 순서 편집 화면이 다루는 한 줄. 화면 쪽 항목이 이 모양을 갖춘다.
abstract interface class OrderedPage {
  /// score_pages 행 id.
  String get id;

  String get scoreId;

  /// 편집 화면에서 새로 만든 행. 원본 행의 자리를 차지하지 않는다.
  bool get added;

  /// DB 에 남길 숨김 값. 세트에서만 뺀 페이지는 곡에서는 그대로 보인다.
  bool get savedHidden;

  /// 세트에서 뺐는지. 곡 하나만 고칠 때는 [savedHidden] 과 같다.
  bool get excludedFromSet;
}

/// 곡별 새 페이지 목록을 만든다.
///
/// [entries] 는 편집 화면이 보여 준 페이지들의 최종 순서다. 곡을 넘나들며
/// 섞여 있어도 좋다. [full] 은 곡별 전체 페이지 행이다.
///
/// 편집 화면이 다루는 페이지는 최종 순서대로 한 덩어리로 놓고, 다루지 않는
/// 페이지(숨긴 페이지, 세트 구간 밖의 페이지)는 원래 자리를 지킨다.
/// 덩어리는 그 곡의 첫 편집 대상 페이지가 있던 자리에 들어간다.
Map<String, List<T>> rebuildScorePages<T extends OrderedPage>(
  List<T> entries,
  Map<String, List<T>> full,
) {
  final byScore = <String, List<T>>{};
  for (final e in entries) {
    (byScore[e.scoreId] ??= <T>[]).add(e);
  }

  final rebuilt = <String, List<T>>{};
  for (final scoreId in byScore.keys) {
    final edited = byScore[scoreId]!;
    final owned = {for (final e in edited) if (!e.added) e.id};

    final rows = <T>[];
    var placed = false;
    for (final r in full[scoreId] ?? <T>[]) {
      if (owned.contains(r.id)) {
        if (!placed) {
          placed = true;
          rows.addAll(edited);
        }
        continue;
      }
      rows.add(r);
    }
    if (!placed) rows.addAll(edited);
    rebuilt[scoreId] = rows;
  }
  return rebuilt;
}

/// 세트리스트 항목을 다시 나눈다.
///
/// 곡을 넘나들며 페이지를 옮기면 한 곡이 여러 토막으로 갈린다. 이어진 토막마다
/// 항목 하나를 만든다. 곡 하나를 통째로 쓰는 항목은 구간을 비워 두어
/// 나중에 그 곡의 페이지가 늘어도 따라오게 한다.
List<SetlistItemDraft> draftSetlistItems<T extends OrderedPage>(
  List<T> entries,
  Map<String, List<T>> rebuilt,
) {
  // 곡마다 보이는 페이지가 몇 번째에 놓였는지.
  final visibleIndex = <String, Map<String, int>>{};
  final visibleCount = <String, int>{};
  for (final score in rebuilt.entries) {
    final map = <String, int>{};
    var n = 0;
    for (final row in score.value) {
      if (!row.savedHidden) map[row.id] = n++;
    }
    visibleIndex[score.key] = map;
    visibleCount[score.key] = n;
  }

  final drafts = <SetlistItemDraft>[];
  String? scoreId;
  int? start;
  int? end;

  void flush() {
    if (scoreId == null) return;
    drafts.add(
      SetlistItemDraft(scoreId: scoreId, startPage: start, endPage: end),
    );
  }

  for (final entry in entries) {
    // 세트에서 뺀 페이지는 구간을 끊는다. 곡에서는 그대로 남는다.
    if (entry.excludedFromSet) continue;
    final at = visibleIndex[entry.scoreId]?[entry.id];
    if (at == null) continue;
    if (scoreId == entry.scoreId && end! + 1 == at) {
      end = at;
      continue;
    }
    flush();
    scoreId = entry.scoreId;
    start = at;
    end = at;
  }
  flush();

  final pieces = <String, int>{};
  for (final d in drafts) {
    pieces[d.scoreId] = (pieces[d.scoreId] ?? 0) + 1;
  }
  return [
    for (final d in drafts)
      if (pieces[d.scoreId] == 1 &&
          d.startPage == 0 &&
          d.endPage == (visibleCount[d.scoreId] ?? 0) - 1)
        SetlistItemDraft(scoreId: d.scoreId)
      else
        d,
  ];
}
