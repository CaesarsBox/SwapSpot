import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's average rating
  Future<double> getUserAverageRating(String userId) async {
    try {
      final query = await _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .get();

      if (query.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var doc in query.docs) {
        final rating = doc.data()['rating'] as double;
        totalRating += rating;
      }

      return totalRating / query.docs.length;
    } catch (e) {
      throw Exception('Failed to get user average rating: $e');
    }
  }

  // Get user's total ratings count
  Future<int> getUserRatingsCount(String userId) async {
    try {
      final query = await _firestore
          .collection('ratings')
          .where('toUserId', isEqualTo: userId)
          .get();

      return query.docs.length;
    } catch (e) {
      throw Exception('Failed to get user ratings count: $e');
    }
  }

  // Get all ratings for a user
  Stream<List<RatingModel>> getUserRatings(String userId) {
    return _firestore
        .collection('ratings')
        .where('toUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RatingModel.fromFirestore(doc)).toList();
    });
  }

  // Get ratings given by a user
  Stream<List<RatingModel>> getRatingsGivenByUser(String userId) {
    return _firestore
        .collection('ratings')
        .where('fromUserId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => RatingModel.fromFirestore(doc)).toList();
    });
  }

  // Check if user has rated a specific chat
  Future<bool> hasUserRatedChat(String chatId, String userId) async {
    try {
      final query = await _firestore
          .collection('ratings')
          .where('chatId', isEqualTo: chatId)
          .where('fromUserId', isEqualTo: userId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get rating for a specific chat by user
  Future<RatingModel?> getRatingForChat(String chatId, String userId) async {
    try {
      final query = await _firestore
          .collection('ratings')
          .where('chatId', isEqualTo: chatId)
          .where('fromUserId', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return RatingModel.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}