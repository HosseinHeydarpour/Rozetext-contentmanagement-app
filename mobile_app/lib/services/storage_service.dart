import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';

class StorageService {
  static const String _keyServerUrl = 'key_server_url';
  static const String _keyCachedPosts = 'key_cached_posts';

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerUrl);
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    // Normalize url
    String normalized = url.trim();
    if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
      normalized = 'http://$normalized';
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    await prefs.setString(_keyServerUrl, normalized);
  }

  static Future<void> clearServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyServerUrl);
  }

  static Future<List<Post>> getCachedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyCachedPosts);
    if (jsonString == null || jsonString.isEmpty) return [];

    try {
      final List decoded = jsonDecode(jsonString) as List;
      return decoded.map((e) => Post.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveCachedPosts(List<Post> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(posts.map((e) => e.toJson()).toList());
    await prefs.setString(_keyCachedPosts, jsonString);
  }
}
