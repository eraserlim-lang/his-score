import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../domain/turn_input.dart';
import '../domain/viewer_controller.dart';
import '../../../core/i18n/tr.dart';

/// 얼굴 제스처 넘김.
///
/// 전면 카메라로 얼굴을 보다가 한쪽 눈을 0.25초쯤 감으면 넘긴다.
/// 오른눈은 다음, 왼눈은 이전. 양쪽을 같이 감는 건 그냥 눈 깜빡임이라 무시한다.
/// 한 번 넘기면 2초 동안은 다시 넘기지 않는다. 연속 오작동을 막기 위해서다.
/// 모바일(ML Kit)에서만 동작한다.
///
/// 화면 표시를 위해 [phase] 로 지금 눈 상태를 알린다. 켜 두고도 얼굴이 안
/// 잡히거나 윙크가 짧아 안 넘어갈 때, 무엇이 문제인지 눈으로 알 수 있다.
class FaceTurnService extends ChangeNotifier {
  FaceTurnService(this._hub);

  final TurnInputHub _hub;

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// 윙크는 보통 0.2~0.3초다. 0.4초를 요구하면 억지로 오래 감아야 해서
  /// 잘 안 먹힌다고 느낀다. 깜빡임(양쪽)은 따로 걸러지므로 짧아도 된다.
  static const holdDuration = Duration(milliseconds: 250);
  static const cooldown = Duration(seconds: 2);

  /// 윙크는 두 눈의 확률 차이로 본다. 절대값으로 보면 눈이 작은 사람은 감은
  /// 눈도 0.4~0.65 로 "반쯤 감은" 값이 나와 놓친다. 한쪽이 [closedThreshold]
  /// 아래이면서 다른 쪽보다 [winkGap] 이상 낮으면 윙크다. 둘 다
  /// [blinkThreshold] 아래면 깜빡임이다.
  static const closedThreshold = 0.6;
  static const winkGap = 0.25;
  static const blinkThreshold = 0.5;

  /// 확률을 1초에 한 번 로그로 남긴다. 기기마다 값이 달라 문턱을 맞출 때 본다.
  DateTime? _lastLogAt;

  CameraController? _camera;
  FaceDetector? _detector;
  bool _running = false;
  bool _busy = false;
  String? _error;
  bool _faceVisible = false;
  DateTime? _cooldownUntil;

  // 한쪽 눈이 감기기 시작한 시각.
  DateTime? _leftClosedSince;
  DateTime? _rightClosedSince;

  WinkPhase _phase = WinkPhase.noFace;
  Timer? _firedReset;

  /// 지금 눈 상태. 화면 표시용이다.
  WinkPhase get phase => _phase;

  void _setPhase(WinkPhase phase) {
    if (phase == _phase) return;
    _phase = phase;
    notifyListeners();
  }

  /// 윙크로 넘기는 기능이 켜져 있는지.
  bool _gestures = false;
  bool get gesturesOn => _gestures;

  /// 윙크 넘김을 켜고 끈다. 켜면 카메라를 열고, 끄면 닫는다.
  Future<void> setGestures(bool on) async {
    if (on == _gestures) return;
    _gestures = on;
    if (on && !_running) {
      await start();
    } else if (!on && _running) {
      await stop();
    } else {
      notifyListeners();
    }
  }

  bool get running => _running;
  String? get error => _error;
  bool get faceVisible => _faceVisible;
  bool get inCooldown => _inCooldownAt(DateTime.now());
  bool _inCooldownAt(DateTime now) =>
      _cooldownUntil != null && now.isBefore(_cooldownUntil!);

  Future<void> start() async {
    if (_running || !supported) return;
    _error = null;
    try {
      final cameras = await availableCameras();
      final front =
          cameras
              .where((c) => c.lensDirection == CameraLensDirection.front)
              .firstOrNull ??
          cameras.firstOrNull;
      if (front == null) {
        _error = tr('카메라가 없습니다');
        notifyListeners();
        return;
      }
      // low(352×288)는 얼굴이 너무 작아 눈 분류가 흔들린다.
      _camera = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _camera!.initialize();
      _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      await _camera!.startImageStream(_onFrame);
      _running = true;
    } on Object catch (e) {
      _error = tr('카메라를 열 수 없습니다: {0}', [e]);
      await stop();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _gestures = false;
    _running = false;
    final cam = _camera;
    _camera = null;
    try {
      if (cam != null && cam.value.isStreamingImages) {
        await cam.stopImageStream();
      }
      await cam?.dispose();
    } on Object {
      // 이미 닫힌 카메라
    }
    await _detector?.close();
    _detector = null;
    _faceVisible = false;
    _firedReset?.cancel();
    _phase = WinkPhase.noFace;
    notifyListeners();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || !_running) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) {
        return;
      }
      final faces = await _detector!.processImage(input);
      _handleFaces(faces);
    } on Object catch (e) {
      debugPrint('얼굴 인식 실패: $e');
    } finally {
      _busy = false;
    }
  }

  void _handleFaces(List<Face> faces) {
    final visible = faces.isNotEmpty;
    if (visible != _faceVisible) {
      _faceVisible = visible;
      notifyListeners();
    }
    if (faces.isEmpty) {
      _leftClosedSince = _rightClosedSince = null;
      _setPhase(WinkPhase.noFace);
      return;
    }
    // 화면을 켜 두려고만 보고 있다면 눈까지 읽지 않는다.
    // 여기서 넘겨 버리면 켠 적 없는 기능이 제멋대로 도는 셈이다.
    if (!_gestures) {
      _leftClosedSince = _rightClosedSince = null;
      _setPhase(WinkPhase.eyesOpen);
      return;
    }
    final face = faces.first;
    final now = DateTime.now();
    final fired = evaluate(
      leftOpen: face.leftEyeOpenProbability,
      rightOpen: face.rightEyeOpenProbability,
      now: now,
    );
    if (fired != null ||
        _lastLogAt == null ||
        now.difference(_lastLogAt!) >= const Duration(seconds: 1)) {
      _lastLogAt = now;
      debugPrint(
        '윙크: 왼눈 ${face.leftEyeOpenProbability?.toStringAsFixed(2)} '
        '오른눈 ${face.rightEyeOpenProbability?.toStringAsFixed(2)} '
        '얼굴 ${face.boundingBox.width.round()}px'
        '${fired != null ? ' → $fired' : ''}',
      );
    }
  }

  /// 눈 뜬 확률로 윙크를 판정한다. 순수 로직이라 테스트한다.
  /// 카메라 이미지는 거울상이라 "사용자의 오른눈" 은 ML Kit 의 leftEye 다.
  TurnCommand? evaluate({
    required double? leftOpen,
    required double? rightOpen,
    required DateTime now,
  }) {
    if (leftOpen == null || rightOpen == null) return null;
    if (_inCooldownAt(now)) {
      _leftClosedSince = _rightClosedSince = null;
      // 방금 넘긴 직후의 "넘김" 표시는 타이머가 걷는다. 그 뒤엔 두 눈 상태다.
      if (_phase != WinkPhase.fired) _setPhase(WinkPhase.eyesOpen);
      return null;
    }
    final lo = leftOpen < rightOpen ? leftOpen : rightOpen;
    final hi = leftOpen < rightOpen ? rightOpen : leftOpen;

    // 둘 다 감으면 깜빡임. 기록을 지운다.
    if (hi < blinkThreshold) {
      _leftClosedSince = _rightClosedSince = null;
      _setPhase(WinkPhase.eyesOpen);
      return null;
    }

    final wink = lo < closedThreshold && hi - lo >= winkGap;
    final leftClosed = wink && leftOpen < rightOpen;
    final rightClosed = wink && rightOpen < leftOpen;

    TurnCommand? fired;
    if (leftClosed) {
      _setPhase(WinkPhase.closingNext);
      _leftClosedSince ??= now;
      _rightClosedSince = null;
      if (now.difference(_leftClosedSince!) >= holdDuration) {
        fired = TurnCommand.next;
      }
    } else if (rightClosed) {
      _setPhase(WinkPhase.closingPrevious);
      _rightClosedSince ??= now;
      _leftClosedSince = null;
      if (now.difference(_rightClosedSince!) >= holdDuration) {
        fired = TurnCommand.previous;
      }
    } else {
      _leftClosedSince = _rightClosedSince = null;
      _setPhase(WinkPhase.eyesOpen);
    }

    if (fired != null) {
      _leftClosedSince = _rightClosedSince = null;
      _cooldownUntil = now.add(cooldown);
      _hub.emit(fired);
      // "넘김" 표시를 잠깐 보여 주고 두 눈 상태로 돌아간다.
      _setPhase(WinkPhase.fired);
      _firedReset?.cancel();
      _firedReset = Timer(const Duration(milliseconds: 700), () {
        if (_phase == WinkPhase.fired) _setPhase(WinkPhase.eyesOpen);
      });
      notifyListeners();
    }
    return fired;
  }

  InputImage? _toInputImage(CameraImage image) {
    final cam = _camera;
    if (cam == null) {
      return null;
    }
    final sensor = cam.description.sensorOrientation;
    final rotation =
        InputImageRotationValue.fromRawValue(sensor) ??
        InputImageRotation.rotation0deg;
    final format =
        InputImageFormatValue.fromRawValue(image.format.raw as int? ?? 0) ??
        (Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888);
    if (image.planes.isEmpty) {
      return null;
    }
    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// dispose 에 들어온 뒤로는 알리지 않는다. 카메라 끄기가 비동기라
  /// dispose 가 끝난 뒤에 알림이 늦게 도착한다.
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}

/// 화면에 알리는 눈 상태.
enum WinkPhase {
  /// 얼굴이 안 잡힌다(카메라가 꺼져 있거나 화면 밖).
  noFace,

  /// 두 눈이 보인다.
  eyesOpen,

  /// 다음 장으로 넘길 눈(사용자의 오른눈)을 감는 중.
  closingNext,

  /// 이전 장으로 넘길 눈(사용자의 왼눈)을 감는 중.
  closingPrevious,

  /// 방금 넘겼다.
  fired,
}

final faceTurnServiceProvider = Provider<FaceTurnService>((ref) {
  final s = FaceTurnService(ref.watch(turnInputHubProvider));
  ref.onDispose(s.dispose);
  return s;
});
