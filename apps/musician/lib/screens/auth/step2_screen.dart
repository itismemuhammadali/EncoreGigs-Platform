import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/complete_profile_header.dart';

class Step2Screen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2Screen({
    super.key,
    required this.profileData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step2Screen> createState() => _Step2ScreenState();
}

class _Step2ScreenState extends State<Step2Screen> {
  late TextEditingController _hourlyRateController;
  late TextEditingController _yearsController;
  late TextEditingController _primaryCityController;
  late TextEditingController _primaryStateController;
  late TextEditingController _primaryZipController;
  late TextEditingController _secondaryCityController;
  late TextEditingController _secondaryStateController;
  late TextEditingController _secondaryZipController;
  late TextEditingController _travelRadiusController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    final initialRate = widget.profileData['hourlyRate'] ?? widget.profileData['feeRange'] ?? 50;
    _hourlyRateController = TextEditingController(
      text: initialRate.toString(),
    );
    _yearsController = TextEditingController(
      text: widget.profileData['yearsOfExperience'].toString(),
    );
    _primaryCityController = TextEditingController(
      text: widget.profileData['primaryCity'] ?? '',
    );
    _primaryStateController = TextEditingController(
      text: widget.profileData['primaryState'] ?? '',
    );
    _primaryZipController = TextEditingController(
      text: widget.profileData['primaryZip'] ?? '',
    );
    _secondaryCityController = TextEditingController(
      text: widget.profileData['secondaryCity'] ?? '',
    );
    _secondaryStateController = TextEditingController(
      text: widget.profileData['secondaryState'] ?? '',
    );
    _secondaryZipController = TextEditingController(
      text: widget.profileData['secondaryZip'] ?? '',
    );
    _travelRadiusController = TextEditingController(
      text: (widget.profileData['travelRadius'] ?? 50).toString(),
    );
    _websiteController = TextEditingController(
      text: widget.profileData['website'] ?? '',
    );
  }

  @override
  void dispose() {
    _hourlyRateController.dispose();
    _yearsController.dispose();
    _primaryCityController.dispose();
    _primaryStateController.dispose();
    _primaryZipController.dispose();
    _secondaryCityController.dispose();
    _secondaryStateController.dispose();
    _secondaryZipController.dispose();
    _travelRadiusController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _updateLocationData() {
    widget.profileData['primaryCity'] = _primaryCityController.text.trim();
    widget.profileData['primaryState'] = _primaryStateController.text.trim();
    widget.profileData['primaryZip'] = _primaryZipController.text.trim();
    widget.profileData['secondaryCity'] = _secondaryCityController.text.trim();
    widget.profileData['secondaryState'] = _secondaryStateController.text.trim();
    widget.profileData['secondaryZip'] = _secondaryZipController.text.trim();
    widget.profileData['travelRadius'] = int.tryParse(_travelRadiusController.text) ?? 50;

    final city = _primaryCityController.text.trim();
    final st = _primaryStateController.text.trim();
    final zip = _primaryZipController.text.trim();

    if (city.isNotEmpty && st.isNotEmpty) {
      widget.profileData['location'] = '$city, $st $zip'.trim();
    } else if (city.isNotEmpty) {
      widget.profileData['location'] = city;
    }
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[700]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFA1F301)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with full-width divider
        CompleteProfileHeader(
          currentStep: 2,
          totalSteps: 3,
          onBack: widget.onBack,
        ),
        
        // Scrollable content
        Expanded(
          child: Container(
            color: const Color(0xFF0A0A0F),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

          // Hourly Rate
          const Text(
            'Hourly Rate (\$/hr)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _hourlyRateController,
            onChanged: (value) {
              final rate = int.tryParse(value) ?? 0;
              widget.profileData['hourlyRate'] = rate;
              widget.profileData['feeRange'] = rate;
            },
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(
                color: Color(0xFFA1F301),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              hintText: '50',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA1F301)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Years Performing Professionally
          const Text(
            'Years Performing Professionally',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _yearsController,
            onChanged: (value) {
              widget.profileData['yearsOfExperience'] =
                  int.tryParse(value) ?? 0;
            },
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA1F301)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary City
          const Text(
            'Primary City',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '(primarily based)',
            style: TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _primaryCityController,
                  onChanged: (_) => _updateLocationData(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('City'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _primaryStateController,
                  onChanged: (_) => _updateLocationData(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('State'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _primaryZipController,
                  onChanged: (_) => _updateLocationData(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('Zip'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Secondary City
          const Text(
            'Secondary City',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '(where you play second most often)',
            style: TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _secondaryCityController,
                  onChanged: (_) => _updateLocationData(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('City'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _secondaryStateController,
                  onChanged: (_) => _updateLocationData(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('State'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _secondaryZipController,
                  onChanged: (_) => _updateLocationData(),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('Zip'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Distance Willing to Travel
          const Text(
            'Distance Willing to Travel',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            '(radius) Miles radius',
            style: TextStyle(color: Color(0xFF999999), fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _travelRadiusController,
            onChanged: (_) => _updateLocationData(),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              suffixText: 'miles',
              suffixStyle: const TextStyle(color: Color(0xFFA1F301), fontWeight: FontWeight.bold),
              hintText: '50',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA1F301)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Website / Social Media
          const Text(
            'Website / Social Media',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _websiteController,
            onChanged: (value) {
              widget.profileData['website'] = value;
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA1F301)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
              ),
            ),
          ),
        ),
        
        // Fixed button at bottom
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA1F301),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: SvgPicture.asset('assets/next_arrow_no_tail.svg'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
