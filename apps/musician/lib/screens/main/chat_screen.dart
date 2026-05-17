import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserImage;
  final String? otherUserOrgName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage,
    this.otherUserOrgName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendMessage(widget.chatId, _messageController.text.trim());
    
    _messageController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUserId = chatService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button row
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Organizer row
                  Row(
                    children: [
                      // Organizer image
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2A2A2F),
                          image: widget.otherUserImage != null && widget.otherUserImage!.isNotEmpty
                              ? (widget.otherUserImage!.startsWith('http')
                                  ? DecorationImage(
                                      image: NetworkImage(widget.otherUserImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : DecorationImage(
                                      image: AssetImage(widget.otherUserImage!),
                                      fit: BoxFit.cover,
                                    ))
                              : null,
                        ),
                        child: widget.otherUserImage == null || widget.otherUserImage!.isEmpty
                            ? Center(
                                child: Text(
                                  widget.otherUserName.isNotEmpty ? widget.otherUserName[0].toUpperCase() : '?',
                                  style: const TextStyle(color: Color(0xFFA1F301), fontWeight: FontWeight.bold, fontSize: 20),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.otherUserName,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            if (widget.otherUserOrgName != null && widget.otherUserOrgName!.isNotEmpty)
                              Text(
                                widget.otherUserOrgName!,
                                style: const TextStyle(color: Color(0xFF999999), fontSize: 13),
                              ),
                          ],
                        ),
                      ),
                      // Active now
                      const Text(
                        'Active now',
                        style: TextStyle(color: Color(0xFFA1F301), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Messages list
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)));
                  }

                  final messages = snapshot.data ?? [];

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      return _buildMessage(msg, isMe);
                    },
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Attachment icon
                  GestureDetector(
                    onTap: () {},
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        'assets/attach_files_icon.svg',
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(Color(0xFF999999), BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFF1A1A1F),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send button
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA1F301),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: SvgPicture.asset(
                            'assets/send_message_icon.svg',
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(MessageModel msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFA1F301) : const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              msg.text,
              style: TextStyle(
                color: isMe ? Colors.black : Colors.white,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(msg.timestamp),
            style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
