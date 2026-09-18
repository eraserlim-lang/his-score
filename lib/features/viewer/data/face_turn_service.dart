import 'dart:async';
import 'dart:io';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../domain/turn_input.dart';
import '../domain/viewer_controller.dart';

/// 얼굴 제스처 넘김.
///
/// 전면 카메라로 얼굴을 보다가 한쪽 눈을 0.4초쯤 감으면 넘긴다.
/// 오른눈은 다음, 왼눈은 이전. 양쪽을 같이 감는 건 그냥 눈 깜빡임이라 무시한다.
/// 한 번 넘기면 2초 동안은 다시 넘기지 않는다. 연속 오작동을 막기 위해서다.
/// 모바일(ML Kit)에서만 동작한다.
class FaceTurnService extends ChangeNotifier {
  FaceTurnService(this._hub);

  final TurnInputHub _hub;

  static bool get supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static const holdDuration = Duration(milliseconds: 400);
  static const cooldown = Duration(seconds: 2);
  static const closedThreshold = 0.25;
  static const openThreshold = 0.6;

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

  bool get running => _running;
  String? get error => _error;
  bool get faceVisible => _faceVisible;
  bool get inCooldown => _inCooldownAt(DateTime.now());
  bool _inCooldownAt(DateTime now) => _cooldownUntil != null && now.isBefore(_cooldownUntil!);

  Future<void> start() async {
    if (_running || !supported) return;
    _error = null;
    try {
      final cameras = await availableCameras();
      final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull ??
          cameras.firstOrNull;
      if (front == null) {
        _error = '카메라가 없습니다';
        notifyListeners();
        return;
      }
      _camera = CameraController(
        front,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
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
      _error = '카메라를 열 수 없습니다: $e';
      await stop();
    }
    notifyListeners();
  }

  Future<void> stop() async {
    _running = false;
    final cam = _camera;
    _camera = null;
    try {
      if (cam != null && cam.value.isStreamingImages) await cam.stopImageStream();
      await cam?.dispose();
    } on Object {
      // 이미 닫힌 카메라
    }
    await _detector?.close();
    _detector = null;
    _faceVisible = false;
    notifyListeners();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || !_running) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      if (input == null) return;
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
      return;
    }
    final face = faces.first;
    final now = DateTime.now();
    evaluate(
      leftOpen: face.leftEyeOpenProbability,
      rightOpen: face.rightEyeOpenProbability,
      now: now,
    );
  }

  /// 눈 뜬 확률로 윙크를 판정한다. 순수 로직이라 테스트한다.
  /// 카메라 이미지는 거울상이라 "사용자의 오른눈" 은 ML Kit 의 leftEye 다.
  TurnCommand? evaluate({required double? leftOpen, required double? rightOpen, required DateTime now}) {
    if (leftOpen == null || rightOpen == null) return null;
    if (_inCooldownAt(now)) {
      _leftClosedSince = _rightClosedSince = null;
      return null;
    }
    final leftClosed = leftOpen < closedThreshold;
    final rightClosed = rightOpen < closedThreshold;
    final leftWideOpen = leftOpen > openThreshold;
    final rightWideOpen = rightOpen > openThreshold;

    // 둘 다 감으면 깜빡임. 기록을 지운다.
    if (leftClosed && rightClosed) {
      _leftClosedSince = _rightClosedSince = null;
      return null;
    }

    TurnCommand? fired;
    if (leftClosed && rightWideOpen) {
      _leftClosedSince ??= now;
      _rightClosedSince = null;
      if (now.difference(_leftClosedSince!) >= holdDuration) fired = TurnCommand.next;
    } else if (rightClosed && leftWideOpen) {
      _rightClosedSince ??= now;
      _leftClosedSince = null;
      if (now.difference(_rightClosedSince!) >= holdDuration) fired = TurnCommand.previous;
    } else {
      _leftClosedSince = _rightClosedSince = null;
    }

    if (fired != null) {
      _leftClosedSince = _rightClosedSince = null;
      _cooldownUntil = now.add(cooldown);
      _hub.emit(fired);
      notifyListeners();
    }
    return fired;
  }

  InputImage? _toInputImage(CameraImage image) {
    final cam = _camera;
    if (cam == null) return null;
    final sensor = cam.description.sensorOrientation;
    final rotation = InputImageRotationValue.fromRawValue(sensor) ?? InputImageRotation.rotation0deg;
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int? ?? 0) ??
        (Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888);
    if (image.planes.isEmpty) return null;
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

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

final faceTurnServiceProvider = Provider<FaceTurnService>((ref) {
  final s = FaceTurnService(ref.watch(turnInputHubProvider));
  ref.onDispose(s.dispose);
  return s;
});
