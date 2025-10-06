import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // Mock notifications for UI-only page
  List<Map<String, Object>> _mockItems() => List.generate(
        8,
        (i) => {
          'id': 'local-$i',
          'title': i.isEven ? 'Nearby match found' : 'Claim status update',
          'body': 'This is a mock notification item #$i for UI preview.',
          'read': i % 3 == 0,
          'time': DateTime.now().subtract(Duration(minutes: i * 7)),
        },
      );

  @override
  Widget build(BuildContext context) {
    final items = _mockItems();
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final it = items[i];
          final read = it['read'] as bool;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: read ? Colors.grey.shade300 : Theme.of(context).colorScheme.primary,
              child: Icon(read ? Icons.drafts : Icons.notifications, color: read ? Colors.black54 : Colors.white),
            ),
            title: Text(it['title'] as String),
            subtitle: Text(it['body'] as String),
            trailing: read ? null : TextButton(onPressed: () {}, child: const Text('Mark read')),
            onTap: () {
              // UI-only: show a simple details dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(it['title'] as String),
                  content: Text(it['body'] as String),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
