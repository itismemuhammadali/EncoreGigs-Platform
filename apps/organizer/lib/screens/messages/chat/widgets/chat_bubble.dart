import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentType;
  final VoidCallback? onAttachmentTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.time,
    required this.isMe,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentType,
    this.onAttachmentTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAttachment = attachmentUrl != null && attachmentUrl!.isNotEmpty;
    final isImage = attachmentType == 'image' ||
        (attachmentUrl != null && RegExp(r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$', caseSensitive: false).hasMatch(attachmentUrl!));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: hasAttachment && isImage ? 6 : 16,
          vertical: hasAttachment && isImage ? 6 : 12,
        ),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
          border: isMe
              ? null
              : Border.all(color: const Color(0xFF2A2A2F), width: 1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (hasAttachment) ...[
              if (isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: onAttachmentTap,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          attachmentUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              color: Colors.black26,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA2F301)),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 120,
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.open_in_new, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: onAttachmentTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.black.withValues(alpha: 0.12) : const Color(0xFF252530),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_rounded,
                          color: isMe ? Colors.black : const Color(0xFFA2F301),
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attachmentName ?? 'Document',
                                style: TextStyle(
                                  color: isMe ? Colors.black : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to view / download',
                                style: TextStyle(
                                  color: isMe ? Colors.black87 : const Color(0xFFA2F301),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            if (message.isNotEmpty &&
                !message.startsWith('📷 Image attachment') &&
                !message.startsWith('📎 ')) ...[
              if (hasAttachment) const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hasAttachment && isImage ? 8 : 0,
                  vertical: hasAttachment && isImage ? 4 : 0,
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isMe ? Colors.black : Colors.white,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe
                    ? Colors.black.withValues(alpha: 0.6)
                    : const Color(0xFF666666),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
