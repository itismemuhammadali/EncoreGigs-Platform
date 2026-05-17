import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'contract_screen.dart';
import '../profile/wallet_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String musicianId;
  final String musicianName;
  final String musicianImage;
  final String gigId;
  final String gigTitle;
  final String gigDate;
  final String gigTime;
  final String? gigDuration;
  final double amount;
  final double walletBalance;
  final String? location;
  final String? organizerName;

  const PaymentScreen({
    super.key,
    required this.musicianId,
    required this.musicianName,
    required this.musicianImage,
    required this.gigId,
    required this.gigTitle,
    required this.gigDate,
    required this.gigTime,
    this.gigDuration,
    required this.amount,
    required this.walletBalance,
    this.location,
    this.organizerName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double _currentBalance = 0;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.walletBalance;
  }

  bool get _hasSufficientFunds => _currentBalance >= widget.amount;

  Widget _placeholderImage() {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2F),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }

  bool _isNetworkImage(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String _getTimeRange() {
    if (widget.gigTime == 'TBD') return 'TBD';
    if (widget.gigDuration == null || widget.gigDuration!.isEmpty) return widget.gigTime;

    try {
      // Try to parse start time (e.g., "1:00 PM" or "1 PM")
      final timeStr = widget.gigTime.toUpperCase().trim();
      final DateFormat inputFormat = DateFormat.jm();
      DateTime startTime;
      
      try {
        startTime = inputFormat.parse(timeStr);
      } catch (e) {
        // Fallback for formats like "1 PM"
        if (RegExp(r'^\d+\s*(AM|PM)$').hasMatch(timeStr)) {
          final ampm = timeStr.contains('PM') ? 'PM' : 'AM';
          final hour = timeStr.replaceAll(RegExp(r'[^0-9]'), '');
          startTime = inputFormat.parse('$hour:00 $ampm');
        } else {
          return '${widget.gigTime} (${widget.gigDuration})';
        }
      }

      // Try to extract hours from duration (e.g., "2 hours", "3 sets...")
      final durationMatch = RegExp(r'(\d+)\s*(hour|hr|h)', caseSensitive: false).firstMatch(widget.gigDuration!);
      if (durationMatch != null) {
        final hours = int.parse(durationMatch.group(1)!);
        final endTime = startTime.add(Duration(hours: hours));
        // Use lowercase for am/pm to match user request "1pm to 3pm"
        final format = DateFormat('h a');
        return '${format.format(startTime).toLowerCase()} to ${format.format(endTime).toLowerCase()}';
      }
      
      return '${widget.gigTime} (${widget.gigDuration})';
    } catch (e) {
      debugPrint('Error calculating time range: $e');
      return '${widget.gigTime} (${widget.gigDuration})';
    }
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text('Payment',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA2F301),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('1',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Payment',
                          style: TextStyle(
                              color: Color(0xFFA2F301), fontSize: 11)),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: const Color(0xFF2A2A2F),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0x992A2A2F),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF444444)),
                        ),
                        child: const Center(
                          child: Text('2',
                              style: TextStyle(
                                  color: Color(0x99FFFFFF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Contract',
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Musician info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _isNetworkImage(widget.musicianImage)
                            ? Image.network(
                                widget.musicianImage,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _placeholderImage(),
                              )
                            : Image.asset(
                                widget.musicianImage,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _placeholderImage(),
                              ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.musicianName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(widget.gigTitle,
                                style: const TextStyle(
                                    color: Color(0xFF888888), fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SvgPicture.asset('assets/bookings_icon.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                                Color(0xFF888888), BlendMode.srcIn)),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.gigDate} • ${_getTimeRange()}',
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        SvgPicture.asset('assets/location_pointer.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                                Color(0xFF888888), BlendMode.srcIn)),
                        const SizedBox(width: 6),
                        Text(widget.location ?? 'Unknown Location',
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Payment amount
              const Text('Payment Amount',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money,
                        color: Color(0xFF888888), size: 20),
                    const SizedBox(width: 8),
                    Text('${widget.amount.toInt()}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text('Amount will be held in escrow until gig completion',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
              const SizedBox(height: 20),
              // Wallet balance
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset('assets/wallet_icon.svg',
                                width: 18,
                                height: 18,
                                colorFilter: const ColorFilter.mode(
                                    Color(0xFFA2F301), BlendMode.srcIn)),
                            const SizedBox(width: 10),
                            const Text('Wallet Balance',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        Text(
                          '\$${_currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFA2F301),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (!_hasSufficientFunds) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A0A0A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x4DFF3B30)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFFF3B30), size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Insufficient funds. You need \$${(widget.amount - _currentBalance).toStringAsFixed(2)} more.',
                                  style: const TextStyle(
                                      color: Color(0xFFFF3B30), fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const WalletScreen(),
                                  ),
                                );
                                // Simulate funds added on return
                                setState(() {
                                  _currentBalance = widget.amount + 1000;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('Add Funds to Wallet',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Fee breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _feeRow('Performance Fee',
                        '\$${widget.amount.toInt()}', false),
                    const SizedBox(height: 12),
                    _feeRow('Platform Fee', '\$0.00', false),
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFF2A2A2F), height: 1),
                    const SizedBox(height: 12),
                    _feeRow('Total', '\$${widget.amount.toInt()}', true),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        child: GestureDetector(
          onTap: _hasSufficientFunds
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ContractScreen(
                      musicianId: widget.musicianId,
                      musicianName: widget.musicianName,
                      musicianImage: widget.musicianImage,
                      gigId: widget.gigId,
                      gigTitle: widget.gigTitle,
                      gigDate: widget.gigDate,
                      gigTime: widget.gigTime,
                      gigDuration: widget.gigDuration,
                      amount: widget.amount,
                      location: widget.location,
                      organizerName: widget.organizerName,
                    ),
                  ))
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _hasSufficientFunds
                  ? const Color(0xFFA2F301)
                  : const Color(0x4DA1F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Proceed to Contract',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _hasSufficientFunds ? Colors.black : const Color(0xFF666666),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _feeRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isTotal ? Colors.white : const Color(0xFF888888),
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400)),
        Text(value,
            style: TextStyle(
                color: isTotal ? const Color(0xFFA2F301) : Colors.white,
                fontSize: isTotal ? 20 : 14,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400)),
      ],
    );
  }
}
