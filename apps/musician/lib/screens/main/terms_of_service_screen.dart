import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SubsectionData {
  final String number;
  final String title;
  final String content;

  SubsectionData({
    required this.number,
    required this.title,
    required this.content,
  });
}

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Header with title and PDF button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 38,
                              height: 38,
                              child: SvgPicture.asset(
                                'assets/privacyterm.svg',
                                fit: BoxFit.contain,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFA1F301),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Terms of Service',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Last updated: Dec 17, 2025',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/download_icon.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Introduction
                    _buildSection(
                      number: '1',
                      title: 'Introduction',
                      content:
                          'Welcome to GigHub ("we," "our," or "us"). These Terms of Service ("Terms") govern your access to and use of our platform, including our website, mobile application, and any related services (collectively, the "Service"). By accessing or using the Service, you agree to be bound by these Terms.',
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Acceptance of Terms
                    _buildSection(
                      number: '2',
                      title: 'Acceptance of Terms',
                      content:
                          'By creating an account or using our Service, you acknowledge that you have read, understood, and agree to be bound by these Terms and our Privacy Policy. If you do not agree to these Terms, you may not access or use the Service.',
                      bulletPoints: [
                        'You must be at least 18 years old to use this Service',
                        'You must provide accurate and complete information',
                        'You are responsible for maintaining account security',
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 3: User Accounts
                    _buildSectionPlainText(
                      number: '3',
                      title: 'User Accounts',
                      content:
                          'To access certain features of the Service, you must create an account. You agree to:',
                      bulletPoints: [
                        '3.1. Provide accurate, current, and complete information during registration',
                        '3.2. Maintain and promptly update your account information',
                        '3.3. Maintain the security of your password and accept all risks of unauthorized access',
                        '3.4. Notify us immediately of any unauthorized use of your account',
                        '3.5. Not create multiple accounts or impersonate others',
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Platform Services
                    _buildSectionPlainText(
                      number: '4',
                      title: 'Platform Services',
                      content:
                          'GigHub provides a marketplace platform connecting musicians and event organizers. The platform facilitates:',
                      bulletPoints: [
                        'For Musicians: Portfolio management, gig discovery, application submission, contract management, and payment processing',
                        'For Organizers: Musician discovery, application review, contract creation, and booking management',
                        'Communication: Secure messaging between parties',
                        'Payments: Payment processing and escrow services',
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Payments and Fees
                    _buildSection(
                      number: '5',
                      title: 'Payments and Fees',
                      content:
                          'GigHub charges a service fee on completed bookings. The current fee structure is:',
                      bulletPoints: [
                        'Musicians: 10% service fee on earnings',
                        'Organizers: 5% booking fee',
                        'Premium subscriptions available with reduced fees',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSubSection(
                      number: '5.1',
                      title: 'Payment Processing',
                      content:
                          'All payments are processed securely through our payment partners. You agree to provide valid payment information and authorize charges.',
                    ),
                    const SizedBox(height: 12),
                    _buildSubSection(
                      number: '5.2',
                      title: 'Refunds',
                      content:
                          'Refunds are outlined in individual contracts and booking agreements.',
                    ),
                    const SizedBox(height: 24),

                    // Section 6: User Conduct
                    _buildSectionPlainText(
                      number: '6',
                      title: 'User Conduct',
                      content: 'You agree not to:',
                      bulletPoints: [
                        'Violate any laws or regulations',
                        'Infringe on intellectual property rights',
                        'Post false, misleading, or fraudulent content',
                        'Harass, abuse, or harm other users',
                        'Attempt to circumvent platform fees',
                        'Use automated systems to access the Service',
                        'Interfere with or disrupt the Service',
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 7: Contracts and Bookings
                    _buildSectionWithSubsections(
                      number: '7',
                      title: 'Contracts and Bookings',
                      subsections: [
                        SubsectionData(
                          number: '7.1',
                          title: 'Contracts and Bookings',
                          content:
                              'All bookings are governed by individual contracts between musicians and organizers. GigHub is not a party to these contracts but provides the platform for their creation and execution.',
                        ),
                        SubsectionData(
                          number: '7.2',
                          title: 'Digital Signatures',
                          content:
                              'Digital signatures executed through the platform are legally binding and have the same effect as handwritten signatures.',
                        ),
                        SubsectionData(
                          number: '7.3',
                          title: 'Cancellation Policies',
                          content:
                              'Cancellation policies are defined in individual contracts. Both parties must honor agreed-upon terms.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 8: Intellectual Property
                    _buildSectionWithSubsections(
                      number: '8',
                      title: 'Intellectual Property',
                      subsections: [
                        SubsectionData(
                          number: '8.1',
                          title: 'Content Ownership',
                          content:
                              'You retain ownership of content you upload to the platform (portfolio items, profile information, etc.).',
                        ),
                        SubsectionData(
                          number: '8.2',
                          title: 'License Grant',
                          content:
                              'By uploading content, you grant GigHub a worldwide, non-exclusive license to use, display, and distribute your content solely for the purpose of operating and promoting the Service.',
                        ),
                        SubsectionData(
                          number: '8.3',
                          title: 'GigHub Trademarks',
                          content:
                              'The GigHub name, logo, and all related marks are trademarks of GigHub. You may not use these without permission.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 9: Limitation of Liability
                    _buildSection(
                      number: '9',
                      title: 'Limitation of Liability',
                      content:
                          'TO THE MAXIMUM EXTENT PERMITTED BY LAW, GIGHUB SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'GigHub is a platform provider and is not responsible for the actions, conduct, or quality of service provided by users. We do not guarantee the accuracy of user-provided information.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 10: Termination
                    _buildSection(
                      number: '10',
                      title: 'Termination',
                      content:
                          'We reserve the right to suspend or terminate your account at any time for violation of these Terms or for any other reason at our discretion. You may terminate your account at any time through your account settings.\nUpon termination, your right to use the Service will immediately cease. Provisions that by their nature should survive termination shall survive.',
                    ),
                    const SizedBox(height: 24),

                    // Section 11: Changes to Terms
                    _buildSection(
                      number: '11',
                      title: 'Changes to Terms',
                      content:
                          'We reserve the right to modify these Terms at any time. We will notify you of material changes via email or through the Service. Your continued use of the Service after such modifications constitutes acceptance of the updated Terms.',
                    ),
                    const SizedBox(height: 24),

                    // Section 12: Contact Information
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('12. ', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Contact Information', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('For questions about these Terms, please contact us:', style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.6)),
                              const SizedBox(height: 12),
                              Text('Email: legal@gighub.com', style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.6)),
                              const SizedBox(height: 8),
                              Text('Address: 123 Music Ave, New York, NY 10001', style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.6)),
                              const SizedBox(height: 8),
                              Text('Phone: +1 (555) 123-4567', style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.6)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Last Updated: December 17, 2025',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Version 1.0',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildSectionWithSubsections({
    required String number,
    required String title,
    required List<SubsectionData> subsections,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$number. ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subsections
              .map((sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sub.number}. ${sub.title}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sub.content,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSubSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. $title',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
    List<String>? bulletPoints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$number. ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
              children: bulletPoints
                  .map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '•',
                              style: const TextStyle(
                                color: Color(0xFFA1F301),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                point,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ] else ...[
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionPlainText({
    required String number,
    required String title,
    required String content,
    List<String>? bulletPoints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$number. ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            height: 1.6,
          ),
        ),
        if (bulletPoints != null && bulletPoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: bulletPoints
                .map((point) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        point,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}
