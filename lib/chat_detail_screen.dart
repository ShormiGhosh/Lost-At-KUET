import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/chat.dart';
import 'models/message.dart';

class ChatDetailPage extends StatefulWidget {
  final Chat chat;

  const ChatDetailPage({super.key, required this.chat});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messages = <Message>[];
  final _messageController = TextEditingController();
  // final _supabase = Supabase.instance.client;
  // late final Stream<List<Message>> _messageStream;

  @override
  void initState() {
    super.initState();
    // _loadMessages();
    // _setupMessageStream();
  }

  // Commented out Supabase functionality
  /*
  Future<void> _loadMessages() async {
    // Supabase message loading logic
  }

  void _setupMessageStream() {
    // Supabase stream setup logic
  }

  Future<void> _sendMessage() async {
    // Supabase message sending logic
  }
  */

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Mock message sending
    setState(() {
      _messages.add(
        Message(
          id: DateTime.now().toString(),
          chatId: widget.chat.id,
          senderId: 'currentUser', // Mock user ID
          content: content,
          createdAt: DateTime.now(),
          read: false,
        ),
      );
    });

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const currentUserId = 'currentUser'; // Mock user ID

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
                  ? Text(widget.chat.otherUserName?[0] ?? '?')
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.chat.otherUserName ?? 'Chat', style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold)),
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
                  alignment:
                  isMe ? Alignment.centerRight : Alignment.centerLeft,
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
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.white,
                      ),
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
}