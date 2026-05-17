import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // Green glow gradient overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFA1F301).withValues(alpha: 0.1),
                  const Color(0xFF0A0A0F).withValues(alpha: 0.0),
                  const Color(0xFFA1F301).withValues(alpha: 0.1),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Logo
              Image.asset(
                'assets/Logo.png',
                height: 90,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to OnlyGigz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account',
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Email address',
                  hintStyle: const TextStyle(color: Color(0xFF666666)),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: Color(0xFF666666), size: 20),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFA2F301)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Color(0xFF666666)),
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Color(0xFF666666), size: 20),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF666666),
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2F)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2F)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFA2F301)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Sign in button
              GestureDetector(
                onTap: _isLoading ? null : _handleSignIn,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA2F301),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Text(
                          'Sign in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              // Divider
              Row(
                children: [
                  Expanded(
                      child: Container(height: 1, color: const Color(0xFF2A2A2F))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                  ),
                  Expanded(
                      child: Container(height: 1, color: const Color(0xFF2A2A2F))),
                ],
              ),
              const SizedBox(height: 24),
              // Social buttons
              _buildSocialButton(
                iconPath: 'assets/google_icon.svg',
                label: 'Continue with Google',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                icon: Icons.facebook,
                iconColor: const Color(0xFF1877F2),
                label: 'Continue with Facebook',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                iconPath: 'assets/apple_icon.svg',
                label: 'Continue with Apple',
                onTap: () {},
              ),
              const SizedBox(height: 48),
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF999999), fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/signup/step1'),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFFA2F301),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    String? iconPath,
    IconData? icon,
    Color? iconColor,
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
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              SvgPicture.asset(iconPath, width: 20, height: 20)
            else if (icon != null)
              Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
