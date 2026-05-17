import 'package:flutter/material.dart';

class PayoutSuccessScreen extends StatefulWidget {
  const PayoutSuccessScreen({super.key});

  @override
  State<PayoutSuccessScreen> createState() => _PayoutSuccessScreenState();
}

class _PayoutSuccessScreenState extends State<PayoutSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Request Payout', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Withdraw your available earnings', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: const Color(0xFFA1F301).withValues(alpha: 0.3)),

            // Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Icon
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFA1F301).withValues(alpha: 0.3),
                          const Color(0xFF6B21A8).withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFA1F301),
                          ),
                          child: const Icon(Icons.check, color: Colors.black, size: 80),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFA1F301),
                            ),
                            child: const Icon(Icons.attach_money, color: Colors.black, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Success Message
                  const Text(
                    'Payout Requested! 🎉',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Your payout request of has been submitted successfully. ',
                          style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
                        ),
                        TextSpan(
                          text: '\$240',
                          style: TextStyle(color: Color(0xFFA1F301), fontSize: 15, fontWeight: FontWeight.bold, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // What's Next Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('What\'s Next:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildNextStep(Icons.calendar_today, 'Processing Time', '1-3 business days'),
                        const SizedBox(height: 16),
                        _buildNextStep(Icons.credit_card, 'Destination', 'Visa •••• 4242'),
                        const SizedBox(height: 16),
                        _buildNextStep(Icons.mail_outline, 'Email Confirmation', 'Sent to your email'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Back to Wallet', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.black, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Redirecting automatically in 3 seconds...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStep(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFA1F301).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFA1F301), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
