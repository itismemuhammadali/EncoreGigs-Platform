import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  final _bankNameController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingController = TextEditingController();
  final _zipController = TextEditingController();
  bool _isChecking = true;
  bool _setAsDefault = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _routingController.dispose();
    _zipController.dispose();
    super.dispose();
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
        title: const Text('Add Bank Account',
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
                            child: SvgPicture.asset(
                              'assets/bank_icon.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFFA2F301), BlendMode.srcIn),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _isChecking ? 'Checking' : 'Savings',
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _bankNameController.text.isEmpty
                          ? 'Bank Name'
                          : _bankNameController.text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _holderNameController.text.isEmpty
                          ? 'Account Holder Name'
                          : _holderNameController.text,
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _accountNumberController.text.isEmpty
                          ? '•••• •••• •••• ••••'
                          : '•••• •••• •••• ${_accountNumberController.text.length >= 4 ? _accountNumberController.text.substring(_accountNumberController.text.length - 4) : '••••'}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Bank Name'),
              const SizedBox(height: 8),
              _buildField(_bankNameController, 'Chase Bank'),
              const SizedBox(height: 16),
              _buildLabel('Account Holder Name'),
              const SizedBox(height: 8),
              _buildField(_holderNameController, 'John Doe'),
              const SizedBox(height: 16),
              _buildLabel('Account Number'),
              const SizedBox(height: 8),
              _buildField(_accountNumberController, '1234567890',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildLabel('Routing Number'),
              const SizedBox(height: 8),
              _buildField(_routingController, '021000021',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildLabel('ZIP Code'),
              const SizedBox(height: 8),
              _buildField(_zipController, '90210',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildLabel('Account Type'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isChecking = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isChecking
                              ? const Color(0xFFA2F301)
                              : const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Checking',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isChecking ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isChecking = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isChecking
                              ? const Color(0xFFA2F301)
                              : const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Savings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_isChecking ? Colors.black : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                          Text('Use this account for withdrawals',
                              style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0x1AA2F301),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DA2F301)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: Color(0xFFA2F301), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your bank details are encrypted and secure. We use industry-standard encryption to protect your information.',
                        style: TextStyle(
                            color: Color(0xFFA2F301), fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
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
            child: const Text('Save Bank Account',
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
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
