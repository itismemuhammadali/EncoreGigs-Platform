import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
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
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Shield icon in rounded square
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A0A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/shield_icon.svg',
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Title + date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Privacy Policy',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Last updated: Dec 17, 2025',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      // PDF button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SvgPicture.asset(
                              'assets/download_icon.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'PDF',
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Introduction'),
                    _buildParagraph(
                      'GigHub ("we," "us," or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our platform. Please read this policy carefully.',
                    ),
                    _buildSection('1. Information We Collect'),
                    _buildSubSection('1.1 Information You Provide'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardItem('Account Information:', 'Name, email address, phone number, password'),
                          _buildCardItem('Profile Information:', 'Title, bio, location, experience, genres, rate ranges'),
                          _buildCardItem('Portfolio Content:', 'Images, audio files, and descriptions'),
                          _buildCardItem('Payment Information:', 'payment card information (encrypted and stored by payment processors)'),
                          _buildCardItem('Communications:', 'Messages, reviews, and feedback'),
                        ],
                      ),
                    ),
                    _buildSubSection('1.2 Automatically Collected Information'),
                    _buildBullets([
                      'Device information (type, operating system, browser)',
                      'IP address and location data',
                      'Usage data (features used, pages viewed, time spent)',
                      'Cookies and similar tracking technologies',
                    ]),
                    _buildSection('2. How We Use Your Information'),
                    _buildParagraph('We use the information we collect to:'),
                    _buildBullets([
                      'Provide, maintain, and improve our Service',
                      'Process bookings and payments',
                      'Facilitate communication between users',
                      'Send important notifications and updates',
                      'Provide customer support',
                      'Detect and prevent fraud and abuse',
                      'Analyze usage patterns and improve user experience',
                      'Send marketing communications (with your consent)',
                      'Comply with legal obligations',
                    ]),
                    _buildSection('3. How We Share Your Information'),
                    _buildSubSection('3.1 With Other Users'),
                    _buildParagraph('Your profile information, portfolio, and reviews are visible to other users. You can control visibility through privacy settings.'),
                    _buildSubSection('3.2 With Service Providers'),
                    _buildParagraph('We share information with trusted third-party service providers who assist in:'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _buildBullets([
                        'Payment processing (Stripe, PayPal)',
                        'Cloud hosting and storage (AWS, Google Cloud)',
                        'Email and communication services',
                        'Analytics and performance monitoring',
                        'Customer support tools',
                      ]),
                    ),
                    _buildSubSection('3.3 Legal Requirements'),
                    _buildParagraph('We may disclose your information if required by law, legal process, or government request, or to protect the rights, property, or safety of GigHub, our users, or others.'),
                    _buildSection('4. Data Security'),
                    _buildParagraph('We implement industry-standard security measures to protect your information:'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.08),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _buildBullets([
                        'SSL/TLS encryption for data transmission',
                        'Encrypted storage of sensitive information',
                        'Regular security audits and updates',
                        'Access controls and authentication',
                        'Secure payment processing (PCI DSS compliant)',
                      ]),
                    ),
                    _buildParagraph('However, no method of transmission over the Internet is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.'),
                    _buildSection('5. Your Rights and Choices'),
                    _buildParagraph('You have the following rights regarding your personal information:'),
                    _buildRightCard('Access and Portability', 'Request a copy of your data in a portable format'),
                    _buildRightCard('Correction', 'Update or correct inaccurate information'),
                    _buildRightCard('Deletion', 'Request deletion of your account and data'),
                    _buildRightCard('Opt-Out', 'Unsubscribe from marketing communications'),
                    _buildRightCard('Object to Processing', 'Object to certain uses of your information'),
                    _buildSection('6. Cookies and Tracking Technologies'),
                    _buildParagraph('We use cookies and similar technologies to:'),
                    _buildBullets([
                      'Remember your preferences and settings',
                      'Authenticate users and prevent fraud',
                      'Analyze site usage and performance',
                      'Deliver personalized content and ads',
                    ]),
                    _buildParagraph('You can control cookies through your browser settings. Note that disabling cookies may affect functionality.'),
                    _buildSection('7. Data Retention'),
                    _buildParagraph('We retain your information for as long as necessary to:'),
                    _buildBullets([
                      'Provide our services to you',
                      'Comply with legal obligations',
                      'Resolve disputes and enforce agreements',
                      'Maintain business records',
                    ]),
                    _buildParagraph("When you delete your account, we will delete or anonymize your information within 30 days, except where we're required to retain it for legal or regulatory purposes."),
                    _buildSection("8. Children's Privacy"),
                    _buildParagraph('Our Service is not intended for users under 18 years of age. We do not knowingly collect information from children. If you believe we have collected information from a child, please contact us immediately.'),
                    _buildSection('9. International Data Transfers'),
                    _buildParagraph('Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your information in accordance with this Privacy Policy.'),
                    _buildSection('10. Changes to This Privacy Policy'),
                    _buildParagraph('We may update this Privacy Policy from time to time. We will notify you of material changes via email or through the Service. Your continued use after such modifications constitutes acceptance of the updated policy.'),
                    _buildSection('11. Contact Us'),
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('If you have questions about this Privacy Policy or our data practices:',
                              style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5)),
                          const SizedBox(height: 12),
                          Text('Email: privacy@gighub.com', style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.8)),
                          Text('Address: 123 Music Ave, New York, NY 10001', style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.8)),
                          Text('Phone: +1 (555) 123-4567', style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.8)),
                          const SizedBox(height: 12),
                          Divider(color: const Color(0xFFA1F301).withValues(alpha: 0.2), thickness: 1),
                          const SizedBox(height: 12),
                          Text('Data Protection Officer: dpo@gighub.com', style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5)),
                        ],
                      ),
                    ),
                    _buildSection('12. Regional Privacy Rights'),
                    _buildSubSection('For EU/UK Users (GDPR)'),
                    _buildParagraph('Under GDPR, you have additional rights including the right to lodge a complaint with a supervisory authority.'),
                    _buildSubSection('For California Users (CCPA)'),
                    _buildParagraph('California residents have specific rights under the California Consumer Privacy Act. Contact us to exercise these rights.'),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text('Last Updated: December 17, 2025',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Version 1.0',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSubSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.6),
      ),
    );
  }

  Widget _buildRightCard(String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCardItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.5),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullets(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
            Expanded(
              child: Text(item, style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.5)),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
