import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/chat.dart';
import 'models/message.dart';
import 'models/profile.dart';
import 'services/chat_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatDetailPage extends StatefulWidget {
  final Chat chat;

  const ChatDetailPage({super.key, required this.chat});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messages = <Message>[];
  final _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final _supabase = Supabase.instance.client;
  late final String currentUserId;
  late final RealtimeChannel _subscription;
  late final ChatService _chatService;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inputKey = GlobalKey();
  double _inputAreaHeight = 80.0;
  Timer? _readPollingTimer;

  @override
  void initState() {
    super.initState();
    currentUserId = _supabase.auth.currentUser!.id;
    _chatService = ChatService(_supabase);
    _loadMessages();
    _setupMessageSubscription();
  }

  Future<void> _loadMessages() async {
    try {
  final messages = await _chatService.fetchMessages(widget.chat.id);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      // scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
      // After loading, mark messages read and update local state immediately
      try {
        await _chatService.markMessagesRead(widget.chat.id, currentUserId);
        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            final m = _messages[i];
            if (m.senderId != currentUserId && !m.read) {
              _messages[i] = m.copyWith(read: true, readAt: DateTime.now());
            }
          }
        });
        _startReadPolling();
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _startReadPolling() {
    _readPollingTimer?.cancel();
    int elapsed = 0;
    _readPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      elapsed += 2;
      if (elapsed > 30) {
        timer.cancel();
        return;
      }
      // Find sent messages that aren't read
      final sentIds = _messages.where((m) => m.senderId == currentUserId && !m.read).map((m) => m.id).toList();
      if (sentIds.isEmpty) {
        timer.cancel();
        return;
      }
      // Fetch those messages from server
    final idsCsv = sentIds.map((s) => '"$s"').join(',');
    final resp = await _supabase
      .from('messages')
      .select('id, read, read_at')
      .filter('id', 'in', '($idsCsv)')
      .eq('chat_id', widget.chat.id);
      setState(() {
        for (final item in resp) {
          final id = item['id'];
          final idx = _messages.indexWhere((m) => m.id == id);
          if (idx >= 0 && item['read'] == true && item['read_at'] != null) {
            _messages[idx] = _messages[idx].copyWith(read: true, readAt: DateTime.parse(item['read_at']));
          }
        }
      });
      // If all sent messages are read, stop polling
      final stillUnread = _messages.where((m) => m.senderId == currentUserId && !m.read).isNotEmpty;
      if (!stillUnread) timer.cancel();
    });
  }

  Message _messageFromRecord(Map<String, dynamic> record) {
    try {
      return Message.fromJson(record);
    } catch (_) {
      // Fallback mapping when record shape is different
      return Message(
        id: record['id'],
        chatId: record['chat_id'],
        senderId: record['sender_id'],
        content: record['content'] ?? '',
        createdAt: record['created_at'] != null ? DateTime.parse(record['created_at']) : DateTime.now(),
        read: record['read'] ?? false,
        readAt: record['read_at'] != null ? DateTime.parse(record['read_at']) : null,
        sender: Profile(
          id: record['sender_id'],
          username: record['sender_name'] ?? 'User',
          isVerified: record['is_verified'] ?? false, // Add this line
        ),
      );
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
        final record = payload.newRecord;
        if (record['chat_id'] != widget.chat.id) return;
        final msg = _messageFromRecord(record);
        setState(() => _messages.add(msg));
        // auto-scroll
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 120,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        final record = payload.newRecord;
        if (record['chat_id'] != widget.chat.id) return;
        // If server provided read_at, refresh authoritative message list so
        // sender's UI shows the exact read_at timestamp (ensures blue ticks).
        if (record['read_at'] != null) {
          _loadMessages();
          return;
        }
        final id = record['id'];
        final idx = _messages.indexWhere((m) => m.id == id);
        if (idx >= 0) {
          final old = _messages[idx];
          final updated = old.copyWith(
            read: record['read'] ?? old.read,
            readAt: record['read_at'] != null ? DateTime.parse(record['read_at']) : old.readAt,
            content: record['content'] ?? old.content,
          );
          setState(() {
            _messages[idx] = updated;
          });
        } else {
          // fallback: try to parse full message
          final msg = _messageFromRecord(record);
          setState(() {
            _messages.add(msg);
          });
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'messages',
      callback: (payload) async {
        final record = payload.oldRecord;
        if (record['chat_id'] != widget.chat.id) return;
        setState(() => _messages.removeWhere((m) => m.id == record['id']));
      },
    )
        .subscribe();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
  final sent = await _chatService.sendMessage(widget.chat.id, currentUserId, content);
      setState(() => _messages.add(sent));
      // Mark messages as read for this chat (messages where sender != current user)
      try {
        await _chatService.markMessagesRead(widget.chat.id, currentUserId);
      } catch (_) {
        // ignore errors
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
      if (file == null) return;

      // show a brief loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading image...')));

      String? url;
      try {
        url = await _chatService.uploadChatImage(file);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
        return;
      }

      if (url == null || url.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload returned no URL')));
        return;
      }

      final sent = await _chatService.sendImageMessage(widget.chat.id, currentUserId, url);
      setState(() => _messages.add(sent));

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // We'll manage keyboard inset using AnimatedPadding so avoid Scaffold auto-resize
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
            Row(
              children: [
                Text(
                  widget.chat.otherUser.username,
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.chat.otherUser.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 16,
                  ),
                ],
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF292929),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(builder: (context) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              final systemBottom = MediaQuery.of(context).padding.bottom;
              // Use the measured input area height (falls back to _inputAreaHeight)
              final inputAreaHeight = _inputAreaHeight;
              // Measure input area after frame and update if height changed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final ctx = _inputKey.currentContext;
                  if (ctx != null) {
                    final renderBox = ctx.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        final newH = renderBox.size.height;
                        if ((newH - _inputAreaHeight).abs() > 0.5) {
                          setState(() {
                            _inputAreaHeight = newH;
                          });
                        }
                      }
                  }
                } catch (_) {}
              });
              return ListView.builder(
                controller: _scrollController,
                // bottom padding = keyboard inset (so content can scroll under the input
                // when keyboard appears) + input area height + system bottom (nav bar) + small gap
                padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset + inputAreaHeight + systemBottom + 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMe = message.senderId == currentUserId;
                  final timeString = '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';
                  // Determine whether this is the last message sent by current user
                  final lastSentIndex = _messages.lastIndexWhere((m) => m.senderId == currentUserId);
                  final isLastSent = index == lastSentIndex && isMe;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: isMe ? null : Colors.grey.shade100,
                          gradient: isMe ? const LinearGradient(colors: [Color(0xFFFFD77A), Color(0xFFFFC815)]) : null,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(isMe ? 12 : 0),
                            topRight: Radius.circular(isMe ? 0 : 12),
                            bottomLeft: const Radius.circular(12),
                            bottomRight: const Radius.circular(12),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // If content looks like an image URL, display image
                            if (message.content.startsWith('http'))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    message.content,
                                    width: MediaQuery.of(context).size.width * 0.6,
                                    height: MediaQuery.of(context).size.width * 0.6,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: Colors.grey.shade200,
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      height: MediaQuery.of(context).size.width * 0.6,
                                      child: const Center(child: Icon(Icons.broken_image)),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Text(
                                message.content,
                                style: TextStyle(color: isMe ? const Color(0xFF292929) : Colors.black87, fontSize: 15),
                              ),
                            const SizedBox(height: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      timeString,
                                      style: TextStyle(color: isMe ? Colors.black54 : Colors.black45, fontSize: 11),
                                    ),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 250),
                                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                                        child: message.readAt != null
                                            ? const Icon(Icons.done_all, key: ValueKey('readAt'), size: 16, color: Colors.blue)
                                            : message.read
                                                ? const Icon(Icons.done_all, key: ValueKey('read'), size: 16, color: Colors.black54)
                                                : const Icon(Icons.done, key: ValueKey('sent'), size: 16, color: Colors.black54),
                                      ),
                                    ],
                                  ],
                                ),
                                // Show 'Seen' label for the last message the current user sent when it's read
                                if (isLastSent && message.read) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Seen',
                                    style: TextStyle(color: Colors.blue.shade400, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          // Input area: lift above keyboard and system bottom nav
          AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SafeArea(
              top: false,
              child: Padding(
                key: _inputKey,
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: Offset(0,2))],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                focusNode: _messageFocusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFFFFC815)),
                              onPressed: () async {
                                // show a simple modal bottom sheet emoji picker
                                final emoji = await showModalBottomSheet<String>(
                                  context: context,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                  ),
                                  builder: (ctx) {
                                    // small curated emoji list
                                    const emojis = [
                                      '😀','😁','😂','🤣','😊','😍','🤩','😘','😅','🙂',
                                      '🤔','😴','😎','😭','😡','👍','🙏','👏','🎉','🔥',
                                    ];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 4,
                                            width: 44,
                                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                                          ),
                                          const SizedBox(height: 12),
                                          GridView.builder(
                                            shrinkWrap: true,
                                            itemCount: emojis.length,
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 8,
                                              mainAxisSpacing: 8,
                                              crossAxisSpacing: 8,
                                            ),
                                            itemBuilder: (c, i) => GestureDetector(
                                              onTap: () => Navigator.of(ctx).pop(emojis[i]),
                                              child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 22))),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                if (emoji != null) {
                                  final controller = _messageController;
                                  final text = controller.text;
                                  final selection = controller.selection;
                                  final newText = selection.isValid
                                      ? text.replaceRange(selection.start, selection.end, emoji)
                                      : text + emoji;
                                  controller.text = newText;
                                  final newPos = (selection.isValid ? selection.start : text.length) + emoji.length;
                                  controller.selection = TextSelection.collapsed(offset: newPos);
                                  // return focus to the message field so user can continue typing
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) FocusScope.of(context).requestFocus(_messageFocusNode);
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.photo_camera_outlined, color: Color(0xFFFFC815)),
                              onPressed: _pickAndSendImage,
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC815),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: Offset(0,2))],
                        ),
                        child: const Icon(Icons.send, color: Color(0xFF292929)),
                      ),
                    ),
                  ],
                ),
              ),
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
    _readPollingTimer?.cancel();
    super.dispose();
  }
}