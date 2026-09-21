import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/score_dao.dart';
import 'package:his_score/core/db/settings_dao.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/importer/data/image_to_pdf.dart';
import 'package:his_score/features/importer/data/score_importer.dart';
import 'package:his_score/features/importer/data/watch_folder_service.dart';
import 'package:his_score/features/library/data/cover_generator.dart';
import 'package:image/image.dart' as img;
import 'package:pdfrx/pdfrx.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();
  });

  group('촬영 이미지 → PDF', () {
    test('이미지 세 장이 세 쪽짜리 PDF 가 되고 회전이 반영된다', () async {
      final dir = await Directory.systemTemp.createTemp('hiscore_img');
      addTearDown(() => dir.delete(recursive: true));

      // 가로로 긴 회색 이미지에 검은 줄을 몇 개 긋는다.
      final files = <File>[];
      for (var i = 0; i < 3; i++) {
        final im = img.Image(width: 400, height: 300);
        img.fill(im, color: img.ColorRgb8(230, 220, 200));
        for (var y = 50; y < 300; y += 40) {
          img.drawLine(im, x1: 20, y1: y, x2: 380, y2: y, color: img.ColorRgb8(0, 0, 0));
        }
        final f = File('${dir.path}/p$i.jpg');
        await f.writeAsBytes(img.encodeJpg(im));
        files.add(f);
      }

      final pdf = await ImageToPdf.build(
        pages: [
          CapturedPage(file: files[0]),
          CapturedPage(file: files[1], rotation: 90),
          CapturedPage(file: files[2]),
        ],
        outDir: dir,
        enhance: true,
      );
      expect(await pdf.exists(), isTrue);

      final doc = await PdfDocument.openFile(pdf.path);
      addTearDown(doc.dispose);
      expect(doc.pages.length, 3);
      // 첫 장은 가로, 둘째 장은 90° 돌아 세로여야 한다.
      expect(doc.pages[0].width, greaterThan(doc.pages[0].height));
      expect(doc.pages[1].height, greaterThan(doc.pages[1].width));
    });
  });

  group('감시 폴더', () {
    test('폴더의 새 PDF 만 들여오고 같은 파일은 두 번 들여오지 않는다', () async {
      final root = await Directory.systemTemp.createTemp('hiscore_watch');
      final watched = await Directory('${root.path}/inbox').create();
      final paths = AppPaths(Directory('${root.path}/app'));
      await paths.ensureCreated();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await db.close();
        try {
          await root.delete(recursive: true);
        } on FileSystemException {
          // pdfium 핸들
        }
      });
      final scores = ScoreDao(db);
      final settings = SettingsDao(db);
      final importer = ScoreImporter(scores, paths, CoverGenerator(paths));
      final service = WatchFolderService(settings, importer);

      await File('test/fixtures/score.pdf').copy('${watched.path}/a.pdf');
      await File('${watched.path}/note.txt').writeAsString('x');

      await service.setFolder(watched.path);
      expect(await scores.count(), 1);

      // 다시 훑어도 늘지 않는다.
      expect(await service.scanNow(), 0);
      expect(await scores.count(), 1);

      // 새 파일이 오면 하나 더.
      await File('test/fixtures/score.pdf').copy('${watched.path}/b.pdf');
      expect(await service.scanNow(), 1);
      expect(await scores.count(), 2);
      await service.dispose();
    });
  });
}
