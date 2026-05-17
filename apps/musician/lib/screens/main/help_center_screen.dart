import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'live_chat_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Back', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Help Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get help and support',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.1),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search for help...',
                                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                border: InputBorder.none,
                              ),
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Contact Support Section
                    const Text(
                      'Contact Support',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LiveChatScreen())),
                      child: _buildContactItem(
                        svgIcon: 'assets/messages_icon.svg',
                        iconColor: const Color(0xFFA1F301),
                        title: 'Live Chat',
                        subtitle: 'Chat with our support team',
                        badge: 'Available now',
                        badgeColor: const Color(0xFFA1F301),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      svgIcon: 'assets/email_icon.svg',
                      iconColor: const Color(0xFF06B6D4),
                      title: 'Email Support',
                      subtitle: 'support@gighub.com',
                      badge: 'Response in 24hrs',
                      badgeColor: const Color(0xFFA1F301),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.phone_outlined,
                      iconColor: const Color(0xFFFF6B9D),
                      title: 'Phone Support',
                      subtitle: '+1 (555) 123-4567\nMon-Fri, 9AM-6PM EST',
                      badge: null,
                      badgeColor: null,
                    ),
                    const SizedBox(height: 32),
                    // Frequently Asked Questions
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Getting Started
                    _buildFAQGroup(
                      icon: 'assets/help_icon.svg',
                      iconColor: const Color(0xFFA1F301),
                      groupTitle: 'Getting Started',
                      items: [
                        'How do I create a profile?',
                        'How to apply for gigs?',
                        'Setting up your portfolio',
                        'Verification process',
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Payments & Earnings
                    _buildFAQGroup(
                      icon: 'assets/help_icon.svg',
                      iconColor: const Color(0xFF06B6D4),
                      groupTitle: 'Payments & Earnings',
                      items: [
                        'How do I get paid?',
                        'Payment methods and fees',
                        'Withdrawal process',
                        'Tax information',
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bookings & Contracts
                    _buildFAQGroup(
                      icon: 'assets/help_icon.svg',
                      iconColor: const Color(0xFFEC4899),
                      groupTitle: 'Bookings & Contracts',
                      items: [
                        'Understanding contracts',
                        'Cancellation policy',
                        'How to manage bookings',
                        'Rescheduling options',
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Account & Security
                    _buildFAQGroup(
                      icon: 'assets/help_icon.svg',
                      iconColor: const Color(0xFFA1F301),
                      groupTitle: 'Account & Security',
                      items: [
                        'Reset password',
                        'Enable two-factor authentication',
                        'Privacy settings',
                        'Delete account',
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Quick Links
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Text('Quick Links', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          _buildQuickLink('Video Tutorials'),
                          _buildQuickLink('Community Forum'),
                          _buildQuickLink('Report a Problem'),
                          _buildQuickLink('Feature Requests'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Can't Find Section with gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromRGBO(161, 243, 1, 0.1),
                            Color(0xFF000000),
                          ],
                        ),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Can't Find What You're Looking For?",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Our support team is here to help you 24/7',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: SvgPicture.asset(
                                        'assets/messages_icon.svg',
                                        fit: BoxFit.contain,
                                        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Start Live Chat', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem({
    IconData? icon,
    String? svgIcon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String? badge,
    required Color? badgeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          svgIcon != null
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: SvgPicture.asset(
                    svgIcon,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                )
              : Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor!.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
        ],
      ),
    );
  }

  Widget _buildFAQGroup({
    required String icon,
    required Color iconColor,
    required String groupTitle,
    required List<String> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24, height: 24,
                  child: SvgPicture.asset(icon, fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
                ),
                const SizedBox(width: 10),
                Text(groupTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(item, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 14),
              ],
            ),
          )),
        ],
      ),
    );
  }




  Widget _buildQuickLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 14),
        ],
      ),
    );
  }
}
