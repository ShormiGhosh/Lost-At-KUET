import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class PostService {
  final SupabaseClient _supabase;

  PostService(this._supabase);

  Future<List<Post>> getPosts() async {
    try {
      final response = await _supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('Error getting posts: $e');
      rethrow;
    }
  }

  Future<String?> _uploadImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileExt = path.extension(imagePath); // Get file extension
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';

      // Upload file
      await _supabase.storage
          .from('posts')
          .upload(fileName, file);

      // Get public URL
      final imageUrl = _supabase.storage
          .from('posts')
          .getPublicUrl(fileName);

      print('Image uploaded successfully: $imageUrl');
      return imageUrl;

    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> createPost({
    required String title,
    required String description,
    required String location,
    required String status,
    required String category,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) async {
    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _uploadImage(imagePath);
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final Map<String, dynamic> payload = {
        'user_id': userId,
        'title': title,
        'description': description,
        'location': location,
        'status': status,
        'category': category,
        'image_url': imageUrl,
      };

      if (latitude != null) payload['latitude'] = latitude;
      if (longitude != null) payload['longitude'] = longitude;

      await _supabase.from('posts').insert(payload);
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }
}