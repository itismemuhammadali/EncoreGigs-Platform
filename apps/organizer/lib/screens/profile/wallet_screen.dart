import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/add_funds_sheet.dart';
import 'widgets/withdraw_funds_sheet.dart';
import 'add_payment_method_screen.dart';
import 'add_bank_account_screen.dart';
import 'payment_method_detail_screen.dart';
import 'bank_account_detail_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0.0;

  @override
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
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
              // Payment Methods
              _sectionHeader('Payment Methods', const AddPaymentMethodScreen()),
              const SizedBox(height: 12),
              _paymentMethodCard(
                  icon: Icons.credit_card,
                  title: 'Visa •••• 4532',
                  subtitle: 'Default',
                  subtitleColor: const Color(0xFFA2F301),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PaymentMethodDetailScreen(
                      cardType: 'Visa', lastFour: '4532',
                      cardHolder: 'Alex Chen', expiry: '14/32', isDefault: true,
                    ),
                  ))),
              const SizedBox(height: 10),
              _paymentMethodCard(
                  icon: Icons.credit_card,
                  title: 'Mastercard •••• 8921',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const PaymentMethodDetailScreen(
                      cardType: 'Mastercard', lastFour: '8921',
                      cardHolder: 'Alex Chen', expiry: '12/28',
                    ),
                  ))),
              const SizedBox(height: 28),
              // Bank Accounts
              _sectionHeader('Bank Accounts', const AddBankAccountScreen()),
              const SizedBox(height: 12),
              _paymentMethodCard(
                  iconPath: 'assets/bank_icon.svg',
                  title: 'Chase Bank •••• 7845',
                  subtitle: 'Checking',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const BankAccountDetailScreen(
                      bankName: 'Chase Bank', accountHolder: 'Alex Chen',
                      lastFour: '7845', routingNumber: '021000021',
                      accountType: 'Checking', isDefault: true,
                    ),
                  ))),
              const SizedBox(height: 28),
              // Recent Transactions
              const Text('Recent Transactions',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _transactionRow('Added Funds', 'Feb 9, 2026', '+\$2000', true),
              _transactionRow('Added Funds', 'Feb 9, 2026', '+\$500', true),
              _transactionRow('Payment to Sarah Johnson', 'Feb 4, 2026', '\$750', false),
              _transactionRow('Added Funds', 'Feb 3, 2026', '+\$1000', true),
              _transactionRow('Payment to Mike Davis', 'Feb 1, 2026', '\$500', false),
              _transactionRow('Refund from Cancelled Gig', 'Jan 30, 2026', '+\$600', true),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Widget destination) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => destination),
          ),
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

  Widget _transactionRow(String title, String date, String amount, bool isIncoming) {
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
              Text(title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              Text(
                amount,
                style: TextStyle(
                  color: isIncoming ? const Color(0xFFA2F301) : Colors.white,
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
              const Text('Completed', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
