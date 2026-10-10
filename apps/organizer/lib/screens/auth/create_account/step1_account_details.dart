import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_config/email_verification_dialog.dart';
import '../../../providers/signup_provider.dart';
import '../../../services/auth_service.dart';

class Step1AccountDetails extends StatefulWidget {
  const Step1AccountDetails({super.key});

  @override
  State<Step1AccountDetails> createState() => _Step1AccountDetailsState();
}

class _Step1AccountDetailsState extends State<Step1AccountDetails> {
  final _nameController = TextEditingController();
  final _organizationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSocialUser = false;
  bool _isLoadingSocial = false;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _isSocialUser = true;
      _nameController.text = currentUser.displayName ?? '';
      _emailController.text = currentUser.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialSignIn(String provider) async {
    setState(() => _isLoadingSocial = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = provider == 'google'
        ? await authService.signInWithGoogle()
        : await authService.signInWithApple();

    if (mounted) {
      setState(() => _isLoadingSocial = false);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (result == null && currentUser != null) {
        final userStatus = await authService.getUserStatus(currentUser.uid);
        if (!mounted) return;
        if (userStatus == 'pending' || userStatus == 'pending_approval') {
          Navigator.of(context).pushReplacementNamed('/account_pending');
          return;
        } else if (userStatus == 'rejected' || userStatus == 'denied') {
          Navigator.of(context).pushReplacementNamed('/account_denied');
          return;
        } else if (userStatus != 'incomplete') {
          Navigator.of(context).pushReplacementNamed('/home');
          return;
        }
      }

      if (currentUser != null) {
        setState(() {
          _isSocialUser = true;
          if (_nameController.text.trim().isEmpty) {
            _nameController.text = currentUser.displayName ?? '';
          }
          if (_emailController.text.trim().isEmpty) {
            _emailController.text = currentUser.email ?? '';
          }
        });
      } else if (result != null && result != 'new_user') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
      }
    }
  }

  void _handleNext() async {
    final missing = <String>[];
    if (_nameController.text.trim().isEmpty) missing.add('Full Name');
    if (_organizationController.text.trim().isEmpty) missing.add('Organization Name');
    if (_emailController.text.trim().isEmpty) missing.add('Email');

    // For social users (Google/Apple), password is not required
    if (!_isSocialUser) {
      if (_passwordController.text.isEmpty) missing.add('Password');
      if (_confirmPasswordController.text.isEmpty) missing.add('Confirm Password');
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in: ${missing.join(', ')}'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final email = _emailController.text.trim();

    if (_isSocialUser) {
      Provider.of<SignUpProvider>(context, listen: false).updateStep1(
        name: _nameController.text.trim(),
        orgName: _organizationController.text.trim(),
        email: email,
        password: '',
      );
      Navigator.of(context).pushNamed('/signup/step2');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final password = _passwordController.text;
    final errors = <String>[];
    if (!RegExp(r'[A-Z]').hasMatch(password)) errors.add('one uppercase letter');
    if (!RegExp(r'[a-z]').hasMatch(password)) errors.add('one lowercase letter');
    if (!RegExp(r'[0-9]').hasMatch(password)) errors.add('one number');
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(password)) errors.add('one special character');
    if (password.length < 8) errors.add('at least 8 characters');
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password must contain ${errors.join(', ')}')),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);

    final createError = await authService.createUser(email, _passwordController.text);
    if (!mounted) return;

    if (createError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(createError), backgroundColor: Colors.redAccent),
      );
      return;
    }

    Provider.of<SignUpProvider>(context, listen: false).updateStep1(
      name: _nameController.text.trim(),
      orgName: _organizationController.text.trim(),
      email: email,
      password: _passwordController.text,
    );

    showEmailVerificationDialog(
      context: context,
      email: email,
      onVerified: () {
        Navigator.of(context).pushNamed('/signup/step2');
      },
      onSendVerification: authService.sendVerificationEmail,
      onCheckVerification: authService.checkEmailVerification,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0A0F),
          elevation: 0,
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chevron_left, color: Colors.white),
            ),
          ),
          title: const Text(
            'Create Account',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Set up your organizer account',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 14),
                ),
                const SizedBox(height: 24),
                if (!_isSocialUser) ...[
                  _buildSocialButton(
                    iconPath: 'assets/google_icon.svg',
                    label: 'Sign up with Google',
                    onTap: _isLoadingSocial ? () {} : () => _handleSocialSignIn('google'),
                  ),
                  if (!kIsWeb && Platform.isIOS) ...[
                    const SizedBox(height: 12),
                    _buildSocialButton(
                      iconPath: 'assets/apple_icon.svg',
                      label: 'Sign up with Apple',
                      onTap: _isLoadingSocial ? () {} : () => _handleSocialSignIn('apple'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: const Color(0xFF2A2A2F))),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or with email',
                            style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                      ),
                      Expanded(child: Container(height: 1, color: const Color(0xFF2A2A2F))),
                    ],
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA2F301).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA2F301).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFFA2F301), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Authenticated via ${_emailController.text.isNotEmpty ? _emailController.text : "Social Account"}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                _buildTextField(_nameController, 'Your full name',
                    textInputAction: TextInputAction.next),
                const SizedBox(height: 20),
                _buildLabel('Organization Name'),
                const SizedBox(height: 8),
                _buildTextField(_organizationController, 'Your company or venue',
                    textInputAction: TextInputAction.next),
                const SizedBox(height: 20),
                _buildLabel('Email Address'),
                const SizedBox(height: 8),
                _buildTextField(
                  _emailController,
                  'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: _isSocialUser ? TextInputAction.done : TextInputAction.next,
                  readOnly: _isSocialUser,
                ),
                if (!_isSocialUser) ...[
                  const SizedBox(height: 20),
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _passwordController,
                    'Create a password',
                    obscure: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    toggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Confirm Password'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _confirmPasswordController,
                    'Re-enter password',
                    obscure: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    toggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ],
                const SizedBox(height: 32),
                _buildNextButton(onTap: _handleNext),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: readOnly ? const Color(0xFF141418) : const Color(0xFF1A1A1F),
        suffixIcon: toggleObscure != null
            ? GestureDetector(
                onTap: toggleObscure,
                child: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF666666),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2F)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(iconPath, width: 22, height: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFA2F301),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Next',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
