import 'package:flutter/material.dart';

class AddFundsSheet extends StatefulWidget {
  final Function(double amount) onAddFunds;

  const AddFundsSheet({super.key, required this.onAddFunds});

  @override
  State<AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends State<AddFundsSheet> {
  final _amountController = TextEditingController(text: '0.00');
  String _selectedMethod = 'Visa ....7545';
  double _amount = 0.0;

  final List<String> _methods = [
    'Visa ....7545',
    'Mastercard •••• 8921',
    'Chase Bank •••• 7845',
  ];

  final List<double> _quickAmounts = [50, 100, 200, 500];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    setState(() {
      _amount = amount;
      _amountController.text = amount.toStringAsFixed(2);
    });
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
          const Text('Add Funds',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
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
          const Text('Payment Method',
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
                value: _selectedMethod,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A1F),
                iconEnabledColor: const Color(0xFF888888),
                style: const TextStyle(color: Colors.white, fontSize: 16),
                items: _methods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedMethod = val!),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Withdrawals typically take 2-3 business days to process',
            style: TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Quick amount buttons
          Row(
            children: _quickAmounts.map((amount) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _setAmount(amount),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _amount == amount
                          ? const Color(0xFFA2F301).withValues(alpha: 0.2)
                          : const Color(0xFF0A0A0F),
                      borderRadius: BorderRadius.circular(12),
                      border: _amount == amount
                          ? Border.all(color: const Color(0xFFA2F301))
                          : null,
                    ),
                    child: Text(
                      '\$${amount.toInt()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _amount == amount
                            ? const Color(0xFFA2F301)
                            : Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Add button
          GestureDetector(
            onTap: () {
              widget.onAddFunds(_amount);
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
                'Add \$${_amount.toInt()}',
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
