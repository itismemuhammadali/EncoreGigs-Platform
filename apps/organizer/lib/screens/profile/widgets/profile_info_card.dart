import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../constants.dart';

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('organizers')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic>? profile;
        if (snapshot.hasData && snapshot.data!.exists) {
          profile = snapshot.data!.data() as Map<String, dynamic>?;
        }

        if (profile == null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: authService.getProfile(user.uid),
            builder: (context, fallbackSnap) {
              final fallbackData = fallbackSnap.data;
              return _buildCard(context, fallbackData, user.email);
            },
          );
        }

        return _buildCard(context, profile, user.email);
      },
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic>? profile, String? userEmail) {
    final name = profile?['name'] ?? profile?['fullName'] ?? profile?['orgName'] ?? 'User';
    final email = profile?['email'] ?? profile?['businessEmail'] ?? userEmail ?? 'No email';
    final contact = profile?['contact'] ?? profile?['phone'] ?? profile?['businessPhone'] ?? 'No contact';
    
    String location = 'No location';
    if (profile?['city'] != null && profile!['city'].toString().trim().isNotEmpty) {
      final city = profile['city'].toString().trim();
      final state = (profile['state'] ?? '').toString().trim();
      location = state.isNotEmpty ? '$city, $state' : city;
    } else if (profile?['location'] != null && profile!['location'].toString().trim().isNotEmpty) {
      location = profile['location'].toString().trim();
    }

    final rawImageUrl = profile?['profileImageUrl'];
    final profileImageUrl = (rawImageUrl != null && rawImageUrl.toString().trim().isNotEmpty)
        ? fixEmulatorUrl(rawImageUrl.toString().trim())
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                    ? Image.network(
                        profileImageUrl,
                        key: ValueKey(profileImageUrl),
                        width: 70,
                        height: 70,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile?['role']?.toString().toUpperCase() ?? 'ORGANIZER',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.email_outlined, text: email),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.phone_outlined, text: contact),
          const SizedBox(height: 12),
          _InfoRowSvg(iconPath: 'assets/location_pointer.svg', text: location),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2F),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Color(0xFF666666), size: 32),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF888888), size: 18),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
      ],
    );
  }
}

class _InfoRowSvg extends StatelessWidget {
  final String iconPath;
  final String text;

  const _InfoRowSvg({required this.iconPath, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(iconPath,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
                Color(0xFF888888), BlendMode.srcIn)),
        const SizedBox(width: 12),
        Text(text,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
      ],
    );
  }
}
