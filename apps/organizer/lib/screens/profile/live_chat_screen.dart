import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isUploading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendEmoji(String emoji) {
    _supportService.sendMessage(emoji, userType: 'organizer');
    setState(() => _showEmojiPicker = false);
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file link.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      if (picked.path == null) return;

      setState(() => _isUploading = true);
      final file = File(picked.path!);
      final fileName = picked.name;
      final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(picked.extension?.toLowerCase());

      await _supportService.sendAttachmentMessage(
        file: file,
        fileName: fileName,
        attachmentType: isImage ? 'image' : 'file',
        userType: 'organizer',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0xFF2A2A35), width: 1),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFA1F301), size: 22),
                ),
                title: const Text('Take Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadImageFromSource(ImageSource.camera);
                },
              ),
              const Divider(color: Color(0xFF222230), height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFA1F301), size: 22),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadImageFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadImageFromSource(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isUploading = true);
      final file = File(picked.path);
      final fileName = picked.name.isNotEmpty ? picked.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supportService.sendAttachmentMessage(
        file: file,
        fileName: fileName,
        attachmentType: 'image',
        userType: 'organizer',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
                                      _buildMessageContent(message, false),
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
                                      _buildMessageContent(message, true),
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

            // Upload status indicator
            if (_isUploading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFF161622),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1F301)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Uploading attachment...',
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    ),
                  ],
                ),
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

  Widget _buildMessageContent(SupportMessage message, bool isUser) {
    final hasAttachment = message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty;
    final isImage = message.type == 'image' ||
        (message.attachmentUrl != null && RegExp(r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$', caseSensitive: false).hasMatch(message.attachmentUrl!));

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: EdgeInsets.symmetric(
        horizontal: hasAttachment && isImage ? 6 : 12,
        vertical: hasAttachment && isImage ? 6 : 12,
      ),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFFA1F301) : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (hasAttachment) ...[
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GestureDetector(
                  onTap: () => _openUrl(message.attachmentUrl!),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        message.attachmentUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 180,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 180,
                            color: Colors.black26,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1F301)),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, err, stack) => Container(
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
                onTap: () => _openUrl(message.attachmentUrl!),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.black.withValues(alpha: 0.12) : const Color(0xFF252530),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insert_drive_file_rounded,
                        color: isUser ? Colors.black : const Color(0xFFA1F301),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.attachmentName ?? 'Document',
                              style: TextStyle(
                                color: isUser ? Colors.black : Colors.white,
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
                                color: isUser ? Colors.black87 : const Color(0xFFA1F301),
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
          if (message.text.isNotEmpty &&
              !message.text.startsWith('📷 Image attachment') &&
              !message.text.startsWith('📎 ')) ...[
            if (hasAttachment) const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: hasAttachment && isImage ? 6 : 0,
                vertical: hasAttachment && isImage ? 2 : 0,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

