import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Offline Community Service — stores posts locally using SharedPreferences.
/// Will be upgraded to Firebase Firestore + Auth post-proposal/demo.
class CommunityService {
  static const String _postsKey = 'community_posts_v2';
  static const String _likesKey = 'liked_community_posts';

  /// Get all posts from local storage (newest first)
  Future<List<Map<String, dynamic>>> getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_postsKey) ?? [];
    final posts = raw.map((s) {
      try {
        return jsonDecode(s) as Map<String, dynamic>;
      } catch (e) { debugPrint("Silent error caught: $e");
        return <String, dynamic>{};
      }
    }).where((m) => m.isNotEmpty).toList();
    // Sort newest first
    posts.sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    return posts;
  }

  /// Add a new post (locally)
  Future<void> addPost({
    required String author,
    required String role,
    required String content,
    required String avatar,
    required int color,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_postsKey) ?? [];
      
      final post = {
        'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'author': author,
        'role': role,
        'content': content,
        'avatar': avatar,
        'color': color,
        'likes': 0,
        'likedBy': <String>[],
        'comments': 0,
        'isVerified': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      existing.add(jsonEncode(post));
      await prefs.setStringList(_postsKey, existing);
    } catch (e) {
      debugPrint("Error adding post: $e");
      rethrow;
    }
  }

  /// Get the set of liked post IDs from local storage
  Future<Set<String>> getLikedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final likedList = prefs.getStringList(_likesKey) ?? [];
    return likedList.toSet();
  }

  /// Toggle like status locally
  Future<void> toggleLike(String postId, bool currentLikeStatus) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update like count in post data
    final existing = prefs.getStringList(_postsKey) ?? [];
    final updated = existing.map((s) {
      try {
        final post = jsonDecode(s) as Map<String, dynamic>;
        if (post['id'] == postId) {
          final likes = (post['likes'] ?? 0) as int;
          post['likes'] = currentLikeStatus ? (likes - 1).clamp(0, 99999) : likes + 1;
        }
        return jsonEncode(post);
      } catch (e) { debugPrint("Silent error caught: $e");
        return s;
      }
    }).toList();
    await prefs.setStringList(_postsKey, updated);
    
    // Update local likes set
    final likedPosts = await getLikedPosts();
    if (currentLikeStatus) {
       likedPosts.remove(postId);
    } else {
       likedPosts.add(postId);
    }
    await prefs.setStringList(_likesKey, likedPosts.toList());
  }

  /// [ADMIN] Delete a post locally
  Future<void> deletePost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_postsKey) ?? [];
      final filtered = existing.where((s) {
        try {
          final post = jsonDecode(s) as Map<String, dynamic>;
          return post['id'] != postId;
        } catch (e) { debugPrint("Silent error caught: $e");
          return true;
        }
      }).toList();
      await prefs.setStringList(_postsKey, filtered);
    } catch (e) {
      debugPrint("Error deleting post: $e");
      rethrow;
    }
  }

  /// [ADMIN] Verify a post (Gold Badge) — locally
  Future<void> toggleVerification(String postId, bool currentStatus) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_postsKey) ?? [];
      final updated = existing.map((s) {
        try {
          final post = jsonDecode(s) as Map<String, dynamic>;
          if (post['id'] == postId) {
            post['isVerified'] = !currentStatus;
          }
          return jsonEncode(post);
        } catch (e) { debugPrint("Silent error caught: $e");
          return s;
        }
      }).toList();
      await prefs.setStringList(_postsKey, updated);
    } catch (e) {
      debugPrint("Error verifying post: $e");
      rethrow;
    }
  }
}
