import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

    final messageData = {
      'senderId': uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'text',
    };

    final batch = _firestore.batch();
    
    // Add message
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(messageRef, messageData);

    // Update chat last message
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': uid,
    });

    await batch.commit();
  }

  Future<String> getOrCreateChat(String otherUserId, String otherUserName, String otherUserImage) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not authenticated');

    // Always fetch the organizer's real name first
    String resolvedName = otherUserName;
    String resolvedImage = otherUserImage;
    try {
      final otherDoc = await _firestore.collection('organizers').doc(otherUserId).get();
      if (otherDoc.exists) {
        resolvedName = otherDoc.data()?['name'] ?? otherUserName;
        resolvedImage = otherDoc.data()?['profileImageUrl'] ?? otherUserImage;
      }
    } catch (e) {
      debugPrint('Could not fetch organizer profile for chat: $e');
    }

    // Get current musician's real name
    final currentUserDoc = await _firestore.collection('musicians').doc(uid).get();
    final currentUserName = currentUserDoc.data()?['fullName'] ?? 'Musician';
    final currentUserImage = currentUserDoc.data()?['profileImageUrl'] ?? '';

    // Check if chat already exists — if so, patch names and return
    final existingChat = await _firestore
        .collection('chats')
        .where('participantIds', arrayContains: uid)
        .get();

    for (var doc in existingChat.docs) {
      final List<String> participants = List<String>.from(doc['participantIds']);
      if (participants.contains(otherUserId)) {
        // Patch with correct names/images in case they were wrong before
        await doc.reference.update({
          'participantNames.$uid': currentUserName,
          'participantNames.$otherUserId': resolvedName,
          'participantImages.$uid': currentUserImage,
          'participantImages.$otherUserId': resolvedImage,
        });
        return doc.id;
      }
    }

    // Create new chat with correct data
    final newChatRef = _firestore.collection('chats').doc();
    await newChatRef.set({
      'participantIds': [uid, otherUserId],
      'participantNames': {
        uid: currentUserName,
        otherUserId: resolvedName,
      },
      'participantImages': {
        uid: currentUserImage,
        otherUserId: resolvedImage,
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': '',
      'unreadCount': {
        uid: 0,
        otherUserId: 0,
      },
    });

    return newChatRef.id;
  }
}
