import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
        'comments': 0,
        'isVerified': false, // New users are not verified by default
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error adding post: $e");
      rethrow;
    }
  }

  /// Toggle like status (Simplistic implementation: increments/decrements count on server)
  /// Note: A real production app would track "who" liked it in a subcollection to prevent double voting.
  /// For this hackathon/MVP, we just increment/decrement.
  Future<void> toggleLike(String postId, bool currentLikeStatus) async {
    final docRef = _firestore.collection(_collection).doc(postId);
    
    // In a real app we'd also store the user ID in a 'likedBy' array
    if (currentLikeStatus) {
       // Unlike
       await docRef.update({'likes': FieldValue.increment(-1)});
    } else {
       // Like
       await docRef.update({'likes': FieldValue.increment(1)});
    }
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
