import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import '../../../services/chat_service.dart';
import '../../../models/chat_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String name;
  final String imagePath;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.name,
    required this.imagePath,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_inputController.text.trim().isEmpty) return;
    
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendMessage(widget.chatId, _inputController.text.trim());
    
    _inputController.clear();
    
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0x4DA2F301)),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: widget.imagePath.isNotEmpty && widget.imagePath.startsWith('http')
                  ? Image.network(
                      widget.imagePath,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
                    )
                  : (widget.imagePath.isNotEmpty
                      ? Image.asset(
                          widget.imagePath,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
                        )
                      : _placeholderAvatar()),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Active now',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFA2F301)));
                }

                final messages = snapshot.data ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return ChatBubble(
                      message: msg.text,
                      time: DateFormat('HH:mm').format(msg.timestamp),
                      isMe: msg.senderId == currentUserId,
                    );
                  },
                );
              },
            ),
          ),
          ChatInput(
            controller: _inputController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2F),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFFA2F301),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
