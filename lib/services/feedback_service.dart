import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitFeedback({
    required double rating,
    required String category,
    required String feedbackText,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'rating': rating,
        'category': category,
        'feedbackText': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      });
    } catch (e) {
      debugPrint("Error submitting feedback: $e");
      // Fail silently or rethrow depending on needs. 
      // For now, we assume standard network issues might occur.
      throw Exception("Failed to submit feedback");
    }
  }
}
