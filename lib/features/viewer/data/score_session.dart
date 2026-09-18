import 'dart:ui' show Rect, Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/storage/app_paths.dart';
import 'page_render_cache.dart';

/// 화면에 보여줄 페이지 한 장.
///
/// 원본 PDF 의 몇 번째 장인지, 어떻게 잘라 보여줄지를 함께 들고 있다.
/// 사용자가 페이지 순서를 바꾸거나 숨겨도 원본은 그대로다.
class ViewPage {
  const ViewPage({
    required this.index,
    required this.sourcePageNumber,
    required this.crop,
    required this.rotation,
    required this.sourceSize,
  });

  /// 표시 순서상의 0-based 위치.
  final int index;

  /// 원본 PDF 안의 1-based 페이지 번호.
  final int sourcePageNumber;

  /// 0.0~1.0 비율의 잘라내기 영역. 기본은 전체.
  final Rect crop;

  final double rotation;

  /// 원본 페이지의 포인트 단위 크기.
  final Size sourceSize;

  /// 잘라낸 뒤의 가로세로 비율.
  double get aspectRatio =>
      (sourceSize.width * crop.width) / (sourceSize.height * crop.height);
}

/// 악보 한 곡을 여는 동안 살아 있는 세션.
///
/// PDF 문서 핸들과 렌더 캐시를 함께 들고 있다가 화면을 닫을 때 정리한다.
class ScoreSession {
  ScoreSession._({
    required this.score,
    required this.document,
    required this.cache,
    required this.pages,
  });

  final Score score;
  final PdfDocument document;
  final PageRenderCache cache;

  /// 숨긴 페이지를 빼고 사용자가 정한 순서로 정렬된 목록.
  final List<ViewPage> pages;

  int get pageCount => pages.length;

  static Future<ScoreSession> open({
    required Score score,
    required List<ScorePage> scorePages,
    required AppPaths paths,
  }) async {
    final file = paths.resolve(score.filePath);
    final document = await PdfDocument.openFile(
      file.path,
      passwordProvider: score.pdfPassword == null
          ? null
          : () => score.pdfPassword,
      firstAttemptByEmptyPassword: score.pdfPassword == null,
    );

    final views = <ViewPage>[];
    for (var i = 0; i < scorePages.length; i++) {
      final row = scorePages[i];
      final sourceNumber = row.sourceIndex + 1;
      if (sourceNumber < 1 || sourceNumber > document.pages.length) continue;
      final page = document.pages[sourceNumber - 1];

      views.add(
        ViewPage(
          index: views.length,
          sourcePageNumber: sourceNumber,
          // 페이지 개별 크롭이 있으면 그것을, 없으면 곡 전체 크롭을 쓴다.
          crop: _cropRect(
            left: row.cropLeft ?? score.cropLeft,
            top: row.cropTop ?? score.cropTop,
            right: row.cropRight ?? score.cropRight,
            bottom: row.cropBottom ?? score.cropBottom,
          ),
          rotation: row.rotation,
          sourceSize: Size(page.width, page.height),
        ),
      );
    }

    return ScoreSession._(
      score: score,
      document: document,
      cache: PageRenderCache(document),
      pages: views,
    );
  }

  static Rect _cropRect({
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
    cache.dispose();
    document.dispose();
  }
}

/// 악보 보기 화면이 살아 있는 동안만 유지되는 세션.
final scoreSessionProvider =
    FutureProvider.autoDispose.family<ScoreSession, String>((ref, scoreId) async {
  final dao = ref.watch(scoreDaoProvider);
  final paths = await ref.watch(appPathsProvider.future);

  final score = await dao.findById(scoreId);
  if (score == null) throw StateError('악보를 찾을 수 없습니다');

  final pages = await dao.visiblePages(scoreId);
  final session = await ScoreSession.open(
    score: score,
    scorePages: pages,
    paths: paths,
  );

  ref.onDispose(session.dispose);
  return session;
});
