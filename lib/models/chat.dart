import 'package:LostAtKuet/models/profile.dart';

class Chat {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Profile otherUser;
  final String? otherUserAvatar; // Add this field
  final int unreadCount;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageAt,
    required this.otherUser,
    this.otherUserAvatar, // Add this parameter
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json, String currentUserId) {
    final isUser1 = json['user1_id'] == currentUserId;
    final otherUserData = isUser1
        ? json['user2']
        : json['user1'];

    return Chat(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      otherUser: Profile.fromJson(otherUserData),
      otherUserAvatar: otherUserData['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      unreadCount: json['unread_count'] ?? 0,
    );
  }

  Chat copyWith({int? unreadCount}) {
    return Chat(
      id: id,
      user1Id: user1Id,
      user2Id: user2Id,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      otherUser: otherUser,
      otherUserAvatar: otherUserAvatar,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
    );
  }
}