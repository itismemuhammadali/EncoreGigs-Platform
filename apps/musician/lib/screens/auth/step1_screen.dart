import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/complete_profile_header.dart';

class Step1Screen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onNext;

  const Step1Screen({
    super.key,
    required this.profileData,
    required this.onNext,
  });

  @override
  State<Step1Screen> createState() => _Step1ScreenState();
}

class _Step1ScreenState extends State<Step1Screen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> genres = [
    'Rock',
    'Jazz',
    'Classical',
    'Pop',
    'Hip Hop',
    'Electronic',
    'Country',
    'R&B',
  ];

  final List<String> instruments = [
    'Guitar',
    'Piano',
    'Drums',
    'Bass',
    'Vocals',
    'Saxophone',
    'Violin',
    'DJ',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profileData['fullName'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.profileData['bio'] ?? '',
    );
    if (widget.profileData['profileImage'] != null) {
      _imageFile = widget.profileData['profileImage'] as File;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          widget.profileData['profileImage'] = _imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFA1F301)),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFA1F301)),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (widget.profileData['genres'].contains(genre)) {
        widget.profileData['genres'].remove(genre);
      } else {
        widget.profileData['genres'].add(genre);
      }
    });
  }

  void _toggleInstrument(String instrument) {
    setState(() {
      if (widget.profileData['instruments'].contains(instrument)) {
        widget.profileData['instruments'].remove(instrument);
      } else {
        widget.profileData['instruments'].add(instrument);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with full-width divider
        CompleteProfileHeader(
          currentStep: 1,
          totalSteps: 3,
          onBack: () => Navigator.pop(context),
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

          // Profile Photo
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _showImageSourceActionSheet,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                        width: 2,
                      ),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      gradient: _imageFile == null 
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFA1F301).withValues(alpha: 0.1),
                              Colors.black,
                            ],
                          )
                        : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_imageFile == null)
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: SvgPicture.asset('assets/camera_icon.svg'),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA1F301),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0A0A0F),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                'assets/upload_icon.svg',
                                width: 16,
                                height: 16,
                                fit: BoxFit.contain,
                                colorFilter: const ColorFilter.mode(
                                  Colors.black,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload profile photo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Full Name
          const Text(
            'Full Name',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (value) {
              widget.profileData['fullName'] = value;
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your name',
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

          // Bio
          const Text(
            'Bio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            onChanged: (value) {
              widget.profileData['bio'] = value;
            },
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tell us about your musical journey...',
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

          // Genres
          const Text(
            'Genres',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              final isSelected = widget.profileData['genres'].contains(genre);
              return GestureDetector(
                onTap: () => _toggleGenre(genre),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFA1F301)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFA1F301)
                          : Colors.grey[700]!,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    genre,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Instruments / Skills
          const Text(
            'Instruments / Skills',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: instruments.map((instrument) {
              final isSelected =
                  widget.profileData['instruments'].contains(instrument);
              return GestureDetector(
                onTap: () => _toggleInstrument(instrument),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFA1F301)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFA1F301)
                          : Colors.grey[700]!,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    instrument,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
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
