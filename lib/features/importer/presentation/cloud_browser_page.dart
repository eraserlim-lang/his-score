import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_providers.dart';
import '../data/score_importer.dart';

/// 클라우드 폴더 탐색기. PDF 를 골라 내려받고 가져온다.
///
/// 폴더 전체를 한 번에 받을 수도 있다.
class CloudBrowserPage extends ConsumerStatefulWidget {
  const CloudBrowserPage({super.key, required this.provider});

  final CloudProvider provider;

  @override
  ConsumerState<CloudBrowserPage> createState() => _CloudBrowserPageState();
}

class _CloudBrowserPageState extends ConsumerState<CloudBrowserPage> {
  /// 폴더 이동 기록. 마지막이 현재 폴더다. (id, 이름)
  final _stack = <(String?, String)>[(null, '내 파일')];
  List<CloudEntry>? _entries;
  String? _error;
  bool _signedIn = false;
  bool _downloading = false;
  int _progress = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _signedIn = await widget.provider.isSignedIn;
    if (_signedIn) {
      await _load();
    } else {
      setState(() {});
    }
  }

  Future<void> _signIn() async {
    final ok = await widget.provider.signIn();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 취소되었거나 실패했습니다')));
      return;
    }
    _signedIn = true;
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _entries = null;
      _error = null;
    });
    try {
      final list = await widget.provider.list(_stack.last.$1);
      if (mounted) setState(() => _entries = list);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _importEntries(List<CloudEntry> targets) async {
    if (targets.isEmpty) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _total = targets.length;
    });
    final importer = await ref.read(scoreImporterProvider.future);
    var ok = 0;
    final failures = <String>[];
    for (final e in targets) {
      final tmp = tempDownloadFile(Directory.systemTemp, e.name);
      try {
        await widget.provider.download(e, tmp);
        final id = await importer.importFile(
          tmp,
          title: e.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
          deleteSource: true,
        );
        if (id != null) ok++;
      } on Object catch (err) {
        failures.add('${e.name}: $err');
      } finally {
        if (await tmp.exists()) await tmp.delete();
        if (mounted) setState(() => _progress++);
      }
    }
    if (!mounted) return;
    setState(() => _downloading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failures.isEmpty ? '$ok개를 가져왔습니다' : '$ok개 성공, ${failures.length}개 실패',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    return PopScope(
      canPop: _stack.length == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _stack.removeLast());
        _load();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_stack.length == 1 ? provider.label : _stack.last.$2),
          actions: [
            if (_signedIn && (_entries?.any((e) => e.isPdf) ?? false))
              IconButton(
                onPressed: _downloading
                    ? null
                    : () => _importEntries(_entries!.where((e) => e.isPdf).toList()),
                icon: const Icon(Icons.cloud_download_outlined),
                tooltip: '이 폴더의 PDF 전부 가져오기',
              ),
            if (_signedIn)
              IconButton(
                onPressed: () async {
                  await provider.signOut();
                  if (mounted) setState(() => _signedIn = false);
                },
                icon: const Icon(Icons.logout),
                tooltip: '로그아웃',
              ),
          ],
        ),
        body: Column(
          children: [
            if (_downloading) LinearProgressIndicator(value: _total == 0 ? null : _progress / _total),
            Expanded(child: _body(provider)),
          ],
        ),
      ),
    );
  }

  Widget _body(CloudProvider provider) {
    if (!provider.isConfigured) {
      return _Message(
        icon: Icons.key_off_outlined,
        title: '${provider.label} 클라이언트 ID 가 없습니다',
        detail: '설정 화면에서 OAuth 클라이언트 ID 를 넣으면 연결할 수 있습니다.',
      );
    }
    if (!_signedIn) {
      return Center(
        child: FilledButton.icon(
          onPressed: _signIn,
          icon: const Icon(Icons.login),
          label: Text('${provider.label} 로그인'),
        ),
      );
    }
    if (_error != null) {
      return _Message(
        icon: Icons.error_outline,
        title: '목록을 가져오지 못했습니다',
        detail: _error!,
        action: TextButton(onPressed: _load, child: const Text('다시 시도')),
      );
    }
    final entries = _entries;
    if (entries == null) return const Center(child: CircularProgressIndicator());
    if (entries.isEmpty) return const _Message(icon: Icons.folder_off_outlined, title: 'PDF 가 없습니다');

    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return ListTile(
          leading: Icon(e.isFolder ? Icons.folder_outlined : Icons.picture_as_pdf_outlined),
          title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: e.size == null ? null : Text(_size(e.size!)),
          trailing: e.isFolder ? const Icon(Icons.chevron_right) : const Icon(Icons.download_outlined),
          onTap: _downloading
              ? null
              : () {
                  if (e.isFolder) {
                    setState(() => _stack.add((e.id, e.name)));
                    _load();
                  } else {
                    _importEntries([e]);
                  }
                },
        );
      },
    );
  }

  static String _size(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).toStringAsFixed(0)} KB'
      : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.detail, this.action});

  final IconData icon;
  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(detail!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
