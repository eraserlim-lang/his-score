import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/score_dao.dart';
import '../../../core/db/settings_dao.dart';
import '../../../core/storage/app_paths.dart';
import '../../importer/data/score_importer.dart';
import '../../viewer/domain/turn_input.dart';
import '../../viewer/domain/viewer_controller.dart';
import 'sync_protocol.dart';

/// 기기 간 페이지 넘김 동기화와 리모컨.
///
/// 리드 하나에 팔로워와 리모컨 여럿이 붙는다. 같은 와이파이에서 UDP 멀티캐스트로
/// 서로를 찾고 TCP 로 이야기한다. 팔로워에 없는 곡은 리드가 파일을 보내 준다.
class SyncService extends ChangeNotifier {
  SyncService({
    required this.hub,
    required this.settings,
    required this.scoreDao,
    required this.paths,
    required this.importer,
  });

  final TurnInputHub hub;
  final SettingsDao settings;
  final ScoreDao scoreDao;
  final AppPaths paths;
  final Future<ScoreImporter> Function() importer;

  static const multicastAddress = '239.255.42.99';
  static const discoveryPort = 47800;

  SyncRole _role = SyncRole.off;
  String _deviceName = Platform.localHostname;
  String? _status;

  // 리드
  ServerSocket? _server;
  final _clients = <Socket>[];
  RawDatagramSocket? _announcer;
  Timer? _announceTimer;

  // 팔로워/리모컨
  Socket? _link;
  FrameReader? _reader;
  RawDatagramSocket? _listener;
  final _peers = <SyncPeer>{};
  SyncPeer? _connectedTo;
  Timer? _reconnect;

  StreamSubscription<ViewerPosition>? _positionSub;
  bool _disposed = false;

  @override
  void notifyListeners() {
    // 소켓 콜백은 dispose 뒤에도 늦게 도착할 수 있다.
    if (_disposed) return;
    super.notifyListeners();
  }

  SyncRole get role => _role;
  String get deviceName => _deviceName;
  String? get status => _status;
  List<SyncPeer> get peers => _peers.toList();
  SyncPeer? get connectedTo => _connectedTo;
  int get clientCount => _clients.length;
  bool get isConnected => _link != null;

  Future<void> init() async {
    _deviceName = await settings.get(SettingKeys.deviceName) ?? _deviceName;
    final saved = await settings.get(SettingKeys.syncRole);
    final role = SyncRole.values.firstWhere((r) => r.name == saved, orElse: () => SyncRole.off);
    if (role != SyncRole.off) await setRole(role);
  }

  Future<void> setDeviceName(String name) async {
    _deviceName = name.trim().isEmpty ? Platform.localHostname : name.trim();
    await settings.set(SettingKeys.deviceName, _deviceName);
    notifyListeners();
  }

  Future<void> setRole(SyncRole role) async {
    if (role == _role) return;
    await _teardown();
    _role = role;
    await settings.set(SettingKeys.syncRole, role == SyncRole.off ? null : role.name);
    notifyListeners();
    try {
      switch (role) {
        case SyncRole.off:
          break;
        case SyncRole.lead:
          await _startLead();
        case SyncRole.follow:
        case SyncRole.remote:
          await _startClient();
      }
    } on Object catch (e) {
      _status = '시작 실패: $e';
      notifyListeners();
    }
  }

  // ------------------------------------------------------------ 리드

  Future<void> _startLead() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_onClient);
    _status = '연결 대기 (포트 ${_server!.port})';

    _positionSub = hub.positions.listen(_broadcastPosition);

    _announcer = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0, reuseAddress: true);
    _announcer!.broadcastEnabled = true;
    _announceTimer = Timer.periodic(const Duration(seconds: 2), (_) => _announce());
    _announce();
    notifyListeners();
  }

  void _announce() {
    final s = _announcer;
    final server = _server;
    if (s == null || server == null) return;
    final payload = utf8.encode(jsonEncode({
      'app': 'hiscore',
      'role': 'lead',
      'name': _deviceName,
      'port': server.port,
    }));
    try {
      s.send(payload, InternetAddress(multicastAddress), discoveryPort);
      // 멀티캐스트를 막는 공유기가 있어 브로드캐스트도 함께 보낸다.
      s.send(payload, InternetAddress('255.255.255.255'), discoveryPort);
    } on Object catch (e) {
      debugPrint('발견 방송 실패: $e');
    }
  }

  void _onClient(Socket socket) {
    _clients.add(socket);
    _status = '${_clients.length}대 연결됨';
    notifyListeners();

    final reader = FrameReader(socket)..start();
    reader.messages.listen(
      (msg) => _onLeadMessage(socket, msg),
      onDone: () {
        _clients.remove(socket);
        _status = _clients.isEmpty ? '연결 대기' : '${_clients.length}대 연결됨';
        notifyListeners();
      },
      onError: (_) => socket.destroy(),
    );

    // 지금 위치를 바로 알려 준다.
    final last = hub.lastPosition;
    if (last != null) sendJson(socket, _positionMsg(last));
  }

  Future<void> _onLeadMessage(Socket socket, Map<String, dynamic> msg) async {
    switch (msg['type']) {
      case SyncMsg.command:
        final name = msg['cmd'] as String?;
        final cmd = TurnCommand.values.where((c) => c.name == name).firstOrNull;
        if (cmd != null) hub.emit(cmd);
      case SyncMsg.needFile:
        await _sendFile(socket, msg['scoreId'] as String);
      case SyncMsg.ping:
        sendJson(socket, {'type': SyncMsg.ping});
    }
  }

  Map<String, dynamic> _positionMsg(ViewerPosition p) => {
        'type': SyncMsg.position,
        'scoreId': p.scoreId,
        'sourcePage': p.sourcePage,
        'pageIndex': p.pageIndex,
        'title': p.title,
        'setlistId': p.setlistId,
      };

  void _broadcastPosition(ViewerPosition p) {
    final msg = _positionMsg(p);
    for (final c in _clients) {
      try {
        sendJson(c, msg);
      } on Object {
        // 끊긴 소켓은 onDone 이 정리한다.
      }
    }
  }

  Future<void> _sendFile(Socket socket, String scoreId) async {
    final score = await scoreDao.findById(scoreId);
    if (score == null) return;
    final file = paths.resolve(score.filePath);
    if (!await file.exists()) return;
    final bytes = await file.readAsBytes();
    sendJson(socket, {
      'type': SyncMsg.file,
      'scoreId': scoreId,
      'title': score.title,
      'artist': score.artist,
      'composer': score.composer,
      'size': bytes.length,
    });
    socket.add(bytes);
    await socket.flush();
  }

  // ------------------------------------------------------------ 팔로워 / 리모컨

  Future<void> _startClient() async {
    _status = '리드 기기를 찾는 중…';
    _listener = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort, reuseAddress: true, reusePort: true);
    try {
      _listener!.joinMulticast(InternetAddress(multicastAddress));
    } on Object catch (e) {
      debugPrint('멀티캐스트 가입 실패(브로드캐스트로만 찾는다): $e');
    }
    _listener!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final d = _listener!.receive();
      if (d == null) return;
      try {
        final j = jsonDecode(utf8.decode(d.data)) as Map<String, dynamic>;
        if (j['app'] != 'hiscore' || j['role'] != 'lead') return;
        final peer = SyncPeer(
          name: j['name'] as String? ?? d.address.address,
          host: d.address.address,
          port: j['port'] as int,
          role: SyncRole.lead,
        );
        if (_peers.add(peer)) notifyListeners();
        // 아직 아무 데도 안 붙었으면 처음 보인 리드에 붙는다.
        if (_link == null && _connectedTo == null) connectTo(peer);
      } on Object {
        // 남의 패킷
      }
    });
    notifyListeners();
  }

  /// 직접 주소로 붙는다. 발견이 안 되는 망에서 쓴다.
  Future<void> connectTo(SyncPeer peer) async {
    _reconnect?.cancel();
    await _link?.close();
    _connectedTo = peer;
    _status = '${peer.name} 에 연결 중…';
    notifyListeners();
    try {
      final socket = await Socket.connect(peer.host, peer.port, timeout: const Duration(seconds: 5));
      _link = socket;
      sendJson(socket, {'type': SyncMsg.hello, 'name': _deviceName, 'role': _role.name});
      _reader = FrameReader(socket)..start();
      _reader!.messages.listen(
        _onClientMessage,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
      );
      _status = '${peer.name} 에 연결됨';
    } on Object catch (e) {
      _status = '연결 실패: $e';
      _scheduleReconnect();
    }
    notifyListeners();
  }

  void _onDisconnected() {
    _link = null;
    _reader = null;
    _status = '연결이 끊겼습니다. 다시 붙는 중…';
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    final peer = _connectedTo;
    if (peer == null || _role == SyncRole.off) return;
    _reconnect = Timer(const Duration(seconds: 3), () => connectTo(peer));
  }

  Future<void> _onClientMessage(Map<String, dynamic> msg) async {
    switch (msg['type']) {
      case SyncMsg.position:
        if (_role != SyncRole.follow) return;
        final scoreId = msg['scoreId'] as String;
        final position = ViewerPosition(
          scoreId: scoreId,
          sourcePage: msg['sourcePage'] as int,
          pageIndex: msg['pageIndex'] as int,
          title: msg['title'] as String? ?? '',
          setlistId: msg['setlistId'] as String?,
        );
        if (await scoreDao.findById(scoreId) == null) {
          _status = '"${position.title}" 을 리드에서 받는 중…';
          notifyListeners();
          final link = _link;
          if (link != null) sendJson(link, {'type': SyncMsg.needFile, 'scoreId': scoreId});
          _pendingPosition = position;
          return;
        }
        hub.applyRemotePosition(position);
      case SyncMsg.file:
        final size = msg['size'] as int;
        final bytes = await _reader!.readBinary(size);
        await _importReceived(msg, bytes);
      case SyncMsg.ping:
        break;
    }
  }

  ViewerPosition? _pendingPosition;

  Future<void> _importReceived(Map<String, dynamic> msg, Uint8List bytes) async {
    final scoreId = msg['scoreId'] as String;
    final tmp = File(p.join(Directory.systemTemp.path, 'sync-$scoreId.pdf'));
    await tmp.writeAsBytes(bytes, flush: true);
    try {
      final imp = await importer();
      await imp.importFile(
        tmp,
        id: scoreId,
        title: msg['title'] as String?,
        artist: msg['artist'] as String?,
        composer: msg['composer'] as String?,
        deleteSource: true,
      );
      _status = '"${msg['title']}" 을 받았습니다';
      final pending = _pendingPosition;
      _pendingPosition = null;
      if (pending != null) hub.applyRemotePosition(pending);
    } on Object catch (e) {
      _status = '파일을 받지 못했습니다: $e';
    }
    notifyListeners();
  }

  /// 리모컨에서 리드로 명령을 보낸다.
  void sendCommand(TurnCommand cmd) {
    final link = _link;
    if (link == null) return;
    sendJson(link, {'type': SyncMsg.command, 'cmd': cmd.name});
  }

  Future<void> _teardown() async {
    _announceTimer?.cancel();
    _announceTimer = null;
    _reconnect?.cancel();
    _reconnect = null;
    await _positionSub?.cancel();
    _positionSub = null;
    _announcer?.close();
    _announcer = null;
    _listener?.close();
    _listener = null;
    for (final c in _clients) {
      c.destroy();
    }
    _clients.clear();
    await _server?.close();
    _server = null;
    await _reader?.close();
    _reader = null;
    _link?.destroy();
    _link = null;
    _connectedTo = null;
    _peers.clear();
    _status = null;
  }

  /// 리드가 열어 둔 포트. 화면에 보여주고 직접 연결에도 쓴다.
  int? get leadPort => _server?.port;

  @override
  void dispose() {
    _disposed = true;
    _teardown();
    super.dispose();
  }
}

final syncServiceProvider = FutureProvider<SyncService>((ref) async {
  final paths = await ref.watch(appPathsProvider.future);
  final service = SyncService(
    hub: ref.watch(turnInputHubProvider),
    settings: ref.watch(settingsDaoProvider),
    scoreDao: ref.watch(scoreDaoProvider),
    paths: paths,
    importer: () => ref.read(scoreImporterProvider.future),
  );
  ref.onDispose(service.dispose);
  await service.init();
  return service;
});
