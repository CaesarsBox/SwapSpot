import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  completed,
}

class OfferModel {
  final String id;
  final String targetItemId;
  final String targetUserId;
  final String offeredItemId;
  final String offeredUserId;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? message;
  final Map<String, dynamic> metadata;

  OfferModel({
    required this.id,
    required this.targetItemId,
    required this.targetUserId,
    required this.offeredItemId,
    required this.offeredUserId,
    this.status = OfferStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.message,
    this.metadata = const {},
  });

  factory OfferModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return OfferModel(
      id: doc.id,
      targetItemId: data['targetItemId'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      offeredItemId: data['offeredItemId'] ?? '',
      offeredUserId: data['offeredUserId'] ?? '',
      status: OfferStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => OfferStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      message: data['message'],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'targetItemId': targetItemId,
      'targetUserId': targetUserId,
      'offeredItemId': offeredItemId,
      'offeredUserId': offeredUserId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null
          ? Timestamp.fromDate(respondedAt!)
          : null,
      'message': message,
      'metadata': metadata,
    };
  }

  OfferModel copyWith({
    String? id,
    String? targetItemId,
    String? targetUserId,
    String? offeredItemId,
    String? offeredUserId,
    OfferStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return OfferModel(
      id: id ?? this.id,
      targetItemId: targetItemId ?? this.targetItemId,
      targetUserId: targetUserId ?? this.targetUserId,
      offeredItemId: offeredItemId ?? this.offeredItemId,
      offeredUserId: offeredUserId ?? this.offeredUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isPending => status == OfferStatus.pending;
  bool get isAccepted => status == OfferStatus.accepted;
  bool get isRejected => status == OfferStatus.rejected;
  bool get isCancelled => status == OfferStatus.cancelled;
  bool get isCompleted => status == OfferStatus.completed;
  bool get isResolved => !isPending;

  String get statusText {
    switch (status) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.cancelled:
        return 'Cancelled';
      case OfferStatus.completed:
        return 'Completed';
    }
  }
}