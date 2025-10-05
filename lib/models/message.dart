import 'profile.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool read;
  final Profile sender;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.read,
    required this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      read: json['read'] ?? false,
      sender: Profile.fromJson(json['profiles']),
    );
  }
}