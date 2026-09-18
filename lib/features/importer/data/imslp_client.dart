import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../../core/i18n/tr.dart';

/// IMSLP 검색 결과 한 건(작품 페이지).
class ImslpWork {
  const ImslpWork({required this.title, required this.pageId});

  /// 위키 페이지 제목. "Sonata No.14, Op.27 No.2 (Beethoven, Ludwig van)" 꼴.
  final String title;
  final int pageId;

  String get workName {
    final i = title.lastIndexOf(' (');
    return i < 0 ? title : title.substring(0, i);
  }

  String get composer {
    final i = title.lastIndexOf(' (');
    return i < 0 ? '' : title.substring(i + 2, title.length - 1);
  }
}

/// 작품 페이지 안의 PDF 파일 한 개.
class ImslpFile {
  const ImslpFile({required this.index, required this.description, this.pages});

  /// IMSLP 파일 번호. 다운로드 주소에 쓴다.
  final int index;
  final String description;
  final int? pages;
}

/// IMSLP(Petrucci Music Library) 검색과 다운로드.
///
/// 공식 API 가 없어 MediaWiki API 와 HTML 을 읽는다. 사이트 구조가 바뀌면
/// [filesOf] 의 정규식부터 깨진다. 실패하면 사용자에게 브라우저로 안내한다.
class ImslpClient {
  ImslpClient({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  static const _base = 'https://imslp.org';
  static const _headers = {
    'User-Agent': 'HIScore/1.0 (sheet music reader; contact via app)',
  };

  Future<List<ImslpWork>> search(String query, {int limit = 30}) async {
    final uri = Uri.parse('$_base/api.php').replace(queryParameters: {
      'action': 'query',
      'list': 'search',
      'srsearch': query,
      'srnamespace': '0',
      'srlimit': '$limit',
      'format': 'json',
    });
    final res = await _http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw HttpException(tr('IMSLP 검색 실패 {0}', [res.statusCode]));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final hits = (j['query']?['search'] as List?) ?? const [];
    return [
      for (final h in hits)
        ImslpWork(
          title: (h as Map<String, dynamic>)['title'] as String,
          pageId: h['pageid'] as int,
        ),
    ];
  }

  /// 작품 페이지의 PDF 목록.
  Future<List<ImslpFile>> filesOf(ImslpWork work) async {
    final uri = Uri.parse('$_base/api.php').replace(queryParameters: {
      'action': 'parse',
      'pageid': '${work.pageId}',
      'prop': 'text',
      'format': 'json',
    });
    final res = await _http.get(uri, headers: _headers);
    if (res.statusCode != 200) throw HttpException(tr('IMSLP 페이지 실패 {0}', [res.statusCode]));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final html = (j['parse']?['text']?['*'] as String?) ?? '';
    return parseFiles(html);
  }

  /// HTML 에서 파일 링크를 뽑는다. 테스트가 가능하도록 분리했다.
  static List<ImslpFile> parseFiles(String html) {
    final files = <ImslpFile>[];
    final seen = <int>{};
    // 파일 링크는 /wiki/Special:ImagefromIndex/{index} 꼴이고 그 앞뒤에 설명이 붙는다.
    final linkRe = RegExp(r'Special:ImagefromIndex/(\d+)[^>]*>([^<]*)<');
    for (final m in linkRe.allMatches(html)) {
      final index = int.parse(m.group(1)!);
      if (!seen.add(index)) continue;
      var desc = _stripTags(m.group(2) ?? '').trim();
      if (desc.isEmpty || desc.startsWith('#')) {
        // 링크 텍스트가 번호뿐이면 근처의 설명을 찾는다.
        final window = html.substring(
          (m.start - 400).clamp(0, html.length),
          m.start,
        );
        final titleRe = RegExp(r'class="we_file_info2"[^>]*>(.*?)<', dotAll: true);
        final t = titleRe.allMatches(window).lastOrNull;
        desc = t == null ? tr('파일 #{0}', [index]) : _stripTags(t.group(1)!).trim();
      }
      final pagesRe = RegExp(r'(\d+)\s*pp');
      final after = html.substring(m.end, (m.end + 300).clamp(0, html.length));
      final pages = pagesRe.firstMatch(after)?.group(1);
      files.add(
        ImslpFile(
          index: index,
          description: desc,
          pages: pages == null ? null : int.tryParse(pages),
        ),
      );
    }
    return files;
  }

  static String _stripTags(String s) =>
      s.replaceAll(RegExp(r'<[^>]+>'), '').replaceAll('&amp;', '&').replaceAll('&#160;', ' ');

  /// PDF 를 내려받는다. 면책 조항 동의 쿠키를 함께 보내 중간 페이지를 건너뛴다.
  Future<void> download(ImslpFile file, File target) async {
    var uri = Uri.parse('$_base/wiki/Special:ImagefromIndex/${file.index}');
    // 리디렉션을 손으로 따라가며 쿠키를 유지한다.
    for (var hop = 0; hop < 6; hop++) {
      final req = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll({..._headers, 'Cookie': 'imslpdisclaimeraccepted=yes'});
      final streamed = await _http.send(req);
      final location = streamed.headers['location'];
      if (streamed.isRedirect && location != null) {
        uri = uri.resolve(location);
        await streamed.stream.drain<void>();
        continue;
      }
      final type = streamed.headers['content-type'] ?? '';
      if (streamed.statusCode == 200 && type.contains('pdf')) {
        final sink = target.openWrite();
        await streamed.stream.pipe(sink);
        return;
      }
      final body = await streamed.stream.bytesToString();
      // 면책 페이지가 나오면 그 안의 계속 링크를 따라간다.
      final cont = RegExp(r'href="([^"]*Special:IMSLPDisclaimerAccept/[^"]*)"').firstMatch(body);
      if (cont != null) {
        uri = uri.resolve(cont.group(1)!.replaceAll('&amp;', '&'));
        continue;
      }
      throw HttpException(tr('PDF 를 받지 못했습니다. IMSLP 사이트 구조가 바뀌었을 수 있습니다.'));
    }
    throw HttpException(tr('리디렉션이 너무 많습니다'));
  }

  Uri pageUrl(ImslpWork work) => Uri.parse('$_base/wiki/${Uri.encodeComponent(work.title.replaceAll(' ', '_'))}');
}
