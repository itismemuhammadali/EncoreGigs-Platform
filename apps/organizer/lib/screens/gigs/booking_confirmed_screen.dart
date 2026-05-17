import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingConfirmedScreen extends StatefulWidget {
  final String musicianName;
  final String gigTitle;

  const BookingConfirmedScreen({
    super.key,
    required this.musicianName,
    required this.gigTitle,
  });

  @override
  State<BookingConfirmedScreen> createState() => _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState extends State<BookingConfirmedScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
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
                'Booking Sent!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your booking request for ${widget.musicianName} has been sent. Waiting for musician to sign the agreement.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Color(0xFF888888), fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
