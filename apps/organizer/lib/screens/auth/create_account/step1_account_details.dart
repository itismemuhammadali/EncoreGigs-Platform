import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/signup_provider.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _organizationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_nameController.text.isEmpty ||
        _organizationController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
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

    Provider.of<SignUpProvider>(context, listen: false).updateStep1(
      name: _nameController.text.trim(),
      orgName: _organizationController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    Navigator.of(context).pushNamed('/signup/step2');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 32),
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              _buildTextField(_nameController, 'Your full name'),
              const SizedBox(height: 20),
              _buildLabel('Organization Name'),
              const SizedBox(height: 8),
              _buildTextField(_organizationController, 'Your company or venue'),
              const SizedBox(height: 20),
              _buildLabel('Email Address'),
              const SizedBox(height: 8),
              _buildTextField(_emailController, 'your@email.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildLabel('Password'),
              const SizedBox(height: 8),
              _buildTextField(
                _passwordController,
                'Create a password',
                obscure: _obscurePassword,
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
                toggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildNextButton(
        onTap: _handleNext,
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
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: const Color(0xFF1A1A1F),
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

  Widget _buildNextButton({required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: GestureDetector(
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
      ),
    );
  }
}
