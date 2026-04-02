import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'community_posts';

  /// Stream of posts ordered by time (newest first)
  Stream<QuerySnapshot> getPostsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Add a new post
  Future<void> addPost({
    required String author,
    required String role,
    required String content,
    required String avatar,
    required int color,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'author': author,
        'role': role,
        'content': content,
        'avatar': avatar,
        'color': color,
        'likes': 0,
        'likedBy': [],
        'comments': 0,
        'isVerified': false, // New users are not verified by default
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error adding post: $e");
      rethrow;
    }
  }


  /// Get the set of liked post IDs from local storage
  Future<Set<String>> getLikedPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final likedList = prefs.getStringList('liked_community_posts') ?? [];
    return likedList.toSet();
  }

  /// Toggle like status and persist securely
  Future<void> toggleLike(String postId, bool currentLikeStatus) async {
    final docRef = _firestore.collection(_collection).doc(postId);
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_device';

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        List<dynamic> likedBy = [];
        if (snapshot.data()!.containsKey('likedBy')) {
            likedBy = snapshot.get('likedBy');
        }

        if (likedBy.contains(uid)) {
          // Already liked, so unlike
          transaction.update(docRef, {
            'likedBy': FieldValue.arrayRemove([uid]),
            'likes': FieldValue.increment(-1),
          });
        } else {
          // Not liked, so like
          transaction.update(docRef, {
            'likedBy': FieldValue.arrayUnion([uid]),
            'likes': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
    
    // Update local prefs for backward compatibility with UI assuming quick updates
    final prefs = await SharedPreferences.getInstance();
    final likedPosts = await getLikedPosts();
    if (currentLikeStatus) {
       likedPosts.remove(postId);
    } else {
       likedPosts.add(postId);
    }
    await prefs.setStringList('liked_community_posts', likedPosts.toList());
  }

  /// [ADMIN] Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection(_collection).doc(postId).delete();
    } catch (e) {
      debugPrint("Error deleting post: $e");
      rethrow;
    }
  }

  /// [ADMIN] Verify a post (Gold Badge)
  Future<void> toggleVerification(String postId, bool currentStatus) async {
    try {
      await _firestore.collection(_collection).doc(postId).update({
        'isVerified': !currentStatus
      });
    } catch (e) {
      debugPrint("Error verifying post: $e");
      rethrow;
    }
  }
}
