import 'package:flutter/material.dart';

class CountryCode {
  final String name;
  final String flag;
  final String code;

  const CountryCode({
    required this.name,
    required this.flag,
    required this.code,
  });
}

const List<CountryCode> countries = [
  CountryCode(name: 'United States', flag: '🇺🇸', code: '+1'),
  CountryCode(name: 'United Kingdom', flag: '🇬🇧', code: '+44'),
  CountryCode(name: 'Canada', flag: '🇨🇦', code: '+1'),
  CountryCode(name: 'Australia', flag: '🇦🇺', code: '+61'),
  CountryCode(name: 'Germany', flag: '🇩🇪', code: '+49'),
  CountryCode(name: 'France', flag: '🇫🇷', code: '+33'),
  CountryCode(name: 'India', flag: '🇮🇳', code: '+91'),
  CountryCode(name: 'Pakistan', flag: '🇵🇰', code: '+92'),
  CountryCode(name: 'United Arab Emirates', flag: '🇦🇪', code: '+971'),
  CountryCode(name: 'Saudi Arabia', flag: '🇸🇦', code: '+966'),
];

class CountryCodePicker extends StatelessWidget {
  final CountryCode selectedCountry;
  final ValueChanged<CountryCode> onCountryChanged;

  const CountryCodePicker({
    super.key,
    required this.selectedCountry,
    required this.onCountryChanged,
  });

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Country',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: countries.length,
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return ListTile(
                      leading: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        country.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        country.code,
                        style: const TextStyle(
                          color: Color(0xFFA2F301),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        onCountryChanged(country);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCountryPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2F)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedCountry.flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              selectedCountry.code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }
}
