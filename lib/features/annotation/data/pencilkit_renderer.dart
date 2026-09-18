import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS 에서 PKDrawing 바이트를 PNG 로 굽는다. 내보내기에서 쓴다.
///
/// 화면에 캔버스가 떠 있지 않아도 되도록 네이티브 쪽 정적 채널을 부른다.
/// 다른 플랫폼은 PencilKit 그림을 그릴 수 없어 null 을 준다.
abstract final class PencilKitRenderer {
  static const _channel = MethodChannel('hiscore/pencilkit_render');

  static bool get supported => !kIsWeb && Platform.isIOS;

  static Future<Uint8List?> render(Uint8List drawing, {required int width, required int height}) async {
    if (!supported || drawing.isEmpty) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('render', {
        'data': drawing,
        'width': width,
        'height': height,
      });
    } on MissingPluginException {
      return null;
    }
  }
}
