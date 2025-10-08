import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:LostAtKuet/models/chat.dart';
import 'package:LostAtKuet/models/message.dart';


class ChatDetailPage extends StatefulWidget {
  final Chat chat;

  const ChatDetailPage({super.key, required this.chat});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messages = <Message>[];
  final _messageController = TextEditingController();
  final _supabase = Supabase.instance.client;
  late final String currentUserId;
  late final RealtimeChannel _subscription;

  @override
  void initState() {
    super.initState();
    currentUserId = _supabase.auth.currentUser!.id;
    _loadMessages();
    _setupMessageSubscription();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select('''
            *,
            profiles!messages_sender_id_fkey (id, username)
          ''')
          .eq('chat_id', widget.chat.id)
          .order('created_at');

      final messages = response.map<Message>((msg) => Message.fromJson(msg)).toList();

      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }
  void _setupMessageSubscription() {
    _subscription = _supabase
        .channel('messages')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        if (payload.newRecord['chat_id'] == widget.chat.id) {
          await _loadMessages();
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        if (payload.oldRecord['chat_id'] == widget.chat.id) {
          await _loadMessages();
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        if (payload.newRecord['chat_id'] == widget.chat.id) {
          await _loadMessages();
        }
      },
    )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await _supabase.from('messages').insert({
        'chat_id': widget.chat.id,
        'sender_id': currentUserId,
        'content': content,
      });

      await _supabase
          .from('chats')
          .update({
        'last_message': content,
        'last_message_at': DateTime.now().toIso8601String(),
      })
          .eq('id', widget.chat.id);

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.chat.otherUserAvatar != null
                  ? NetworkImage(widget.chat.otherUserAvatar!)
                  : null,
              child: widget.chat.otherUserAvatar == null
                  ? Text(widget.chat.otherUser.username[0])
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.chat.otherUser.username,
              style: const TextStyle(
                color: Color(0xFFFFFFFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF292929),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == currentUserId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF585858) : const Color(0xFFFFC815),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      message.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _subscription.unsubscribe();
    super.dispose();
  }
}