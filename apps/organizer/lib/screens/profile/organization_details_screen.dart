import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/country_code_picker.dart';

class OrganizationDetailsScreen extends StatefulWidget {
  const OrganizationDetailsScreen({super.key});

  @override
  State<OrganizationDetailsScreen> createState() =>
      _OrganizationDetailsScreenState();
}

class _OrganizationDetailsScreenState
    extends State<OrganizationDetailsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedType;
  String? _licenseUrl;
  File? _selectedLicenseFile;
  bool _isLoading = true;
  bool _isSaving = false;
  CountryCode _selectedCountry = countries[0];

  final List<String> _orgTypes = [
    'Venue / Club',
    'Event Planner',
    'Corporate',
    'Private',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrganizationData();
  }

  Future<void> _loadOrganizationData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user != null) {
      final profile = await authService.getProfile(user.uid);
      if (profile != null) {
        setState(() {
          _nameController.text = profile['orgName'] ?? profile['name'] ?? '';
          _emailController.text = profile['businessEmail'] ?? profile['email'] ?? '';
          
          String phone = profile['businessPhone'] ?? profile['contact'] ?? '';
          if (phone.isNotEmpty) {
            bool found = false;
            for (var country in countries) {
              if (phone.startsWith(country.code)) {
                _selectedCountry = country;
                _phoneController.text = phone.substring(country.code.length).trim();
                found = true;
                break;
              }
            }
            if (!found) {
              _phoneController.text = phone;
            }
          }

          _addressController.text = profile['address'] ?? '';
          _cityController.text = profile['city'] ?? '';
          _stateController.text = profile['state'] ?? '';
          _zipController.text = profile['zipCode'] ?? '';
          _websiteController.text = profile['website'] ?? '';
          _taxIdController.text = profile['taxId'] ?? '';
          _descriptionController.text = profile['description'] ?? '';
          _licenseUrl = profile['licenseUrl'];
          
          // Use 'type' from DB to set dropdown
          final dbType = profile['type'];
          if (dbType != null && _orgTypes.contains(dbType)) {
            _selectedType = dbType;
          } else {
            _selectedType = 'Other';
          }
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _selectedType = _orgTypes.first;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLicense() async {
    if (_isLoading) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFA2F301)),
              title: const Text('Take a photo of license', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                if (mounted) Navigator.pop(context, photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFA2F301)),
              title: const Text('Choose license from gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final XFile? galleryImage = await picker.pickImage(source: ImageSource.gallery);
                if (mounted) Navigator.pop(context, galleryImage);
              },
            ),
          ],
        ),
      ),
    );

    if (image != null) {
      setState(() {
        _selectedLicenseFile = File(image.path);
      });
    }
  }

  Future<void> _saveOrganizationData() async {
    if (_isLoading) return;
    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) return;

    String? licenseUrl = _licenseUrl;
    if (_selectedLicenseFile != null) {
      final uploadedUrl = await authService.uploadImage(
        _selectedLicenseFile!,
        'business_licenses/${user.uid}.jpg',
      );
      if (uploadedUrl != null) {
        licenseUrl = uploadedUrl;
      }
    }

    final error = await authService.updateOrganization(
      uid: user.uid,
      orgName: _nameController.text,
      type: _selectedType ?? 'Other',
      businessEmail: _emailController.text,
      businessPhone: '${_selectedCountry.code} ${_phoneController.text.trim()}',
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipController.text,
      website: _websiteController.text,
      taxId: _taxIdController.text,
      description: _descriptionController.text,
      licenseUrl: licenseUrl,
    );

    setState(() => _isSaving = false);

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization details updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  String _getLicenseName() {
    if (_selectedLicenseFile != null) {
      return _selectedLicenseFile!.path.split('/').last;
    }
    if (_licenseUrl != null) {
      return 'business-license.jpg';
    }
    return 'No document uploaded';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _descriptionController.dispose();
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
            child: const Icon(Icons.chevron_left,
                color: Colors.white, size: 26),
          ),
        ),
        title: const Text(
          'Organization Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Update your organization or venue information',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xFF888888), fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Organization Name'),
              const SizedBox(height: 8),
              _buildField(_nameController, 'Organization name'),
              const SizedBox(height: 20),
              _buildLabel('Organization Type'),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildLabel('Business Email'),
              const SizedBox(height: 8),
              _buildField(_emailController, 'business@email.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildLabel('Business Phone'),
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
                    child: _buildField(_phoneController, '555 000-0000',
                        keyboardType: TextInputType.phone),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Business Address'),
              const SizedBox(height: 8),
              _buildField(_addressController, 'Street address'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildField(_cityController, 'City')),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildField(_stateController, 'State')),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(_zipController, 'ZIP Code',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildLabel('Website'),
              const SizedBox(height: 8),
              _buildField(_websiteController, 'https://yourwebsite.com',
                  keyboardType: TextInputType.url),
              const SizedBox(height: 20),
              _buildLabel('Tax ID / EIN'),
              const SizedBox(height: 8),
              _buildField(_taxIdController, 'XX-XXXXXXX'),
              const SizedBox(height: 20),
              _buildLabel('Business License'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getLicenseName(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          if (_licenseUrl != null || _selectedLicenseFile != null)
                            const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text('Document ready for review',
                                  style: TextStyle(
                                      color: Color(0xFF888888),
                                      fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickLicense,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/upload_icon.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFFA2F301), BlendMode.srcIn),
                            ),
                            const SizedBox(width: 6),
                            Text(
                                (_licenseUrl == null && _selectedLicenseFile == null)
                                    ? 'Upload'
                                    : 'Replace',
                                style: const TextStyle(
                                    color: Color(0xFFA2F301),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Describe your organization...',
                  hintStyle:
                      const TextStyle(color: Color(0xFF555555)),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFFA2F301)),
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
            24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
        child: GestureDetector(
          onTap: (_isSaving || _isLoading) ? null : _saveOrganizationData,
          child: Container(
            width: double.infinity,
            height: 56,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: (_isSaving || _isLoading) ? const Color(0xFF2A2A2F) : const Color(0xFFA2F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'Save Changes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: (_isSaving || _isLoading) ? Colors.white54 : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500),
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
          dropdownColor: const Color(0xFF1A1A1F),
          iconEnabledColor: const Color(0xFF888888),
          isExpanded: true,
          items: _orgTypes
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type,
                        style: const TextStyle(color: Colors.white)),
                  ))
              .toList(),
          onChanged: _isLoading ? null : (val) => setState(() => _selectedType = val),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      style: TextStyle(color: _isLoading ? Colors.white54 : Colors.white),
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
