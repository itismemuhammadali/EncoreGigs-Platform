import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'payout_success_screen.dart';

class RequestPayoutScreen extends StatefulWidget {
  const RequestPayoutScreen({super.key});

  @override
  State<RequestPayoutScreen> createState() => _RequestPayoutScreenState();
}

class _RequestPayoutScreenState extends State<RequestPayoutScreen> {
  final _amountController = TextEditingController();
  String? _selectedDestination;
  double _balance = 0.0;
  List<dynamic> _paymentMethods = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _connectedBankAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final musicianId = authService.currentUser?.uid;
    if (musicianId == null) return;

    // Fetch wallet data (cards)
    try {
      final walletData = await apiService.getWalletData(musicianId);
      _paymentMethods = walletData['payment_methods'] ?? [];
    } catch (e) {
      debugPrint('Error loading wallet: $e');
    }

    // Compute balance from wallet transactions
    try {
      final txSnap = await FirebaseFirestore.instance
          .collection('musicians')
          .doc(musicianId)
          .collection('wallet_transactions')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      _balance = 0.0;
      for (final doc in txSnap.docs) {
        final tx = doc.data();
        final amt = (tx['amount'] ?? 0).toDouble();
        _balance += amt;
      }
      if (_balance < 0) _balance = 0.0;
    } catch (e) {
      debugPrint('Error loading balance from transactions: $e');
    }

    // Fetch connected bank account directly from Firestore
    try {
      final musicianDoc = await FirebaseFirestore.instance.collection('musicians').doc(musicianId).get();
      final data = musicianDoc.data();
      final connectId = data?['stripe_connect_id'] ?? '';
      final status = data?['stripe_status'] ?? 'not_connected';
      if (connectId.isNotEmpty && status == 'active') {
        _connectedBankAccounts = [
          {'id': 'bank_account', 'bank_name': 'Connected Bank Account', 'last4': '****', 'type': 'bank_account'}
        ];
      }
    } catch (e) {
      debugPrint('Error loading bank account: $e');
    }

    // Set default destination to bank account if available, otherwise first card
    if (_connectedBankAccounts.isNotEmpty) {
      _selectedDestination = _connectedBankAccounts[0]['id'];
    } else if (_paymentMethods.isNotEmpty) {
      _selectedDestination = _paymentMethods[0]['id'];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _requestFullAmount() {
    setState(() {
      _amountController.text = _balance.toStringAsFixed(2);
    });
  }

  Future<void> _confirmPayout() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal is \$10.00')),
      );
      return;
    }
    if (amount > _balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payout destination')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final musicianId = authService.currentUser?.uid;
      if (musicianId == null) throw Exception('User not logged in');

      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.musicianPayout(musicianId, amount);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PayoutSuccessScreen(amount: amount)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payoutAmount = double.tryParse(_amountController.text) ?? 0;
    final fee = payoutAmount * 0.025;
    final netAmount = payoutAmount - fee;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Text('Withdraw your available earnings', style: TextStyle(color: Colors.grey[500]!, fontSize: 14)),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFA1F301).withValues(alpha: 0.3)),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Available Balance
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
                                    Text('Available Balance', style: TextStyle(color: Colors.grey[500]!, fontSize: 13)),
                                    const SizedBox(height: 8),
                                    Text('\$' + _balance.toStringAsFixed(2), style: const TextStyle(color: Color(0xFFA1F301), fontSize: 32, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  width: 48, height: 48,
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
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                prefixText: '\$ ',
                                prefixStyle: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                hintText: '0.00',
                                hintStyle: TextStyle(color: Colors.grey[600]!, fontSize: 24),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: _requestFullAmount,
                                child: const Text('Request Full Amount', style: TextStyle(color: Color(0xFFA1F301), fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                              Text('Min: \$10.00', style: TextStyle(color: Colors.grey[500]!, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Payout Destination
                          const Text('Payout Destination', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          // Connected Bank Account
                          ..._connectedBankAccounts.map((bank) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDestinationOption(
                              bank['id'] ?? 'bank_account',
                              bank['bank_name'] ?? 'Bank Account',
                              '•••• ${bank['last4'] ?? '****'}',
                              Icons.account_balance,
                            ),
                          )),
                          // Saved Cards
                          ..._paymentMethods.map((pm) {
                            final brand = (pm['card']?['brand'] ?? 'Card').toString().toUpperCase();
                            final last4 = pm['card']?['last4'] ?? '????';
                            final id = pm['id'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildDestinationOption(id, brand, '•••• $last4', Icons.credit_card),
                            );
                          }),
                          if (_paymentMethods.isEmpty && _connectedBankAccounts.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('No payment methods available', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
                            ),
                          const SizedBox(height: 24),
                          // Processing Time
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
                                const Icon(Icons.info_outline, color: Color(0xFFA1F301), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Processing Time', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text('Payouts typically arrive within 1-3 business days. A processing fee of 2.5% will be deducted.',
                                          style: TextStyle(color: Colors.grey[400]!, fontSize: 13, height: 1.5)),
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
                                _buildSummaryRow('Requested Amount', '\$' + payoutAmount.toStringAsFixed(2), Colors.white),
                                const SizedBox(height: 12),
                                _buildSummaryRow('Processing Fee (2.5%)', '-\$' + fee.toStringAsFixed(2), const Color(0xFFEF4444)),
                                const SizedBox(height: 16),
                                Container(height: 1, color: Colors.grey[800]),
                                const SizedBox(height: 16),
                                _buildSummaryRow('You\'ll Receive', '\$' + netAmount.toStringAsFixed(2), const Color(0xFFA1F301), isBold: true, isLarge: true),
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
                onTap: _isProcessing ? null : _confirmPayout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isProcessing ? const Color(0xFF2A2A2F) : const Color(0xFFA1F301),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isProcessing)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      else ...[
                        const Icon(Icons.credit_card, color: Colors.black, size: 20),
                        const SizedBox(width: 8),
                        const Text('Confirm Payout Request', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
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
              width: 40, height: 40,
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
                  Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400]!, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(number, style: TextStyle(color: Colors.grey[600]!, fontSize: 13)),
                ],
              ),
            ),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFFA1F301) : Colors.grey[600]!, width: 2),
                color: isSelected ? const Color(0xFFA1F301) : Colors.transparent,
              ),
              child: isSelected ? const Center(child: Icon(Icons.check, color: Colors.black, size: 12)) : null,
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
        Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.grey[400]!, fontSize: isLarge ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(amount, style: TextStyle(color: amountColor, fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
