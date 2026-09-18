import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/db/settings_dao.dart';
import 'oauth_client.dart';
import '../../../core/i18n/tr.dart';

/// 클라우드 폴더 안의 항목 하나.
class CloudEntry {
  const CloudEntry({
    required this.id,
    required this.name,
    required this.isFolder,
    this.size,
  });

  final String id;
  final String name;
  final bool isFolder;
  final int? size;

  bool get isPdf => !isFolder && name.toLowerCase().endsWith('.pdf');
}

/// 클라우드 저장소 공통 동작. Google Drive 와 Dropbox 가 구현한다.
abstract class CloudProvider {
  String get id;
  String get label;

  /// 클라이언트 ID 가 설정돼 있어야 로그인할 수 있다.
  bool get isConfigured;

  Future<bool> get isSignedIn;
  Future<bool> signIn();
  Future<void> signOut();

  /// [folderId] 가 null 이면 루트.
  Future<List<CloudEntry>> list(String? folderId);

  /// 파일을 [target] 에 내려받는다.
  Future<void> download(CloudEntry entry, File target);
}

class GoogleDriveProvider implements CloudProvider {
  GoogleDriveProvider(this._clientId);

  final String? _clientId;
  late final _oauth = OAuthClient(
    OAuthConfig(
      id: 'google',
      authorizeUrl: Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
      tokenUrl: Uri.parse('https://oauth2.googleapis.com/token'),
      clientId: _clientId ?? '',
      scopes: const ['https://www.googleapis.com/auth/drive.readonly'],
      extraAuthParams: const {'access_type': 'offline', 'prompt': 'consent'},
    ),
  );

  @override
  String get id => 'google';
  @override
  String get label => 'Google Drive';
  @override
  bool get isConfigured => _clientId != null && _clientId.isNotEmpty;
  @override
  Future<bool> get isSignedIn async => (await _oauth.loadToken()) != null;
  @override
  Future<bool> signIn() => _oauth.signIn();
  @override
  Future<void> signOut() => _oauth.signOut();

  Future<Map<String, String>> _headers() async {
    final token = await _oauth.accessToken();
    if (token == null) throw StateError(tr('로그인이 필요합니다'));
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Future<List<CloudEntry>> list(String? folderId) async {
    final parent = folderId ?? 'root';
    final q = "'$parent' in parents and trashed = false and "
        "(mimeType = 'application/pdf' or mimeType = 'application/vnd.google-apps.folder')";
    final entries = <CloudEntry>[];
    String? pageToken;
    do {
      final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
        'q': q,
        'fields': 'nextPageToken,files(id,name,mimeType,size)',
        'orderBy': 'folder,name',
        'pageSize': '200',
        'pageToken': ?pageToken,
      });
      final res = await http.get(uri, headers: await _headers());
      if (res.statusCode != 200) throw HttpException('Drive ${res.statusCode}: ${res.body}');
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      for (final f in (j['files'] as List)) {
        final m = f as Map<String, dynamic>;
        entries.add(
          CloudEntry(
            id: m['id'] as String,
            name: m['name'] as String,
            isFolder: m['mimeType'] == 'application/vnd.google-apps.folder',
            size: int.tryParse('${m['size'] ?? ''}'),
          ),
        );
      }
      pageToken = j['nextPageToken'] as String?;
    } while (pageToken != null);
    return entries;
  }

  @override
  Future<void> download(CloudEntry entry, File target) async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files/${entry.id}', {'alt': 'media'});
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw HttpException(tr('Drive 다운로드 {0}', [res.statusCode]));
    await target.writeAsBytes(res.bodyBytes, flush: true);
  }
}

class DropboxProvider implements CloudProvider {
  DropboxProvider(this._clientId);

  final String? _clientId;
  late final _oauth = OAuthClient(
    OAuthConfig(
      id: 'dropbox',
      authorizeUrl: Uri.parse('https://www.dropbox.com/oauth2/authorize'),
      tokenUrl: Uri.parse('https://api.dropboxapi.com/oauth2/token'),
      clientId: _clientId ?? '',
      scopes: const ['files.metadata.read', 'files.content.read'],
      extraAuthParams: const {'token_access_type': 'offline'},
    ),
  );

  @override
  String get id => 'dropbox';
  @override
  String get label => 'Dropbox';
  @override
  bool get isConfigured => _clientId != null && _clientId.isNotEmpty;
  @override
  Future<bool> get isSignedIn async => (await _oauth.loadToken()) != null;
  @override
  Future<bool> signIn() => _oauth.signIn();
  @override
  Future<void> signOut() => _oauth.signOut();

  Future<Map<String, String>> _headers() async {
    final token = await _oauth.accessToken();
    if (token == null) throw StateError(tr('로그인이 필요합니다'));
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Future<List<CloudEntry>> list(String? folderId) async {
    final entries = <CloudEntry>[];
    var res = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/list_folder'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'path': folderId ?? '', 'limit': 500}),
    );
    while (true) {
      if (res.statusCode != 200) throw HttpException('Dropbox ${res.statusCode}: ${res.body}');
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      for (final e in (j['entries'] as List)) {
        final m = e as Map<String, dynamic>;
        final isFolder = m['.tag'] == 'folder';
        final name = m['name'] as String;
        if (!isFolder && !name.toLowerCase().endsWith('.pdf')) continue;
        entries.add(
          CloudEntry(
            id: m['path_lower'] as String,
            name: name,
            isFolder: isFolder,
            size: (m['size'] as num?)?.toInt(),
          ),
        );
      }
      if (j['has_more'] != true) break;
      res = await http.post(
        Uri.parse('https://api.dropboxapi.com/2/files/list_folder/continue'),
        headers: {...await _headers(), 'Content-Type': 'application/json'},
        body: jsonEncode({'cursor': j['cursor']}),
      );
    }
    entries.sort((a, b) {
      if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }

  @override
  Future<void> download(CloudEntry entry, File target) async {
    final res = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {
        ...await _headers(),
        'Dropbox-API-Arg': jsonEncode({'path': entry.id}),
      },
    );
    if (res.statusCode != 200) throw HttpException(tr('Dropbox 다운로드 {0}', [res.statusCode]));
    await target.writeAsBytes(res.bodyBytes, flush: true);
  }
}

/// 설정에 저장된 클라이언트 ID 로 제공자 목록을 만든다.
final cloudProvidersProvider = FutureProvider<List<CloudProvider>>((ref) async {
  final settings = ref.watch(settingsDaoProvider);
  return [
    GoogleDriveProvider(await settings.get(SettingKeys.googleClientId)),
    DropboxProvider(await settings.get(SettingKeys.dropboxClientId)),
  ];
});

/// 내려받은 파일을 놓아둘 임시 경로.
File tempDownloadFile(Directory dir, String name) =>
    File(p.join(dir.path, '${DateTime.now().microsecondsSinceEpoch}-$name'));
