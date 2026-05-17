import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import 'api_service.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _apiService = ApiService();

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<ChatModel>> getChats() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatModel.fromFirestore(doc)).toList();
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendMessage(String chatId, String text) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _apiService.sendMessage({
        'chatId': chatId,
        'senderId': uid,
        'text': text,
      });
    } catch (e) {
      debugPrint('Error sending message via backend: $e');
      throw e;
    }
  }

  Future<String> getOrCreateChat(String otherUserId, String otherUserName, String otherUserImage) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    try {
      // Get profiles from backend to ensure latest names/images
      final organizerProfile = await _apiService.getProfile(uid);
      final otherProfile = await _apiService.getProfile(otherUserId);

      final chatData = {
        'participantIds': [uid, otherUserId],
        'participantNames': {
          uid: organizerProfile['name'] ?? 'Organizer',
          otherUserId: otherProfile['fullName'] ?? otherProfile['name'] ?? otherUserName,
        },
        'participantImages': {
          uid: organizerProfile['profileImageUrl'] ?? '',
          otherUserId: otherProfile['profileImageUrl'] ?? otherProfile['imageUrl'] ?? otherUserImage,
        },
      };

      return await _apiService.getOrCreateChat(chatData);
    } catch (e) {
      debugPrint('Error getting/creating chat via backend: $e');
      // Fallback or rethrow
      throw e;
    }
  }
}
