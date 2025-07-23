import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../models/offer_model.dart';
import '../models/user_model.dart';
import 'dart:math';


class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = pow(sin(dLat / 2), 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            pow(sin(dLon / 2), 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Create new item listing
  Future<String> createItem({
    required String userId,
    required String title,
    required String description,
    required List<String> tags,
    required ItemCondition condition,
    required double estimatedValue,
    String? preferredSwap,
    required List<File> images,
    File? video,
    required GeoPoint location,
    required String address,
  }) async {
    try {
      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        String imageUrl = await _uploadImage(images[i], userId, 'item_${_uuid.v4()}');
        imageUrls.add(imageUrl);
      }

      // Upload video if provided
      String? videoUrl;
      if (video != null) {
        videoUrl = await _uploadVideo(video, userId, 'video_${_uuid.v4()}');
      }

      // Create item document
      final itemId = _uuid.v4();
      final item = ItemModel(
        id: itemId,
        userId: userId,
        title: title,
        description: description,
        tags: tags,
        condition: condition,
        estimatedValue: estimatedValue,
        preferredSwap: preferredSwap,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        location: location,
        address: address,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 60)),
      );

      await _firestore.collection('items').doc(itemId).set(item.toFirestore());
      return itemId;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  // Get items with filters
  Stream<List<ItemModel>> getItems({
    String? userId,
    List<String>? tags,
    ItemCondition? condition,
    double? minValue,
    double? maxValue,
    GeoPoint? userLocation,
    double? radiusKm,
    int limit = 20,
  }) {
    Query query = _firestore.collection('items')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    if (condition != null) {
      query = query.where('condition', isEqualTo: condition.toString().split('.').last);
    }

    if (minValue != null) {
      query = query.where('estimatedValue', isGreaterThanOrEqualTo: minValue);
    }

    if (maxValue != null) {
      query = query.where('estimatedValue', isLessThanOrEqualTo: maxValue);
    }

    return query.snapshots().map((snapshot) {
      List<ItemModel> items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => !item.isExpired)
          .toList();

      // Filter by location if provided
      if (userLocation != null && radiusKm != null) {
        items = items.where((item) {
          double distance = _calculateDistance(
            userLocation.latitude,
            userLocation.longitude,
            item.location.latitude,
            item.location.longitude,
          );
          return distance <= radiusKm;
        }).toList();
      }

      return items;
    });
  }

  // Get item by ID
  Future<ItemModel?> getItemById(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (doc.exists) {
        return ItemModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get item: $e');
    }
  }

  // Update item
  Future<void> updateItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('items').doc(itemId).update(updates);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      // Get item to delete associated media
      final item = await getItemById(itemId);
      if (item != null) {
        // Delete images
        for (String imageUrl in item.imageUrls) {
          await _deleteFile(imageUrl);
        }

        // Delete video
        if (item.videoUrl != null) {
          await _deleteFile(item.videoUrl!);
        }
      }

      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // Create offer
  Future<String> createOffer({
    required String targetItemId,
    required String targetUserId,
    required String offeredItemId,
    required String offeredUserId,
    String? message,
  }) async {
    try {
      // Check if offer already exists
      final existingOffer = await _firestore
          .collection('offers')
          .where('targetItemId', isEqualTo: targetItemId)
          .where('offeredUserId', isEqualTo: offeredUserId)
          .get();

      if (existingOffer.docs.isNotEmpty) {
        throw Exception('You have already made an offer for this item');
      }

      // Create offer
      final offerId = _uuid.v4();
      final offer = OfferModel(
        id: offerId,
        targetItemId: targetItemId,
        targetUserId: targetUserId,
        offeredItemId: offeredItemId,
        offeredUserId: offeredUserId,
        message: message,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('offers').doc(offerId).set(offer.toFirestore());

      // Update item offer count
      await _firestore.collection('items').doc(targetItemId).update({
        'offerCount': FieldValue.increment(1),
      });

      return offerId;
    } catch (e) {
      throw Exception('Failed to create offer: $e');
    }
  }

  // Get offers for user
  Stream<List<OfferModel>> getOffersForUser(String userId) {
    return _firestore
        .collection('offers')
        .where('targetUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OfferModel.fromFirestore(doc)).toList();
    });
  }
// In ItemService
  Stream<List<OfferModel>> getOffersByUser(String userId) {
    try {
      return _firestore
          .collection('offers')
          .where('offeredUserId', isEqualTo: userId) // CHANGED FIELD NAME
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
        return Stream.error(error);
      })
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => OfferModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      return Stream.error(e);
    }
  }
  // Respond to offer
  Future<void> respondToOffer(String offerId, OfferStatus status) async {
    try {
      final offer = await _firestore.collection('offers').doc(offerId).get();
      if (!offer.exists) throw Exception('Offer not found');

      final offerData = OfferModel.fromFirestore(offer);

      await _firestore.collection('offers').doc(offerId).update({
        'status': status.toString().split('.').last,
        'respondedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update item status if accepted
      if (status == OfferStatus.accepted) {
        await _firestore.collection('items').doc(offerData.targetItemId).update({
          'status': 'pending',
        });
        await _firestore.collection('items').doc(offerData.offeredItemId).update({
          'status': 'pending',
        });
      }
    } catch (e) {
      throw Exception('Failed to respond to offer: $e');
    }
  }

  // Upload image with compression
  Future<String> _uploadImage(File imageFile, String userId, String fileName) async {
    try {
      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        '${imageFile.path}_compressed.jpg',
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedFile == null) throw Exception('Failed to compress image');

      // Upload to Firebase Storage
      final ref = _storage.ref().child('users/$userId/items/$fileName.jpg');
      await ref.putFile(File(compressedFile.path));
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload video
  Future<String> _uploadVideo(File videoFile, String userId, String fileName) async {
    try {
      final ref = _storage.ref().child('users/$userId/items/$fileName.mp4');
      await ref.putFile(videoFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  // Delete file from storage
  Future<void> _deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors when deleting files
    }
  }

  // Report item
  Future<void> reportItem(String itemId, String reporterId, String reason) async {
    try {
      await _firestore.collection('items').doc(itemId).update({
        'reportedBy': FieldValue.arrayUnion([reporterId]),
        'status': 'reported',
      });

      // Create report record
      await _firestore.collection('reports').add({
        'itemId': itemId,
        'reporterId': reporterId,
        'reason': reason,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report item: $e');
    }
  }
// In item_service.dart
  Future<List<ItemModel>> getUserItems(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
  }

  // Get smart matches for user
  Future<List<ItemModel>> getSmartMatches(String userId, {int limit = 10}) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final user = UserModel.fromFirestore(userDoc);

      final userItems = await _firestore
          .collection('items')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (userItems.docs.isEmpty) return [];

      Set<String> userTags = {};
      for (var doc in userItems.docs) {
        final item = ItemModel.fromFirestore(doc);
        userTags.addAll(item.tags);
      }

      final matchingItems = await _firestore
          .collection('items')
          .where('status', isEqualTo: 'active')
          .where('userId', isNotEqualTo: userId)
          .where('tags', arrayContainsAny: userTags.toList())
          .limit(limit)
          .get();

      List<ItemModel> items = matchingItems.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => !item.isExpired)
          .toList();

      items.sort((a, b) {
        int aMatches = a.tags.where((tag) => userTags.contains(tag)).length;
        int bMatches = b.tags.where((tag) => userTags.contains(tag)).length;

        if (aMatches != bMatches) {
          return bMatches.compareTo(aMatches);
        }

        double aDistance = _calculateDistance(
          user.location.latitude,
          user.location.longitude,
          a.location.latitude,
          a.location.longitude,
        );
        double bDistance = _calculateDistance(
          user.location.latitude,
          user.location.longitude,
          b.location.latitude,
          b.location.longitude,
        );

        return aDistance.compareTo(bDistance);
      });

      return items.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get smart matches: $e');
    }
  }
}