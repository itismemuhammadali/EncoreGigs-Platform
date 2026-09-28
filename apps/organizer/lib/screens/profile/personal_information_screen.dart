import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';
import '../../widgets/country_code_picker.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _bioController = TextEditingController();
  String? _profileImageUrl;
  File? _selectedImage;
  bool _isLoading = true;
  bool _isSaving = false;
  CountryCode _selectedCountry = countries[0];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user != null) {
      final profile = await authService.getProfile(user.uid);
      if (profile != null) {
        setState(() {
          _nameController.text = profile['name'] ?? profile['fullName'] ?? profile['orgName'] ?? '';
          _emailController.text = profile['email'] ?? profile['businessEmail'] ?? user.email ?? '';
          
          String phone = profile['contact'] ?? profile['phone'] ?? profile['businessPhone'] ?? '';
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
          _cityController.text = profile['city'] ?? profile['primaryCity'] ?? '';
          _stateController.text = profile['state'] ?? profile['primaryState'] ?? '';
          _zipController.text = profile['zipCode'] ?? profile['zip'] ?? profile['primaryZip'] ?? '';

          // Fallback if city/state is empty but legacy location exists
          if (_cityController.text.isEmpty && profile['location'] != null) {
            final loc = profile['location'].toString();
            if (loc.contains(',')) {
              final parts = loc.split(',');
              _cityController.text = parts[0].trim();
              if (parts.length > 1) {
                _stateController.text = parts[1].trim();
              }
            } else {
              _cityController.text = loc.trim();
            }
          }

          _bioController.text = profile['bio'] ?? profile['description'] ?? profile['about'] ?? '';
          _profileImageUrl = fixEmulatorUrl(profile['profileImageUrl']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
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
              title: const Text('Take a photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1200,
                  maxHeight: 1200,
                  imageQuality: 85,
                );
                if (context.mounted) Navigator.pop(context, photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFA2F301)),
              title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final XFile? galleryImage = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1200,
                  maxHeight: 1200,
                  imageQuality: 85,
                );
                if (context.mounted) Navigator.pop(context, galleryImage);
              },
            ),
          ],
        ),
      ),
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isLoading) return;
    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    String? imageUrl = _profileImageUrl;
    if (_selectedImage != null) {
      final uploadPath = 'profile_photos/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final uploadedUrl = await authService.uploadImage(
        _selectedImage!,
        uploadPath,
      );
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    final street = _addressController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final zip = _zipController.text.trim();
    final combinedLocation = [city, state].where((s) => s.isNotEmpty).join(', ');

    // 1. Immediately persist to Firestore
    try {
      final Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'contact': '${_selectedCountry.code} ${_phoneController.text.trim()}',
        'address': street,
        'city': city,
        'state': state,
        'zipCode': zip,
        'location': combinedLocation.isNotEmpty ? combinedLocation : street,
        'bio': _bioController.text.trim(),
        'about': _bioController.text.trim(),
      };
      if (imageUrl != null) {
        updateData['profileImageUrl'] = imageUrl;
      }
      await FirebaseFirestore.instance
          .collection('organizers')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore direct save error: $e');
    }

    // 2. Persist via backend API
    final error = await authService.updateProfile(
      uid: user.uid,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      contact: '${_selectedCountry.code} ${_phoneController.text.trim()}',
      location: combinedLocation.isNotEmpty ? combinedLocation : street,
      bio: _bioController.text.trim(),
      address: street,
      city: city,
      state: state,
      zipCode: zip,
      profileImageUrl: imageUrl,
    );

    setState(() {
      _isSaving = false;
      if (imageUrl != null) {
        _profileImageUrl = imageUrl;
      }
    });

    if (error == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _bioController.dispose();
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
          'Personal Information',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2A2A2F),
                              shape: BoxShape.circle,
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                        color: Color(0xFFA2F301),
                                        strokeWidth: 2))
                                : (_selectedImage != null
                                    ? Image.file(_selectedImage!,
                                        fit: BoxFit.cover)
                                    : (_profileImageUrl != null
                                        ? Image.network(_profileImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Icon(Icons.person,
                                                    color: Color(0xFF666666),
                                                    size: 40))
                                        : const Icon(Icons.person,
                                            color: Color(0xFF666666),
                                            size: 40))),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFFA2F301),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/camera_icon.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(
                                      Colors.black, BlendMode.srcIn),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Click the camera icon to change photo',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildLabel('Full Name'),
              const SizedBox(height: 8),
              _buildField(_nameController, 'Your Name'),
              const SizedBox(height: 20),
              _buildLabel('Email Address'),
              const SizedBox(height: 8),
              _buildField(_emailController, 'your@email.com',
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildLabel('Phone Number'),
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
              // Location fields
              _buildLabel('Street Address'),
              const SizedBox(height: 8),
              _buildField(_addressController, 'e.g. 123 Main St'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('City'),
                        const SizedBox(height: 8),
                        _buildField(_cityController, 'City'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('State'),
                        const SizedBox(height: 8),
                        _buildField(_stateController, 'State'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Zip Code'),
                        const SizedBox(height: 8),
                        _buildField(_zipController, 'Zip Code',
                            keyboardType: TextInputType.text),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // About (formerly Bio)
              _buildLabel('About'),
              const SizedBox(height: 6),
              const Text(
                'Tell entertainers a little about you, your organization, venue, or the types of events you host.',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bioController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Share anything you'd like entertainers to know about you or your events...",
                  hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 14),
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
          onTap: (_isSaving || _isLoading) ? null : _saveProfile,
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
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      );

  Widget _buildField(
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA2F301)),
        ),
      ),
    );
  }
}
