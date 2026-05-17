import 'package:flutter/material.dart';
import 'payout_success_screen.dart';

class RequestPayoutScreen extends StatefulWidget {
  const RequestPayoutScreen({super.key});

  @override
  State<RequestPayoutScreen> createState() => _RequestPayoutScreenState();
}

class _RequestPayoutScreenState extends State<RequestPayoutScreen> {
  final _amountController = TextEditingController();
  String _selectedDestination = 'visa';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
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

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Available Balance Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131F),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available Balance', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('717.51', style: TextStyle(color: Color(0xFFA1F301), fontSize: 32, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.attach_money, color: Color(0xFFA1F301), size: 28),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payout Amount
                    const Text('Payout Amount', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2B1A),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          prefixStyle: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          hintText: '240',
                          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 24),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Text('Request Full Amount', style: TextStyle(color: Color(0xFFA1F301), fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        Text('Min: \$10.00', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Payout Destination
                    const Text('Payout Destination', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildDestinationOption('visa', 'Visa', '•••• 4242', Icons.credit_card),
                    const SizedBox(height: 12),
                    _buildDestinationOption('mastercard', 'Mastercard', '•••• 5555', Icons.credit_card),
                    const SizedBox(height: 12),
                    _buildDestinationOption('bank', 'Bank Account', '•••• 6789', Icons.account_balance),
                    const SizedBox(height: 24),

                    // Processing Time Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D4A1F).withValues(alpha: 0.4),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.4), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: const Color(0xFFA1F301), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Processing Time', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  'Payouts typically arrive within 1-3 business days. A processing fee of 2.5% will be deducted.',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payout Summary
                    const Text('Payout Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131F),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Requested Amount', '\$2400.00', Colors.white),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Processing Fee (2.5%)', '-\$60.00', const Color(0xFFEF4444)),
                          const SizedBox(height: 16),
                          Container(height: 1, color: Colors.grey[800]),
                          const SizedBox(height: 16),
                          _buildSummaryRow('You\'ll Receive', '\$2340.00', const Color(0xFFA1F301), isBold: true, isLarge: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PayoutSuccessScreen())),
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
                      Icon(Icons.credit_card, color: Colors.black, size: 20),
                      SizedBox(width: 8),
                      Text('Confirm Payout Request', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationOption(String id, String title, String number, IconData icon) {
    final isSelected = _selectedDestination == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedDestination = id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFFA1F301) : Colors.grey[800]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFA1F301).withValues(alpha: 0.2) : Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? const Color(0xFFA1F301) : Colors.grey[600], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(number, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFA1F301) : Colors.grey[600]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFA1F301) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, color: Colors.black, size: 12),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String amount, Color amountColor, {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.grey[400], fontSize: isLarge ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(amount, style: TextStyle(color: amountColor, fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
