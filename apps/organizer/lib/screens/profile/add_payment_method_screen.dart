import 'package:flutter/material.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _setAsDefault = false;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  String get _displayCardNumber {
    final raw = _cardNumberController.text.replaceAll(' ', '');
    if (raw.isEmpty) return '•••• •••• •••• ••••';
    return raw.padRight(16, '•').replaceAllMapped(
        RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim();
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
        title: const Text('Add Payment Method',
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
              // Card preview
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
                          width: 40,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFA2F301), width: 2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.credit_card,
                              color: Color(0xFFA2F301), size: 18),
                        ),
                        const Text('Debit Card',
                            style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _displayCardNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Card Holder',
                                style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _cardHolderController.text.isEmpty
                                  ? 'YOUR NAME'
                                  : _cardHolderController.text.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Expires',
                                style: TextStyle(color: Color(0xFF888888), fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              _expiryController.text.isEmpty
                                  ? 'MM/YY'
                                  : _expiryController.text,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Card Number'),
              const SizedBox(height: 8),
              _buildField(_cardNumberController, '1234 5678 9012 3456',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildLabel('Cardholder Name'),
              const SizedBox(height: 8),
              _buildField(_cardHolderController, 'JOHN DOE',
                  textCapitalization: TextCapitalization.characters),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Expiry Date'),
                        const SizedBox(height: 8),
                        _buildField(_expiryController, 'MM/YY',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CVV'),
                        const SizedBox(height: 8),
                        _buildField(_cvvController, '123',
                            keyboardType: TextInputType.number,
                            obscureText: true),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Set as default
              GestureDetector(
                onTap: () => setState(() => _setAsDefault = !_setAsDefault),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _setAsDefault
                              ? const Color(0xFFA2F301)
                              : Colors.transparent,
                          border: Border.all(
                            color: _setAsDefault
                                ? const Color(0xFFA2F301)
                                : const Color(0xFF555555),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _setAsDefault
                            ? const Icon(Icons.check, size: 14, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Set as default',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text('Use this card for future transactions',
                              style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
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
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFA2F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Save Payment Method',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500));

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: const Color(0xFF1A1A1F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA2F301)),
        ),
      ),
    );
  }
}
