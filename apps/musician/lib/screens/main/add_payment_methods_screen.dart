import 'package:flutter/material.dart';
import 'card_added_success_screen.dart';

class AddPaymentMethodsScreen extends StatefulWidget {
  const AddPaymentMethodsScreen({super.key});

  @override
  State<AddPaymentMethodsScreen> createState() => _AddPaymentMethodsScreenState();
}

class _AddPaymentMethodsScreenState extends State<AddPaymentMethodsScreen> {
  final _cardNumberController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: hint.contains('1234') ? const Icon(Icons.credit_card, color: Colors.grey) : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[800]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFA1F301), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  const Text('Add Payment Methods', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Enter your card details', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: const Color(0xFFA1F301).withValues(alpha: 0.3)),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Card Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFA1F301),
                            const Color(0xFF0A0A0F),
                          ],
                        ),
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
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Text('Card', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text('•••• •••• •••• ••••', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 2)),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Cardholder Name', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                  const SizedBox(height: 4),
                                  const Text('FULL NAME', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Expires', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                  const SizedBox(height: 4),
                                  const Text('MM/YY', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Card Number
                    Text('Card Number', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration('1234 5678 9012 3456'),
                    ),
                    const SizedBox(height: 20),

                    // Cardholder Name
                    Text('Cardholder Name', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _cardholderNameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration('John Doe'),
                    ),
                    const SizedBox(height: 20),

                    // Expiry + CVV row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Expiry Date', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _expiryController,
                                keyboardType: TextInputType.datetime,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: _inputDecoration('MM/YY'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CVV', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: _inputDecoration('123'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ZIP Code
                    Text('ZIP Code', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration('12345'),
                    ),
                    const SizedBox(height: 20),

                    // Secure Payment Info
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
                          Row(
                            children: [
                              Icon(Icons.credit_card, color: const Color(0xFFA1F301), size: 24),
                              const SizedBox(width: 12),
                              const Text('Secure Payment', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your card information is encrypted and secure. We never store your full card details.',
                            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.6),
                          ),
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
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CardAddedSuccessScreen())),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA1F301),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, color: Colors.black, size: 20),
                      SizedBox(width: 8),
                      Text('Add Card', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
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
}
