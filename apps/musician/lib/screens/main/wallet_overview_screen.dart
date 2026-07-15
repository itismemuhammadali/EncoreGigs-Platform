import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';

import '../../services/api_service.dart';

import '../../services/auth_service.dart';

import 'add_bank_account_screen.dart';

import 'transaction_detail_screen.dart';

import 'request_early_release_screen.dart';

import 'request_payout_screen.dart';

import 'default_card_success_screen.dart';



class WalletOverviewScreen extends StatefulWidget {

  const WalletOverviewScreen({super.key});



  @override

  State<WalletOverviewScreen> createState() => _WalletOverviewScreenState();

}



class _WalletOverviewScreenState extends State<WalletOverviewScreen> with WidgetsBindingObserver {

  int _selectedTabIndex = 0;

  double _totalEarned = 0.0;
  double _inEscrow = 0.0;
  double _thisMonth = 0.0;
  int _pendingGigs = 0;

  List<dynamic> _paymentMethods = [];

  List<Map<String, dynamic>> _escrowBookings = [];
  List<Map<String, dynamic>> _walletTransactions = [];
  String _bankAccountStatus = 'not_connected';
  List<Map<String, dynamic>> _connectedBankAccounts = [];
  List<dynamic> _transactions = [];

  bool _isLoading = true;



  @override

  void initState() {

    super.initState();

    _loadData();

  }



  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final musicianId = authService.currentUser?.uid;
      if (musicianId == null) return;

      final walletData = await apiService.getWalletData(musicianId);
      setState(() {
        _paymentMethods = walletData['payment_methods'] ?? [];
      });

      // Load bank account status and connected bank accounts
      try {
        final accountData = await apiService.getConnectedAccount(musicianId);
        if (mounted) setState(() {
          _bankAccountStatus = accountData['status'] ?? 'not_connected';
          _connectedBankAccounts = (accountData['bank_accounts'] ?? []).cast<Map<String, dynamic>>();
        });
      } catch (e) {
        debugPrint('Error loading bank account status: $e');
      }

      // Load escrow bookings — query by musicianId only, filter client-side
      // to avoid requiring a Firestore composite index on (musicianId, escrow_status)
      try {
        final bookingsSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('musicianId', isEqualTo: musicianId)
            .get();
        _escrowBookings = bookingsSnap.docs
            .map((doc) => Map<String, dynamic>.from(doc.data())..['id'] = doc.id)
            .where((b) => b['escrow_status'] == 'held')
            .toList();
      } catch (e) {
        debugPrint('Error loading escrow: $e');
      }

      // Load wallet transactions
      try {
        final txSnap = await FirebaseFirestore.instance
            .collection('musicians')
            .doc(musicianId)
            .collection('wallet_transactions')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
        _walletTransactions = txSnap.docs.map((doc) => Map<String, dynamic>.from(doc.data())..['id'] = doc.id).toList();

        _totalEarned = 0.0;
        _thisMonth = 0.0;
        final now = DateTime.now();
        for (final tx in _walletTransactions) {
          final amt = (tx['amount'] ?? 0).toDouble();
          _totalEarned += amt;
          final createdAt = tx['createdAt'];
          if (createdAt != null) {
            DateTime? txDate;
            if (createdAt is Timestamp) txDate = createdAt.toDate();
            else if (createdAt is String) txDate = DateTime.tryParse(createdAt);
            if (txDate != null && txDate.year == now.year && txDate.month == now.month) {
              _thisMonth += amt;
            }
          }
        }
        if (_totalEarned < 0) _totalEarned = 0.0;
        if (_thisMonth < 0) _thisMonth = 0.0;
      } catch (e) {
        debugPrint('Error loading transactions: $e');
      }

      _inEscrow = 0.0;
      for (final b in _escrowBookings) {
        _inEscrow += (b['escrow_amount'] ?? b['amount'] ?? 0).toDouble();
      }
      _pendingGigs = _escrowBookings.length;

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading wallet data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  Future<void> _openStripePaymentSheet() async {

    try {

      final apiService = Provider.of<ApiService>(context, listen: false);

      final authService = Provider.of<AuthService>(context, listen: false);

      final musicianId = authService.currentUser?.uid;



      if (musicianId == null) throw Exception('User not logged in');



      // 1. Create SetupIntent on backend

      final setupIntentData = await apiService.createSetupIntent(musicianId);

      final clientSecret = setupIntentData['clientSecret'];



      // 2. Initialize Payment Sheet (shows both Card and Bank options)

      await Stripe.instance.initPaymentSheet(

        paymentSheetParameters: SetupPaymentSheetParameters(

          setupIntentClientSecret: clientSecret,

          merchantDisplayName: 'OnlyGigz',

          style: ThemeMode.dark,

          appearance: PaymentSheetAppearance(

            colors: const PaymentSheetAppearanceColors(

              primary: Color(0xFF00C950),

              background: Color(0xFF0A0A0F),

              componentBackground: Color(0xFF3A3A3F),

              componentDivider: Color(0xFF2A2A2F),

              primaryText: Color(0xFFFFFFFF),

              secondaryText: Color(0xFFFFFFFF),

              placeholderText: Color(0xFF888888),

              icon: Color(0xFF00C950),

            ),

            primaryButton: PaymentSheetPrimaryButtonAppearance(

              colors: PaymentSheetPrimaryButtonTheme(

                light: PaymentSheetPrimaryButtonThemeColors(

                  background: const Color(0xFF00C950),

                  text: const Color(0xFF000000),

                ),

                dark: PaymentSheetPrimaryButtonThemeColors(

                  background: const Color(0xFF00C950),

                  text: const Color(0xFF000000),

                ),

              ),

            ),

          ),

        ),

      );



      // 3. Present Payment Sheet

      await Stripe.instance.presentPaymentSheet();



      // Wait for webhook to process

      await Future.delayed(const Duration(seconds: 2));



      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Payment method added successfully!')),

        );

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(content: Text('Error: $e')),

        );

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFF0A0A0F),

      body: SafeArea(

        child: Column(

          children: [

            // Header

            Container(

              width: double.infinity,

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

              decoration: BoxDecoration(

                border: Border(

                  bottom: BorderSide(

                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),

                    width: 1.5,

                  ),

                ),

              ),

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

                  const SizedBox(height: 16),

                  const Text('Wallet', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),

                  const SizedBox(height: 4),

                  Text('Manage earnings, escrow & payments', style: TextStyle(color: Colors.grey[500], fontSize: 14)),

                ],

              ),

            ),



            // Scrollable content

            Expanded(

              child: SingleChildScrollView(

                padding: const EdgeInsets.all(16),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // Available Balance Card

                    Container(

                      width: double.infinity,

                      padding: const EdgeInsets.all(20),

                      decoration: BoxDecoration(

                        gradient: const LinearGradient(

                          begin: Alignment.topCenter,

                          end: Alignment.bottomCenter,

                          colors: [Color(0xFFA1F301), Color(0xFF0A0A0F)],

                        ),

                        borderRadius: BorderRadius.circular(16),

                      ),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Row(

                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [

                              Text('Available Balance', style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w600)),

                              Icon(Icons.visibility_outlined, color: Colors.black.withValues(alpha: 0.6), size: 20),

                            ],

                          ),

                          const SizedBox(height: 12),

                          Text('\$${_totalEarned.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),

                          const SizedBox(height: 20),

                          Row(

                            children: [

                              Expanded(

                                child: Container(

                                  padding: const EdgeInsets.all(16),

                                  decoration: BoxDecoration(

                                    color: Colors.white.withValues(alpha: 0.15),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      Row(

                                        children: [

                                          Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.8), size: 16),

                                          const SizedBox(width: 6),

                                          Text('In Escrow', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),

                                        ],

                                      ),

                                      const SizedBox(height: 8),

                                      Text('\$' + _inEscrow.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

                                    ],

                                  ),

                                ),

                              ),

                              const SizedBox(width: 12),

                              Expanded(

                                child: Container(

                                  padding: const EdgeInsets.all(16),

                                  decoration: BoxDecoration(

                                    color: Colors.white.withValues(alpha: 0.15),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      Row(

                                        children: [

                                          Icon(Icons.trending_up, color: Colors.white.withValues(alpha: 0.8), size: 16),

                                          const SizedBox(width: 6),

                                          Text('Total Earned', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),

                                        ],

                                      ),

                                      const SizedBox(height: 8),

                                      Text('\$' + _totalEarned.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

                                    ],

                                  ),

                                ),

                              ),

                            ],

                          ),

                          const SizedBox(height: 20),

                          GestureDetector(

                            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequestPayoutScreen())),

                            child: Container(

                              width: double.infinity,

                              padding: const EdgeInsets.symmetric(vertical: 16),

                              decoration: BoxDecoration(

                                color: const Color(0xFFA1F301),

                                borderRadius: BorderRadius.circular(12),

                              ),

                              child: Row(

                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [

                                  SizedBox(

                                    width: 20,

                                    height: 20,

                                    child: SvgPicture.asset(

                                      'assets/download_icon.svg',

                                      fit: BoxFit.contain,

                                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),

                                    ),

                                  ),

                                  const SizedBox(width: 8),

                                  const Text('Withdraw Funds', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),

                                ],

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(height: 24),



                    // Tab Bar

                    Container(

                      padding: const EdgeInsets.all(4),

                      decoration: BoxDecoration(

                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

                        borderRadius: BorderRadius.circular(12),

                      ),

                      child: Row(

                        children: [

                          _buildPillTab('Overview', 0),

                          _buildPillTab('Escrow', 1),

                          _buildPillTab('History', 2),

                          _buildPillTab('Methods', 3),

                        ],

                      ),

                    ),

                    const SizedBox(height: 24),



                    // Tab Content

                    if (_selectedTabIndex == 0) _buildOverviewTab(),

                    if (_selectedTabIndex == 1) _buildEscrowTab(),

                    if (_selectedTabIndex == 2) _buildHistoryTab(),

                    if (_selectedTabIndex == 3) _buildMethodsTab(),

                  ],

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  void _showDeleteConfirmation(BuildContext context, {required String title, required String subtitle, required VoidCallback onConfirm}) {

    showModalBottomSheet(

      context: context,

      backgroundColor: const Color(0xFF0A0A0F),

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (_) => Padding(

        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Container(

              width: 72,

              height: 72,

              decoration: BoxDecoration(

                color: const Color(0xFFEF4444).withValues(alpha: 0.15),

                shape: BoxShape.circle,

              ),

              child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 36),

            ),

            const SizedBox(height: 20),

            Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),

            const SizedBox(height: 12),

            Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6), textAlign: TextAlign.center),

            const SizedBox(height: 32),

            Row(

              children: [

                Expanded(

                  child: GestureDetector(

                    onTap: () => Navigator.of(context).pop(),

                    child: Container(

                      padding: const EdgeInsets.symmetric(vertical: 16),

                      decoration: BoxDecoration(

                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

                        borderRadius: BorderRadius.circular(14),

                      ),

                      child: const Center(

                        child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),

                      ),

                    ),

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: GestureDetector(

                    onTap: () {

                      Navigator.of(context).pop();

                      onConfirm();

                    },

                    child: Container(

                      padding: const EdgeInsets.symmetric(vertical: 16),

                      decoration: BoxDecoration(

                        color: const Color(0xFFEF4444),

                        borderRadius: BorderRadius.circular(14),

                      ),

                      child: const Center(

                        child: Text('Delete', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),

                      ),

                    ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }



  void _showSetDefaultConfirmation(BuildContext context, String cardName) {

    showModalBottomSheet(

      context: context,

      backgroundColor: const Color(0xFF0A0A0F),

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),

      ),

      builder: (_) => Padding(

        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Container(

              width: 72,

              height: 72,

              decoration: BoxDecoration(

                color: const Color(0xFFA1F301).withValues(alpha: 0.15),

                shape: BoxShape.circle,

              ),

              child: const Icon(Icons.credit_card, color: Color(0xFFA1F301), size: 36),

            ),

            const SizedBox(height: 20),

            const Text(

              'Set as Default?',

              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),

              textAlign: TextAlign.center,

            ),

            const SizedBox(height: 12),

            Text(

              '$cardName will be set as your default payment method for all future transactions.',

              style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6),

              textAlign: TextAlign.center,

            ),

            const SizedBox(height: 32),

            Row(

              children: [

                Expanded(

                  child: GestureDetector(

                    onTap: () => Navigator.of(context).pop(),

                    child: Container(

                      padding: const EdgeInsets.symmetric(vertical: 16),

                      decoration: BoxDecoration(

                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

                        borderRadius: BorderRadius.circular(14),

                      ),

                      child: const Center(

                        child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),

                      ),

                    ),

                  ),

                ),

                const SizedBox(width: 12),

                Expanded(

                  child: GestureDetector(

                    onTap: () {

                      Navigator.of(context).pop();

                      Navigator.of(context).push(MaterialPageRoute(

                        builder: (_) => DefaultCardSuccessScreen(cardName: cardName),

                      ));

                    },

                    child: Container(

                      padding: const EdgeInsets.symmetric(vertical: 16),

                      decoration: BoxDecoration(

                        color: const Color(0xFFA1F301),

                        borderRadius: BorderRadius.circular(14),

                      ),

                      child: const Center(

                        child: Text('Confirm', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),

                      ),

                    ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildPillTab(String title, int index) {

    bool isActive = _selectedTabIndex == index;

    return Expanded(

      child: GestureDetector(

        onTap: () => setState(() => _selectedTabIndex = index),

        child: Container(

          padding: const EdgeInsets.symmetric(vertical: 12),

          decoration: BoxDecoration(

            color: isActive ? const Color(0xFFA1F301) : Colors.transparent,

            borderRadius: BorderRadius.circular(50),

          ),

          child: Center(

            child: Text(

              title,

              style: TextStyle(

                color: isActive ? Colors.black : Colors.grey[500],

                fontSize: 14,

                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,

              ),

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildOverviewTab() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        // Stats Row

        Row(

          children: [

            Expanded(

              child: Container(

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        Icon(Icons.trending_up, color: const Color(0xFFA1F301), size: 16),

                        const SizedBox(width: 6),

                        const Text('This Month', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),

                      ],

                    ),

                    const SizedBox(height: 12),

                    Text('\$' + _thisMonth.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Current balance', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),

                  ],

                ),

              ),

            ),

            const SizedBox(width: 12),

            Expanded(

              child: Container(

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Row(

                      children: [

                        Icon(Icons.schedule_outlined, color: Colors.orange, size: 16),

                        const SizedBox(width: 6),

                        const Text('Pending', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),

                      ],

                    ),

                    const SizedBox(height: 12),

                    Text('\$' + _inEscrow.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('From $_pendingGigs gigs', style: TextStyle(color: Colors.grey[500], fontSize: 12)),

                  ],

                ),

              ),

            ),

          ],

        ),

        const SizedBox(height: 32),

        // Active Escrow Section
        const Text('Active Escrow', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (_escrowBookings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No active escrow', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
          )
        else
          ..._escrowBookings.map((booking) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEscrowItem(
              booking['gigTitle'] ?? 'Gig',
              booking['organizerName'] ?? 'Organizer',
              'Amount held in escrow',
              '\$' + (booking['escrow_amount'] ?? booking['amount'] ?? 0).toDouble().toStringAsFixed(2),
              'Held',
              const Color(0xFFF59E0B),
              'assets/profile_image.png',
            ),
          )),
        const SizedBox(height: 32),
        // Recent Activity Section

        Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            const Text('Recent Activity', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

            GestureDetector(

              onTap: () => setState(() => _selectedTabIndex = 2),

              child: const Row(

                children: [

                  Text('View All', style: TextStyle(color: Color(0xFFA1F301), fontSize: 14, fontWeight: FontWeight.w600)),

                  SizedBox(width: 4),

                  Icon(Icons.arrow_forward_ios, color: Color(0xFFA1F301), size: 14),

                ],

              ),

            ),

          ],

        ),

        const SizedBox(height: 16),

        if (_walletTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No recent activity', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
          )
        else
          ..._walletTransactions.map((tx) {
            final amount = (tx['amount'] ?? 0).toDouble();
            final isIncoming = amount >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildActivityItem(
                tx['description'] ?? 'Transaction',
                tx['createdAt'] != null ? tx['createdAt'].toString().substring(0, 10) : '',
                (isIncoming ? '+' : '-') + '\$' + amount.abs().toStringAsFixed(2),
                isIncoming ? const Color(0xFF00C950) : const Color(0xFFEF4444),
                isIncoming ? Icons.south_east : Icons.north_east,
              ),
            );
          }),
        const SizedBox(height: 24),

      ],

    );

  }



  Widget _buildEscrowTab() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        // Escrow Protection Info Card

        Container(

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(

            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

            borderRadius: BorderRadius.circular(12),

          ),

          child: Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              SizedBox(

                width: 24,

                height: 24,

                child: SvgPicture.asset(

                  'assets/shield_icon.svg',

                  fit: BoxFit.contain,

                  colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn),

                ),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text('Secure Escrow Protection', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 8),

                    Text(

                      'When you\'re hired, payment is held securely in escrow until the gig is completed. Funds are automatically released 24 hours after your performance. You can request early release if the gig is completed early or if special circumstances apply.',

                      style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.6),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

        const SizedBox(height: 24),

        // Detailed Escrow Transaction

        if (_escrowBookings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No escrow transactions', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
          )
        else
          ..._escrowBookings.map((booking) {
            final amount = (booking['escrow_amount'] ?? booking['amount'] ?? 0).toDouble();
            final fee = amount * 0.05;
            final net = amount - fee;
            final status = booking['escrow_status'] ?? 'held';
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipOval(
                        child: Container(
                          width: 64, height: 64,
                          decoration: const BoxDecoration(color: Color(0xFF2A2A2F)),
                          child: const Icon(Icons.person, color: Colors.white54, size: 32),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking['gigTitle'] ?? 'Gig', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(booking['organizerName'] ?? 'Organizer', style: TextStyle(color: Colors.grey[500]!, fontSize: 15)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: status == 'released' ? const Color(0xFF00C950).withValues(alpha: 0.15) : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                border: Border.all(
                                  color: status == 'released' ? const Color(0xFF00C950) : const Color(0xFFF59E0B),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    status == 'released' ? Icons.check_circle : Icons.lock_outline,
                                    color: status == 'released' ? const Color(0xFF00C950) : const Color(0xFFF59E0B),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status == 'released' ? 'Released' : 'In Escrow - ${status.toUpperCase()}',
                                    style: TextStyle(
                                      color: status == 'released' ? const Color(0xFF00C950) : const Color(0xFFF59E0B),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildAmountRow('Gross Amount', '\$' + amount.toStringAsFixed(2), Colors.white),
                  const SizedBox(height: 16),
                  _buildAmountRow('Platform Fee (5%)', '-\$' + fee.toStringAsFixed(2), const Color(0xFFEF4444)),
                  const SizedBox(height: 20),
                  Container(height: 1, color: Colors.grey[800]),
                  const SizedBox(height: 20),
                  _buildAmountRow('You Receive', '\$' + net.toStringAsFixed(2), const Color(0xFFA1F301), isBold: true, isLarge: true),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Gig Date', style: TextStyle(color: Colors.grey[500]!, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text(booking['gigDate'] ?? booking['gigdate'] ?? 'TBD', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amount', style: TextStyle(color: Colors.grey[500]!, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('\$' + amount.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (status == 'held') ...[
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Early release request sent')),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, color: Colors.black, size: 16),
                            SizedBox(width: 8),
                            Text('Request Early Release', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ] else if (status == 'released') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A2A0A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF00C950), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('Payment successfully added to your wallet balance', style: TextStyle(color: const Color(0xFF00C950), fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

        const SizedBox(height: 24),

      ],

    );

  }



  Widget _buildHistoryTab() {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            const Text('Transaction History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

            GestureDetector(

              onTap: () {},

              child: Row(

                children: [

                  SizedBox(

                    width: 20,

                    height: 20,

                    child: SvgPicture.asset(

                      'assets/download_icon.svg',

                      fit: BoxFit.contain,

                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),

                    ),

                  ),

                  const SizedBox(width: 8),

                  const Text('Export', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                ],

              ),

            ),

          ],

        ),

        const SizedBox(height: 16),

        if (_walletTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No transactions yet', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
          )
        else
          ..._walletTransactions.map((tx) {
            final amount = (tx['amount'] ?? 0).toDouble();
            final isIncoming = amount >= 0;
            final txType = tx['type'] ?? 'transaction';
            Color amountColor;
            Color iconBgColor;
            IconData icon;
            if (txType == 'topup') {
              amountColor = const Color(0xFF00C950);
              iconBgColor = const Color(0xFF0A2A0A);
              icon = Icons.south_east;
            } else if (txType == 'escrow_hold') {
              amountColor = const Color(0xFFF59E0B);
              iconBgColor = const Color(0xFF2A1A00);
              icon = Icons.lock_outline;
            } else if (txType == 'payment_received') {
              amountColor = const Color(0xFF00C950);
              iconBgColor = const Color(0xFF0A2A0A);
              icon = Icons.south_east;
            } else if (txType == 'withdrawal') {
              amountColor = const Color(0xFF3B82F6);
              iconBgColor = const Color(0xFF0A1A2A);
              icon = Icons.north_east;
            } else {
              amountColor = isIncoming ? const Color(0xFF00C950) : const Color(0xFFEF4444);
              iconBgColor = isIncoming ? const Color(0xFF0A2A0A) : const Color(0xFF2A0A0A);
              icon = isIncoming ? Icons.south_east : Icons.north_east;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHistoryItem(
                tx['description'] ?? 'Transaction',
                null,
                tx['createdAt'] != null ? tx['createdAt'].toString().substring(0, 10) : '',
                '',
                (isIncoming ? '+' : '-') + '\$' + amount.abs().toStringAsFixed(2),
                amountColor,
                icon,
                null,
              ),
            );
          }),
        const SizedBox(height: 24),

      ],

    );

  }



  Widget _buildMethodsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Payment Cards', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: _openStripePaymentSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA1F301),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.black, size: 18),
                    SizedBox(width: 6),
                    Text('Add Card', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_paymentMethods.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No cards saved', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
          )
        else
          ..._paymentMethods.map((pm) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D4A1F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.credit_card, color: Color(0xFFA1F301), size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(pm['card']?['brand'] ?? 'Card').toString().toUpperCase()} •••• ${pm['card']?['last4'] ?? '????'}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Expires ${pm['card']?['exp_month']}/${pm['card']?['exp_year'] ?? '??'}',
                          style: TextStyle(color: Colors.grey[500]!, fontSize: 14)),
                    ],
                  ),
                ),
                if (_paymentMethods.indexOf(pm) == 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFFA1F301), width: 1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Default', style: TextStyle(color: Color(0xFFA1F301), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          )),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bank Accounts', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddBankAccountScreen()));
                _loadData();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: const Color(0xFF00C950).withValues(alpha: 0.3), width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text('Add Bank', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_bankAccountStatus == 'not_connected' || _connectedBankAccounts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No bank account connected', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
          )
        else
          ..._connectedBankAccounts.map((bank) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: const Color(0xFF00C950).withValues(alpha: 0.3), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SvgPicture.asset(
                      'assets/bank_icon2.svg',
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(Color(0xFF3B82F6), BlendMode.srcIn),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bank['bank_name'] ?? 'Bank Account', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Checking \u2022\u2022\u2022\u2022 ${bank['last4'] ?? '????'}', style: TextStyle(color: Colors.grey[500]!, fontSize: 15)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C950).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFF00C950), width: 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Default', style: TextStyle(color: Color(0xFF00C950), fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1F),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C950).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: Color(0xFF00C950), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Withdrawal Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Withdrawals are processed to your default bank account within 2-3 business days. Minimum withdrawal amount is \$50. No fees for standard withdrawals.',
                        style: TextStyle(color: Colors.grey[400]!, fontSize: 13, height: 1.6)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedEscrowItem() {

    return Column(

      children: [

        // First Card - Corporate Event Entertainment

        Container(

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color: Colors.black,

            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

            borderRadius: BorderRadius.circular(12),

          ),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  ClipOval(

                    child: Image.asset('assets/profile_image.png', width: 64, height: 64, fit: BoxFit.cover),

                  ),

                  const SizedBox(width: 16),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const Text('Wedding Reception Live Band', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 6),

                        Text('Emily & John', style: TextStyle(color: Colors.grey[500], fontSize: 15)),

                        const SizedBox(height: 12),

                        Container(

                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

                          decoration: BoxDecoration(

                            color: const Color(0xFF00C950).withValues(alpha: 0.15),

                            border: Border.all(color: const Color(0xFF00C950), width: 1.5),

                            borderRadius: BorderRadius.circular(20),

                          ),

                          child: Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Icon(Icons.check_circle, color: const Color(0xFF00C950), size: 12),

                              const SizedBox(width: 4),

                              const Text('Released', style: TextStyle(color: Color(0xFF00C950), fontSize: 11, fontWeight: FontWeight.w600)),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 24),

              _buildAmountRow('Gross Amount', '\$1200.00', Colors.white),

              const SizedBox(height: 16),

              _buildAmountRow('Platform Fee (5%)', '-\$60.00', const Color(0xFFEF4444)),

              const SizedBox(height: 20),

              Container(height: 1, color: Colors.grey[800]),

              const SizedBox(height: 20),

              _buildAmountRow('You Receive', '\$1140.00', const Color(0xFFA1F301), isBold: true, isLarge: true),

              const SizedBox(height: 24),

              Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Contract Signed', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Dec 28, 2025', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Gig Date', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Jan 5, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Released', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Jan 6, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 20),

              Row(

                children: [

                  Icon(Icons.location_on, color: const Color(0xFFEF4444), size: 18),

                  const SizedBox(width: 6),

                  Text('Grand Ballroom Hotel', style: TextStyle(color: Colors.grey[400], fontSize: 14)),

                  const Spacer(),

                  Icon(Icons.access_time, color: Colors.grey[500], size: 18),

                  const SizedBox(width: 6),

                  Text('4 hours', style: TextStyle(color: Colors.grey[400], fontSize: 14)),

                ],

              ),

              const SizedBox(height: 20),

              Container(

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color: const Color(0xFF00C950).withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(10),

                ),

                child: Row(

                  children: [

                    Icon(Icons.check_circle, color: const Color(0xFF00C950), size: 24),

                    const SizedBox(width: 12),

                    Expanded(

                      child: const Text('Payment successfully add to your wallet balance', style: TextStyle(color: Color(0xFF00C950), fontSize: 14, fontWeight: FontWeight.w600)),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

        const SizedBox(height: 16),

        // Second Card - Corporate Event Entertainment

        Container(

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color: Colors.black,

            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

            borderRadius: BorderRadius.circular(12),

          ),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  ClipOval(

                    child: Image.asset('assets/profile_image.png', width: 64, height: 64, fit: BoxFit.cover),

                  ),

                  const SizedBox(width: 16),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const Text('Corporate Event Entertainment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 6),

                        Text('TechCorp Events', style: TextStyle(color: Colors.grey[500], fontSize: 15)),

                        const SizedBox(height: 12),

                        Container(

                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

                          decoration: BoxDecoration(

                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),

                            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),

                            borderRadius: BorderRadius.circular(20),

                          ),

                          child: Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Icon(Icons.schedule, color: const Color(0xFFF59E0B), size: 14),

                              const SizedBox(width: 4),

                              const Text('In Escrow - Pending', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w600)),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 24),

              _buildAmountRow('Gross Amount', '\$2500.00', Colors.white),

              const SizedBox(height: 16),

              _buildAmountRow('Platform Fee (5%)', '-\$125.00', const Color(0xFFEF4444)),

              const SizedBox(height: 20),

              Container(height: 1, color: Colors.grey[800]),

              const SizedBox(height: 20),

              _buildAmountRow('You Receive', '\$2375.00', const Color(0xFFA1F301), isBold: true, isLarge: true),

              const SizedBox(height: 24),

              Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Contract Signed', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Jan 3, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Gig Date', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Jan 10, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Releases', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Jan 11, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 20),

              Row(

                children: [

                  Icon(Icons.location_on, color: const Color(0xFFEF4444), size: 18),

                  const SizedBox(width: 6),

                  Text('Tech Conference Center', style: TextStyle(color: Colors.grey[400], fontSize: 14)),

                  const Spacer(),

                  Icon(Icons.access_time, color: Colors.grey[500], size: 18),

                  const SizedBox(width: 6),

                  Text('6 hours', style: TextStyle(color: Colors.grey[400], fontSize: 14)),

                ],

              ),

              const SizedBox(height: 20),

              GestureDetector(

                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequestEarlyReleaseScreen())),

                child: Container(

                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(vertical: 16),

                  decoration: BoxDecoration(

                    color: const Color(0xFFA1F301),

                    borderRadius: BorderRadius.circular(12),

                  ),

                  child: Row(

                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [

                      SizedBox(

                        width: 20,

                        height: 20,

                        child: SvgPicture.asset(

                          'assets/send_message_icon.svg',

                          fit: BoxFit.contain,

                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),

                        ),

                      ),

                      const SizedBox(width: 8),

                      const Text('Request Early Release', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),

                    ],

                  ),

                ),

              ),

            ],

          ),

        ),

        const SizedBox(height: 16),

        // Third Card - Birthday Party DJ Set

        Container(

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(

            color: Colors.black,

            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

            borderRadius: BorderRadius.circular(12),

          ),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  ClipOval(

                    child: Image.asset('assets/profile_image.png', width: 64, height: 64, fit: BoxFit.cover),

                  ),

                  const SizedBox(width: 16),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const Text('Birthday Party DJ Set', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 6),

                        Text('Michael Rodriguez', style: TextStyle(color: Colors.grey[500], fontSize: 15)),

                        const SizedBox(height: 12),

                        Container(

                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

                          decoration: BoxDecoration(

                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),

                            border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),

                            borderRadius: BorderRadius.circular(20),

                          ),

                          child: Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Icon(Icons.lock, color: const Color(0xFFF59E0B), size: 12),

                              const SizedBox(width: 4),

                              const Text('In Escrow - Held', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600)),

                            ],

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 24),

              _buildAmountRow('Gross Amount', '\$800.00', Colors.white),

              const SizedBox(height: 16),

              _buildAmountRow('Platform Fee (5%)', '-\$40.00', const Color(0xFFEF4444)),

              const SizedBox(height: 20),

              Container(height: 1, color: Colors.grey[800]),

              const SizedBox(height: 20),

              _buildAmountRow('You Receive', '\$760.00', const Color(0xFFA1F301), isBold: true, isLarge: true),

              const SizedBox(height: 24),

              Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Contract Signed', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Jan 8, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Gig Date', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Feb 14, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text('Releases', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                        const SizedBox(height: 6),

                        const Text('Feb 15, 2026', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                      ],

                    ),

                  ),

                ],

              ),

              const SizedBox(height: 20),

              Row(

                children: [

                  Icon(Icons.location_on, color: const Color(0xFFEF4444), size: 18),

                  const SizedBox(width: 6),

                  Text('Private Residence', style: TextStyle(color: Colors.grey[400], fontSize: 14)),

                  const Spacer(),

                  Icon(Icons.access_time, color: Colors.grey[500], size: 18),

                  const SizedBox(width: 6),

                  Text('3 hours', style: TextStyle(color: Colors.grey[400], fontSize: 14)),

                ],

              ),

              const SizedBox(height: 20),

              Container(

                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),

                  borderRadius: BorderRadius.circular(10),

                ),

                child: Row(

                  children: [

                    Icon(Icons.info_outline, color: const Color(0xFFF59E0B), size: 20),

                    const SizedBox(width: 12),

                    Expanded(

                      child: Text(

                        'Payment will be automatically released 24h after gig completion',

                        style: TextStyle(color: Colors.grey[400], fontSize: 14),

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

      ],

    );

  }



  Widget _buildAmountRow(String label, String amount, Color amountColor, {bool isBold = false, bool isLarge = false}) {

    return Row(

      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [

        Text(label, style: TextStyle(color: isBold ? Colors.white : Colors.grey[400], fontSize: isLarge ? 16 : 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),

        Text(amount, style: TextStyle(color: amountColor, fontSize: isLarge ? 20 : 16, fontWeight: FontWeight.bold)),

      ],

    );

  }



  Widget _buildEscrowItem(String title, String client, String releaseDate, String amount, String status, Color statusColor, String avatarPath) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

        borderRadius: BorderRadius.circular(12),

      ),

      child: Column(

        children: [

          Row(

            children: [

              ClipOval(

                child: Image.asset(avatarPath, width: 48, height: 48, fit: BoxFit.cover),

              ),

              const SizedBox(width: 12),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 4),

                    Text(client, style: TextStyle(color: Colors.grey[500], fontSize: 14)),

                  ],

                ),

              ),

              const SizedBox(width: 12),

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

                decoration: BoxDecoration(

                  color: statusColor.withValues(alpha: 0.2),

                  border: Border.all(color: statusColor, width: 1),

                  borderRadius: BorderRadius.circular(20),

                ),

                child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),

              ),

            ],

          ),

          const SizedBox(height: 16),

          Row(

            children: [

              SizedBox(

                width: 18,

                height: 18,

                child: SvgPicture.asset(

                  'assets/lock_icon.svg',

                  fit: BoxFit.contain,

                  colorFilter: const ColorFilter.mode(Color(0xFFF59E0B), BlendMode.srcIn),

                ),

              ),

              const SizedBox(width: 6),

              Text(releaseDate, style: TextStyle(color: Colors.grey[400], fontSize: 14)),

              const Spacer(),

              Text(amount, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 22, fontWeight: FontWeight.bold)),

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildActivityItem(String title, String date, String amount, Color amountColor, IconData icon) {

    return GestureDetector(

      onTap: () {

        Navigator.of(context).push(

          MaterialPageRoute(

            builder: (_) => TransactionDetailScreen(

              title: title,

              subtitle: null,

              date: date,

              time: '',

              amount: amount,

              amountColor: amountColor,

              status: null,

            ),

          ),

        );

      },

      child: Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

          borderRadius: BorderRadius.circular(12),

        ),

        child: Row(

          children: [

            Container(

              width: 48,

              height: 48,

              decoration: BoxDecoration(

                color: amountColor.withValues(alpha: 0.2),

                shape: BoxShape.circle,

              ),

              child: Icon(icon, color: amountColor, size: 24),

            ),

            const SizedBox(width: 12),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                  const SizedBox(height: 4),

                  Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                ],

              ),

            ),

            const SizedBox(width: 12),

            Text(amount, style: TextStyle(color: amountColor, fontSize: 18, fontWeight: FontWeight.bold)),

          ],

        ),

      ),

    );

  }



  Widget _buildHistoryItem(String title, String? subtitle, String date, String time, String amount, Color amountColor, IconData icon, String? status) {

    return GestureDetector(

      onTap: () {

        Navigator.of(context).push(

          MaterialPageRoute(

            builder: (_) => TransactionDetailScreen(

              title: title,

              subtitle: subtitle,

              date: date,

              time: time,

              amount: amount,

              amountColor: amountColor,

              status: status,

            ),

          ),

        );

      },

      child: Container(

        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(

          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),

          borderRadius: BorderRadius.circular(12),

        ),

        child: Row(

        children: [

          Container(

            width: 48,

            height: 48,

            decoration: BoxDecoration(

              color: amountColor.withValues(alpha: 0.2),

              shape: BoxShape.circle,

            ),

            child: Icon(icon, color: amountColor, size: 24),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),

                const SizedBox(height: 4),

                if (subtitle != null) ...[

                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                  const SizedBox(height: 4),

                ],

                Row(

                  children: [

                    Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                    const SizedBox(width: 4),

                    Text('•', style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                    const SizedBox(width: 4),

                    Text(time, style: TextStyle(color: Colors.grey[500], fontSize: 13)),

                  ],

                ),

              ],

            ),

          ),

          const SizedBox(width: 12),

          Column(

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [

              Text(amount, style: TextStyle(color: amountColor, fontSize: 18, fontWeight: FontWeight.bold)),

              if (status != null) ...[

                const SizedBox(height: 6),

                Container(

                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                  decoration: BoxDecoration(

                    color: const Color(0xFF00C950).withValues(alpha: 0.15),

                    border: Border.all(color: const Color(0xFF00C950), width: 1),

                    borderRadius: BorderRadius.circular(16),

                  ),

                  child: Text(status, style: const TextStyle(color: Color(0xFF00C950), fontSize: 12, fontWeight: FontWeight.w600)),

                ),

              ],

            ],

          ),

        ],

      ),

      ),

    );

  }

}