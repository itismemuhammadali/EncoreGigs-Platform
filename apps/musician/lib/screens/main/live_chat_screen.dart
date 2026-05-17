import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> messages = [
    ChatMessage(
      sender: 'Sarah',
      message: 'Hi! Welcome to GigHub Support. I\'m Sarah, and I\'m here to help you today. How can I assist you?',
      time: '10:32 AM',
      isUser: false,
    ),
    ChatMessage(
      sender: 'You',
      message: 'Hi Sarah! I have a question about payment methods.',
      time: '10:33 AM',
      isUser: true,
    ),
    ChatMessage(
      sender: 'Sarah',
      message: 'Of course! I\'d be happy to help with payment methods. What specifically would you like to know?',
      time: '10:33 AM',
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFA1F301), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.asset('assets/profile_image.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sarah from Support', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF00C950),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('Online - Typically responds in minutes', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Chat started at 10:32 AM • Average response time: 2 min',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Column(
                    crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (!message.isUser) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFA1F301), width: 1),
                              ),
                              child: ClipOval(
                                child: Image.asset('assets/profile_image.png', fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(message.sender, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[900],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message.message,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(message.time, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA1F301),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      message.message,
                                      style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(message.time, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.check, color: Colors.grey[600], size: 14),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),

            // Typing Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Sarah is typing...', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)),
            ),

            // Input Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        'assets/attach_files_icon.svg',
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {},
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: SvgPicture.asset(
                        'assets/image_icon.svg',
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.emoji_emotions_outlined, color: Colors.grey[600], size: 24),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFA1F301),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/send_message_icon.svg',
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
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
}

class ChatMessage {
  final String sender;
  final String message;
  final String time;
  final bool isUser;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
    required this.isUser,
  });
}
