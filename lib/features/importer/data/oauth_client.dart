import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// OAuth 2.0 PKCE 로그인.
///
/// 데스크톱은 localhost 로 되돌아오는 임시 서버를 띄우고, 모바일은
/// `hiscore://oauth` 커스텀 스킴으로 돌아온다. 클라이언트 비밀은 없다.
/// PKCE 공개 클라이언트라 앱 안에 비밀을 넣을 이유가 없다.
class OAuthConfig {
  const OAuthConfig({
    required this.id,
    required this.authorizeUrl,
    required this.tokenUrl,
    required this.clientId,
    required this.scopes,
    this.extraAuthParams = const {},
  });

  /// 토큰 저장 키에 쓰는 이름.
  final String id;
  final Uri authorizeUrl;
  final Uri tokenUrl;
  final String clientId;
  final List<String> scopes;
  final Map<String, String> extraAuthParams;
}

class OAuthToken {
  const OAuthToken({
    required this.accessToken,
    this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt.subtract(const Duration(minutes: 1)));

  Map<String, dynamic> toJson() => {
        'access': accessToken,
        'refresh': refreshToken,
        'expires': expiresAt.toIso8601String(),
      };

  static OAuthToken fromJson(Map<String, dynamic> j) => OAuthToken(
        accessToken: j['access'] as String,
        refreshToken: j['refresh'] as String?,
        expiresAt: DateTime.parse(j['expires'] as String),
      );
}

class OAuthClient {
  OAuthClient(this.config, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final OAuthConfig config;
  final FlutterSecureStorage _storage;

  String get _storageKey => 'oauth.${config.id}';

  static bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  static const mobileRedirect = 'hiscore://oauth';

  Future<OAuthToken?> loadToken() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null) return null;
    return OAuthToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _saveToken(OAuthToken token) =>
      _storage.write(key: _storageKey, value: jsonEncode(token.toJson()));

  Future<void> signOut() => _storage.delete(key: _storageKey);

  /// 유효한 액세스 토큰. 만료됐으면 갱신하고, 없으면 null.
  Future<String?> accessToken() async {
    var token = await loadToken();
    if (token == null) return null;
    if (!token.isExpired) return token.accessToken;
    if (token.refreshToken == null) return null;

    final res = await http.post(config.tokenUrl, body: {
      'grant_type': 'refresh_token',
      'refresh_token': token.refreshToken!,
      'client_id': config.clientId,
    });
    if (res.statusCode != 200) {
      debugPrint('토큰 갱신 실패 ${config.id}: ${res.statusCode} ${res.body}');
      return null;
    }
    token = _parseToken(res.body, fallbackRefresh: token.refreshToken);
    await _saveToken(token);
    return token.accessToken;
  }

  /// 브라우저를 띄워 로그인한다. 사용자가 취소하면 false.
  Future<bool> signIn({Duration timeout = const Duration(minutes: 5)}) async {
    final verifier = _randomString(64);
    final challenge = base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', '');
    final state = _randomString(16);

    HttpServer? server;
    String redirectUri;
    final codeCompleter = Completer<String?>();
    StreamSubscription<Uri>? linkSub;

    if (_isDesktop) {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      redirectUri = 'http://127.0.0.1:${server.port}/callback';
      server.listen((req) async {
        final code = req.uri.queryParameters['code'];
        final gotState = req.uri.queryParameters['state'];
        req.response
          ..headers.contentType = ContentType.html
          ..write(
            '<html><body style="font-family:sans-serif;text-align:center;padding:40px">'
            '<h2>HIScore</h2><p>로그인이 끝났습니다. 이 창을 닫고 앱으로 돌아가세요.</p></body></html>',
          );
        await req.response.close();
        if (!codeCompleter.isCompleted) {
          codeCompleter.complete(gotState == state ? code : null);
        }
      });
    } else {
      redirectUri = mobileRedirect;
      linkSub = AppLinks().uriLinkStream.listen((uri) {
        if (uri.scheme != 'hiscore' || uri.host != 'oauth') return;
        if (uri.queryParameters['state'] != state) return;
        if (!codeCompleter.isCompleted) {
          codeCompleter.complete(uri.queryParameters['code']);
        }
      });
    }

    final url = config.authorizeUrl.replace(queryParameters: {
      ...config.authorizeUrl.queryParameters,
      'response_type': 'code',
      'client_id': config.clientId,
      'redirect_uri': redirectUri,
      'scope': config.scopes.join(' '),
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      ...config.extraAuthParams,
    });

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        return false;
      }
      final code = await codeCompleter.future.timeout(timeout, onTimeout: () => null);
      if (code == null) return false;

      final res = await http.post(config.tokenUrl, body: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': config.clientId,
        'redirect_uri': redirectUri,
        'code_verifier': verifier,
      });
      if (res.statusCode != 200) {
        debugPrint('토큰 교환 실패 ${config.id}: ${res.statusCode} ${res.body}');
        return false;
      }
      await _saveToken(_parseToken(res.body));
      return true;
    } finally {
      await server?.close(force: true);
      await linkSub?.cancel();
    }
  }

  OAuthToken _parseToken(String body, {String? fallbackRefresh}) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    final expiresIn = (j['expires_in'] as num?)?.toInt() ?? 3600;
    return OAuthToken(
      accessToken: j['access_token'] as String,
      refreshToken: j['refresh_token'] as String? ?? fallbackRefresh,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }

  static String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
