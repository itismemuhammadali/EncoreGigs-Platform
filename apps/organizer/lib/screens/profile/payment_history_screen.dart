import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'payment_receipt_screen.dart';

class PaymentModel {
  final String title;
  final String subtitle;
  final String amount;
  final String date;
  final String imagePath;
  final String status;
  final bool isIncoming;

  const PaymentModel({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.imagePath,
    required this.status,
    this.isIncoming = false,
  });
}

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<PaymentModel> _allPayments = [];
  double _totalPaid = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final organizerId = authService.currentUser?.uid;

      if (organizerId != null) {
        final transactions = await apiService.getTransactions(organizerId);
        final List<PaymentModel> parsed = [];
        double total = 0.0;

        for (final map in transactions) {
          final rawAmount = map['amount'];
          double amt = 0.0;
          if (rawAmount is num) {
            amt = (rawAmount / 100.0).abs();
          } else if (rawAmount is String) {
            amt = (double.tryParse(rawAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);
          }

          final type = (map['type'] ?? '').toString().toLowerCase();
          final status = (map['status'] ?? 'completed').toString().toLowerCase();
          final isRefund = type.contains('refund') || (map['isIncoming'] == true);

          if (!isRefund && (status == 'completed' || status == 'succeeded' || status == 'held')) {
            total += amt;
          }

          String dateStr = 'Recent';
          if (map['created'] != null && map['created'] is int) {
            final dt = DateTime.fromMillisecondsSinceEpoch((map['created'] as int) * 1000);
            dateStr = DateFormat('MMM d, yyyy • h:mm a').format(dt);
          } else if (map['createdAt'] != null) {
            try {
              final dt = DateTime.parse(map['createdAt'].toString());
              dateStr = DateFormat('MMM d, yyyy • h:mm a').format(dt);
            } catch (_) {}
          }

          final title = map['description'] ?? map['title'] ?? (isRefund ? 'Refund' : 'Payment');
          final subtitle = map['booking_id'] != null ? 'Booking #${map['booking_id']}' : (map['subtitle'] ?? 'Transaction');

          parsed.add(PaymentModel(
            title: title.toString(),
            subtitle: subtitle.toString(),
            amount: isRefund ? '+\$${amt.toStringAsFixed(2)}' : '-\$${amt.toStringAsFixed(2)}',
            date: dateStr,
            imagePath: 'assets/recent_activity_image1.jpg',
            status: status == 'succeeded' ? 'completed' : status,
            isIncoming: isRefund,
          ));
        }

        if (mounted) {
          setState(() {
            _allPayments = parsed;
            _totalPaid = total;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading payment history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PaymentModel> get _filtered {
    if (_selectedFilter == 'All') return _allPayments;
    if (_selectedFilter == 'Refunds') {
      return _allPayments.where((p) => p.isIncoming).toList();
    }
    return _allPayments
        .where((p) => p.status.toLowerCase() == _selectedFilter.toLowerCase())
        .toList();
  }

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
        title: const Text(
          'Payment History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Total paid banner
            Container(
              margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x1AA1F301),
                    Color(0x0DA1F301),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x4DA2F301)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Paid',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(_totalPaid)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/download_icon.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                                Color(0xFFA2F301), BlendMode.srcIn),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Export Report',
                            style: TextStyle(
                              color: Color(0xFFA2F301),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Completed', 'Pending', 'Refunds'].map((tab) {
                    final isActive = tab == _selectedFilter;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedFilter = tab),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isActive ? Colors.black : const Color(0xFF888888),
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Payment list or empty state
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFA2F301)),
                    )
                  : (_filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1F),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0x33A2F301)),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: Color(0xFFA2F301),
                                      size: 34,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'No Payment History',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Your completed payments, escrow holds, and refunds will appear here once you book musicians.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF888888),
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) =>
                              _PaymentCard(payment: _filtered[index]),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PaymentReceiptScreen(
          title: payment.title,
          subtitle: payment.subtitle,
          imagePath: payment.imagePath,
          date: payment.date,
          amount: payment.amount,
          status: payment.status,
          isIncoming: payment.isIncoming,
        ),
      )),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              payment.imagePath,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row with arrow and amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        payment.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      payment.isIncoming
                          ? Icons.call_received
                          : Icons.arrow_outward,
                      color: payment.isIncoming
                          ? const Color(0xFF4CAF50)
                          : payment.status == 'pending'
                              ? const Color(0xFFFF6900)
                              : const Color(0xFFFF3B30),
                      size: 21,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      payment.amount,
                      style: TextStyle(
                        color: payment.isIncoming
                            ? const Color(0xFF4CAF50)
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(payment.subtitle,
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(payment.date,
                        style: const TextStyle(color: Color(0xFF666666), fontSize: 14)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(payment.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(payment.status).withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            payment.status,
                            style: TextStyle(
                              color: _statusColor(payment.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (payment.status.toLowerCase() != 'pending') ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA2F301).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0x4DA2F301)),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/receipt_icon.svg',
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                    Color(0xFFA2F301), BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
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
