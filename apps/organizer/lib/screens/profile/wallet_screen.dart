import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'widgets/add_funds_sheet.dart';
import 'widgets/withdraw_funds_sheet.dart';
import 'payment_method_detail_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  List<dynamic> _paymentMethods = [];
  List<dynamic> _transactions = [];
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWalletData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWalletData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final organizerId = authService.currentUser?.uid;

      if (organizerId != null) {
        final walletData = await apiService.getWalletData(organizerId);
        final transactions = await apiService.getTransactions(organizerId);
        
        setState(() {
          _paymentMethods = walletData['payment_methods'] ?? [];
          _transactions = transactions;
          _balance = (walletData['wallet_balance'] ?? 0.0).toDouble();
        });
      }
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
      final organizerId = authService.currentUser?.uid;

      if (organizerId == null) throw Exception('User not logged in');

      final setupIntentData = await apiService.createSetupIntent(organizerId);
      final clientSecret = setupIntentData['clientSecret'];

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

      await Stripe.instance.presentPaymentSheet();

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        _loadWalletData();
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

  String _formatDate(dynamic value) {
    try {
      int timestamp;
      if (value is int) {
        timestamp = value;
      } else if (value is double) {
        timestamp = value.toInt();
      } else {
        return '';
      }
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '';
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text('Wallet',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA2F301)))
          : RefreshIndicator(
              onRefresh: _loadWalletData,
              color: const Color(0xFFA2F301),
              backgroundColor: const Color(0xFF1A1A1F),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA2F301),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset('assets/wallet_icon.svg',
                                  width: 18, height: 18,
                                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                              const SizedBox(width: 8),
                              const Text('Available Balance',
                                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('\$${_balance.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.black, fontSize: 36, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => AddFundsSheet(
                                      onAddFunds: (amount) {
                                        setState(() => _balance += amount);
                                      },
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add, color: Colors.black, size: 16),
                                        SizedBox(width: 6),
                                        Text('Add Funds',
                                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => WithdrawFundsSheet(
                                      availableBalance: _balance,
                                      onWithdraw: (amount) {
                                        setState(() => _balance -= amount);
                                      },
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset('assets/download_icon.svg',
                                            width: 16, height: 16,
                                            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                                        const SizedBox(width: 6),
                                        const Text('Withdraw',
                                            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionHeader('Payment Methods', onAddNew: _openStripePaymentSheet),
                    const SizedBox(height: 12),
                    if (_paymentMethods.isEmpty)
                      _emptyState('No payment methods added')
                    else
                      ..._paymentMethods.map((pm) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _paymentMethodCard(
                          icon: Icons.credit_card,
                          title: '${pm['card']['brand'].toString().toUpperCase()} •••• ${pm['card']['last4']}',
                          subtitle: pm['id'] == _paymentMethods[0]['id'] ? 'Default' : 'Expires ${pm['card']['exp_month']}/${pm['card']['exp_year']}',
                          subtitleColor: pm['id'] == _paymentMethods[0]['id'] ? const Color(0xFFA2F301) : const Color(0xFF888888),
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => PaymentMethodDetailScreen(
                              cardType: pm['card']['brand'],
                              lastFour: pm['card']['last4'],
                              cardHolder: 'Organizer', 
                              expiry: '${pm['card']['exp_month']}/${pm['card']['exp_year']}',
                              isDefault: pm['id'] == _paymentMethods[0]['id'],
                            ),
                          )),
                        ),
                      )),
                    const SizedBox(height: 28),
                    const Text('Recent Transactions',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (_transactions.isEmpty)
                      _emptyState('No recent transactions')
                    else
                      ..._transactions.map((tx) {
                        final amount = (tx['amount'] ?? 0).toDouble();
                        final isWallet = tx['type'] == 'topup' || tx['type'] == 'escrow_hold';
                        final displayAmount = isWallet ? amount : amount / 100.0;
                        final prefix = displayAmount >= 0 ? '+' : '-';
                        final formatted = '$prefix\$${displayAmount.abs().toStringAsFixed(2)}';
                        final success = tx['status'] == 'succeeded' || tx['type'] == 'topup' || tx['type'] == 'escrow_hold';
                        return _transactionRow(
                          tx['description'] ?? 'Transaction',
                          _formatDate(tx['created']),
                          formatted,
                          success,
                        );
                      }),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 14),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onAddNew}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: onAddNew,
          child: const Text('+ Add New',
              style: TextStyle(color: Color(0xFFA2F301), fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _paymentMethodCard({
    IconData? icon,
    String? iconPath,
    required String title,
    String? subtitle,
    Color subtitleColor = const Color(0xFF888888),
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFA2F301).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: iconPath != null
                  ? SvgPicture.asset(iconPath,
                      width: 20, height: 20,
                      colorFilter: const ColorFilter.mode(Color(0xFFA2F301), BlendMode.srcIn))
                  : Icon(icon, color: const Color(0xFFA2F301), size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF555555), size: 20),
        ],
      ),
      ),
    );
  }

  Widget _transactionRow(String title, String date, String amount, bool isSuccess) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 10),
              Text(
                amount,
                style: TextStyle(
                  color: amount.startsWith('+') ? const Color(0xFFA2F301) : Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
              Text(
                isSuccess ? 'Completed' : 'Pending', 
                style: TextStyle(
                  color: isSuccess ? const Color(0xFFA2F301) : Colors.orange, 
                  fontSize: 13
                )
              ),
            ],
          ),
        ],
      ),
    );
  }
}
