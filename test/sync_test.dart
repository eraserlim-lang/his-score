import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:his_score/core/db/database.dart';
import 'package:his_score/core/db/score_dao.dart';
import 'package:his_score/core/db/settings_dao.dart';
import 'package:his_score/core/storage/app_paths.dart';
import 'package:his_score/features/importer/data/score_importer.dart';
import 'package:his_score/features/library/data/cover_generator.dart';
import 'package:his_score/features/sync/data/sync_protocol.dart';
import 'package:his_score/features/sync/data/sync_service.dart';
import 'package:his_score/features/viewer/data/face_turn_service.dart';
import 'package:his_score/features/viewer/domain/turn_input.dart';
import 'package:his_score/features/viewer/domain/viewer_controller.dart';
import 'package:pdfrx/pdfrx.dart';

/// 리드 하나와 팔로워 하나를 같은 프로세스 안에서 띄워 본다.
class _Device {
  _Device(this.name);
  final String name;
  late Directory root;
  late AppDatabase db;
  late ScoreDao scores;
  late AppPaths paths;
  late TurnInputHub hub;
  late SyncService service;

  Future<void> up() async {
    root = await Directory.systemTemp.createTemp('hiscore_sync_$name');
    paths = AppPaths(root);
    await paths.ensureCreated();
    db = AppDatabase(NativeDatabase.memory());
    scores = ScoreDao(db);
    hub = TurnInputHub();
    final importer = ScoreImporter(scores, paths, CoverGenerator(paths));
    service = SyncService(
      hub: hub,
      settings: SettingsDao(db),
      scoreDao: scores,
      paths: paths,
      importer: () async => importer,
    );
    await service.setDeviceName(name);
  }

  Future<void> down() async {
    service.dispose();
    hub.dispose();
    await db.close();
    try {
      await root.delete(recursive: true);
    } on FileSystemException {
      // pdfium 핸들
    }
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    Pdfrx.cacheDirectoryPath ??= Directory.systemTemp.path;
    await pdfrxFlutterInitialize();
  });

  group('프레임 리더', () {
    test('JSON 줄과 파일 바이트를 번갈아 읽는다', () async {
      final controller = StreamController<List<int>>();
      final reader = FrameReader(controller.stream.map(Uint8List.fromList))..start();
      final received = <Map<String, dynamic>>[];
      reader.messages.listen(received.add);

      controller.add('{"type":"hello","name":"a"}\n{"type":"file","size":5}\n'.codeUnits);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received.map((m) => m['type']), ['hello', 'file']);

      final bin = reader.readBinary(5);
      controller.add([1, 2, 3, 4, 5]);
      controller.add('{"type":"ping"}\n'.codeUnits);
      expect(await bin, [1, 2, 3, 4, 5]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(received.last['type'], 'ping');
      await controller.close();
    });
  });

  group('페달 매핑', () {
    test('기본 키가 명령으로 바뀐다', () {
      final m = PedalMapping.defaults;
      expect(m.commandFor(LogicalKeyboardKey.arrowRight), TurnCommand.next);
      expect(m.commandFor(LogicalKeyboardKey.pageUp), TurnCommand.previous);
      expect(m.commandFor(LogicalKeyboardKey.home), TurnCommand.first);
      expect(m.commandFor(LogicalKeyboardKey.keyQ), isNull);
    });

    test('학습한 키는 반대쪽에서 빠지고 저장 형식이 왕복한다', () {
      final m = PedalMapping.defaults
          .withLearned(nextKey: LogicalKeyboardKey.keyQ.keyId)
          .withLearned(previousKey: LogicalKeyboardKey.keyQ.keyId);
      expect(m.commandFor(LogicalKeyboardKey.keyQ), TurnCommand.previous);
      final back = PedalMapping.decode(m.encode());
      expect(back.commandFor(LogicalKeyboardKey.keyQ), TurnCommand.previous);
      expect(back.commandFor(LogicalKeyboardKey.arrowRight), TurnCommand.next);
    });
  });

  group('윙크 판정', () {
    test('한쪽 눈을 오래 감으면 넘기고 곧바로는 다시 넘기지 않는다', () {
      final hub = TurnInputHub();
      final fired = <TurnCommand>[];
      hub.commands.listen(fired.add);
      final s = FaceTurnService(hub);
      var t = DateTime(2026, 1, 1, 12);

      // 왼눈(카메라 기준) 감기 시작.
      expect(s.evaluate(leftOpen: 0.1, rightOpen: 0.9, now: t), isNull);
      t = t.add(const Duration(milliseconds: 200));
      expect(s.evaluate(leftOpen: 0.1, rightOpen: 0.9, now: t), isNull);
      t = t.add(const Duration(milliseconds: 250));
      expect(s.evaluate(leftOpen: 0.1, rightOpen: 0.9, now: t), TurnCommand.next);

      // 쿨다운 안에서는 무시.
      t = t.add(const Duration(milliseconds: 500));
      expect(s.evaluate(leftOpen: 0.1, rightOpen: 0.9, now: t), isNull);
      t = t.add(const Duration(milliseconds: 500));
      expect(s.evaluate(leftOpen: 0.1, rightOpen: 0.9, now: t), isNull);
    });

    test('양쪽을 같이 감으면 깜빡임이라 무시한다', () {
      final s = FaceTurnService(TurnInputHub());
      var t = DateTime(2026, 1, 1, 12);
      expect(s.evaluate(leftOpen: 0.1, rightOpen: 0.1, now: t), isNull);
      t = t.add(const Duration(seconds: 1));
      expect(s.evaluate(leftOpen: 0.1, rightOpen: 0.1, now: t), isNull);
    });

    test('오른눈이면 이전 페이지', () {
      final s = FaceTurnService(TurnInputHub());
      var t = DateTime(2026, 1, 1, 12);
      s.evaluate(leftOpen: 0.9, rightOpen: 0.1, now: t);
      t = t.add(const Duration(milliseconds: 450));
      expect(s.evaluate(leftOpen: 0.9, rightOpen: 0.1, now: t), TurnCommand.previous);
    });
  });

  group('기기 동기화', () {
    late _Device lead;
    late _Device follower;

    setUp(() async {
      lead = _Device('lead');
      follower = _Device('follower');
      await lead.up();
      await follower.up();
    });

    tearDown(() async {
      await lead.down();
      await follower.down();
    });

    Future<void> connect() async {
      await lead.service.setRole(SyncRole.lead);
      // 발견 방송 대신 직접 붙는다. 테스트 러너의 네트워크는 믿을 수 없다.
      follower.service
        ..setRole(SyncRole.follow)
        ..connectTo(SyncPeer(name: 'lead', host: '127.0.0.1', port: lead.service.leadPort!, role: SyncRole.lead));
      // 리드는 UDP 소켓 없이도 동작해야 한다.
      for (var i = 0; i < 50 && !follower.service.isConnected; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(follower.service.isConnected, isTrue);
    }

    test('리드가 페이지를 넘기면 팔로워가 같은 자리로 간다', () async {
      // 두 기기 모두 같은 id 의 곡을 갖고 있다.
      final importerL = ScoreImporter(lead.scores, lead.paths, CoverGenerator(lead.paths));
      final importerF = ScoreImporter(follower.scores, follower.paths, CoverGenerator(follower.paths));
      await importerL.importFile(File('test/fixtures/score.pdf'), id: 'shared');
      await importerF.importFile(File('test/fixtures/score.pdf'), id: 'shared');

      await connect();
      final got = <ViewerPosition>[];
      follower.hub.remotePositions.listen(got.add);

      lead.hub.reportPosition(const ViewerPosition(scoreId: 'shared', sourcePage: 5, pageIndex: 4, title: 't'));
      for (var i = 0; i < 40 && got.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(got.single.sourcePage, 5);
      expect(got.single.scoreId, 'shared');
    });

    test('팔로워에 없는 곡은 리드가 파일을 보내 준다', () async {
      final importerL = ScoreImporter(lead.scores, lead.paths, CoverGenerator(lead.paths));
      await importerL.importFile(File('test/fixtures/score.pdf'), id: 'only-lead', title: '리드만 가진 곡');

      await connect();
      final got = <ViewerPosition>[];
      follower.hub.remotePositions.listen(got.add);

      lead.hub.reportPosition(const ViewerPosition(scoreId: 'only-lead', sourcePage: 2, pageIndex: 1, title: '리드만 가진 곡'));
      for (var i = 0; i < 100 && got.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(got, isNotEmpty);
      final received = await follower.scores.findById('only-lead');
      expect(received, isNotNull);
      expect(received!.title, '리드만 가진 곡');
      expect(received.pageCount, 8);
    });

    test('리모컨이 보낸 명령이 리드의 허브에 도착한다', () async {
      await lead.service.setRole(SyncRole.lead);
      await follower.service.setRole(SyncRole.remote);
      await follower.service.connectTo(SyncPeer(name: 'lead', host: '127.0.0.1', port: lead.service.leadPort!, role: SyncRole.lead));
      for (var i = 0; i < 50 && !follower.service.isConnected; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      final got = <TurnCommand>[];
      lead.hub.commands.listen(got.add);
      follower.service.sendCommand(TurnCommand.next);
      follower.service.sendCommand(TurnCommand.previous);
      for (var i = 0; i < 40 && got.length < 2; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(got, [TurnCommand.next, TurnCommand.previous]);
    });
  });
}

