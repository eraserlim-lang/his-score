import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewer/domain/viewer_controller.dart';
import '../data/sync_protocol.dart';
import '../data/sync_service.dart';

/// 기기 동기화 설정 시트. 역할을 고르고 상대 기기를 본다.
Future<void> showSyncSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SyncPanel(),
    ),
  );
}

class SyncPanel extends ConsumerWidget {
  const SyncPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(syncServiceProvider);
    final service = serviceAsync.value;
    if (service == null) return const Center(child: CircularProgressIndicator());

    return ListenableBuilder(
      listenable: service,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('기기 동기화', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '같은 와이파이에 있는 기기끼리 페이지 넘김과 곡 선택을 맞춥니다. '
            '리드가 넘기면 팔로워가 따라가고, 팔로워에 없는 곡은 리드가 보내 줍니다.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SegmentedButton<SyncRole>(
            segments: const [
              ButtonSegment(value: SyncRole.off, label: Text('끄기')),
              ButtonSegment(value: SyncRole.lead, label: Text('리드'), icon: Icon(Icons.wifi_tethering)),
              ButtonSegment(value: SyncRole.follow, label: Text('팔로우'), icon: Icon(Icons.wifi)),
              ButtonSegment(value: SyncRole.remote, label: Text('리모컨'), icon: Icon(Icons.settings_remote)),
            ],
            selected: {service.role},
            onSelectionChanged: (s) => service.setRole(s.first),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.devices),
            title: Text(service.deviceName),
            subtitle: Text(service.status ?? '꺼짐'),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final c = TextEditingController(text: service.deviceName);
                final v = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('이 기기 이름'),
                    content: TextField(controller: c, autofocus: true),
                    actions: [
                      FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('저장')),
                    ],
                  ),
                );
                if (v != null) await service.setDeviceName(v);
              },
            ),
          ),
          if (service.role == SyncRole.lead && service.leadPort != null)
            Text('포트 ${service.leadPort} · 연결 ${service.clientCount}대', style: Theme.of(context).textTheme.bodySmall),
          if (service.role == SyncRole.follow || service.role == SyncRole.remote) ...[
            const SizedBox(height: 8),
            Text('발견된 리드', style: Theme.of(context).textTheme.labelLarge),
            if (service.peers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('아직 없습니다. 리드 기기에서 "리드" 를 켜 주세요.'),
              ),
            for (final peer in service.peers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(service.connectedTo == peer && service.isConnected ? Icons.link : Icons.link_off),
                title: Text(peer.name),
                subtitle: Text('${peer.host}:${peer.port}'),
                onTap: () => service.connectTo(peer),
              ),
            TextButton.icon(
              onPressed: () => _connectManually(context, service),
              icon: const Icon(Icons.add_link),
              label: const Text('주소로 직접 연결'),
            ),
          ],
          if (service.role == SyncRole.remote) ...[
            const SizedBox(height: 12),
            const RemoteControls(),
          ],
        ],
      ),
    );
  }

  Future<void> _connectManually(BuildContext context, SyncService service) async {
    final host = TextEditingController();
    final port = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리드 기기 주소'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: host, decoration: const InputDecoration(labelText: 'IP 주소', hintText: '192.168.0.10')),
            TextField(controller: port, decoration: const InputDecoration(labelText: '포트'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('연결')),
        ],
      ),
    );
    if (ok != true) return;
    final p = int.tryParse(port.text.trim());
    if (host.text.trim().isEmpty || p == null) return;
    await service.connectTo(SyncPeer(name: host.text.trim(), host: host.text.trim(), port: p, role: SyncRole.lead));
  }
}

/// 리모컨 버튼. 폰을 보면대 옆에 두고 큼직하게 누른다.
class RemoteControls extends ConsumerWidget {
  const RemoteControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(syncServiceProvider).value;
    if (service == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 120,
            child: FilledButton.tonal(
              onPressed: () => service.sendCommand(TurnCommand.previous),
              child: const Icon(Icons.chevron_left, size: 48),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 120,
            child: FilledButton(
              onPressed: () => service.sendCommand(TurnCommand.next),
              child: const Icon(Icons.chevron_right, size: 48),
            ),
          ),
        ),
      ],
    );
  }
}

/// 전체 화면 리모컨. 설정에서 들어온다.
class RemotePage extends ConsumerWidget {
  const RemotePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(syncServiceProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('리모컨')),
      body: service == null
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: service,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (service.role != SyncRole.remote)
                      FilledButton.icon(
                        onPressed: () => service.setRole(SyncRole.remote),
                        icon: const Icon(Icons.settings_remote),
                        label: const Text('리모컨 모드 켜기'),
                      ),
                    Text(service.status ?? '', style: Theme.of(context).textTheme.bodySmall),
                    const Spacer(),
                    const RemoteControls(),
                    const Spacer(),
                    TextButton(onPressed: () => showSyncSheet(context), child: const Text('연결 설정')),
                  ],
                ),
              ),
            ),
    );
  }
}
