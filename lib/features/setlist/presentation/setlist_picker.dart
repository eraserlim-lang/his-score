import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/setlist_dao.dart';
import 'setlist_page.dart';

/// 기존 세트리스트를 고르거나 새로 만든다. 고른 id 를 돌려준다.
Future<String?> pickSetlist(BuildContext context, WidgetRef ref) async {
  final lists = await ref.read(setlistDaoProvider).watchAll().first;
  if (!context.mounted) return null;

  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('새 세트리스트'),
            onTap: () async {
              final id = await createSetlist(context, ref);
              if (context.mounted) Navigator.pop(context, id);
            },
          ),
          const Divider(height: 1),
          for (final entry in lists)
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(entry.setlist.name),
              subtitle: Text('${entry.itemCount}곡'),
              onTap: () => Navigator.pop(context, entry.setlist.id),
            ),
        ],
      ),
    ),
  );
}
