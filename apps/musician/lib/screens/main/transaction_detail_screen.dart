import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String date;
  final String time;
  final String amount;
  final Color amountColor;
  final String? status;

  const TransactionDetailScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.date,
    required this.time,
    required this.amount,
    required this.amountColor,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncoming = amount.startsWith('+');

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
                  const Text('Transaction Details', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: const Color(0xFFA1F301).withValues(alpha: 0.3)),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Amount Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13131F),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            amount,
                            style: TextStyle(color: amountColor, fontSize: 40, fontWeight: FontWeight.bold),
                          ),
                          if (status != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C950).withValues(alpha: 0.15),
                                border: Border.all(color: const Color(0xFF00C950), width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(status!, style: const TextStyle(color: Color(0xFF00C950), fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Transaction Info
                    _buildInfoRow('Transaction ID', isIncoming ? 'TXN-WED-001' : 'TXN-FEE-001'),
                    _buildDivider(),
                    _buildInfoRow('Date', date),
                    _buildDivider(),
                    _buildInfoRow('Time', time),
                    _buildDivider(),
                    _buildInfoRow('Type', isIncoming ? 'Gig Payment' : 'Platform Fee'),
                    if (subtitle != null) ...[
                      _buildDivider(),
                      _buildInfoRow('From', subtitle!),
                    ],
                    const SizedBox(height: 28),

                    // Payment Breakdown
                    const Text('Payment Breakdown', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildBreakdownRow('Gross Amount', isIncoming ? '\$1200.00' : amount.replaceAll('-', ''), Colors.white),
                    const SizedBox(height: 12),
                    _buildBreakdownRow('Platform Fee', isIncoming ? '-\$60.00' : '—', const Color(0xFFEF4444)),
                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.grey[800]),
                    const SizedBox(height: 12),
                    _buildBreakdownRow('Net Amount', isIncoming ? '\$1140.00' : amount.replaceAll('-', ''), const Color(0xFF00C950), isBold: true),
                    const SizedBox(height: 28),

                    // Download Receipt Button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.grey[800]!, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/download_icon.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 10),
                            const Text('Download Receipt', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDivider() => Container(height: 1, color: Colors.grey[900]);

  Widget _buildBreakdownRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.grey[400], fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
