import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool profileVisibility = true;
  bool showEmail = true;
  bool showPhone = true;
  bool showLocation = true;
  bool activityStatus = true;
  bool searchEngineIndexing = true;
  String profileVisibilityOption = 'everyone';

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
                      'Privacy Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Control your privacy and visibility',
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
                    // Your Privacy Matters Info Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: SvgPicture.asset(
                              'assets/eye_icon.svg',
                              fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFA1F301),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Privacy Matters',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Control what information is visible to other users and how you appear on the platform.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Privacy Settings Items
                    Column(
                      children: [
                        _buildToggleItemWithBorder(
                          svgIcon: 'assets/profile_icon.svg',
                          iconColor: const Color(0xFFA1F301),
                          title: 'Profile Visibility',
                          subtitle: 'Make your profile visible to all users',
                          value: profileVisibility,
                          onChanged: (v) => setState(() => profileVisibility = v),
                        ),
                        const SizedBox(height: 12),
                        _buildToggleItemWithBorder(
                          svgIcon: 'assets/email_icon.svg',
                          iconColor: const Color(0xFF06B6D4),
                          title: 'Show Email Address',
                          subtitle: 'Display your email on your public profile',
                          value: showEmail,
                          onChanged: (v) => setState(() => showEmail = v),
                        ),
                        const SizedBox(height: 12),
                        _buildToggleItemWithBorder(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFFEC4899),
                          title: 'Show Phone Number',
                          subtitle: 'Display your phone number on your public profile',
                          value: showPhone,
                          onChanged: (v) => setState(() => showPhone = v),
                        ),
                        const SizedBox(height: 12),
                        _buildToggleItemWithBorder(
                          svgIcon: 'assets/location_pointer.svg',
                          iconColor: const Color(0xFFA1F301),
                          title: 'Show Location',
                          subtitle: 'Display your city and state',
                          value: showLocation,
                          onChanged: (v) => setState(() => showLocation = v),
                        ),
                        const SizedBox(height: 12),
                        _buildToggleItemWithBorder(
                          icon: Icons.visibility_outlined,
                          iconColor: const Color(0xFF06B6D4),
                          title: 'Activity Status',
                          subtitle: 'Show when you\'re online and active',
                          value: activityStatus,
                          onChanged: (v) => setState(() => activityStatus = v),
                        ),
                        const SizedBox(height: 12),
                        _buildToggleItemWithBorder(
                          svgIcon: 'assets/users_icon.svg',
                          iconColor: const Color(0xFFEC4899),
                          title: 'Search Engine Indexing',
                          subtitle: 'Allow search engines to index your profile',
                          value: searchEngineIndexing,
                          onChanged: (v) => setState(() => searchEngineIndexing = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Who Can See Your Profile
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Who Can See Your Profile',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          _buildRadioItem(
                            title: 'Everyone',
                            value: 'everyone',
                            groupValue: profileVisibilityOption,
                            onChanged: (v) => setState(() => profileVisibilityOption = v!),
                          ),
                          _buildRadioItem(
                            title: 'Only verified users',
                            value: 'verified',
                            groupValue: profileVisibilityOption,
                            onChanged: (v) => setState(() => profileVisibilityOption = v!),
                          ),
                          _buildRadioItem(
                            title: 'Only my connections',
                            value: 'connections',
                            groupValue: profileVisibilityOption,
                            onChanged: (v) => setState(() => profileVisibilityOption = v!),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Blocked Users
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Blocked Users',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '0 users',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Blocked users can\'t view your profile or contact you.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
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

  Widget _buildToggleItemWithBorder({
    IconData? icon,
    String? svgIcon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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

  Widget _buildRadioItem({
    required String title,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '•',
            style: TextStyle(
              color: groupValue == value ? const Color(0xFFA1F301) : Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: groupValue == value ? const Color(0xFFA1F301) : Colors.grey[700]!,
                  width: 2.5,
                ),
              ),
              child: groupValue == value
                  ? Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFA1F301),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
