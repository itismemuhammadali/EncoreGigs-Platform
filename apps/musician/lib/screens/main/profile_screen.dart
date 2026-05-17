import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/featured_artist_card.dart';
import '../../widgets/about_section.dart';
import '../../widgets/portfolio_section.dart';
import '../../widgets/action_buttons.dart';
import '../../models/profile_model.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentNavIndex = 4;

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
        Navigator.of(context).pushReplacementNamed('/messages');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/bookings');
        break;
      case 4:
        // Profile - already here
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('musicians')
              .doc(currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Profile not found', style: TextStyle(color: Colors.white)));
            }

            final profileData = snapshot.data!.data() as Map<String, dynamic>;
            final profile = Profile.fromFirestore(profileData);

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with settings icon
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 116),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            ),
                            child: SvgPicture.asset(
                              'assets/setting_icon.svg',
                              width: 28,
                              height: 28,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Card (overlapping header)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Transform.translate(
                      offset: const Offset(0, -100),
                      child: ProfileHeader(profile: profile),
                    ),
                  ),

                  // All remaining content moved up to eliminate gap
                  Transform.translate(
                    offset: const Offset(0, -84),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Featured Artist Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: FeaturedArtistCard(),
                        ),
                        const SizedBox(height: 24),

                        // About Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AboutSection(profile: profile),
                        ),
                        const SizedBox(height: 24),

                        // Portfolio Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PortfolioSection(
                            portfolioItems: profile.portfolioItems,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ActionButtons(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
