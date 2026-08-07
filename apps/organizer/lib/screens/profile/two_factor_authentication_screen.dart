import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TwoFactorAuthenticationScreen extends StatefulWidget {
  const TwoFactorAuthenticationScreen({super.key});

  @override
  State<TwoFactorAuthenticationScreen> createState() => _TwoFactorAuthenticationScreenState();
}

class _TwoFactorAuthenticationScreenState extends State<TwoFactorAuthenticationScreen> {
  bool is2FAEnabled = false;
  String? phoneNumber;
  String twoFactorMethod = 'sms';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('organizers').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          is2FAEnabled = data['is2FAEnabled'] ?? false;
          phoneNumber = data['phoneNumber'];
          twoFactorMethod = data['twoFactorMethod'] ?? 'sms';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectMethod(String method) async {
    if (method == 'sms' && (phoneNumber == null || phoneNumber!.isEmpty)) {
      setState(() => twoFactorMethod = 'sms');
      _showPhoneNumberDialog();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('organizers').doc(user.uid).set(
        {
          'twoFactorMethod': method,
        },
        SetOptions(merge: true),
      );
    }
    if (mounted) {
      setState(() {
        twoFactorMethod = method;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected 2FA method: ${method.toUpperCase()}')),
      );
    }
  }

  Future<void> _toggle2FA(bool value) async {
    if (value && twoFactorMethod == 'sms' && (phoneNumber == null || phoneNumber!.isEmpty)) {
      _showPhoneNumberDialog();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('organizers').doc(user.uid).set(
        {
          'is2FAEnabled': value,
          'twoFactorMethod': twoFactorMethod,
        },
        SetOptions(merge: true),
      );
      if (mounted) {
        setState(() {
          is2FAEnabled = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(value ? '2FA Enabled with ${twoFactorMethod.toUpperCase()}' : '2FA Disabled')),
        );
      }
    }
  }

  Future<void> _showPhoneNumberDialog() async {
    final controller = TextEditingController(text: phoneNumber);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A24),
        title: const Text('Add Phone Number', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '+1 234 567 8900',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA1F301))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFA1F301))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null && controller.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('organizers').doc(user.uid).set(
                  {
                    'phoneNumber': controller.text,
                    'is2FAEnabled': true,
                    'twoFactorMethod': twoFactorMethod,
                  },
                  SetOptions(merge: true),
                );
                if (mounted) {
                  setState(() {
                    phoneNumber = controller.text;
                    is2FAEnabled = true;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone number saved and 2FA Enabled with ${twoFactorMethod.toUpperCase()}')),
                  );
                }
              }
            },
            child: const Text('Save & Enable', style: TextStyle(color: Color(0xFFA1F301))),
          ),
        ],
      ),
    );
  }
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
                      'Two-Factor Authentication',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add an extra layer of security',
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
                    // 2FA Status Card
                    if (is2FAEnabled)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.1),
                          border: Border.all(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: SvgPicture.asset(
                                    'assets/tick_icon.svg',
                                    fit: BoxFit.contain,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '2FA is Enabled',
                                    style: TextStyle(
                                      color: Color(0xFFA1F301),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your account is protected with two-factor authentication',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      twoFactorMethod == 'email'
                                          ? 'Active method: Email to ${FirebaseAuth.instance.currentUser?.email ?? "your email"}'
                                          : 'Active method: SMS to ${phoneNumber ?? "your phone"}',
                                      style: TextStyle(
                                        color: Color(0xFFA1F301),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4D3D1F).withValues(alpha: 0.4),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.info,
                                  color: Colors.black,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '2FA is Disabled',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Enable 2FA to secure your account with an extra verification step',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    // How 2FA Works
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
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: SvgPicture.asset(
                                  'assets/shield_icon.svg',
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFFA1F301),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'How 2FA Works',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBulletPoint('When you sign in, you\'ll enter your password as usual'),
                          _buildBulletPoint('Then, you\'ll receive a verification code via your chosen method'),
                          _buildBulletPoint('Enter the code to complete the sign-in process'),
                          _buildBulletPoint('This ensures that only you can access your account'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Authentication Methods
                    const Text(
                      'Authentication Methods',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // SMS Authentication
                    GestureDetector(
                      onTap: () => _selectMethod('sms'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: twoFactorMethod == 'sms' ? const Color(0xFFA1F301) : const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: twoFactorMethod == 'sms' ? 2 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: twoFactorMethod == 'sms'
                                    ? const Icon(Icons.check_circle, color: Color(0xFFA1F301), size: 24)
                                    : const Icon(Icons.radio_button_unchecked, color: Color(0xFFA1F301), size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'SMS Authentication',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (twoFactorMethod == 'sms' && is2FAEnabled) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Active',
                                            style: TextStyle(
                                              color: Color(0xFFA1F301),
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
                                    'Receive verification codes via text message',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (phoneNumber != null && phoneNumber!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Phone: $phoneNumber',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Email Authentication
                    GestureDetector(
                      onTap: () => _selectMethod('email'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: twoFactorMethod == 'email' ? const Color(0xFF06B6D4) : const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: twoFactorMethod == 'email' ? 2 : 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: twoFactorMethod == 'email'
                                    ? const Icon(Icons.check_circle, color: Color(0xFF06B6D4), size: 24)
                                    : const Icon(Icons.radio_button_unchecked, color: Color(0xFF06B6D4), size: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Email Authentication',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (twoFactorMethod == 'email' && is2FAEnabled) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Active',
                                            style: TextStyle(
                                              color: Color(0xFF06B6D4),
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
                                    'Receive verification codes via email',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (FirebaseAuth.instance.currentUser?.email != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Email: ${FirebaseAuth.instance.currentUser?.email}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!is2FAEnabled) ...[
                      const SizedBox(height: 12),
                      // Backup Codes
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
                          children: [
                            const Text(
                              'Backup Codes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate backup codes to use when you can\'t access your phone or email. Store them securely.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Generate Backup Codes',
                                    style: TextStyle(
                                      color: Color(0xFFA1F301),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Bottom Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _toggle2FA(!is2FAEnabled),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: is2FAEnabled ? const Color(0xFFEF4444) : const Color(0xFFA1F301),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  is2FAEnabled ? 'Disable 2FA' : 'Enable 2FA',
                                  style: TextStyle(
                                    color: is2FAEnabled ? Colors.white : Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFA1F301),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
