import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/message_card.dart';
import '../../widgets/message_search_bar.dart';
import '../../models/chat_model.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  int _currentNavIndex = 2;
  String _searchQuery = '';

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    // Handle navigation to different screens
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/applications');
        break;
      case 2:
        // Messages - already here
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/bookings');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
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
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Chat with Organizers',
                      style: TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    MessageSearchBar(
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

            // Messages List
            Expanded(
              child: StreamBuilder<List<ChatModel>>(
                stream: chatService.getChats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
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
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: filteredChats.length,
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final otherName = chat.getOtherParticipantName(currentUserId ?? '');
                      final otherImage = chat.getOtherParticipantImage(currentUserId ?? '');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MessageCard(
                          chat: chat,
                          currentUserId: currentUserId ?? '',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  chatId: chat.id,
                                  otherUserId: chat.getOtherParticipantId(currentUserId ?? ''),
                                  otherUserName: otherName,
                                  otherUserImage: otherImage,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
