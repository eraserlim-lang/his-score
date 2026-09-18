import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import '../../../core/storage/app_paths.dart';

/// 카탈로그에 보여줄 표지 이미지를 만든다.
///
/// 기본은 첫 페이지를 작게 구운 PNG 다. 사용자가 다른 페이지나 사진으로
/// 바꿀 수도 있다. 표지는 언제든 다시 만들 수 있으므로 원본이 아니다.
class CoverGenerator {
  CoverGenerator(this._paths);

  final AppPaths _paths;

  /// 표지 폭. 목록 카드에서 2배 밀도까지 선명하면 충분하다.
  static const width = 400.0;

  /// [document] 의 [pageNumber] 를 구워 표지로 저장하고 상대 경로를 준다.
  Future<String> fromPage(
    String scoreId,
    PdfDocument document,
    int pageNumber,
  ) async {
    final page = document.pages[pageNumber - 1];
    final height = width * page.height / page.width;

    final rendered = await page.render(
      fullWidth: width,
      fullHeight: height,
      backgroundColor: 0xFFFFFFFF,
    );
    if (rendered == null) throw StateError('표지를 구울 수 없습니다');

    try {
      final image = await _decode(rendered);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) throw StateError('PNG 변환 실패');

      return _write(scoreId, png.buffer.asUint8List());
    } finally {
      rendered.dispose();
    }
  }

  /// 사진 파일을 표지로 쓴다. 크기가 크면 줄인다.
  Future<String> fromImageFile(String scoreId, File source) async {
    final bytes = await source.readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: width.toInt(),
    );
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    if (png == null) throw StateError('이미지를 읽을 수 없습니다');

    return _write(scoreId, png.buffer.asUint8List());
  }

  Future<String> _write(String scoreId, List<int> png) async {
    // 같은 이름으로 덮어쓰면 이미지 캐시가 옛 그림을 보여준다. 시각을 붙인다.
    final name = '$scoreId-${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(p.join(_paths.coversDir.path, name));
    await file.writeAsBytes(png, flush: true);
    return _paths.relativeOf(file);
  }

  /// 예전 표지 파일을 지운다. 없어도 조용히 넘어간다.
  Future<void> deleteCover(String? relativePath) async {
    if (relativePath == null) return;
    final file = _paths.resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  static Future<ui.Image> _decode(PdfImage source) {
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
}
