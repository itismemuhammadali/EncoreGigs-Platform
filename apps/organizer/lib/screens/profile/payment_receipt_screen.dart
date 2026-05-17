import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaymentReceiptScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final String date;
  final String amount;
  final String status;
  final bool isIncoming;

  const PaymentReceiptScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.date,
    required this.amount,
    required this.status,
    this.isIncoming = false,
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
        title: const Text('Payment Receipt',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt ID banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0x1AA1F301), Color(0x0DA1F301)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DA2F301)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt ID',
                        style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    SizedBox(height: 4),
                    Text('RCP-00000001',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Main receipt card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            imagePath,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2A2A2F),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: const TextStyle(
                                    color: Color(0xFF888888), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF2A2A2F), height: 1),
                    const SizedBox(height: 16),
                    _infoRow('Date & Time', date),
                    const SizedBox(height: 12),
                    _infoRow('Transaction Type', isIncoming ? 'Refund' : 'Payment'),
                    const SizedBox(height: 12),
                    _infoRow('Payment Method', 'Escrow Account'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(status).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2A2A2F), height: 1),
                    const SizedBox(height: 16),
                    // Amount breakdown
                    _amountRow('Subtotal', amount.replaceAll('-', '').replaceAll('+', '')),
                    const SizedBox(height: 10),
                    _amountRow('Platform Fee', '\$0.00'),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF2A2A2F), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text(
                          isIncoming ? '+${amount.replaceAll('+', '')}' : '-${amount.replaceAll('-', '')}',
                          style: TextStyle(
                            color: isIncoming
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF3B30),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Paid by card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paid by',
                        style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    SizedBox(height: 6),
                    Text('Blue Note Entertainment',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('131 West 3rd Street, New York, NY',
                        style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA2F301),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset('assets/download_icon.svg',
                                width: 16, height: 16,
                                colorFilter: const ColorFilter.mode(
                                    Colors.black, BlendMode.srcIn)),
                            const SizedBox(width: 8),
                            const Text('Download PDF',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Close',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'This is an official payment receipt from OnlyGigz Platform',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF555555), fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _amountRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4A9EFF);
      case 'pending':
        return const Color(0xFFFF8C00);
      default:
        return const Color(0xFF888888);
    }
  }
}
