import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 촬영한 종이 악보 한 장.
class CapturedPage {
  CapturedPage({required this.file, this.rotation = 0});

  final File file;

  /// 0, 90, 180, 270 중 하나. 시계 방향.
  int rotation;

  CapturedPage rotated() => CapturedPage(file: file, rotation: (rotation + 90) % 360);
}

/// 촬영 이미지를 PDF 한 권으로 묶는다.
///
/// 무거운 작업은 별도 isolate 에서 돌려 화면이 멈추지 않게 한다.
/// [enhance] 가 참이면 흑백으로 바꾸고 명암을 키워 종이 악보의 회색 배경을 지운다.
class ImageToPdf {
  const ImageToPdf._();

  static Future<File> build({
    required List<CapturedPage> pages,
    required Directory outDir,
    bool enhance = true,
    int maxSide = 2200,
  }) async {
    final out = File(p.join(outDir.path, 'capture-${DateTime.now().millisecondsSinceEpoch}.pdf'));
    final bytes = await Isolate.run(
      () => _buildBytes(
        [for (final c in pages) (c.file.path, c.rotation)],
        enhance: enhance,
        maxSide: maxSide,
      ),
    );
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  static Future<List<int>> _buildBytes(
    List<(String, int)> pages, {
    required bool enhance,
    required int maxSide,
  }) async {
    final doc = pw.Document(compress: true);

    for (final (path, rotation) in pages) {
      var image = img.decodeImage(await File(path).readAsBytes());
      if (image == null) continue;

      // 촬영 메타데이터의 방향을 먼저 반영하고 사용자가 돌린 각도를 더한다.
      image = img.bakeOrientation(image);
      if (rotation != 0) image = img.copyRotate(image, angle: rotation);

      final longest = image.width > image.height ? image.width : image.height;
      if (longest > maxSide) {
        final scale = maxSide / longest;
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.average,
        );
      }

      if (enhance) image = _enhance(image);

      final jpg = img.encodeJpg(image, quality: enhance ? 82 : 88);
      final pdfImage = pw.MemoryImage(jpg);

      // 이미지 비율대로 페이지를 만든다. A4 에 억지로 맞추면 여백이 생긴다.
      final pageFormat = PdfPageFormat(
        image.width.toDouble() * 72 / 200,
        image.height.toDouble() * 72 / 200,
      );
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(pdfImage, fit: pw.BoxFit.fill),
        ),
      );
    }

    return doc.save();
  }

  /// 흑백 + 명암 보정. 종이의 누런 배경과 그림자를 눌러 오선이 또렷해진다.
  static img.Image _enhance(img.Image src) {
    final gray = img.grayscale(src);
    // 어두운 쪽은 더 어둡게, 밝은 쪽은 흰색으로 밀어 배경을 날린다.
    img.adjustColor(gray, contrast: 1.35, brightness: 1.08, gamma: 0.9);
    return gray;
  }
}
