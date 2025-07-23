import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/rating_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Uuid _uuid = Uuid();

  Future<String> createChat({
    required String offerId,
    required List<String> participantIds,
  }) async {
    try {
      final chatId = _uuid.v4();
      final chat = ChatModel(
        id: chatId,
        offerId: offerId,
        participantIds: participantIds,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toFirestore());
      return chatId;
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.exists ? ChatModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  Stream<List<ChatModel>> getChatsForUser(String userId) {
    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ChatModel.fromFirestore(doc))
        .toList());
  }

  Future<ChatModel?> getChatByOfferId(String offerId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('offerId', isEqualTo: offerId)
          .limit(1)
          .get();

      return query.docs.isEmpty ? null : ChatModel.fromFirestore(query.docs.first);
    } catch (e) {
      throw Exception('Failed to get chat by offer ID: $e');
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final messageId = _uuid.v4();
      final now = DateTime.now();

      final message = MessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        content: content,
        messageType: messageType,
        timestamp: now,
        isRead: false,
        metadata: metadata,
      );

      final messageData = message.toFirestore(); // Make sure senderId is included here

      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(messageData);

      // ✅ 2. Update chat metadata
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessagePreview': content.length > 30
            ? '${content.substring(0, 30)}...'
            : content,
        'lastMessageSenderId': senderId,
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<String> createOrGetChat({
    required String offerId,
    required List<String> participants,
  }) async {
    try {
      // Check for existing chat
      final existingChat = await _firestore
          .collection('chats')
          .where('offerId', isEqualTo: offerId)
          .limit(1)
          .get();

      if (existingChat.docs.isNotEmpty) {
        return existingChat.docs.first.id;
      }

      // Create new chat
      final chatId = _uuid.v4();
      final chat = ChatModel(
        id: chatId,
        offerId: offerId,
        participantIds: participants,
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
      );

      await _firestore.collection('chats').doc(chatId).set(chat.toFirestore());

      // Add initial system message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(_uuid.v4())
          .set({
        'chatId': chatId,
        'senderId': 'system',
        'content': 'Chat started for this offer',
        'messageType': 'system',
        'timestamp': Timestamp.now(),
        'isRead': false,
      });

      return chatId;
    } catch (e) {
      throw Exception('Failed to create or get chat: $e');
    }
  }
  Stream<List<MessageModel>> getMessages(String chatId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        doc.data();
        return MessageModel.fromFirestore(doc);
      }).toList();
    });
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  Future<List<String>> getChatParticipants(String chatId) async {
    try {
      final chat = await getChatById(chatId);
      return chat?.participantIds ?? [];
    } catch (e) {
      throw Exception('Failed to get chat participants: $e');
    }
  }

  Future<bool> isUserInChat(String chatId, String userId) async {
    try {
      final participants = await getChatParticipants(chatId);
      return participants.contains(userId);
    } catch (e) {
      return false;
    }
  }
  Future<void> markSwapAsCompleted(String chatId, String userId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) throw Exception('Chat not found');

      final isUserA = chat.participantIds[0] == userId;
      final updateData = <String, dynamic>{};

      if (isUserA) {
        updateData['completedByUserA'] = true;
      } else {
        updateData['completedByUserB'] = true;
      }

      // Check if both users have completed
      final newCompletedByUserA = isUserA ? true : chat.completedByUserA;
      final newCompletedByUserB = isUserA ? chat.completedByUserB : true;

      if (newCompletedByUserA && newCompletedByUserB) {
        updateData['status'] = 'completed';
      }

      await _firestore.collection('chats').doc(chatId).update(updateData);
    } catch (e) {
      throw Exception('Failed to mark swap as completed: $e');
    }
  }

  // Submit rating for completed swap
  Future<void> submitRating({
    required String fromUserId,
    required String toUserId,
    required String chatId,
    required double rating,
    String? reviewText,
  }) async {
    try {
      final ratingId = _uuid.v4();
      final ratingModel = RatingModel(
        id: ratingId,
        fromUserId: fromUserId,
        toUserId: toUserId,
        chatId: chatId,
        rating: rating,
        reviewText: reviewText,
        timestamp: DateTime.now(),
      );

      // Save rating
      await _firestore.collection('ratings').doc(ratingId).set(ratingModel.toFirestore());

      // Mark that user has rated
      final chat = await getChatById(chatId);
      if (chat != null) {
        final isUserA = chat.participantIds[0] == fromUserId;
        final updateData = <String, dynamic>{};

        if (isUserA) {
          updateData['hasRatedByUserA'] = true;
        } else {
          updateData['hasRatedByUserB'] = true;
        }

        await _firestore.collection('chats').doc(chatId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to submit rating: $e');
    }
  }

  // Check if user has already rated this swap
  Future<bool> hasUserRated(String chatId, String userId) async {
    try {
      final chat = await getChatById(chatId);
      if (chat == null) return false;

      final isUserA = chat.participantIds[0] == userId;
      return isUserA ? chat.hasRatedByUserA : chat.hasRatedByUserB;
    } catch (e) {
      return false;
    }
  }

  // Get other participant ID in chat
  String getOtherParticipantId(ChatModel chat, String currentUserId) {
    return chat.participantIds.firstWhere((id) => id != currentUserId);
  }

  // Check if swap is completed by both users
  bool isSwapCompleted(ChatModel chat) {
    return chat.completedByUserA && chat.completedByUserB;
  }

  // Check if current user has completed the swap
  bool hasUserCompletedSwap(ChatModel chat, String userId) {
    final isUserA = chat.participantIds[0] == userId;
    return isUserA ? chat.completedByUserA : chat.completedByUserB;
  }
}