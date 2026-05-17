import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/remove_confirm_dialog.dart';

class BankAccountDetailScreen extends StatelessWidget {
  final String bankName;
  final String accountHolder;
  final String lastFour;
  final String routingNumber;
  final String accountType;
  final bool isDefault;

  const BankAccountDetailScreen({
    super.key,
    required this.bankName,
    required this.accountHolder,
    required this.lastFour,
    required this.routingNumber,
    required this.accountType,
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
        title: const Text('Bank Account',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bank card preview
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
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA2F301).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: SvgPicture.asset('assets/bank_icon.svg',
                                width: 22, height: 22,
                                colorFilter: const ColorFilter.mode(
                                    Color(0xFFA2F301), BlendMode.srcIn)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(accountType,
                              style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(bankName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(accountHolder,
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                    const SizedBox(height: 10),
                    Text('•••• •••• •••• $lastFour',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, letterSpacing: 2)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Routing:',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                        Text(routingNumber,
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
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
                    Text('Default Withdrawal Account',
                        style: TextStyle(
                            color: Color(0xFFA2F301), fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              const SizedBox(height: 16),
              // Account info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Information',
                        style: TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    _infoRow('Bank Name', bankName),
                    _infoRow('Account Holder', accountHolder),
                    _infoRow('Account Type', accountType),
                    _infoRow('Routing Number', routingNumber, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Remove button
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => RemoveConfirmDialog(
                    title: 'Remove?',
                    message: 'Are you sure you want to remove this bank account? This action cannot be undone.',
                    confirmLabel: 'Yes, Delete Bank Account',
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
                      Text('Delete Bank Account',
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
                  'This bank account will be used for withdrawals from your wallet. Transfers typically take 2-3 business days.',
                  style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2A2F), height: 1),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
