import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../services/support_chat_service.dart';
import 'package:intl/intl.dart';
import '../../constants/emoji_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _messageController = TextEditingController();
  final _supportService = SupportChatService();
  bool _showEmojiPicker = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    _messageController.text = newText;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: selection.start + emoji.length),
    );
  }

  void _sendEmoji(String emoji) {
    _supportService.sendMessage(emoji, userType: 'organizer');
    setState(() => _showEmojiPicker = false);
  }

  void _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result != null) {
      debugPrint('File picked: ${result.files.single.name}');
      // TODO: Upload to Firebase Storage
    }
  }

  void _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      debugPrint('Image picked: ${image.path}');
      // TODO: Upload to Firebase Storage
    }
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
                          color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                          border: Border.all(color: const Color(0xFFA1F301), width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.support_agent_rounded, color: Color(0xFFA1F301), size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Admin Support', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
                ],
              ),
            ),

            // Messages
            Expanded(
              child: StreamBuilder<List<SupportMessage>>(
                stream: _supportService.getMessages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }
                  
                  final messages = snapshot.data ?? [];
                  
                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages yet. Start chatting!', style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    reverse: true, // Display latest at the bottom
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isUser = message.senderType == 'user';
                      final timeStr = DateFormat('h:mm a').format(message.timestamp);
                      final isOldestMessage = index == messages.length - 1;

                      return Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (isOldestMessage)
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Chat started at ${DateFormat('h:mm a').format(messages.last.timestamp)} • Average response time: 2 min',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ),
                            ),
                          if (!isUser) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                                    border: Border.all(color: const Color(0xFFA1F301), width: 1),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.support_agent_rounded, color: Color(0xFFA1F301), size: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(message.senderName, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[900],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          message.text,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(timeStr, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
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
                                          message.text,
                                          style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Text(timeStr, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
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
                  );
                }
              ),
            ),

            // Typing Indicator - REMOVED since we do real-time
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: Text('Sarah is typing...', style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)),
            // ),

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Emoji Picker Grid (shown when toggled)
                  if (_showEmojiPicker)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3)),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
                        itemCount: EmojiConstants.emojiCount,
                        itemBuilder: (context, index) {
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _sendEmoji(EmojiConstants.getEmojiByIndex(index)),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    EmojiConstants.getEmojiByIndex(index),
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Input controls
                  Row(
                    children: [
                      // File Picker
                      GestureDetector(
                        onTap: _pickFile,
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
                      // Image Picker
                      GestureDetector(
                        onTap: _pickImage,
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
                      // Emoji Picker Toggle
                      GestureDetector(
                        onTap: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
                        child: Icon(Icons.emoji_emotions_outlined, color: _showEmojiPicker ? const Color(0xFFA1F301) : Colors.grey[600], size: 24),
                      ),
                      const SizedBox(width: 12),
                      // Send Button
                      GestureDetector(
                        onTap: () {
                          final text = _messageController.text.trim();
                          if (text.isNotEmpty) {
                            _supportService.sendMessage(text, userType: 'organizer');
                            _messageController.clear();
                            setState(() => _showEmojiPicker = false);
                          }
                        },
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

