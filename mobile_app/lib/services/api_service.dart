import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/post.dart';
import 'storage_service.dart';

class ApiService {
  /// Test server connectivity
  static Future<bool> testConnection(String baseUrl) async {
    try {
      String url = baseUrl.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }
      final uri = Uri.parse('$url/api/status');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetch all posts from server and update local cache
  static Future<List<Post>> fetchPosts() async {
    final baseUrl = await StorageService.getServerUrl();
    if (baseUrl == null) {
      return await StorageService.getCachedPosts();
    }

    try {
      final uri = Uri.parse('$baseUrl/api/posts');
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List decoded = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        final posts = decoded
            .map((item) => Post.fromJson(item as Map<String, dynamic>))
            .toList();

        // Update local cache
        await StorageService.saveCachedPosts(posts);
        return posts;
      }
    } catch (e) {
      // Return cached posts on failure
    }

    return await StorageService.getCachedPosts();
  }

  /// Toggle "isPosted" status
  static Future<Post?> togglePostedStatus(String postId) async {
    final baseUrl = await StorageService.getServerUrl();
    if (baseUrl == null) return null;

    try {
      final uri = Uri.parse('$baseUrl/api/posts/$postId/toggle');
      final res = await http.patch(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return Post.fromJson(data);
      }
    } catch (e) {
      // Error toggling status
    }
    return null;
  }

  /// Delete a post
  static Future<bool> deletePost(String postId) async {
    final baseUrl = await StorageService.getServerUrl();
    if (baseUrl == null) return false;

    try {
      final uri = Uri.parse('$baseUrl/api/posts/$postId');
      final res = await http.delete(uri).timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
