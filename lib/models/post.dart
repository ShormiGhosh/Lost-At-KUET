class Post {
  final String title;
  final String description;
  final String location;
  final String status;
  final String category;
  final String? imageUrl;
  final String userId;
  final DateTime createdAt;

  Post({
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.category,
    this.imageUrl,
    required this.createdAt,
    required this.userId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      status: json['status'] as String,
      category: json['category'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String? ?? (json['user'] != null ? json['user']['id'] as String : ''),
    );
  }
}