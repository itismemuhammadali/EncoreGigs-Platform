import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/message_card.dart';
import '../home/widgets/search_bar_widget.dart';
import 'chat/chat_screen.dart';
import '../../services/chat_service.dart';
import '../../models/chat_model.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _searchQuery = '';
  Key _refreshKey = UniqueKey();

  void _refreshData() {
    setState(() => _refreshKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUserId = chatService.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            SizedBox(
              width: double.infinity,
              child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0x4DA2F301), width: 1),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recent Chats',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SearchBarWidget(
                    hint: 'Search chats and messages...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
              ),
            ),
            // Message list
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFA2F301),
                backgroundColor: const Color(0xFF1A1A1F),
                onRefresh: () async => _refreshData(),
                child: StreamBuilder<List<ChatModel>>(
                  key: _refreshKey,
                  stream: chatService.getChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFA2F301)));
                  }
                  
                  final chats = snapshot.data ?? [];
                  final filteredChats = chats.where((chat) {
                    final otherName = chat.getOtherParticipantName(currentUserId ?? '');
                    return otherName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           chat.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (filteredChats.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty ? 'No messages yet' : 'No chats found',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final otherName = chat.getOtherParticipantName(currentUserId ?? '');
                      final otherImage = chat.getOtherParticipantImage(currentUserId ?? '');

                      return MessageCard(
                        chat: chat,
                        currentUserId: currentUserId ?? '',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              chatId: chat.id,
                              otherUserId: chat.getOtherParticipantId(currentUserId ?? ''),
                              name: otherName,
                              imagePath: otherImage,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
