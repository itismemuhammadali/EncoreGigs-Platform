import 'package:flutter/material.dart';
import 'widgets/remove_confirm_dialog.dart';

class PaymentMethodDetailScreen extends StatelessWidget {
  final String cardType;
  final String lastFour;
  final String cardHolder;
  final String expiry;
  final bool isDefault;

  const PaymentMethodDetailScreen({
    super.key,
    required this.cardType,
    required this.lastFour,
    required this.cardHolder,
    required this.expiry,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0x4DA2F301), height: 1),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text('Payment Method',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFA2F301), width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.credit_card, color: Color(0xFFA2F301), size: 18),
                        ),
                        Text(cardType,
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '•••• •••• •••• $lastFour',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Card Holder',
                                style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(cardHolder,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Expires',
                                style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(expiry,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isDefault)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.star, color: Color(0xFFA2F301), size: 18),
                    SizedBox(width: 6),
                    Text('Default Payment Method',
                        style: TextStyle(
                            color: Color(0xFFA2F301), fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              const SizedBox(height: 16),
              // Remove button
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => RemoveConfirmDialog(
                    title: 'Remove?',
                    message: 'Are you sure you want to remove this payment method? This action cannot be undone.',
                    confirmLabel: 'Yes, Remove Card',
                    onConfirm: () => Navigator.of(context).pop(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Color(0xFFFF3B30), size: 18),
                      SizedBox(width: 8),
                      Text('Remove Card',
                          style: TextStyle(
                              color: Color(0xFFFF3B30), fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'This card will be used to add funds to your wallet. You can change your default payment method at any time.',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
