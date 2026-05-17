import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FeaturedSuccessScreen extends StatefulWidget {
  final String duration;

  const FeaturedSuccessScreen({super.key, required this.duration});

  @override
  State<FeaturedSuccessScreen> createState() => _FeaturedSuccessScreenState();
}

class _FeaturedSuccessScreenState extends State<FeaturedSuccessScreen> {
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 3; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown = i - 1);
    }
    if (mounted) _goToProfile();
  }

  void _goToProfile() {
    Navigator.of(context).pushNamedAndRemoveUntil('/profile', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon stack
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer dark circle
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Green circle with checkmark
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA1F301),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, color: Colors.black, size: 52),
                      ),
                      // Crown badge top right
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0B100),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 18, height: 18,
                              child: SvgPicture.asset(
                                'assets/crown_icon.svg',
                                fit: BoxFit.contain,
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'You\'re Featured! 🎉',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'Your profile is now featured for ${widget.duration}. Get ready for more visibility and gig opportunities!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF999999), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 28),

                // Now Active card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Now Active:',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildActiveRow('Top search visibility'),
                      _buildActiveRow('Featured badge on profile'),
                      _buildActiveRow('3x more gig invitations'),
                      _buildActiveRow('Priority support'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Go to Profile button
                GestureDetector(
                  onTap: _goToProfile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1F301),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: SvgPicture.asset('assets/crown_icon.svg', fit: BoxFit.contain,
                              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                        ),
                        const SizedBox(width: 8),
                        const Text('Go to Profile',
                            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Countdown
                Text(
                  _countdown > 0
                      ? 'Redirecting automatically in $_countdown seconds...'
                      : 'Redirecting...',
                  style: const TextStyle(color: Color(0xFF555555), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFFA1F301), size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}
