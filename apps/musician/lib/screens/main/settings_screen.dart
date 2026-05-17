import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onlygigz_musician/screens/main/edit_profile_screen.dart';
import 'package:onlygigz_musician/screens/main/change_password_screen.dart';
import 'package:onlygigz_musician/screens/main/notifications_screen.dart';
import 'package:onlygigz_musician/screens/main/privacy_policy_screen.dart';
import 'package:onlygigz_musician/screens/main/terms_of_service_screen.dart';
import 'package:onlygigz_musician/screens/main/help_center_screen.dart';
import 'package:onlygigz_musician/screens/main/wallet_overview_screen.dart';
import 'package:onlygigz_musician/screens/main/payment_method_screen.dart';
import 'package:onlygigz_musician/screens/main/privacy_settings_screen.dart';
import 'package:onlygigz_musician/screens/main/data_privacy_screen.dart';
import 'package:onlygigz_musician/screens/main/two_factor_authentication_screen.dart';
import 'package:onlygigz_musician/models/profile_model.dart';
import 'package:onlygigz_musician/services/auth_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool emailNotifications = true;

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
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

            Profile? profile;
            if (snapshot.hasData && snapshot.data!.exists) {
              profile = Profile.fromFirestore(snapshot.data!.data() as Map<String, dynamic>);
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + Title with border
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
                        const Text('Settings',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Manage your account and preferences',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // User Card
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0A0F),
                              border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: profile?.profileImage != null
                                      ? (_isNetworkImage(profile!.profileImage!)
                                          ? Image.network(
                                              profile.profileImage!,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                                'assets/profile_image.png',
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Image.asset(
                                              profile.profileImage!,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                            ))
                                      : Image.asset(
                                          'assets/profile_image.png',
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(profile?.name ?? 'Loading...',
                                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(profile?.profession ?? 'Musician', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1F),
                                    border: Border.all(color: const Color(0xFFA1F301), width: 1.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Premium',
                                      style: TextStyle(color: Color(0xFFA1F301), fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Account Section
                        _buildSectionLabel('Account'),
                        const SizedBox(height: 12),
                        _buildGroup([
                          _buildItem(svgIcon: 'assets/profile_icon.svg', title: 'Edit Profile', subtitle: profile?.name ?? '',
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
                          _buildInfoItem(svgIcon: 'assets/email_icon.svg', title: 'Email', subtitle: profile?.email ?? currentUser?.email ?? ''),
                          _buildInfoItem(svgIcon: 'assets/phone_icon.svg', title: 'Phone Number', subtitle: profile?.contact ?? ''),
                          _buildItem(svgIcon: 'assets/lock_icon.svg', title: 'Change Password', subtitle: '',
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
                        ]),
                        const SizedBox(height: 32),

                        // Notifications Section
                        _buildSectionLabel('Notifications'),
                        const SizedBox(height: 12),
                        _buildGroup([
                          _buildItem(icon: Icons.notifications_outlined, title: 'Notification Center', subtitle: '3 new',
                              iconColor: const Color(0xFF06B6D4), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                          _buildToggleItem(icon: Icons.notifications_outlined, title: 'Push Notifications',
                              value: pushNotifications, iconColor: const Color(0xFF06B6D4),
                              onChanged: (v) => setState(() => pushNotifications = v)),
                          _buildToggleItem(svgIcon: 'assets/email_icon.svg', title: 'Email Notifications',
                              value: emailNotifications, iconColor: const Color(0xFF06B6D4),
                              onChanged: (v) => setState(() => emailNotifications = v)),
                        ]),
                        const SizedBox(height: 32),

                        // Payment & Billing Section
                        _buildSectionLabel('Payment & Billing'),
                        const SizedBox(height: 12),
                        _buildGroup([
                          _buildItem(
                            svgIcon: 'assets/wallet_icon.svg',
                            title: 'Wallet',
                            subtitle: 'Manage balance and payments',
                            iconColor: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalletOverviewScreen())),
                          ),
                          _buildItem(
                            svgIcon: 'assets/payment_icon.svg',
                            title: 'Payment Methods',
                            subtitle: '2 cards',
                            iconColor: const Color(0xFF8B5CF6),
                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaymentMethodScreen())),
                          ),
                        ]),
                        const SizedBox(height: 32),

                        // Privacy & Security Section
                        _buildSectionLabel('Privacy & Security'),
                        const SizedBox(height: 12),
                        _buildGroup([
                          _buildItem(svgIcon: 'assets/shield_icon.svg', title: 'Two-Factor Authentication',
                              subtitle: 'Enabled', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TwoFactorAuthenticationScreen()))),
                          _buildItem(svgIcon: 'assets/eye_icon.svg', title: 'Privacy Settings', subtitle: '', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()))),
                          _buildItem(svgIcon: 'assets/lock_icon.svg', title: 'Data & Privacy', subtitle: '', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DataPrivacyScreen()))),
                        ]),
                        const SizedBox(height: 32),

                        // Support Section
                        _buildSectionLabel('Support'),
                        const SizedBox(height: 12),
                        _buildGroup([
                          _buildItem(svgIcon: 'assets/help_icon.svg', title: 'Help Center', subtitle: '',
                              iconColor: const Color(0xFF06B6D4), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpCenterScreen()))),
                          _buildItem(svgIcon: 'assets/application_icon.svg', title: 'Terms of Service', subtitle: '',
                              iconColor: const Color(0xFF06B6D4), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()))),
                          _buildItem(svgIcon: 'assets/application_icon.svg', title: 'Privacy Policy', subtitle: '',
                              iconColor: const Color(0xFF06B6D4), onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
                        ]),
                        const SizedBox(height: 40),

                        // App Info
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0F),
                            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1F301),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 32, height: 32,
                                      child: SvgPicture.asset('assets/music_note_icon.svg', fit: BoxFit.contain,
                                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text('OnlyGigz',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text('Version 1.0.0', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('©️ 2025 OnlyGigz. All rights reserved.',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Logout Button
                        GestureDetector(
                          onTap: () async {
                            await Provider.of<AuthService>(context, listen: false).signOut();
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x1AEF4444),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
                                  SizedBox(width: 8),
                                  Text('Log Out',
                                      style: TextStyle(color: Color(0xFFEF4444), fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildGroup(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          return Column(
            children: [
              e.value,
              if (e.key < items.length - 1)
                Container(height: 1, color: const Color(0xFFA1F301).withValues(alpha: 0.2)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem({
    IconData? icon,
    String? svgIcon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            svgIcon != null
                ? SizedBox(width: 30, height: 30,
                    child: SvgPicture.asset(svgIcon, fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(iconColor ?? const Color(0xFFA1F301), BlendMode.srcIn)))
                : Icon(icon, color: iconColor ?? const Color(0xFFA1F301), size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    IconData? icon,
    String? svgIcon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          svgIcon != null
              ? SizedBox(width: 30, height: 30,
                  child: SvgPicture.asset(svgIcon, fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(iconColor ?? const Color(0xFFA1F301), BlendMode.srcIn)))
              : Icon(icon, color: iconColor ?? const Color(0xFFA1F301), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.black,
            activeTrackColor: const Color(0xFFA1F301),
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey[900],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    String? svgIcon,
    IconData? icon,
    required String title,
    required String subtitle,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          svgIcon != null
              ? SizedBox(width: 30, height: 30,
                  child: SvgPicture.asset(svgIcon, fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(iconColor ?? const Color(0xFFA1F301), BlendMode.srcIn)))
              : Icon(icon, color: iconColor ?? const Color(0xFFA1F301), size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
