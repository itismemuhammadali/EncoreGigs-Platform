import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlygigz_musician/models/profile_model.dart';
import 'package:onlygigz_musician/services/auth_service.dart';
import 'package:onlygigz_musician/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/profile_image_cropper_dialog.dart';
import '../../widgets/country_code_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  late TextEditingController fullNameController;
  late TextEditingController professionalTitleController;
  late TextEditingController bioController;
  late TextEditingController locationController;
  late TextEditingController primaryCityController;
  late TextEditingController primaryStateController;
  late TextEditingController primaryZipController;
  late TextEditingController secondaryCityController;
  late TextEditingController secondaryStateController;
  late TextEditingController secondaryZipController;
  late TextEditingController travelRadiusController;
  late TextEditingController phoneController;
  late TextEditingController minRateController;
  late TextEditingController maxRateController;
  late TextEditingController yearsOfExperienceController;
  final TextEditingController genreController = TextEditingController();
  final TextEditingController tagController = TextEditingController();

  List<String> selectedGenres = [];
  List<String> selectedTags = [];
  String? currentProfileImageUrl;
  String? currentBannerImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;
  File? _bannerImageFile;
  CountryCode _selectedCountry = countries[0];

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController();
    professionalTitleController = TextEditingController();
    bioController = TextEditingController();
    locationController = TextEditingController();
    primaryCityController = TextEditingController();
    primaryStateController = TextEditingController();
    primaryZipController = TextEditingController();
    secondaryCityController = TextEditingController();
    secondaryStateController = TextEditingController();
    secondaryZipController = TextEditingController();
    travelRadiusController = TextEditingController();
    phoneController = TextEditingController();
    minRateController = TextEditingController();
    maxRateController = TextEditingController();
    yearsOfExperienceController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final data = await _apiService.getProfile(currentUser.uid);

      if (mounted) {
        final profile = Profile.fromFirestore(data);

        setState(() {
          fullNameController.text = profile.name;
          professionalTitleController.text = profile.profession;
          bioController.text = profile.bio;
          locationController.text = profile.location;
          primaryCityController.text = data['primaryCity'] ?? profile.primaryCity;
          primaryStateController.text = data['primaryState'] ?? profile.primaryState;
          primaryZipController.text = data['primaryZip'] ?? profile.primaryZip;
          secondaryCityController.text = data['secondaryCity'] ?? profile.secondaryCity;
          secondaryStateController.text = data['secondaryState'] ?? profile.secondaryState;
          secondaryZipController.text = data['secondaryZip'] ?? profile.secondaryZip;
          travelRadiusController.text = (data['travelRadius'] ?? profile.travelRadius).toString();
          
          String phone = data['contact'] ?? '';
          if (phone.isNotEmpty) {
            bool found = false;
            for (var country in countries) {
              if (phone.startsWith(country.code)) {
                _selectedCountry = country;
                phoneController.text = phone.substring(country.code.length).trim();
                found = true;
                break;
              }
            }
            if (!found) {
              phoneController.text = phone;
            }
          }
          
          // Parsing rate range
          final rateStr = data['feeRange']?.toString() ?? '0';
          minRateController.text = rateStr;
          maxRateController.text = (data['maxFeeRange'] ?? rateStr).toString();
          
          yearsOfExperienceController.text = data['yearsOfExperience']?.toString() ?? '0';
          selectedGenres = List<String>.from(profile.genres);
          selectedTags = List<String>.from(profile.tags);
          currentProfileImageUrl = profile.profileImage;
          currentBannerImageUrl = profile.bannerImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTag(String rawTag) {
    final tag = rawTag.trim().replaceAll('#', '');
    if (tag.isEmpty) return;
    setState(() {
      if (!selectedTags.contains(tag)) {
        selectedTags.add(tag);
      }
      tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      selectedTags.remove(tag);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (pickedFile != null && mounted) {
      final croppedFile = await showDialog<File>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ProfileImageCropperDialog(
          imageFile: File(pickedFile.path),
        ),
      );

      if (croppedFile != null && mounted) {
        setState(() {
          _imageFile = croppedFile;
        });
      }
    }
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 900,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _bannerImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String? imageUrl = currentProfileImageUrl;
      String? bannerUrl = currentBannerImageUrl;

      if (_imageFile != null) {
        imageUrl = await authService.uploadImage(
          _imageFile!,
          'profile_images/${currentUser.uid}.jpg',
        );
      }

      if (_bannerImageFile != null) {
        bannerUrl = await authService.uploadImage(
          _bannerImageFile!,
          'profile_photos/banner_${currentUser.uid}.jpg',
        );
      }

      final pCity = primaryCityController.text.trim();
      final pState = primaryStateController.text.trim();
      final pZip = primaryZipController.text.trim();
      final computedLocation = (pCity.isNotEmpty && pState.isNotEmpty)
          ? '$pCity, $pState $pZip'.trim()
          : (locationController.text.isNotEmpty ? locationController.text.trim() : pCity);

      // Update via Backend
      await _apiService.updateProfile({
        'uid': currentUser.uid,
        'name': fullNameController.text.trim(),
        'email': currentUser.email,
        'contact': '${_selectedCountry.code} ${phoneController.text.trim()}',
        'location': computedLocation,
        'primaryCity': pCity,
        'primaryState': pState,
        'primaryZip': pZip,
        'secondaryCity': secondaryCityController.text.trim(),
        'secondaryState': secondaryStateController.text.trim(),
        'secondaryZip': secondaryZipController.text.trim(),
        'travelRadius': int.tryParse(travelRadiusController.text) ?? 50,
        'bio': bioController.text.trim(),
        'profileImageUrl': imageUrl,
        'bannerImageUrl': bannerUrl,
        'instruments': professionalTitleController.text.split(',').map((e) => e.trim()).toList(),
        'feeRange': double.tryParse(minRateController.text) ?? 0.0,
        'maxFeeRange': double.tryParse(maxRateController.text) ?? 0.0,
        'yearsOfExperience': int.tryParse(yearsOfExperienceController.text) ?? 0,
        'genres': selectedGenres,
        'tags': selectedTags,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    professionalTitleController.dispose();
    bioController.dispose();
    locationController.dispose();
    primaryCityController.dispose();
    primaryStateController.dispose();
    primaryZipController.dispose();
    secondaryCityController.dispose();
    secondaryStateController.dispose();
    secondaryZipController.dispose();
    travelRadiusController.dispose();
    phoneController.dispose();
    minRateController.dispose();
    maxRateController.dispose();
    yearsOfExperienceController.dispose();
    genreController.dispose();
    super.dispose();
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFA1F301))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button + Title with border
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Back', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your profile information',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // Profile Photo & Cover Banner Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFA1F301)
                                            .withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _imageFile != null
                                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                                          : (currentProfileImageUrl != null
                                              ? (_isNetworkImage(currentProfileImageUrl!)
                                                  ? Image.network(
                                                      currentProfileImageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Image.asset('assets/profile_image.png', fit: BoxFit.cover),
                                                    )
                                                  : Image.asset(currentProfileImageUrl!, fit: BoxFit.cover))
                                              : Image.asset('assets/profile_image.png', fit: BoxFit.cover)),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFFA1F301),
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: SvgPicture.asset(
                                              'assets/camera_icon.svg',
                                              fit: BoxFit.contain,
                                              colorFilter: const ColorFilter.mode(
                                                Colors.black,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFA1F301),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Upload Photo',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'JPG, PNG or WebP. Max 5MB.',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFF2A2A2F), height: 1),
                          const SizedBox(height: 20),

                          // Profile Cover Banner section inside Profile Photo Card
                          const Text(
                            'Profile Cover Banner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickBannerImage,
                            child: Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                color: const Color(0xFF0A0A0F),
                                image: _bannerImageFile != null
                                    ? DecorationImage(
                                        image: FileImage(_bannerImageFile!),
                                        fit: BoxFit.cover,
                                      )
                                    : (currentBannerImageUrl != null && currentBannerImageUrl!.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(currentBannerImageUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null),
                              ),
                              child: (_bannerImageFile == null && (currentBannerImageUrl == null || currentBannerImageUrl!.isEmpty))
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            color: Color(0xFFA1F301), size: 32),
                                        SizedBox(height: 6),
                                        Text(
                                          'Upload Banner Cover Image',
                                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    )
                                  : Stack(
                                      children: [
                                        Positioned(
                                          right: 10,
                                          top: 10,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.edit, color: Color(0xFFA1F301), size: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Information Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Full Name',
                            controller: fullNameController,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Professional Title',
                            controller: professionalTitleController,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Bio',
                            controller: bioController,
                            maxLines: 4,
                            hintText: 'Tell us about yourself and your experience',
                          ),
                          const SizedBox(height: 16),
                          // Primary City
                          const Text(
                            'Primary City (primarily based)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  label: '',
                                  controller: primaryCityController,
                                  hintText: 'City',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  label: '',
                                  controller: primaryStateController,
                                  hintText: 'State',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  label: '',
                                  controller: primaryZipController,
                                  hintText: 'Zip',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Secondary City
                          const Text(
                            'Secondary City (where you play second most often)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  label: '',
                                  controller: secondaryCityController,
                                  hintText: 'City',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  label: '',
                                  controller: secondaryStateController,
                                  hintText: 'State',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  label: '',
                                  controller: secondaryZipController,
                                  hintText: 'Zip',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Distance Willing to Travel
                          const Text(
                            'Distance Willing to Travel (miles radius)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            label: '',
                            controller: travelRadiusController,
                            hintText: '50',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Phone Number',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
                                child: _buildTextField(
                                  label: '',
                                  controller: phoneController,
                                  hintText: '555 000-0000',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Professional Details Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Professional Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Rate Range',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField(
                                      label: '',
                                      controller: minRateController,
                                      isCompact: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Minimum rate',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTextField(
                                      label: '',
                                      controller: maxRateController,
                                      isCompact: true,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Maximum rate',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Years Performing Professionally',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            label: '',
                            controller: yearsOfExperienceController,
                            isCompact: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Music Genres Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Music Genres',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: selectedGenres.map((genre) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: const Color(0xFFA1F301).withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      genre,
                                      style: const TextStyle(
                                        color: Color(0xFFA1F301),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedGenres.remove(genre);
                                        });
                                      },
                                      child: const Text(
                                        '×',
                                        style: TextStyle(
                                          color: Color(0xFFA1F301),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: genreController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Add a genre',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF0A0A0F),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      borderSide: BorderSide(
                                        color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      borderSide: BorderSide(
                                        color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFA1F301),
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () {
                                  if (genreController.text.isNotEmpty) {
                                    setState(() {
                                      selectedGenres.add(genreController.text);
                                      genreController.clear();
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1F301),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Profile & Vibe Tags Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profile & Vibe Tags',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Custom tags describing your vibe & specialties (e.g. Acoustic, Wedding, High Energy)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedTags.map((tag) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1F),
                                  border: Border.all(
                                    color: const Color(0xFFA1F301).withValues(alpha: 0.5),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '#$tag',
                                      style: const TextStyle(
                                        color: Color(0xFFA1F301),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _removeTag(tag),
                                      child: const Text(
                                        '×',
                                        style: TextStyle(
                                          color: Color(0xFFA1F301),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: tagController,
                                  onSubmitted: _addTag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Add a tag (e.g. Acoustic)',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF0A0A0F),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      borderSide: BorderSide(
                                        color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      borderSide: BorderSide(
                                        color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(50),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFA1F301),
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _addTag(tagController.text),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1F301),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Add',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFA1F301)
                                      .withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _isSaving ? null : _saveChanges,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    String? hintText,
    bool isCompact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 14,
            ),
            filled: true,
            fillColor: const Color(0xFF0A0A0F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFA1F301),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
