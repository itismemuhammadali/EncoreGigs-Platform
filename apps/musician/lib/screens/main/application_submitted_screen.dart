import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ApplicationSubmittedScreen extends StatefulWidget {
  final bool returnToBookings;
  const ApplicationSubmittedScreen({super.key, this.returnToBookings = false});

  @override
  State<ApplicationSubmittedScreen> createState() => _ApplicationSubmittedScreenState();
}

class _ApplicationSubmittedScreenState extends State<ApplicationSubmittedScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        if (widget.returnToBookings) {
          // Pop success screen, then pop booking detail screen to return to bookings list
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil('/applications', (route) => false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Back button row with bottom border
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Centered content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Application Submitted!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Your application has been sent to the organizer. You\'ll be notified when they respond.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Green glow checkmark circle
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 90,
                        height: 90,
                        child: SvgPicture.asset(
                          'assets/tick_circle_outine_icon.svg',
                          fit: BoxFit.contain,
                          colorFilter: const ColorFilter.mode(
                            Color(0xFFA1F301),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
