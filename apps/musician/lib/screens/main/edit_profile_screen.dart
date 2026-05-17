import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onlygigz_musician/models/profile_model.dart';
import 'package:onlygigz_musician/services/auth_service.dart';
import 'package:onlygigz_musician/services/api_service.dart';
import 'package:provider/provider.dart';

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
  late TextEditingController phoneController;
  late TextEditingController minRateController;
  late TextEditingController maxRateController;
  late TextEditingController yearsOfExperienceController;
  final TextEditingController genreController = TextEditingController();

  List<String> selectedGenres = [];
  String? currentProfileImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController();
    professionalTitleController = TextEditingController();
    bioController = TextEditingController();
    locationController = TextEditingController();
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
          phoneController.text = data['contact'] ?? '';
          
          // Parsing rate range
          final rateStr = data['feeRange']?.toString() ?? '0';
          minRateController.text = rateStr;
          maxRateController.text = (data['maxFeeRange'] ?? rateStr).toString();
          
          yearsOfExperienceController.text = data['yearsOfExperience']?.toString() ?? '0';
          selectedGenres = List<String>.from(profile.genres);
          currentProfileImageUrl = profile.profileImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
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

      if (_imageFile != null) {
        imageUrl = await authService.uploadImage(
          _imageFile!,
          'profile_images/${currentUser.uid}.jpg',
        );
      }

      // Update via Backend
      await _apiService.updateProfile({
        'uid': currentUser.uid,
        'name': fullNameController.text.trim(),
        'email': currentUser.email,
        'contact': phoneController.text.trim(),
        'location': locationController.text.trim(),
        'bio': bioController.text.trim(),
        'profileImageUrl': imageUrl,
        'instruments': professionalTitleController.text.split(',').map((e) => e.trim()).toList(),
        'feeRange': double.tryParse(minRateController.text) ?? 0.0,
        'maxFeeRange': double.tryParse(maxRateController.text) ?? 0.0,
        'yearsOfExperience': int.tryParse(yearsOfExperienceController.text) ?? 0,
        'genres': selectedGenres,
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

                    // Profile Photo Section
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
                          _buildTextField(
                            label: 'Location',
                            controller: locationController,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Phone Number',
                            controller: phoneController,
                            hintText: '+1 (555) 000-0000',
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
                            'Years of Experience',
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
