import 'package:flutter/material.dart';
import '../models/chat_model.dart';

class MessageCard extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const MessageCard({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = chat.getOtherParticipantName(currentUserId);
    final otherImage = chat.getOtherParticipantImage(currentUserId);
    final unreadCount = chat.unreadCount[currentUserId] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Image or Avatar in circle
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2A2A2F),
                      image: otherImage.isNotEmpty && otherImage.startsWith('http')
                          ? DecorationImage(
                              image: NetworkImage(otherImage),
                              fit: BoxFit.cover,
                            )
                          : (otherImage.isNotEmpty
                              ? DecorationImage(
                                  image: AssetImage(otherImage),
                                  fit: BoxFit.cover,
                                )
                              : null),
                    ),
                    child: otherImage.isEmpty
                        ? Center(
                            child: Text(
                              otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Color(0xFFA1F301),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFA1F301),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Timestamp
            Text(
              _formatTime(chat.lastMessageTime),
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}';
    }
  }
}
