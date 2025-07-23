import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class DataExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> exportUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Collect all user data
      final userData = await _collectUserData(user.uid);

      // Convert to JSON
      final jsonData = jsonEncode(userData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'swapspot_data_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonData);

      return file.path;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  Future<Map<String, dynamic>> _collectUserData(String userId) async {
    final userData = <String, dynamic>{};
    final timestamp = DateTime.now().toIso8601String();

    // User profile
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      userData['profile'] = {
        ...userDoc.data()!,
        'createdAt': userDoc.data()!['createdAt'].toDate().toIso8601String(),
        'lastActive': userDoc.data()!['lastActive'].toDate().toIso8601String(),
      };
    }

    // User's items
    final itemsQuery = await _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .get();

    userData['items'] = itemsQuery.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'createdAt': data['createdAt'].toDate().toIso8601String(),
      };
    }).toList();

    // User's offers (as offerer)
    final offersQuery = await _firestore
        .collection('offers')
        .where('offererId', isEqualTo: userId)
        .get();

    userData['offers_made'] = offersQuery.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'createdAt': data['createdAt'].toDate().toIso8601String(),
      };
    }).toList();

    // Offers received by user
    final receivedOffersQuery = await _firestore
        .collection('offers')
        .where('targetItemOwnerId', isEqualTo: userId)
        .get();

    userData['offers_received'] = receivedOffersQuery.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'createdAt': data['createdAt'].toDate().toIso8601String(),
      };
    }).toList();

    // User's chats
    final chatsQuery = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    userData['chats'] = [];
    for (final chatDoc in chatsQuery.docs) {
      final chatData = chatDoc.data();
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatDoc.id)
          .collection('messages')
          .get();

      final messages = messagesQuery.docs.map((msgDoc) {
        final msgData = msgDoc.data();
        return {
          'id': msgDoc.id,
          ...msgData,
          'timestamp': msgData['timestamp'].toDate().toIso8601String(),
        };
      }).toList();

      userData['chats'].add({
        'id': chatDoc.id,
        ...chatData,
        'createdAt': chatData['createdAt'].toDate().toIso8601String(),
        'lastMessageAt': chatData['lastMessageAt'].toDate().toIso8601String(),
        'messages': messages,
      });
    }

    // Export metadata
    userData['export_metadata'] = {
      'exported_at': timestamp,
      'user_id': userId,
      'total_items': userData['items'].length,
      'total_offers_made': userData['offers_made'].length,
      'total_offers_received': userData['offers_received'].length,
      'total_chats': userData['chats'].length,
    };

    return userData;
  }

  Future<void> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors when deleting files
    }
  }
}