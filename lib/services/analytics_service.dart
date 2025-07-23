import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsData {
  final int totalSwaps;
  final int successfulSwaps;
  final double successRate;
  final int totalChats;
  final int totalMessages;
  final int totalItems;
  final int activeOffers;

  AnalyticsData({
    required this.totalSwaps,
    required this.successfulSwaps,
    required this.successRate,
    required this.totalChats,
    required this.totalMessages,
    required this.totalItems,
    required this.activeOffers,
  });
}

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AnalyticsData> getUserAnalytics() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get user's offers
      final offersQuery = await _firestore
          .collection('offers')
          .where('offererId', isEqualTo: user.uid)
          .get();

      final totalSwaps = offersQuery.docs.length;
      final successfulSwaps = offersQuery.docs
          .where((doc) => doc.data()['status'] == 'completed')
          .length;
      final successRate = totalSwaps == 0 ? 0.0 : (successfulSwaps / totalSwaps) * 100;

      // Get user's chats
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();

      final totalChats = chatsQuery.docs.length;

      // Get total messages
      int totalMessages = 0;
      for (final chatDoc in chatsQuery.docs) {
        final messagesQuery = await _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .get();
        totalMessages += messagesQuery.docs.length;
      }

      // Get user's items
      final itemsQuery = await _firestore
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .get();

      final totalItems = itemsQuery.docs.length;

      // Get active offers (pending)
      final activeOffers = offersQuery.docs
          .where((doc) => doc.data()['status'] == 'pending')
          .length;

      return AnalyticsData(
        totalSwaps: totalSwaps,
        successfulSwaps: successfulSwaps,
        successRate: successRate,
        totalChats: totalChats,
        totalMessages: totalMessages,
        totalItems: totalItems,
        activeOffers: activeOffers,
      );
    } catch (e) {
      throw Exception('Failed to fetch analytics: $e');
    }
  }

  Future<Map<String, dynamic>> getDetailedAnalytics() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Monthly activity
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final monthlyOffersQuery = await _firestore
          .collection('offers')
          .where('offererId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      final monthlySwaps = monthlyOffersQuery.docs.length;

      // Category breakdown
      final itemsQuery = await _firestore
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .get();

      final categoryBreakdown = <String, int>{};
      for (final doc in itemsQuery.docs) {
        final tags = List<String>.from(doc.data()['tags'] ?? []);
        for (final tag in tags) {
          categoryBreakdown[tag] = (categoryBreakdown[tag] ?? 0) + 1;
        }
      }

      // Recent activity
      final recentOffersQuery = await _firestore
          .collection('offers')
          .where('offererId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final recentActivity = recentOffersQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': 'offer',
          'status': data['status'],
          'createdAt': data['createdAt'],
          'targetItemId': data['targetItemId'],
        };
      }).toList();

      return {
        'monthlySwaps': monthlySwaps,
        'categoryBreakdown': categoryBreakdown,
        'recentActivity': recentActivity,
      };
    } catch (e) {
      throw Exception('Failed to fetch detailed analytics: $e');
    }
  }
}