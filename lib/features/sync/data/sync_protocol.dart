import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 기기 사이 메시지.
///
/// 한 줄에 JSON 하나. 파일은 `file` 메시지 뒤에 [size] 바이트가 그대로 따라온다.
/// 프로토콜은 일부러 단순하게 둔다. 공연장 와이파이는 믿을 수 없어서
/// 끊기면 다시 붙는 것이 복잡한 것보다 낫다.
abstract final class SyncMsg {
  static const hello = 'hello';
  static const position = 'position';
  static const command = 'command';
  static const needFile = 'needFile';
  static const file = 'file';
  static const ping = 'ping';
}

/// 기기 역할.
enum SyncRole { off, lead, follow, remote }

/// 발견 방송에 들어가는 정보.
class SyncPeer {
  const SyncPeer({required this.name, required this.host, required this.port, required this.role});

  final String name;
  final String host;
  final int port;
  final SyncRole role;

  @override
  bool operator ==(Object other) =>
      other is SyncPeer && other.host == host && other.port == port;

  @override
  int get hashCode => Object.hash(host, port);
}

/// 소켓에서 JSON 줄과 원시 바이트 덩어리를 번갈아 읽는다.
class FrameReader {
  FrameReader(this._socket);

  final Stream<Uint8List> _socket;
  final _buffer = BytesBuilder(copy: false);
  final _lines = StreamController<Map<String, dynamic>>();
  Completer<Uint8List>? _pendingBinary;
  int _pendingSize = 0;
  StreamSubscription<Uint8List>? _sub;

  Stream<Map<String, dynamic>> get messages => _lines.stream;

  void start() {
    _sub = _socket.listen(
      (chunk) {
        _buffer.add(chunk);
        _drain();
      },
      onDone: () => _lines.close(),
      onError: (Object e) => _lines.addError(e),
    );
  }

  /// 다음 [size] 바이트를 통째로 받는다. `file` 메시지 직후에 부른다.
  Future<Uint8List> readBinary(int size) {
    final c = Completer<Uint8List>();
    _pendingBinary = c;
    _pendingSize = size;
    _drain();
    return c.future;
  }

  void _drain() {
    while (true) {
      if (_pendingBinary != null) {
        if (_buffer.length < _pendingSize) return;
        final all = _buffer.takeBytes();
        final head = Uint8List.sublistView(all, 0, _pendingSize);
        final rest = Uint8List.sublistView(all, _pendingSize);
        _buffer.add(Uint8List.fromList(rest));
        final c = _pendingBinary!;
        _pendingBinary = null;
        c.complete(Uint8List.fromList(head));
        continue;
      }
      final bytes = _buffer.toBytes();
      final nl = bytes.indexOf(10);
      if (nl < 0) return;
      final line = utf8.decode(bytes.sublist(0, nl));
      _buffer.clear();
      _buffer.add(bytes.sublist(nl + 1));
      if (line.trim().isNotEmpty) {
        try {
          _lines.add(jsonDecode(line) as Map<String, dynamic>);
        } on Object {
          // 깨진 줄은 버린다.
        }
      }
      // 파일 메시지 뒤 바이트를 기다려야 하면 호출자가 readBinary 를 부를 때까지 멈춘다.
      if (_pendingBinary == null && _lastWasFile(line)) return;
    }
  }

  bool _lastWasFile(String line) => line.contains('"type":"${SyncMsg.file}"');

  Future<void> close() async => _sub?.cancel();
}

/// 소켓에 JSON 한 줄을 쓴다.
void sendJson(Socket socket, Map<String, dynamic> msg) {
  socket.add(utf8.encode('${jsonEncode(msg)}\n'));
}
