import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Rect, Size;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';

import '../../../core/db/database.dart';
import '../../../core/db/score_dao.dart';
import '../../../core/storage/app_paths.dart';
import '../../annotation/data/annotation_dao.dart';
import '../../annotation/data/pencilkit_renderer.dart';
import '../../annotation/domain/ink_models.dart';
import '../../annotation/presentation/ink_painter.dart';

/// 내보내기 선택지.
class ExportOptions {
  const ExportOptions({
    this.withInk = true,
    this.applyPageEdits = true,
    this.firstPage,
    this.lastPage,
    this.dpi = 150,
  });

  /// 필기와 스탬프를 얹을지.
  final bool withInk;

  /// 순서 편집, 숨김, 크롭을 반영할지. 끄면 원본 순서와 전체 페이지다.
  final bool applyPageEdits;

  /// 표시 순서 기준 0-based 구간. null 이면 전체.
  final int? firstPage;
  final int? lastPage;

  /// 굽는 해상도. 150 이면 인쇄에 충분하고 파일이 너무 크지 않다.
  final int dpi;
}

/// 악보를 새 PDF 로 만든다.
///
/// 원본을 편집하는 것이 아니라 페이지를 그림으로 구워 새로 묶는다.
/// 벡터 정보는 사라지지만 어떤 PDF 라도, 어떤 필기라도 같은 방식으로 나간다.
class ScoreExporter {
  ScoreExporter(this._paths, this._scores, this._ink);

  final AppPaths _paths;
  final ScoreDao _scores;
  final AnnotationDao _ink;

  /// 원본 파일 그대로. 필기 없이 빠르게 보낼 때.
  Future<Uint8List> originalBytes(Score score) =>
      _paths.resolve(score.filePath).readAsBytes();

  Future<Uint8List> build(Score score, ExportOptions options, {void Function(int done, int total)? onProgress}) async {
    final file = _paths.resolve(score.filePath);
    final document = await PdfDocument.openFile(
      file.path,
      passwordProvider: score.pdfPassword == null ? null : () => score.pdfPassword,
      firstAttemptByEmptyPassword: score.pdfPassword == null,
    );
    try {
      final rows = options.applyPageEdits
          ? await _scores.visiblePages(score.id)
          : await _scores.allPages(score.id);
      final ordered = options.applyPageEdits
          ? rows
          : (rows.toList()..sort((a, b) => a.sourceIndex.compareTo(b.sourceIndex)));

      final first = (options.firstPage ?? 0).clamp(0, ordered.length);
      final last = (options.lastPage ?? ordered.length - 1).clamp(first, ordered.length - 1);
      final selected = ordered.sublist(first, last + 1);

      final doc = pw.Document(compress: true, title: score.title, author: score.artist ?? score.composer);
      var done = 0;
      for (final row in selected) {
        final image = await _renderRow(document, score, row, options);
        if (image != null) {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final w = image.width.toDouble();
          final h = image.height.toDouble();
          image.dispose();
          if (png != null) {
            final mem = pw.MemoryImage(png.buffer.asUint8List());
            doc.addPage(
              pw.Page(
                pageFormat: PdfPageFormat(w * 72 / options.dpi, h * 72 / options.dpi),
                margin: pw.EdgeInsets.zero,
                build: (_) => pw.Image(mem, fit: pw.BoxFit.fill),
              ),
            );
          }
        }
        done++;
        onProgress?.call(done, selected.length);
      }
      return Uint8List.fromList(await doc.save());
    } finally {
      document.dispose();
    }
  }

  Future<ui.Image?> _renderRow(PdfDocument document, Score score, ScorePage row, ExportOptions options) async {
    final Size sourceSize;
    ui.Image base;

    if (row.sourceIndex < 0) {
      // 빈 페이지. 첫 장 크기를 따른다.
      final ref = document.pages.first;
      sourceSize = Size(ref.width, ref.height);
      base = await _blank(sourceSize, options.dpi);
    } else {
      if (row.sourceIndex >= document.pages.length) return null;
      final page = document.pages[row.sourceIndex];
      sourceSize = Size(page.width, page.height);
      final width = page.width / 72 * options.dpi;
      final height = page.height / 72 * options.dpi;
      final rendered = await page.render(
        fullWidth: width,
        fullHeight: height,
        backgroundColor: 0xFFFFFFFF,
      );
      if (rendered == null) return null;
      base = await _decode(rendered);
      rendered.dispose();
    }

    // 크롭을 반영한다. 필기 좌표는 전체 페이지 기준이라 먼저 합성한 뒤 자른다.
    if (options.withInk) {
      final ink = await _ink.loadPage(score.id, row.sourceIndex + 1);
      if (!ink.isEmpty) {
        base = await _composite(base, ink);
      }
    }

    if (options.applyPageEdits) {
      final crop = _cropOf(score, row);
      if (crop != const Rect.fromLTRB(0, 0, 1, 1) || row.rotation != 0) {
        base = await _cropAndRotate(base, crop, row.rotation);
      }
    }
    return base;
  }

  Rect _cropOf(Score score, ScorePage row) {
    final l = (row.cropLeft ?? score.cropLeft).clamp(0.0, 0.45);
    final t = (row.cropTop ?? score.cropTop).clamp(0.0, 0.45);
    final r = (row.cropRight ?? score.cropRight).clamp(0.0, 0.45);
    final b = (row.cropBottom ?? score.cropBottom).clamp(0.0, 0.45);
    return Rect.fromLTRB(l, t, 1 - r, 1 - b);
  }

  Future<ui.Image> _composite(ui.Image page, PageInk ink) async {
    // 벡터 필기와 스탬프.
    var out = await InkPainter.composite(page, ink);
    page.dispose();

    // iOS PencilKit 그림은 네이티브가 PNG 로 구워 준다.
    final pk = ink.pencilKitData;
    if (pk != null && pk.isNotEmpty) {
      final png = await PencilKitRenderer.render(pk, width: out.width, height: out.height);
      if (png != null) {
        final codec = await ui.instantiateImageCodec(png);
        final frame = await codec.getNextFrame();
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawImage(out, ui.Offset.zero, ui.Paint());
        canvas.drawImageRect(
          frame.image,
          ui.Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
          ui.Rect.fromLTWH(0, 0, out.width.toDouble(), out.height.toDouble()),
          ui.Paint(),
        );
        final merged = await recorder.endRecording().toImage(out.width, out.height);
        out.dispose();
        frame.image.dispose();
        codec.dispose();
        out = merged;
      }
    }
    return out;
  }

  Future<ui.Image> _cropAndRotate(ui.Image src, Rect crop, double rotation) async {
    final w = (src.width * crop.width).round();
    final h = (src.height * crop.height).round();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()), ui.Paint()..color = const ui.Color(0xFFFFFFFF));
    if (rotation != 0) {
      canvas.translate(w / 2, h / 2);
      canvas.rotate(rotation * 3.141592653589793 / 180);
      canvas.translate(-w / 2, -h / 2);
    }
    canvas.drawImageRect(
      src,
      ui.Rect.fromLTRB(crop.left * src.width, crop.top * src.height, crop.right * src.width, crop.bottom * src.height),
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final out = await recorder.endRecording().toImage(w, h);
    src.dispose();
    return out;
  }

  Future<ui.Image> _blank(Size size, int dpi) async {
    final w = (size.width / 72 * dpi).round();
    final h = (size.height / 72 * dpi).round();
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    return recorder.endRecording().toImage(w, h);
  }

  static Future<ui.Image> _decode(PdfImage source) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(source.pixels, source.width, source.height, ui.PixelFormat.bgra8888, completer.complete);
    return completer.future;
  }
}

final scoreExporterProvider = FutureProvider<ScoreExporter>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  return ScoreExporter(paths, ref.watch(scoreDaoProvider), ref.watch(annotationDaoProvider));
});
