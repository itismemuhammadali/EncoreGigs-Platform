import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContractSuccessScreen extends StatefulWidget {
  final String gigTitle;

  const ContractSuccessScreen({super.key, required this.gigTitle});

  @override
  State<ContractSuccessScreen> createState() => _ContractSuccessScreenState();
}

class _ContractSuccessScreenState extends State<ContractSuccessScreen> {
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
    if (mounted) _goToBookings();
  }

  void _goToBookings() {
    Navigator.of(context).pushNamedAndRemoveUntil('/bookings', (route) => false);
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
                // Icon
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA1F301),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.black, size: 56),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E2D0E),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/application_icon.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFFA1F301), BlendMode.srcIn),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Contract Signed! 🎉',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'You\'ve successfully signed the contract for "${widget.gigTitle}". Your gig is now confirmed!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF999999), fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 28),

                // What's next card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                        width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('What\'s Next:',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildRow('Payment is now held in escrow'),
                      _buildRow('Organizer has been notified'),
                      _buildRow('Check your bookings for details'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Go to Bookings button
                GestureDetector(
                  onTap: _goToBookings,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1F301),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.black, size: 20),
                        SizedBox(width: 8),
                        Text('Go to Bookings',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

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

  Widget _buildRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFFA1F301), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
