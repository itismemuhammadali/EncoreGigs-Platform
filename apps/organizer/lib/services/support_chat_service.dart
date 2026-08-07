import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


class SupportMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderType; // 'user' or 'admin'
  final String senderName;
  final DateTime timestamp;

  SupportMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.timestamp,
  });

  factory SupportMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportMessage(
      id: doc.id,
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      senderType: data['senderType'] ?? 'user',
      senderName: data['senderName'] ?? (data['senderType'] == 'admin' ? 'Admin Support' : 'User'),
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}

class SupportChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<SupportMessage>> getMessages() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    // Optional: mark as read by user when listening
    _firestore.collection('support_chats').doc(uid).update({
      'unreadByUser': false
    }).catchError((_) {});

    return _firestore
        .collection('support_chats')
        .doc(uid)
        .collection('messages')
        .orderBy('timestamp', descending: true) // For ListView.builder with reverse: true
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => SupportMessage.fromFirestore(doc)).toList();
    });
  }

  Future<void> sendMessage(String text, {required String userType, String? userName, bool isFeatured = false}) async {
    final uid = currentUserId;
    if (uid == null) return;

    // If userName not provided, try to fetch from organizer profile
    String finalUserName = userName ?? 'User';
    if (userName == null || userName.isEmpty) {
      try {
        final userDoc = await _firestore.collection('organizers').doc(uid).get();
        if (userDoc.exists) {
          finalUserName = userDoc.data()?['companyName'] ?? userDoc.data()?['fullName'] ?? 'Organizer';
        }
      } catch (e) {
        debugPrint('Error fetching user name: $e');
        finalUserName = 'Organizer';
      }
    }

    final batch = _firestore.batch();
    final chatRef = _firestore.collection('support_chats').doc(uid);
    
    // Check if chat doc exists, if not create it, else update
    final chatData = {
      'userId': uid,
      'userType': userType,
      'userName': finalUserName,
      'isFeatured': isFeatured,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByAdmin': true,
    };
    
    // Use set with merge: true to update or create
    batch.set(chatRef, chatData, SetOptions(merge: true));

    final msgRef = chatRef.collection('messages').doc();
    batch.set(msgRef, {
      'text': text,
      'senderId': uid,
      'senderType': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
