import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/chat.dart';
import 'chat_detail_screen.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chats = <Chat>[];
  bool _loading = false;
  // final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadMockChats();
  }

  void _loadMockChats() {
    // Mock chat data
    final mockChats = [
      Chat(
        id: '1',
        user1Id: 'currentUser',
        user2Id: 'user2',
        lastMessage: 'Hello , I love you!',
        lastMessageAt: DateTime.now(),
        otherUserName: 'Shormi Ghosh',
        otherUserAvatar: null,
      ),
      Chat(
        id: '2',
        user1Id: 'currentUser',
        user2Id: 'user3',
        lastMessage: 'Valo acho?',
        lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
        otherUserName: 'ke be?',
        otherUserAvatar: null,
      ),
    ];

    setState(() {
      _chats.clear();
      _chats.addAll(mockChats);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF292929),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
          ? const Center(child: Text('No messages yet'))
          : ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: chat.otherUserAvatar != null
                  ? NetworkImage(chat.otherUserAvatar!)
                  : null,
              child: chat.otherUserAvatar == null
                  ? Text(chat.otherUserName?[0] ?? '?')
                  : null,
            ),
            title: Text(chat.otherUserName ?? 'Unknown'),
            subtitle: chat.lastMessage != null
                ? Text(
              chat.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
                : null,
            trailing: chat.lastMessageAt != null
                ? Text(
              _formatDate(chat.lastMessageAt!),
              style: Theme.of(context).textTheme.bodySmall,
            )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(chat: chat),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}';
  }
}