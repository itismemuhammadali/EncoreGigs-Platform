import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/signup_provider.dart';
import '../../../services/auth_service.dart';

class Step3Verification extends StatefulWidget {
  const Step3Verification({super.key});

  @override
  State<Step3Verification> createState() => _Step3VerificationState();
}

class _Step3VerificationState extends State<Step3Verification> {
  final _bioController = TextEditingController();
  bool _acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleComplete() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms & Conditions')),
      );
      return;
    }

    if (_bioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a brief bio')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final signUpProvider = Provider.of<SignUpProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      signUpProvider.updateStep3(bio: _bioController.text.trim());

      final error = await authService.signUp(
        email: signUpProvider.email,
        password: signUpProvider.password,
        name: signUpProvider.name,
        orgName: signUpProvider.orgName,
        type: signUpProvider.type,
        contact: signUpProvider.contact,
        location: signUpProvider.location,
        bio: signUpProvider.bio,
      );

      if (!mounted) return;

      if (error == null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/signup/pending', (route) => false);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An unexpected error occurred: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
                'Verification & Submission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Almost there!',
                style: TextStyle(color: Color(0xFF999999), fontSize: 14),
              ),
              const SizedBox(height: 32),
              const Text(
                'About Organizer / Venue',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Brief description of your organization or venue...',
                  hintStyle: const TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _acceptedTerms = !_acceptedTerms),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _acceptedTerms
                                ? const Color(0xFFA2F301)
                                : const Color(0xFF555555),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          color: _acceptedTerms
                              ? const Color(0xFFA2F301)
                              : Colors.transparent,
                        ),
                        child: _acceptedTerms
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.black)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: const TextSpan(
                          style:
                              TextStyle(color: Color(0xFF999999), fontSize: 13),
                          children: [
                            TextSpan(text: 'I accept the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(color: Color(0xFFA2F301)),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(color: Color(0xFFA2F301)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: GestureDetector(
          onTap: _isLoading ? null : _handleComplete,
          child: Container(
            width: double.infinity,
            height: 56, // Added fixed height
            decoration: BoxDecoration(
              color: const Color(0xFFA2F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'Profile Completed',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
