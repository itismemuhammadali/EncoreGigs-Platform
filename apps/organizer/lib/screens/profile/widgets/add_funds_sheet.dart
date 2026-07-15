import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class AddFundsSheet extends StatefulWidget {
  final Function(double amount) onAddFunds;

  const AddFundsSheet({super.key, required this.onAddFunds});

  @override
  State<AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends State<AddFundsSheet> {
  final _amountController = TextEditingController(text: '0.00');
  String? _selectedMethodId;
  String _selectedMethodLabel = 'Select Payment Method';
  double _amount = 0.0;
  bool _isLoadingMethods = true;
  bool _isAdding = false;
  List<dynamic> _paymentMethods = [];

  final List<double> _quickAmounts = [50, 100, 200, 500];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _isLoadingMethods = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final organizerId = authService.currentUser?.uid;

      if (organizerId != null) {
        final walletData = await apiService.getWalletData(organizerId);
        final methods = walletData['payment_methods'] ?? [];
        
        setState(() {
          _paymentMethods = methods;
          if (_paymentMethods.isNotEmpty) {
            _selectedMethodId = _paymentMethods[0]['id'];
            _selectedMethodLabel = _formatMethodLabel(_paymentMethods[0]);
          } else {
            _selectedMethodLabel = 'No cards saved - Add a card first';
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
      setState(() {
        _selectedMethodLabel = 'Error loading methods';
      });
    } finally {
      if (mounted) setState(() => _isLoadingMethods = false);
    }
  }

  String _formatMethodLabel(dynamic pm) {
    final brand = pm['card']['brand'].toString().toUpperCase();
    final last4 = pm['card']['last4'];
    return '$brand •••• $last4';
  }

  Future<void> _handleAddFunds() async {
    if (_amount <= 0 || _selectedMethodId == null) return;

    setState(() => _isAdding = true);
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final organizerId = authService.currentUser?.uid;

      if (organizerId == null) throw Exception('User not logged in');

      final result = await apiService.addFunds(organizerId, _selectedMethodId!, _amount);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully added \$${result['newBalance'].toStringAsFixed(2)}'),
              backgroundColor: const Color(0xFF00C950),
            ),
          );
          widget.onAddFunds(_amount);
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Payment failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    if (_isAdding) return;
    setState(() {
      _amount = amount;
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool canAdd = _amount > 0 && _selectedMethodId != null && !_isAdding && !_isLoadingMethods;

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
            readOnly: _isAdding,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: _isAdding ? Colors.grey : Colors.white, fontSize: 18),
            onChanged: (val) {
              setState(() {
                _amount = double.tryParse(val) ?? 0.0;
              });
            },
            decoration: InputDecoration(
              prefixText: '\$',
              prefixStyle: TextStyle(color: _isAdding ? Colors.grey : Colors.white, fontSize: 18),
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
              child: (_isLoadingMethods)
                ? const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA2F301)),
                      ),
                    ),
                  )
                : DropdownButton<String>(
                    value: _selectedMethodId,
                    hint: Text(_selectedMethodLabel, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1F),
                    iconEnabledColor: const Color(0xFF888888),
                    style: TextStyle(color: _isAdding ? Colors.grey : Colors.white, fontSize: 16),
                    items: _paymentMethods.isEmpty 
                      ? null
                      : _paymentMethods.map((pm) {
                          return DropdownMenuItem<String>(
                            value: pm['id'],
                            child: Text(_formatMethodLabel(pm)),
                          );
                        }).toList(),
                    onChanged: _isAdding ? null : (val) {
                      setState(() {
                        _selectedMethodId = val;
                      });
                    },
                  ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Funds are added instantly to your wallet balance',
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
                            : (_isAdding ? Colors.grey : Colors.white),
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
            onTap: canAdd ? _handleAddFunds : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: canAdd
                  ? const Color(0xFFA2F301)
                  : const Color(0xFF2A2A2F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isAdding 
                ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)))
                : Text(
                    'Add \$${_amount.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: canAdd ? Colors.black : const Color(0xFF555555),
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isAdding ? null : () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Cancel',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _isAdding ? Colors.grey : Colors.white,
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
