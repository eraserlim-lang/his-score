import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/features/viewer/data/page_render_cache.dart';
import 'package:pdfrx/pdfrx.dart';

/// 실제 PDF 로 여는 것부터 비트맵이 나오는 데까지를 확인한다.
void main() {
  late PdfDocument document;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 단위 테스트에는 path_provider 플러그인이 없으므로 캐시 경로를 직접 준다.
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();
    final path = File('test/fixtures/score.pdf').absolute.path;
    document = await PdfDocument.openFile(path);
  });

  tearDownAll(() => document.dispose());

  test('8쪽짜리 악보를 연다', () {
    expect(document.pages.length, 8);
    expect(document.pages.first.width, closeTo(595, 1));
    expect(document.pages.first.height, closeTo(842, 1));
  });

  test('페이지를 요청한 폭으로 굽는다', () async {
    final cache = PageRenderCache(document);
    addTearDown(cache.dispose);

    final key = PageRenderKey.forWidth(1, 1000);
    final image = await cache.render(key);

    expect(image, isNotNull);
    expect(image!.width, key.widthBucket);
    // A4 비율이 유지되어야 한다.
    expect(image.height / image.width, closeTo(842 / 595, 0.01));
  });

  test('같은 키를 두 번 요청하면 같은 이미지를 준다', () async {
    final cache = PageRenderCache(document);
    addTearDown(cache.dispose);

    final key = PageRenderKey.forWidth(2, 800);
    final first = await cache.render(key);
    final second = await cache.render(key);

    expect(identical(first, second), isTrue);
    expect(cache.peek(key), isNotNull);
  });

  test('폭이 조금 달라도 같은 구간이면 다시 굽지 않는다', () async {
    final cache = PageRenderCache(document);
    addTearDown(cache.dispose);

    final a = PageRenderKey.forWidth(3, 900);
    final b = PageRenderKey.forWidth(3, 950);
    expect(a, b);

    final first = await cache.render(a);
    expect(identical(cache.peek(b), first), isTrue);
  });

  test('미리 굽기가 이웃 페이지를 채운다', () async {
    final cache = PageRenderCache(document);
    addTearDown(cache.dispose);

    cache.prefetch(4, 640, ahead: 2, behind: 1);
    // 요청만 걸어 두므로 완료를 기다린 뒤 확인한다.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(cache.peek(PageRenderKey.forWidth(5, 640)), isNotNull);
    expect(cache.peek(PageRenderKey.forWidth(6, 640)), isNotNull);
    expect(cache.peek(PageRenderKey.forWidth(3, 640)), isNotNull);
  });

  test('없는 페이지를 요청하면 null 을 준다', () async {
    final cache = PageRenderCache(document);
    addTearDown(cache.dispose);

    expect(await cache.render(PageRenderKey.forWidth(0, 640)), isNull);
    expect(await cache.render(PageRenderKey.forWidth(99, 640)), isNull);
  });

  test('한도를 넘으면 오래된 것부터 버린다', () async {
    final cache = PageRenderCache(document, capacity: 3);
    addTearDown(cache.dispose);

    for (var page = 1; page <= 5; page++) {
      await cache.render(PageRenderKey.forWidth(page, 400));
    }

    expect(cache.peek(PageRenderKey.forWidth(1, 400)), isNull);
    expect(cache.peek(PageRenderKey.forWidth(5, 400)), isNotNull);
  });
}
