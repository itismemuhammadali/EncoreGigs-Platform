import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class OrganizerProfileScreen extends StatefulWidget {
  final String organizerId;

  const OrganizerProfileScreen({super.key, required this.organizerId});

  @override
  State<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends State<OrganizerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _gigs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getProfile(widget.organizerId);
    final gigs = await authService.getGigsByOrganizer(widget.organizerId);

    if (mounted) {
      setState(() {
        _profile = profile;
        _gigs = gigs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFA2F301))),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white))),
      );
    }

    final name = _profile?['name'] ?? _profile?['fullName'] ?? _profile?['orgName'] ?? 'Organizer';
    final orgName = _profile?['orgName'] ?? _profile?['name'] ?? 'Organization';
    final orgType = _profile?['type'] ?? 'Event Organizer';
    final profileImageUrl = _profile?['profileImageUrl'];
    final bio = _profile?['bio'] ?? 'No bio provided.';
    final location = _profile?['location'] ?? _profile?['city'] ?? 'No location provided';
    final website = _profile?['website'] ?? 'No website';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            backgroundColor: const Color(0xFF0A0A0F),
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.white),
                ),
              ),
            ),
            title: const Text('Organizer Profile', 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: const Color(0xFFA2F301).withValues(alpha: 0.3),
                height: 1.5,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: profileImageUrl != null
                            ? Image.network(
                                profileImageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              )
                            : _buildDefaultAvatar(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              orgType,
                              style: const TextStyle(
                                color: Color(0xFFA2F301),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SvgPicture.asset('assets/gigs_icon.svg', 
                                  width: 14, height: 14, 
                                  colorFilter: const ColorFilter.mode(Color(0xFF888888), BlendMode.srcIn)),
                                const SizedBox(width: 6),
                                Text(
                                  '${_gigs.length} Gigs Posted',
                                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Organization Info
                  const Text(
                    'Organization Details',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFA2F301).withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('assets/organization_icon.svg', 'Company', orgName),
                        const SizedBox(height: 16),
                        _buildInfoRow('assets/location_pointer.svg', 'Location', location),
                        const SizedBox(height: 16),
                        _buildInfoRow('assets/link_icon.svg', 'Website', website),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bio
                  const Text(
                    'About',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio,
                    style: const TextStyle(color: Color(0xFF999999), fontSize: 15, height: 1.6),
                  ),
                  const SizedBox(height: 24),

                  // Recent Gigs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Gigs',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_gigs.length} Total',
                        style: const TextStyle(color: Color(0xFFA2F301), fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_gigs.isEmpty)
                    const Text('No gigs posted yet.', style: TextStyle(color: Color(0xFF666666)))
                  else
                    ..._gigs.take(3).map((gig) => _buildGigItem(gig)),
                  
                  const SizedBox(height: 24),
                  
                  // Message Button
                  GestureDetector(
                    onTap: () async {
                      final chatService = Provider.of<ChatService>(context, listen: false);
                      try {
                        final chatId = await chatService.getOrCreateChat(
                          widget.organizerId,
                          name,
                          profileImageUrl ?? '',
                        );
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chatId,
                                otherUserId: widget.organizerId,
                                otherUserName: name,
                                otherUserImage: profileImageUrl,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error starting chat: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA2F301),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Message Organizer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(color: Color(0xFF2A2A2F), shape: BoxShape.circle),
      child: const Icon(Icons.person, color: Color(0xFF666666), size: 40),
    );
  }

  Widget _buildInfoRow(String assetPath, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2F),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(assetPath, width: 18, height: 18, 
            colorFilter: const ColorFilter.mode(Color(0xFFA2F301), BlendMode.srcIn)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildGigItem(Map<String, dynamic> gig) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA2F301).withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: gig['imageUrl'] != null
                ? Image.network(gig['imageUrl'], width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultGigImage())
                : _buildDefaultGigImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gig['title'] ?? 'Untitled Gig',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    SvgPicture.asset('assets/location_pointer.svg', 
                      width: 10, height: 10, 
                      colorFilter: const ColorFilter.mode(Color(0xFF888888), BlendMode.srcIn)),
                    const SizedBox(width: 4),
                    Text(gig['location'] ?? 'Remote',
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Text(gig['budget'] ?? '',
              style: const TextStyle(color: Color(0xFFA2F301), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDefaultGigImage() {
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFF2A2A2F),
      child: const Icon(Icons.music_note, color: Color(0xFF666666)),
    );
  }
}
