import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'viewer_controller.dart';

/// 열려 있는 뷰어의 위치. 리드 기기가 팔로워에게 알릴 때 쓴다.
@immutable
class ViewerPosition {
  const ViewerPosition({
    required this.scoreId,
    required this.sourcePage,
    required this.pageIndex,
    required this.title,
    this.setlistId,
  });

  final String scoreId;

  /// 원본 PDF 페이지 번호(1-based). 기기마다 순서 편집이 달라도 같은 장을 가리킨다.
  final int sourcePage;
  final int pageIndex;
  final String title;
  final String? setlistId;
}

/// 모든 넘김 입력이 모이는 허브.
///
/// 페달, 얼굴 제스처, 리모컨, 리드 기기가 여기로 명령을 보내고,
/// 열려 있는 뷰어 화면이 구독해 자기 컨트롤러에 넘긴다. 뷰어가 없으면 버린다.
/// 반대로 뷰어의 위치 변화도 여기로 흘러 리드 역할이 팔로워에게 전한다.
class TurnInputHub {
  final _commands = StreamController<TurnCommand>.broadcast();
  final _positions = StreamController<ViewerPosition>.broadcast();
  final _remotePositions = StreamController<ViewerPosition>.broadcast();

  /// 외부 입력 → 뷰어.
  Stream<TurnCommand> get commands => _commands.stream;
  void emit(TurnCommand c) => _commands.add(c);

  /// 뷰어 → 외부(리드 방송).
  Stream<ViewerPosition> get positions => _positions.stream;
  ViewerPosition? lastPosition;
  void reportPosition(ViewerPosition p) {
    lastPosition = p;
    _positions.add(p);
  }

  /// 리드 기기가 보낸 위치 → 팔로워 뷰어.
  Stream<ViewerPosition> get remotePositions => _remotePositions.stream;
  void applyRemotePosition(ViewerPosition p) => _remotePositions.add(p);

  /// 뷰어가 열려 있는지. 리모컨과 팔로워가 상태를 보여줄 때 쓴다.
  bool viewerOpen = false;

  void dispose() {
    _commands.close();
    _positions.close();
    _remotePositions.close();
  }
}

final turnInputHubProvider = Provider<TurnInputHub>((ref) {
  final hub = TurnInputHub();
  ref.onDispose(hub.dispose);
  return hub;
});

/// 페달 키 매핑. 블루투스 페달은 키보드로 잡히므로 키 하나가 명령 하나다.
@immutable
class PedalMapping {
  const PedalMapping({required this.next, required this.previous});

  /// 논리 키 id 집합. 기본값에 사용자가 학습시킨 키를 더한다.
  final Set<int> next;
  final Set<int> previous;

  static final defaults = PedalMapping(
    next: {
      LogicalKeyboardKey.arrowRight.keyId,
      LogicalKeyboardKey.arrowDown.keyId,
      LogicalKeyboardKey.pageDown.keyId,
      LogicalKeyboardKey.space.keyId,
      LogicalKeyboardKey.enter.keyId,
      LogicalKeyboardKey.mediaTrackNext.keyId,
    },
    previous: {
      LogicalKeyboardKey.arrowLeft.keyId,
      LogicalKeyboardKey.arrowUp.keyId,
      LogicalKeyboardKey.pageUp.keyId,
      LogicalKeyboardKey.backspace.keyId,
      LogicalKeyboardKey.mediaTrackPrevious.keyId,
    },
  );

  TurnCommand? commandFor(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.home) return TurnCommand.first;
    if (key == LogicalKeyboardKey.end) return TurnCommand.last;
    if (next.contains(key.keyId)) return TurnCommand.next;
    if (previous.contains(key.keyId)) return TurnCommand.previous;
    return null;
  }

  PedalMapping withLearned({int? nextKey, int? previousKey}) => PedalMapping(
        next: {...next, ?nextKey}..removeAll({?previousKey}),
        previous: {...previous, ?previousKey}..removeAll({?nextKey}),
      );

  String encode() => '${next.join(',')}|${previous.join(',')}';

  static PedalMapping decode(String? raw) {
    if (raw == null || !raw.contains('|')) return defaults;
    final parts = raw.split('|');
    Set<int> ids(String s) =>
        s.split(',').where((e) => e.isNotEmpty).map(int.parse).toSet();
    return PedalMapping(next: ids(parts[0]), previous: ids(parts[1]));
  }
}
