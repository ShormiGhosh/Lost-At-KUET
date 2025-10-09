import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:LostAtKuet/models/chat.dart';
import 'chat_detail_screen.dart';
import 'services/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _chats = <Chat>[];
  bool _loading = false;
  final _supabase = Supabase.instance.client;
  late final String _currentUserId;
  late final ChatService _chatService;
  late final RealtimeChannel _messagesSubscription;

  @override
  void initState() {
    super.initState();
  _currentUserId = _supabase.auth.currentUser!.id;
  _chatService = ChatService(_supabase);
  _loadChats();
  _setupMessagesSubscription();
  }

  @override
  void dispose() {
    try {
      _messagesSubscription.unsubscribe();
    } catch (_) {}
    super.dispose();
  }

  void _setupMessagesSubscription() {
    _messagesSubscription = _supabase
        .channel('messages_inbox')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        // Refresh inbox when a new message arrives
        _loadChats();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        // Refresh inbox when message updates (like read/read_at changes)
        _loadChats();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        _loadChats();
      },
    )
        .subscribe();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      final chats = await _chatService.listChatsForUser(_currentUserId);
      setState(() {
        _chats.clear();
        _chats.addAll(chats);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF292929),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
          ? const Center(child: Text('No messages yet'))
          : ListView.separated(
        itemCount: _chats.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return InkWell(
            onTap: () async {
              // Mark messages as read for this chat (messages where sender != current user)
              try {
                await _chatService.markMessagesRead(chat.id, _currentUserId);
              } catch (_) {
                // ignore errors here; navigation should still proceed
              }
              // Refresh chats list so the dot disappears (optional)
              _loadChats();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatDetailPage(chat: chat),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFFFFD77A), Color(0xFFFFC815)]),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: Offset(0,2))],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: chat.otherUserAvatar != null ? NetworkImage(chat.otherUserAvatar!) : null,
                      backgroundColor: Colors.grey.shade100,
                      child: chat.otherUserAvatar == null ? Text(chat.otherUser.username[0], style: const TextStyle(color: Color(0xFF292929), fontWeight: FontWeight.bold)) : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chat.otherUser.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          chat.lastMessage ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (chat.lastMessageAt != null) Text(_formatDate(chat.lastMessageAt!), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 6),
                      if (chat.unreadCount > 0) Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC815),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: Offset(0,1))],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
    return '${date.day}/${date.month}/${date.year}';
  }
}