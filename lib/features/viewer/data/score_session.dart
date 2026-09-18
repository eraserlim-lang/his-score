import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/db/setlist_dao.dart';
import '../../../core/storage/app_paths.dart';
import 'page_render_cache.dart';

/// 뷰어가 열 대상. 곡 하나이거나 세트리스트 하나다.
@immutable
class SessionKey {
  const SessionKey.score(this.id) : isSetlist = false;
  const SessionKey.setlist(this.id) : isSetlist = true;

  final String id;
  final bool isSetlist;

  @override
  bool operator ==(Object other) =>
      other is SessionKey && other.id == id && other.isSetlist == isSetlist;

  @override
  int get hashCode => Object.hash(id, isSetlist);
}

/// 화면에 보여줄 페이지 한 장.
///
/// 원본 PDF 의 몇 번째 장인지, 어떻게 잘라 보여줄지를 함께 들고 있다.
/// 사용자가 페이지 순서를 바꾸거나 숨겨도 원본은 그대로다.
class ViewPage {
  const ViewPage({
    required this.index,
    required this.scoreId,
    required this.scorePageId,
    required this.docIndex,
    required this.sourcePageNumber,
    required this.crop,
    required this.rotation,
    required this.sourceSize,
  });

  /// 세션 안에서의 0-based 위치.
  final int index;

  final String scoreId;
  final String scorePageId;

  /// 세션이 든 문서 목록 안의 위치. 세트리스트는 여러 문서를 이어 붙인다.
  final int docIndex;

  /// 원본 PDF 안의 1-based 페이지 번호. 0 이면 사용자가 추가한 빈 페이지다.
  final int sourcePageNumber;

  /// 0.0~1.0 비율의 잘라내기 영역. 기본은 전체.
  final Rect crop;

  final double rotation;

  /// 원본 페이지의 포인트 단위 크기.
  final Size sourceSize;

  bool get isBlank => sourcePageNumber == 0;

  /// 잘라낸 뒤의 가로세로 비율.
  double get aspectRatio =>
      (sourceSize.width * crop.width) / (sourceSize.height * crop.height);

  /// 필기와 주석을 저장할 때 쓰는 키. 원본 페이지 기준이어야
  /// 순서를 바꿔도 필기가 따라간다.
  (String, int) get inkKey => (scoreId, sourcePageNumber);
}

/// 악보를 여는 동안 살아 있는 세션.
///
/// PDF 문서 핸들과 렌더 캐시를 함께 들고 있다가 화면을 닫을 때 정리한다.
/// 세트리스트를 열면 여러 곡이 한 세션에 이어 붙는다.
class ScoreSession {
  ScoreSession._({
    required this.key,
    required this.title,
    required this.scores,
    required this.documents,
    required this.caches,
    required this.pages,
  });

  final SessionKey key;
  final String title;

  /// 세션에 든 곡들. 곡 하나면 한 개다.
  final List<Score> scores;
  final List<PdfDocument> documents;
  final List<PageRenderCache> caches;

  /// 숨긴 페이지를 빼고 사용자가 정한 순서로 정렬된 목록.
  final List<ViewPage> pages;

  int get pageCount => pages.length;

  /// 보기 설정은 첫 곡의 것을 따른다.
  Score get primaryScore => scores.first;

  PageRenderCache cacheFor(ViewPage page) => caches[page.docIndex];
  PdfDocument documentFor(ViewPage page) => documents[page.docIndex];

  /// 페이지가 속한 곡. 세트리스트에서 제목 표시에 쓴다.
  Score scoreOf(ViewPage page) => scores[page.docIndex];

  /// 페이지 인덱스로 곡 안의 상대 위치를 구한다.
  int pageIndexOf(String scoreId, int sourcePageNumber) => pages.indexWhere(
        (p) => p.scoreId == scoreId && p.sourcePageNumber == sourcePageNumber,
      );

  /// 곡 하나를 연다.
  static Future<ScoreSession> openScore({
    required Score score,
    required List<ScorePage> scorePages,
    required AppPaths paths,
  }) async {
    final document = await _openDocument(score, paths);
    final pages = _buildPages(
      score: score,
      scorePages: scorePages,
      document: document,
      docIndex: 0,
      startIndex: 0,
    );
    return ScoreSession._(
      key: SessionKey.score(score.id),
      title: score.title,
      scores: [score],
      documents: [document],
      caches: [PageRenderCache(document)],
      pages: pages,
    );
  }

  /// 세트리스트를 연다. 항목마다 지정한 페이지 구간만 이어 붙인다.
  static Future<ScoreSession> openSetlist({
    required Setlist setlist,
    required List<SetlistEntry> entries,
    required Future<List<ScorePage>> Function(String scoreId) pagesOf,
    required AppPaths paths,
  }) async {
    final scores = <Score>[];
    final documents = <PdfDocument>[];
    final pages = <ViewPage>[];

    for (final entry in entries) {
      final document = await _openDocument(entry.score, paths);
      final docIndex = documents.length;
      scores.add(entry.score);
      documents.add(document);

      var scorePages = await pagesOf(entry.score.id);
      final start = entry.item.startPage;
      final end = entry.item.endPage;
      if (start != null || end != null) {
        final s = (start ?? 0).clamp(0, scorePages.length);
        final e = ((end ?? scorePages.length - 1) + 1).clamp(s, scorePages.length);
        scorePages = scorePages.sublist(s, e);
      }

      pages.addAll(
        _buildPages(
          score: entry.score,
          scorePages: scorePages,
          document: document,
          docIndex: docIndex,
          startIndex: pages.length,
        ),
      );
    }

    if (scores.isEmpty) throw StateError('세트리스트가 비어 있습니다');

    return ScoreSession._(
      key: SessionKey.setlist(setlist.id),
      title: setlist.name,
      scores: scores,
      documents: documents,
      caches: [for (final d in documents) PageRenderCache(d)],
      pages: pages,
    );
  }

  static Future<PdfDocument> _openDocument(Score score, AppPaths paths) {
    final file = paths.resolve(score.filePath);
    return PdfDocument.openFile(
      file.path,
      passwordProvider:
          score.pdfPassword == null ? null : () => score.pdfPassword,
      firstAttemptByEmptyPassword: score.pdfPassword == null,
    );
  }

  static List<ViewPage> _buildPages({
    required Score score,
    required List<ScorePage> scorePages,
    required PdfDocument document,
    required int docIndex,
    required int startIndex,
  }) {
    final views = <ViewPage>[];
    // 빈 페이지 크기는 이 문서의 첫 장을 따라 어색하지 않게 한다.
    final firstPage = document.pages.isEmpty ? null : document.pages.first;
    final blankSize = firstPage == null
        ? const Size(595, 842)
        : Size(firstPage.width, firstPage.height);

    for (final row in scorePages) {
      final Size size;
      final int sourceNumber;
      if (row.sourceIndex < 0) {
        size = blankSize;
        sourceNumber = 0;
      } else {
        sourceNumber = row.sourceIndex + 1;
        if (sourceNumber > document.pages.length) continue;
        final page = document.pages[sourceNumber - 1];
        size = Size(page.width, page.height);
      }

      views.add(
        ViewPage(
          index: startIndex + views.length,
          scoreId: score.id,
          scorePageId: row.id,
          docIndex: docIndex,
          sourcePageNumber: sourceNumber,
          // 페이지 개별 크롭이 있으면 그것을, 없으면 곡 전체 크롭을 쓴다.
          crop: cropRect(
            left: row.cropLeft ?? score.cropLeft,
            top: row.cropTop ?? score.cropTop,
            right: row.cropRight ?? score.cropRight,
            bottom: row.cropBottom ?? score.cropBottom,
          ),
          rotation: row.rotation,
          sourceSize: size,
        ),
      );
    }
    return views;
  }

  static Rect cropRect({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) {
    // 잘못된 값이 들어와 페이지가 사라지지 않도록 최소 폭을 지킨다.
    final l = left.clamp(0.0, 0.45);
    final t = top.clamp(0.0, 0.45);
    final r = right.clamp(0.0, 0.45);
    final b = bottom.clamp(0.0, 0.45);
    return Rect.fromLTRB(l, t, 1 - r, 1 - b);
  }

  void dispose() {
    for (final c in caches) {
      c.dispose();
    }
    for (final d in documents) {
      d.dispose();
    }
  }
}

/// 악보 보기 화면이 살아 있는 동안만 유지되는 세션.
final scoreSessionProvider =
    FutureProvider.autoDispose.family<ScoreSession, SessionKey>((ref, key) async {
  final dao = ref.watch(scoreDaoProvider);
  final paths = await ref.watch(appPathsProvider.future);

  final ScoreSession session;
  if (key.isSetlist) {
    final setlistDao = ref.watch(setlistDaoProvider);
    final setlist = await setlistDao.findById(key.id);
    if (setlist == null) throw StateError('세트리스트를 찾을 수 없습니다');
    session = await ScoreSession.openSetlist(
      setlist: setlist,
      entries: await setlistDao.entries(key.id),
      pagesOf: dao.visiblePages,
      paths: paths,
    );
  } else {
    final score = await dao.findById(key.id);
    if (score == null) throw StateError('악보를 찾을 수 없습니다');
    session = await ScoreSession.openScore(
      score: score,
      scorePages: await dao.visiblePages(key.id),
      paths: paths,
    );
  }

  ref.onDispose(session.dispose);
  return session;
});
