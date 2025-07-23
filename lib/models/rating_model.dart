import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String chatId;
  final double rating;
  final String? reviewText;
  final DateTime timestamp;

  RatingModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.chatId,
    required this.rating,
    this.reviewText,
    required this.timestamp,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      chatId: data['chatId'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewText: data['reviewText'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'chatId': chatId,
      'rating': rating,
      'reviewText': reviewText,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  RatingModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? chatId,
    double? rating,
    String? reviewText,
    DateTime? timestamp,
  }) {
    return RatingModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      chatId: chatId ?? this.chatId,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}