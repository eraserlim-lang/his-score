import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'score_importer.dart';

/// 다른 앱에서 "HIScore 로 열기" 한 PDF 를 받아 가져온다.
///
/// 네이티브 쪽이 파일을 캐시에 복사하고 경로를 보낸다. 앱이 그 순간
/// 떠 있지 않았으면 시작 직후 `takePending` 으로 가져온다.
class OpenInHandler {
  OpenInHandler(this._ref);

  final Ref _ref;
  static const _channel = MethodChannel('hiscore/open_in');

  /// 가져온 곡 id 를 흘려보낸다. 화면이 듣고 안내를 띄운다.
  final imported = ValueNotifier<String?>(null);

  Future<void> start() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openFile') await _import(call.arguments as String);
    });
    try {
      final pending = await _channel.invokeMethod<String>('takePending');
      if (pending != null) await _import(pending);
    } on MissingPluginException {
      // 네이티브 쪽이 없는 빌드(테스트 등)에서는 조용히 넘어간다.
    }
  }

  Future<void> _import(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    try {
      final importer = await _ref.read(scoreImporterProvider.future);
      final id = await importer.importFile(file, deleteSource: true);
      imported.value = id;
    } on Object catch (e) {
      debugPrint('Open In 가져오기 실패: $e');
    }
  }
}

final openInHandlerProvider = Provider<OpenInHandler>((ref) {
  final handler = OpenInHandler(ref);
  handler.start();
  return handler;
});
