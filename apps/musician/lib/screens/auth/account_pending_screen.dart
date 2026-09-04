import 'package:flutter/material.dart';

class AccountPendingScreen extends StatelessWidget {
  const AccountPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFFA1F301),
                  size: 40,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Account Pending Approval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your musician profile has been submitted for review. Our admin team will verify your information and approve your account within 24-48 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    _InfoRow(
                      title: "You'll be notified via Email",
                      description:
                          "We'll send an automated approval email once your account is verified",
                    ),
                    SizedBox(height: 20),
                    _InfoRow(
                      title: "What's next?",
                      description:
                          "Once approved, you can log in, apply to musician gigs, connect with organizers, and receive payments",
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1F301),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Go back to login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String description;

  const _InfoRow({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline,
            color: Color(0xFFA1F301), size: 22),
        const SizedBox(width: 12),
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
                description,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
