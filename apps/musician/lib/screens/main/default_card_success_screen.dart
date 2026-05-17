import 'package:flutter/material.dart';
import 'dart:async';

class DefaultCardSuccessScreen extends StatefulWidget {
  final String cardName;
  const DefaultCardSuccessScreen({super.key, required this.cardName});

  @override
  State<DefaultCardSuccessScreen> createState() => _DefaultCardSuccessScreenState();
}

class _DefaultCardSuccessScreenState extends State<DefaultCardSuccessScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

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
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFFA1F301), size: 52),
              ),
              const SizedBox(height: 32),
              const Text(
                'Default Card Updated!',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.cardName} has been set as your default payment method.',
                style: TextStyle(color: Colors.grey[400], fontSize: 15, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("What's Next", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.credit_card, 'This card will be used for all future transactions'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.sync, 'Your previous default card has been updated'),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.schedule, 'Redirecting you back in a moment...'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFA1F301), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5)),
        ),
      ],
    );
  }
}
