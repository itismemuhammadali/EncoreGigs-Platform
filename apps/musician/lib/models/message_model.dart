class Message {
  final String id;
  final String senderName;
  final String organizerName;
  final String lastMessage;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  Message({
    required this.id,
    required this.senderName,
    required this.organizerName,
    required this.lastMessage,
    required this.timestamp,
    required this.isRead,
    this.imageUrl,
  });
}
