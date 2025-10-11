class Profile {
  final String id;
  final String username;
  final bool isVerified;

  Profile({
    required this.id,
    required this.username,
    required this.isVerified,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      isVerified: json['is_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'is_verified': isVerified,
    };
  }
}