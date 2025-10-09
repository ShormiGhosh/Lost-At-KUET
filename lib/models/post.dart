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
    // Parse id robustly (some responses may return string or int)
    final dynamic rawId = json['id'];
    final int id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final createdRaw = json['created_at'] ?? json['createdAt'] ?? '';
    final DateTime createdAt = createdRaw is String && createdRaw.isNotEmpty
        ? DateTime.parse(createdRaw)
        : DateTime.now();

    final userId = (json['user_id'] as String?) ??
        ((json['user'] is Map && json['user']['id'] != null) ? json['user']['id'].toString() : '');

    return Post(
      id: id,
      userId: userId,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      location: (json['location'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      createdAt: createdAt,
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