import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final String offerId;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final String status;
  final bool completedByUserA;
  final bool completedByUserB;
  final bool hasRatedByUserA;
  final bool hasRatedByUserB;

  ChatModel({
    required this.id,
    required this.offerId,
    required this.participantIds,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.lastMessageSenderId,
    this.status = 'active',
    this.completedByUserA = false,
    this.completedByUserB = false,
    this.hasRatedByUserA = false,
    this.hasRatedByUserB = false,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      offerId: data['offerId'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessageAt: (data['lastMessageAt'] as Timestamp).toDate(),
      lastMessagePreview: data['lastMessagePreview'],
      lastMessageSenderId: data['lastMessageSenderId'],
      status: data['status'] ?? 'active',
      completedByUserA: data['completedByUserA'] ?? false,
      completedByUserB: data['completedByUserB'] ?? false,
      hasRatedByUserA: data['hasRatedByUserA'] ?? false,
      hasRatedByUserB: data['hasRatedByUserB'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'offerId': offerId,
      'participantIds': participantIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      if (lastMessagePreview != null) 'lastMessagePreview': lastMessagePreview,
      if (lastMessageSenderId != null) 'lastMessageSenderId': lastMessageSenderId,
      'status': status,
      'completedByUserA': completedByUserA,
      'completedByUserB': completedByUserB,
      'hasRatedByUserA': hasRatedByUserA,
      'hasRatedByUserB': hasRatedByUserB,
    };
  }
  ChatModel copyWith({
    String? id,
    String? offerId,
    List<String>? participantIds,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? status,
    bool? completedByUserA,
    bool? completedByUserB,
    bool? hasRatedByUserA,
    bool? hasRatedByUserB,
  }) {
    return ChatModel(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      participantIds: participantIds ?? this.participantIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      status: status ?? this.status,
      completedByUserA: completedByUserA ?? this.completedByUserA,
      completedByUserB: completedByUserB ?? this.completedByUserB,
      hasRatedByUserA: hasRatedByUserA ?? this.hasRatedByUserA,
      hasRatedByUserB: hasRatedByUserB ?? this.hasRatedByUserB,
    );
  }
}
