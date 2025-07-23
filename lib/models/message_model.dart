import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.messageType = 'text',
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      content: data['content'] ?? '',
      isRead: data['isRead'] ?? false,
      messageType: data['messageType'] ?? 'text',
      senderId: data['senderId'] ?? '',
      // NOT inside metadata
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: data['metadata'] ?? {},
    );
  }


  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
