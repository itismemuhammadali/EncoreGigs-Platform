import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReviewSubmittedScreen extends StatefulWidget {
  const ReviewSubmittedScreen({super.key});

  @override
  State<ReviewSubmittedScreen> createState() => _ReviewSubmittedScreenState();
}

class _ReviewSubmittedScreenState extends State<ReviewSubmittedScreen> {
  @override
  void initState() {
    super.initState();
    // Auto navigate back after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1F),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/tick_icon.svg',
                  width: 60,
                  height: 60,
                  colorFilter: const ColorFilter.mode(
                      Color(0xFFA2F301), BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Review Submitted!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thank you for your feedback',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
