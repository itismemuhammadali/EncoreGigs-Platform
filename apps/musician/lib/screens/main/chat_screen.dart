import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

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
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  Future<void> _pickAndSendImage(ImageSource source) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
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
      await chatService.sendAttachmentMessage(
        chatId: widget.chatId,
        file: file,
        fileName: fileName,
        attachmentType: 'image',
      );
      _scrollToBottom();
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

  Future<void> _pickAndSendFile() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      final result = await FilePicker.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      if (picked.path == null) return;

      setState(() => _isUploading = true);
      final file = File(picked.path!);
      final fileName = picked.name;
      final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(picked.extension?.toLowerCase());
      await chatService.sendAttachmentMessage(
        chatId: widget.chatId,
        file: file,
        fileName: fileName,
        attachmentType: isImage ? 'image' : 'file',
      );
      _scrollToBottom();
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

  void _showAttachmentOptions() {
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
                  _pickAndSendImage(ImageSource.camera);
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
                  _pickAndSendImage(ImageSource.gallery);
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
                  child: const Icon(Icons.attach_file_rounded, color: Color(0xFFA1F301), size: 22),
                ),
                title: const Text('Attach Document / File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
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

            // Upload progress indicator
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
                    behavior: HitTestBehavior.opaque,
                    onTap: _isUploading ? null : _showAttachmentOptions,
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/attach_files_icon.svg',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          _isUploading ? Colors.grey[700]! : const Color(0xFFA1F301),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
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
    final hasAttachment = msg.attachmentUrl != null && msg.attachmentUrl!.isNotEmpty;
    final isImage = msg.type == 'image' || 
        (msg.attachmentUrl != null && RegExp(r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$', caseSensitive: false).hasMatch(msg.attachmentUrl!));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: EdgeInsets.symmetric(
                horizontal: hasAttachment && isImage ? 6 : 16,
                vertical: hasAttachment && isImage ? 6 : 12,
              ),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFA1F301) : const Color(0xFF1A1A1F),
                border: isMe ? null : Border.all(color: const Color(0xFF2A2A2F), width: 1),
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
                          onTap: () => _openUrl(msg.attachmentUrl!),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.network(
                                msg.attachmentUrl!,
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1F301)),
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
                        onTap: () => _openUrl(msg.attachmentUrl!),
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
                                color: isMe ? Colors.black : const Color(0xFFA1F301),
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.attachmentName ?? 'Document',
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
                                        color: isMe ? Colors.black87 : const Color(0xFFA1F301),
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
                  if (msg.text.isNotEmpty &&
                      !msg.text.startsWith('📷 Image attachment') &&
                      !msg.text.startsWith('📎 ')) ...[
                    if (hasAttachment) const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: hasAttachment && isImage ? 8 : 0,
                        vertical: hasAttachment && isImage ? 4 : 0,
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: isMe ? Colors.black : Colors.white,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(msg.timestamp),
              style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
