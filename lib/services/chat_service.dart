import 'package:supabase_flutter/supabase_flutter.dart';
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
    final resp = await supabase
        .from('chats')
        .select('*, user1:profiles!chats_user1_id_fkey(*), user2:profiles!chats_user2_id_fkey(*)')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('last_message_at', ascending: false);

  final list = (resp as List).map((e) => Chat.fromJson(e as Map<String, dynamic>, userId)).toList();
    return list;
  }

  /// Placeholder: fetch messages for a chat (used in subtask 2)
  Future<List<Message>> fetchMessages(String chatId, {int limit = 50}) async {
    final resp = await supabase
        .from('messages')
        .select('*, profiles(*)')
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .limit(limit);

  final list = (resp as List).map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
    return list;
  }
}
