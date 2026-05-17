import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _bankNameController = TextEditingController();
  final _routingController = TextEditingController();
  final _accountController = TextEditingController();
  String _selectedAccountType = 'Checking';

  @override
  void dispose() {
    _bankNameController.dispose();
    _routingController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  const Text('Add bank account', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
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

                    // Bank Name
                    Text('Bank Name', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bankNameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration('Chase Bank'),
                    ),
                    const SizedBox(height: 20),

                    // Account Type Dropdown
                    Text('Account type', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAccountType,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1A1A24),
                          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          items: ['Checking', 'Savings', 'Business'].map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedAccountType = val!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Routing Number
                    Text('Routing number', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _routingController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration('13134654656'),
                    ),
                    const SizedBox(height: 20),

                    // Account Number
                    Text('Account number', style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _accountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: _inputDecoration('013134654656'),
                    ),
                    const SizedBox(height: 20),

                    // Security Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SvgPicture.asset(
                            'assets/shield_icon.svg',
                            width: 22,
                            height: 22,
                            colorFilter: const ColorFilter.mode(Color(0xFF3B82F6), BlendMode.srcIn),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your bank information is encrypted and securely stored. We use industry-standard security measures to protect your financial data.',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.grey[800]!, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
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
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/bank_icon2.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            const Text('Add Bank Account', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
