import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? bio;
  final GeoPoint location;
  final String address;
  final DateTime createdAt;
  final DateTime lastActive;
  final int totalSwaps;
  final int successfulSwaps;
  final double trustScore;
  final bool isVerified;
  final List<String> reportedBy;
  final Map<String, dynamic> preferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio,
    required this.location,
    required this.address,
    required this.createdAt,
    required this.lastActive,
    this.totalSwaps = 0,
    this.successfulSwaps = 0,
    this.trustScore = 0.0,
    this.isVerified = false,
    this.reportedBy = const [],
    this.preferences = const {},
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      location: data['location'] ?? const GeoPoint(0, 0),
      address: data['address'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp).toDate(),
      totalSwaps: data['totalSwaps'] ?? 0,
      successfulSwaps: data['successfulSwaps'] ?? 0,
      trustScore: (data['trustScore'] ?? 0.0).toDouble(),
      isVerified: data['isVerified'] ?? false,
      reportedBy: List<String>.from(data['reportedBy'] ?? []),
      preferences: data['preferences'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'location': location,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'totalSwaps': totalSwaps,
      'successfulSwaps': successfulSwaps,
      'trustScore': trustScore,
      'isVerified': isVerified,
      'reportedBy': reportedBy,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    GeoPoint? location,
    String? address,
    DateTime? createdAt,
    DateTime? lastActive,
    int? totalSwaps,
    int? successfulSwaps,
    double? trustScore,
    bool? isVerified,
    List<String>? reportedBy,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      location: location ?? this.location,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      totalSwaps: totalSwaps ?? this.totalSwaps,
      successfulSwaps: successfulSwaps ?? this.successfulSwaps,
      trustScore: trustScore ?? this.trustScore,
      isVerified: isVerified ?? this.isVerified,
      reportedBy: reportedBy ?? this.reportedBy,
      preferences: preferences ?? this.preferences,
    );
  }
  double get successRate {
    if (totalSwaps == 0) return 0.0;
    return (successfulSwaps / totalSwaps) * 100;
  }
} 