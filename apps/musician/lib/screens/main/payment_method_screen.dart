import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_bank_account_screen.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  List<dynamic> _paymentMethods = [];
  bool _isLoading = true;
  String _bankAccountStatus = 'not_connected';

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoading = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final musicianId = authService.currentUser?.uid;
      if (musicianId == null) return;

      final walletData = await apiService.getWalletData(musicianId);
      
      // Check musician's Stripe Connect status
      final musicianDoc = await FirebaseFirestore.instance.collection('musicians').doc(musicianId).get();
      final musicianData = musicianDoc.data();
      final connectStatus = musicianData?['stripe_status'] ?? 'not_connected';
      final connectId = musicianData?['stripe_connect_id'] ?? '';
      
      setState(() {
        _paymentMethods = walletData['payment_methods'] ?? [];
        _bankAccountStatus = connectId.isNotEmpty ? connectStatus : 'not_connected';
      });
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewCard() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final musicianId = authService.currentUser?.uid;
      if (musicianId == null) return;

      final setupData = await apiService.createSetupIntent(musicianId);
      final clientSecret = setupData['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'OnlyGigz',
          style: ThemeMode.dark,
          appearance: PaymentSheetAppearance(
            colors: const PaymentSheetAppearanceColors(
              primary: Color(0xFFA1F301),
              background: Color(0xFF0A0A0F),
              componentBackground: Color(0xFF3A3A3F),
              componentDivider: Color(0xFF2A2A2F),
              primaryText: Color(0xFFFFFFFF),
              secondaryText: Color(0xFFFFFFFF),
              placeholderText: Color(0xFF888888),
              icon: Color(0xFFA1F301),
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
      
      // Fetch the latest payment method from Stripe and save to Firestore
      final walletData = await apiService.getWalletData(musicianId);
      final methods = walletData['payment_methods'] ?? [];
      if (methods.isNotEmpty) {
        final latestPm = methods.last;
        await apiService.savePaymentMethod(musicianId, latestPm['id']);
      }
      
      await _loadPaymentMethods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card added successfully!')),
        );
      }
    } catch (e) {
      final msg = e.toString();
      if (mounted && !msg.contains('Canceled') && !msg.contains('canceled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatCardLabel(dynamic pm) {
    final brand = (pm['card']?['brand'] ?? 'Card').toString().toUpperCase();
    final last4 = pm['card']?['last4'] ?? '????';
    return '$brand •••• $last4';
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Payment Methods', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Manage your payment cards', style: TextStyle(color: Colors.grey[500]!, fontSize: 14)),
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
                          GestureDetector(
                            onTap: _addNewCard,
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: Color(0xFFA1F301), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Add New Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddBankAccountScreen()),
                              );
                              _loadPaymentMethods();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: const Color(0xFF00C950).withValues(alpha: 0.3), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00C950).withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.account_balance, color: Color(0xFF00C950), size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text('Connect Bank Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Connected Bank Account Status
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _bankAccountStatus == 'active'
                                    ? const Color(0xFF00C950).withValues(alpha: 0.5)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _bankAccountStatus == 'active' ? Icons.check_circle : Icons.warning_amber_rounded,
                                  color: _bankAccountStatus == 'active' ? const Color(0xFF00C950) : const Color(0xFFEF4444),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _bankAccountStatus == 'active' ? 'Bank Account Connected' : 'No Bank Account',
                                        style: TextStyle(
                                          color: _bankAccountStatus == 'active' ? const Color(0xFF00C950) : const Color(0xFFEF4444),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _bankAccountStatus == 'active'
                                            ? 'You can receive payouts from gigs'
                                            : 'Connect a bank account to receive payouts',
                                        style: TextStyle(color: Colors.grey[400]!, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text('Saved Payment Methods', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          if (_paymentMethods.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'No cards saved',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500]!, fontSize: 14),
                              ),
                            )
                          else
                            ..._paymentMethods.map((pm) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(_formatCardLabel(pm), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                              if (_paymentMethods.indexOf(pm) == 0) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                                                    border: Border.all(color: const Color(0xFFA1F301), width: 1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Text('Default', style: TextStyle(color: Color(0xFFA1F301), fontSize: 12, fontWeight: FontWeight.w600)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Expires ${pm['card']?['exp_month']}/${pm['card']?['exp_year']}', style: TextStyle(color: Colors.grey[500]!, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Secure Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Text(
                                  'Your card information is encrypted and secure. We never store your full card details.',
                                  style: TextStyle(color: Colors.grey[400]!, fontSize: 14, height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
