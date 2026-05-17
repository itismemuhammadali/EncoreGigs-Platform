import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class ChatModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantImages;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantImages,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.unreadCount = const {},
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantNames: Map<String, String>.from(data['participantNames'] ?? {}),
      participantImages: (data['participantImages'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, fixEmulatorUrl(value.toString()))),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] is Timestamp
              ? (data['lastMessageTime'] as Timestamp).toDate()
              : (data['lastMessageTime'] is String
                  ? DateTime.tryParse(data['lastMessageTime']) ?? DateTime.now()
                  : DateTime.now()))
          : DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  String getOtherParticipantName(String currentUserId) {
    return participantNames.entries
        .firstWhere((e) => e.key != currentUserId, orElse: () => const MapEntry('', 'Unknown'))
        .value;
  }

  String getOtherParticipantImage(String currentUserId) {
    return participantImages.entries
        .firstWhere((e) => e.key != currentUserId, orElse: () => const MapEntry('', ''))
        .value;
  }

  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String type;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.type = 'text',
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
              ? (data['timestamp'] as Timestamp).toDate()
              : (data['timestamp'] is String
                  ? DateTime.tryParse(data['timestamp']) ?? DateTime.now()
                  : DateTime.now()))
          : DateTime.now(),
      type: data['type'] ?? 'text',
    );
  }
}
