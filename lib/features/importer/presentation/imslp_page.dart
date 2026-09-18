import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cloud_providers.dart' show tempDownloadFile;
import '../data/imslp_client.dart';
import '../data/score_importer.dart';

/// IMSLP 무료 클래식 악보 검색.
class ImslpPage extends ConsumerStatefulWidget {
  const ImslpPage({super.key});

  @override
  ConsumerState<ImslpPage> createState() => _ImslpPageState();
}

class _ImslpPageState extends ConsumerState<ImslpPage> {
  final _client = ImslpClient();
  final _query = TextEditingController();
  List<ImslpWork>? _results;
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final r = await _client.search(q);
      if (mounted) setState(() => _results = r);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _openWork(ImslpWork work) async {
    List<ImslpFile> files;
    try {
      files = await _client.filesOf(work);
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('파일 목록을 가져오지 못했습니다: $e')));
      return;
    }
    if (!mounted) return;

    final picked = await showModalBottomSheet<ImslpFile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(work.workName, style: Theme.of(context).textTheme.titleMedium, maxLines: 2),
                  ),
                  IconButton(
                    onPressed: () => launchUrl(_client.pageUrl(work), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.open_in_browser),
                    tooltip: '브라우저에서 열기',
                  ),
                ],
              ),
            ),
            Expanded(
              child: files.isEmpty
                  ? const Center(child: Text('이 페이지에서 PDF 를 찾지 못했습니다.\n브라우저에서 확인해 보세요.', textAlign: TextAlign.center))
                  : ListView.builder(
                      itemCount: files.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(Icons.picture_as_pdf_outlined),
                        title: Text(files[i].description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('#${files[i].index}${files[i].pages == null ? '' : ' · ${files[i].pages}쪽'}'),
                        onTap: () => Navigator.pop(context, files[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _download(work, picked);
  }

  Future<void> _download(ImslpWork work, ImslpFile file) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(content: Text('내려받는 중…'), duration: Duration(seconds: 60)));
    final tmp = tempDownloadFile(Directory.systemTemp, 'imslp-${file.index}.pdf');
    try {
      await _client.download(file, tmp);
      final importer = await ref.read(scoreImporterProvider.future);
      final id = await importer.importFile(
        tmp,
        title: work.workName,
        composer: work.composer,
        deleteSource: true,
      );
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(id == null ? '가져오지 못했습니다' : '가져왔습니다: ${work.workName}')));
    } on Object catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('내려받기 실패: $e'),
          action: SnackBarAction(
            label: '브라우저',
            onPressed: () => launchUrl(_client.pageUrl(work), mode: LaunchMode.externalApplication),
          ),
        ),
      );
    } finally {
      if (await tmp.exists()) await tmp.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IMSLP 무료 클래식 악보')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: '작곡가, 곡명 (예: Chopin Nocturne)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(onPressed: _search, icon: const Icon(Icons.arrow_forward)),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '저작권이 만료된 악보를 IMSLP(Petrucci Music Library)에서 검색합니다. 이용 시 IMSLP 후원을 부탁드립니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) return Center(child: Text('검색 실패: $_error'));
    final results = _results;
    if (results == null) return const SizedBox.shrink();
    if (results.isEmpty) return const Center(child: Text('결과가 없습니다'));
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) => ListTile(
        leading: const Icon(Icons.library_music_outlined),
        title: Text(results[i].workName, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(results[i].composer),
        onTap: () => _openWork(results[i]),
      ),
    );
  }
}
