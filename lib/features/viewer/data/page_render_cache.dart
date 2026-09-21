import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';

/// 렌더 요청 한 건을 식별하는 키.
///
/// 목표 폭을 구간으로 반올림해 캐시 적중률을 높인다. 창 크기를 1픽셀씩
/// 바꿀 때마다 새로 렌더하면 넘김이 끊긴다.
@immutable
class PageRenderKey {
  const PageRenderKey({required this.pageNumber, required this.widthBucket});

  final int pageNumber;
  final int widthBucket;

  static const bucketSize = 128;

  factory PageRenderKey.forWidth(int pageNumber, double width) {
    final bucket = (width / bucketSize).ceil() * bucketSize;
    return PageRenderKey(pageNumber: pageNumber, widthBucket: bucket.clamp(bucketSize, 8192));
  }

  @override
  bool operator ==(Object other) =>
      other is PageRenderKey &&
      other.pageNumber == pageNumber &&
      other.widthBucket == widthBucket;

  @override
  int get hashCode => Object.hash(pageNumber, widthBucket);
}

/// 페이지를 비트맵으로 굽고 LRU 로 보관한다.
///
/// 넘김 속도가 이 앱의 핵심이므로 현재 페이지 주변을 미리 구워 둔다.
/// 넘기는 순간에 렌더가 시작되면 이미 늦다.
class PageRenderCache {
  PageRenderCache(this.document, {this.capacity = 12});

  final PdfDocument document;

  /// 동시에 메모리에 두는 페이지 수. A4 를 2000px 폭으로 구우면
  /// 한 장에 약 22MB 라 이 값을 크게 잡으면 구형 기기에서 죽는다.
  final int capacity;

  final _cache = <PageRenderKey, ui.Image>{};
  final _inFlight = <PageRenderKey, Future<ui.Image?>>{};
  final _tokens = <PageRenderKey, PdfPageRenderCancellationToken>{};
  bool _disposed = false;

  /// 지금 들고 있는 이미지의 키. 테스트가 무엇을 구웠는지 본다.
  @visibleForTesting
  Iterable<PageRenderKey> get cachedKeys => _cache.keys;

  /// 이미 구워진 이미지가 있으면 즉시 준다. 없으면 null.
  ui.Image? peek(PageRenderKey key) {
    final image = _cache.remove(key);
    if (image != null) _cache[key] = image; // 최근 사용으로 올린다
    return image;
  }

  /// 굽는다. 이미 진행 중인 같은 요청이 있으면 그 결과를 함께 기다린다.
  Future<ui.Image?> render(PageRenderKey key) {
    if (_disposed) return Future.value();

    final cached = peek(key);
    if (cached != null) return Future.value(cached);

    final running = _inFlight[key];
    if (running != null) return running;

    final future = _renderInternal(key);
    _inFlight[key] = future;
    return future;
  }

  Future<ui.Image?> _renderInternal(PageRenderKey key) async {
    try {
      if (key.pageNumber < 1 || key.pageNumber > document.pages.length) {
        return null;
      }
      final page = document.pages[key.pageNumber - 1];

      final fullWidth = key.widthBucket.toDouble();
      final fullHeight = fullWidth * page.height / page.width;

      final token = page.createCancellationToken();
      _tokens[key] = token;

      final rendered = await page.render(
        fullWidth: fullWidth,
        fullHeight: fullHeight,
        backgroundColor: 0xFFFFFFFF,
        cancellationToken: token,
      );
      _tokens.remove(key);
      if (rendered == null || _disposed) {
        rendered?.dispose();
        return null;
      }

      final image = await _toUiImage(rendered);
      rendered.dispose();

      if (_disposed) {
        image.dispose();
        return null;
      }

      _put(key, image);
      return image;
    } on Object catch (e, st) {
      debugPrint('페이지 렌더 실패 ${key.pageNumber}: $e\n$st');
      return null;
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<ui.Image> _toUiImage(PdfImage source) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      source.pixels,
      source.width,
      source.height,
      ui.PixelFormat.bgra8888,
      completer.complete,
    );
    return completer.future;
  }

  void _put(PageRenderKey key, ui.Image image) {
    _cache[key] = image;
    while (_cache.length > capacity) {
      final oldest = _cache.keys.first;
      _cache.remove(oldest)?.dispose();
    }
  }

  /// 아직 굽는 중인 요청을 거둔다.
  ///
  /// 굽는 일꾼은 하나라 요청이 줄을 선다. 줄에 선 채면 건너뛰고, 이미 굽고
  /// 있으면 끝까지 굽는다(pdfium 은 도중에 멈추지 못한다). 같은 요청을
  /// 기다리던 쪽은 null 을 받는다. 훑는 동안 스쳐 간 쪽에 쓴다.
  void cancel(PageRenderKey key) => _tokens.remove(key)?.cancel();

  /// 현재 페이지 주변을 미리 굽는다. 결과는 기다리지 않는다.
  ///
  /// 뒤로 가는 경우도 있으므로 앞뒤를 함께 데운다. 앞쪽을 먼저 요청해
  /// 순방향 넘김이 항상 준비되게 한다.
  void prefetch(int centerPage, double width, {int ahead = 2, int behind = 1}) {
    for (var i = 1; i <= ahead; i++) {
      unawaited(render(PageRenderKey.forWidth(centerPage + i, width)));
    }
    for (var i = 1; i <= behind; i++) {
      unawaited(render(PageRenderKey.forWidth(centerPage - i, width)));
    }
  }

  void dispose() {
    _disposed = true;
    for (final token in _tokens.values) {
      token.cancel();
    }
    _tokens.clear();
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }
}
