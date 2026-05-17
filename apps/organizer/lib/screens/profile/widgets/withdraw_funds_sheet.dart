import 'package:flutter/material.dart';

class WithdrawFundsSheet extends StatefulWidget {
  final double availableBalance;
  final Function(double amount) onWithdraw;

  const WithdrawFundsSheet({
    super.key,
    required this.availableBalance,
    required this.onWithdraw,
  });

  @override
  State<WithdrawFundsSheet> createState() => _WithdrawFundsSheetState();
}

class _WithdrawFundsSheetState extends State<WithdrawFundsSheet> {
  final _amountController = TextEditingController(text: '0.00');
  String _selectedAccount = 'Chase Bank ....7545';
  double _amount = 0.0;

  final List<String> _accounts = [
    'Chase Bank ....7545',
    'Bank of America ....3421',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Withdraw Funds',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          // Available balance banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Balance',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  '\$${widget.availableBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFA2F301),
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Amount',
              style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            onChanged: (val) {
              setState(() {
                _amount = double.tryParse(val) ?? 0.0;
              });
            },
            decoration: InputDecoration(
              prefixText: '\$',
              prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
              filled: true,
              fillColor: const Color(0xFF0A0A0F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFA2F301)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Withdraw To',
              style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAccount,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1F),
                iconEnabledColor: const Color(0xFF888888),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: _accounts
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedAccount = val!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Withdrawals typically take 2-3 business days to process',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              widget.onWithdraw(_amount);
              Navigator.of(context).pop();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFA2F301),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Withdraw \$${_amount.toInt()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
