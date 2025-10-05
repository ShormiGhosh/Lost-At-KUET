class Post {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String location;
  final bool isLost;
  final String? imageUrl;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    required this.isLost,
    this.imageUrl,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      isLost: json['is_lost'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}