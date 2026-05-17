import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GigPostedScreen extends StatefulWidget {
  final bool returnToGigs;

  const GigPostedScreen({super.key, this.returnToGigs = false});

  @override
  State<GigPostedScreen> createState() => _GigPostedScreenState();
}

class _GigPostedScreenState extends State<GigPostedScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        // Pop back to either home or gigs screen
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
                  width: 52,
                  height: 52,
                  colorFilter: const ColorFilter.mode(
                      Color(0xFFA2F301), BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Gig Posted Successfully!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Musicians will start applying soon',
              style: TextStyle(color: Color(0xFF888888), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
