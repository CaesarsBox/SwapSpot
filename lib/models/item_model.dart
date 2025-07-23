import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemCondition {
  new_,
  likeNew,
  good,
  fair,
  poor,
}
extension ItemConditionExtension on ItemCondition {
  String get conditionText {
    switch (this) {
      case ItemCondition.new_:
        return 'Brand New';
      case ItemCondition.likeNew:
        return 'Barely Used';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }
}

enum ItemStatus {
  active,
  pending,
  swapped,
  expired,
  reported,
}

class ItemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> tags;
  final ItemCondition condition;
  final double estimatedValue;
  final String? preferredSwap;
  final List<String> imageUrls;
  final String? videoUrl;
  final GeoPoint location;
  final String address;
  final DateTime createdAt;
  final DateTime expiresAt;
  final ItemStatus status;
  final int viewCount;
  final int offerCount;
  final List<String> reportedBy;
  final Map<String, dynamic> metadata;

  ItemModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.tags,
    required this.condition,
    required this.estimatedValue,
    this.preferredSwap,
    required this.imageUrls,
    this.videoUrl,
    required this.location,
    required this.address,
    required this.createdAt,
    required this.expiresAt,
    this.status = ItemStatus.active,
    this.viewCount = 0,
    this.offerCount = 0,
    this.reportedBy = const [],
    this.metadata = const {},
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      condition: ItemCondition.values.firstWhere(
            (e) => e.toString().split('.').last == data['condition'],
        orElse: () => ItemCondition.good,
      ),
      estimatedValue: (data['estimatedValue'] ?? 0.0).toDouble(),
      preferredSwap: data['preferredSwap'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      location: data['location'] ?? const GeoPoint(0, 0),
      address: data['address'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      status: ItemStatus.values.firstWhere(
            (e) => e.toString().split('.').last == data['status'],
        orElse: () => ItemStatus.active,
      ),
      viewCount: data['viewCount'] ?? 0,
      offerCount: data['offerCount'] ?? 0,
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'tags': tags,
      'condition': condition.toString().split('.').last,
      'estimatedValue': estimatedValue,
      'preferredSwap': preferredSwap,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'location': location,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': status.toString().split('.').last,
      'viewCount': viewCount,
      'offerCount': offerCount,
      'reportedBy': reportedBy,
      'metadata': metadata,
    };
  }

  ItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<String>? tags,
    ItemCondition? condition,
    double? estimatedValue,
    String? preferredSwap,
    List<String>? imageUrls,
    String? videoUrl,
    GeoPoint? location,
    String? address,
    DateTime? createdAt,
    DateTime? expiresAt,
    ItemStatus? status,
    int? viewCount,
    int? offerCount,
    List<String>? reportedBy,
    Map<String, dynamic>? metadata,
  }) {
    return ItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      condition: condition ?? this.condition,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      preferredSwap: preferredSwap ?? this.preferredSwap,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      location: location ?? this.location,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      viewCount: viewCount ?? this.viewCount,
      offerCount: offerCount ?? this.offerCount,
      reportedBy: reportedBy ?? this.reportedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => status == ItemStatus.active && !isExpired;
  bool get canReceiveOffers => isActive && offerCount == 0;

  String get conditionText {
    switch (condition) {
      case ItemCondition.new_:
        return 'New';
      case ItemCondition.likeNew:
        return 'Like New';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
    }
  }
}