import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/signup_provider.dart';
import '../../../widgets/country_code_picker.dart';

class Step2OrganizerInfo extends StatefulWidget {
  const Step2OrganizerInfo({super.key});

  @override
  State<Step2OrganizerInfo> createState() => _Step2OrganizerInfoState();
}

class _Step2OrganizerInfoState extends State<Step2OrganizerInfo> {
  final _contactController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedType;
  CountryCode _selectedCountry = countries[0]; // Default to US

  final List<String> _organizerTypes = [
    'Event Planner',
    'Venue Owner',
    'Corporate',
    'Private',
    'Other',
  ];

  @override
  void dispose() {
    _contactController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_selectedType == null ||
        _contactController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    Provider.of<SignUpProvider>(context, listen: false).updateStep2(
      type: _selectedType!,
      contact: '${_selectedCountry.code} ${_contactController.text.trim()}',
      location: _locationController.text.trim(),
    );

    Navigator.of(context).pushNamed('/signup/step3');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white),
          ),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Organizer Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tell us about yourself',
                style: TextStyle(color: Color(0xFF999999), fontSize: 14),
              ),
              const SizedBox(height: 32),
              _buildLabel('Organizer Type'),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildLabel('Contact Number'),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CountryCodePicker(
                    selectedCountry: _selectedCountry,
                    onCountryChanged: (code) {
                      setState(() {
                        _selectedCountry = code;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(_contactController, '555 000-0000',
                        keyboardType: TextInputType.phone),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('City & Location'),
              const SizedBox(height: 8),
              _buildTextField(_locationController, 'Los Angeles, CA'),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildNextButton(
        onTap: _handleNext,
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      );

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          hint: const Text('Select type',
              style: TextStyle(color: Color(0xFF555555))),
          dropdownColor: const Color(0xFF1A1A1F),
          iconEnabledColor: const Color(0xFF666666),
          isExpanded: true,
          items: _organizerTypes
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type,
                        style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          onChanged: (val) => setState(() => _selectedType = val),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555)),
        filled: true,
        fillColor: const Color(0xFF1A1A1F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildNextButton({required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFA2F301),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Next',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
