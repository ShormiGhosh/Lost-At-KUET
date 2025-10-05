class Profile {
  final String id;
  final String username;

  Profile({
    required this.id,
    required this.username,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
    );
  }
}