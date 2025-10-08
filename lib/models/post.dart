class Post {
  final int id;
  final String userId;
  final String title;
  final String description;
  final String status;
  final String category;
  final String location;
  final String? imageUrl;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.location,
    this.imageUrl,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      category: json['category'],
      location: json['location'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status,
      'category': category,
      'location': location,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}