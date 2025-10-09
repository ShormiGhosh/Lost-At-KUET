import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../models/chat.dart';
import '../models/message.dart';

class ChatService {
  final SupabaseClient supabase;
  ChatService(this.supabase);

  /// Create or return an existing 1:1 chat between two users.
  Future<Chat> createOrGetDirectChat(String userA, String userB) async {
    // Try to find existing chat where the two users match (either ordering)
    final resp = await supabase
        .from('chats')
        .select('*, user1:profiles!chats_user1_id_fkey(*), user2:profiles!chats_user2_id_fkey(*)')
        .or('and(user1_id.eq.$userA,user2_id.eq.$userB),and(user1_id.eq.$userB,user2_id.eq.$userA)')
        .limit(1);

    final respList = resp as List;
    if (respList.isNotEmpty) return Chat.fromJson(respList.first as Map<String, dynamic>, userA);

    // Create a new chat row
    final insert = await supabase.from('chats').insert({
      'user1_id': userA,
      'user2_id': userB,
    }).select('*, user1:profiles!chats_user1_id_fkey(*), user2:profiles!chats_user2_id_fkey(*)').limit(1);

    final insertList = insert as List;
    if (insertList.isNotEmpty) return Chat.fromJson(insertList.first as Map<String, dynamic>, userA);
    throw Exception('Failed to create or fetch chat');
  }

  /// List chats for a user
  Future<List<Chat>> listChatsForUser(String userId) async {
    // Fetch chats for user first
    final resp = await supabase
        .from('chats')
        .select('*, user1:profiles!chats_user1_id_fkey(*), user2:profiles!chats_user2_id_fkey(*)')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('last_message_at', ascending: false);

    final list = (resp as List).map((e) => Chat.fromJson(e as Map<String, dynamic>, userId)).toList();

    if (list.isEmpty) return list;

    // Batch fetch unread counts for all chat ids in a single query.
    // We select chat_id and count(*) grouped by chat_id where sender != userId and read = false.
    final chatIds = list.map((c) => c.id).toList();
    final chatIdsCsv = chatIds.map((s) => '"$s"').join(',');
    // Fetch all unread message rows for these chats in one request and group locally
    final unreadResp = await supabase
        .from('messages')
        .select('chat_id')
        .filter('chat_id', 'in', '($chatIdsCsv)')
        .neq('sender_id', userId)
        .eq('read', false);

    final Map<String, int> counts = {};
    final unreadList = List<Map<String, dynamic>>.from(unreadResp as List);
    for (final m in unreadList) {
      final cid = m['chat_id'] as String?;
      if (cid == null) continue;
      counts[cid] = (counts[cid] ?? 0) + 1;
    }

    for (var i = 0; i < list.length; i++) {
      final chat = list[i];
      final unreadCount = counts[chat.id] ?? 0;
      list[i] = chat.copyWith(unreadCount: unreadCount);
    }

    return list;
  }

  /// Placeholder: fetch messages for a chat (used in subtask 2)
  Future<List<Message>> fetchMessages(String chatId, {int limit = 50}) async {
  final resp = await supabase
    .from('messages')
    .select('*, profiles:profiles!messages_sender_id_fkey(id, username, avatar_url)')
    .eq('chat_id', chatId)
    .order('created_at', ascending: true)
    .limit(limit);

  final list = (resp as List).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    return list;
  }

  /// Send a message in a chat and update chat's last_message fields
  Future<Message> sendMessage(String chatId, String senderId, String content) async {
    final insert = await supabase
        .from('messages')
        .insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
    })
        .select('*, profiles:profiles!messages_sender_id_fkey(id, username, avatar_url)')
        .limit(1);

    final insertList = insert as List;
    if (insertList.isEmpty) throw Exception('Failed to insert message');

    // update last message on chat
    await supabase.from('chats').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);

    return Message.fromJson(insertList.first as Map<String, dynamic>);
  }

  /// Mark all messages in chat as read by the current user (set read_at)
  Future<void> markMessagesRead(String chatId, String readerId) async {
    await supabase
        .from('messages')
        .update({'read': true, 'read_at': DateTime.now().toIso8601String()})
        .eq('chat_id', chatId)
        .neq('sender_id', readerId);
  }

  /// Upload a chat image to Supabase Storage and return a public URL, or null on failure.
  Future<String?> uploadChatImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final ext = path.extension(file.path);
    final fileName = 'chats/${DateTime.now().millisecondsSinceEpoch}$ext';

    // Upload into the existing 'posts' bucket (reusing the app's image bucket)
    // This avoids permission/RLS issues for a newly-created 'chats' bucket.
    await supabase.storage.from('posts').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = supabase.storage.from('posts').getPublicUrl(fileName);
    return publicUrl;
  }

  /// Send an image message - stores the image public URL in the content column
  Future<Message> sendImageMessage(String chatId, String senderId, String imageUrl) async {
    final insert = await supabase
        .from('messages')
        .insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'content': imageUrl,
    })
        .select('*, profiles:profiles!messages_sender_id_fkey(id, username, avatar_url)')
        .limit(1);

    final insertList = insert as List;
    if (insertList.isEmpty) throw Exception('Failed to insert image message');

    // update last message on chat with a placeholder indicating an image
    await supabase.from('chats').update({
      'last_message': '[Image]',
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);

    return Message.fromJson(insertList.first as Map<String, dynamic>);
  }
}
