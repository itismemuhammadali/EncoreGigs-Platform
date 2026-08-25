import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/complete_profile_header.dart';
import '../../widgets/profile_image_cropper_dialog.dart';

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
  late TextEditingController _tagController;
  File? _imageFile;
  File? _bannerImageFile;
  final ImagePicker _picker = ImagePicker();

  final List<String> primaryGenres = [
    'Country',
    'Rock',
    'Pop',
    'Hip Hop / R&B',
    'Jazz',
    'Blues',
    'Electronic',
    'Latin',
    'Gospel',
    'Cajun / Zydeco',
    'Swamp Pop',
    'Soul',
    'Other',
  ];

  final List<String> subgenresList = [
    'Country Rock',
    'Pop',
    'Hip Hop R&B',
    'Jazz',
    'Blues',
    'Electronic',
    'Latin Gospel',
    'Cajun / Zydeco',
    'Swamp Pop',
    'Soul',
    'Other...',
  ];

  final List<String> instruments = [
    'Vocals',
    'Guitar',
    'Bass',
    'Drums',
    'Piano / Keys',
    'Accordion',
    'Saxophone',
    'Violin',
    'Trumpet',
    'DJ',
    'MC',
    'Other...',
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
    _tagController = TextEditingController();
    if (widget.profileData['profileImage'] != null) {
      _imageFile = widget.profileData['profileImage'] as File;
    }
    if (widget.profileData['bannerImage'] != null) {
      _bannerImageFile = widget.profileData['bannerImage'] as File;
    }
    widget.profileData['primaryGenre'] ??= '';
    widget.profileData['subgenres'] ??= <String>[];
    widget.profileData['tags'] ??= <String>[];
    widget.profileData['genres'] ??= <String>[];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String rawTag) {
    final tag = rawTag.trim().replaceAll('#', '');
    if (tag.isEmpty) return;
    setState(() {
      final tags = List<String>.from(widget.profileData['tags'] ?? []);
      if (!tags.contains(tag)) {
        tags.add(tag);
        widget.profileData['tags'] = tags;
      }
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      final tags = List<String>.from(widget.profileData['tags'] ?? []);
      tags.remove(tag);
      widget.profileData['tags'] = tags;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
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
            widget.profileData['profileImage'] = _imageFile;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickBannerImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _bannerImageFile = File(pickedFile.path);
          widget.profileData['bannerImage'] = _bannerImageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking banner image: $e')),
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

  void _showBannerImageSourceActionSheet() {
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
            const Text(
              'Select Banner Image Source',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFA1F301)),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickBannerImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFA1F301)),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickBannerImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _selectPrimaryGenre(String genre) {
    setState(() {
      if (widget.profileData['primaryGenre'] == genre) {
        widget.profileData['primaryGenre'] = '';
      } else {
        widget.profileData['primaryGenre'] = genre;
      }
      _syncAllGenres();
    });
  }

  void _toggleSubgenre(String subgenre) {
    final List<String> currentSub = List<String>.from(widget.profileData['subgenres'] ?? []);
    if (currentSub.contains(subgenre)) {
      currentSub.remove(subgenre);
    } else {
      if (currentSub.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can pick up to 3 subgenres'),
            backgroundColor: Colors.amber,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      currentSub.add(subgenre);
    }
    setState(() {
      widget.profileData['subgenres'] = currentSub;
      _syncAllGenres();
    });
  }

  void _syncAllGenres() {
    final List<String> all = [];
    final primary = widget.profileData['primaryGenre'] as String? ?? '';
    if (primary.isNotEmpty) {
      all.add(primary);
    }
    final subs = List<String>.from(widget.profileData['subgenres'] ?? []);
    for (var s in subs) {
      if (!all.contains(s)) {
        all.add(s);
      }
    }
    widget.profileData['genres'] = all;
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
                  // Banner Image Picker
          const Text(
            'Profile Cover Banner',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showBannerImageSourceActionSheet,
            child: Container(
              width: double.infinity,
              height: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                color: const Color(0xFF1A1A1F),
                image: _bannerImageFile != null
                    ? DecorationImage(
                        image: FileImage(_bannerImageFile!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _bannerImageFile == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: Color(0xFFA1F301), size: 34),
                        SizedBox(height: 6),
                        Text(
                          'Upload Profile Cover Banner',
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
          const SizedBox(height: 20),

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

          // Profile & Vibe Tags
          const Text(
            'Profile & Vibe Tags',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Type custom tags to describe your vibe (e.g. Acoustic, Wedding, High Energy)',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  onSubmitted: _addTag,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a tag (e.g. Acoustic)',
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
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _addTag(_tagController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA1F301),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if ((widget.profileData['tags'] as List).isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (widget.profileData['tags'] as List<String>).map((tag) {
                return Chip(
                  backgroundColor: const Color(0xFF1A1A1F),
                  side: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.5)),
                  label: Text(
                    '#$tag',
                    style: const TextStyle(color: Color(0xFFA1F301), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.white70),
                  onDeleted: () => _removeTag(tag),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Primary Genre Section
          const Text(
            'Primary Genre',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select 1 main genre that defines your music',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: primaryGenres.map((genre) {
              final isSelected = widget.profileData['primaryGenre'] == genre;
              return GestureDetector(
                onTap: () => _selectPrimaryGenre(genre),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Subgenres Section (Pick up to 3)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subgenres (Pick up to 3)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(widget.profileData['subgenres'] as List? ?? []).length}/3 selected',
                style: const TextStyle(
                  color: Color(0xFFA1F301),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose up to 3 subgenres that best describe your sound',
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subgenresList.map((subgenre) {
              final isSelected = (widget.profileData['subgenres'] as List? ?? []).contains(subgenre);
              return GestureDetector(
                onTap: () => _toggleSubgenre(subgenre),
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subgenre,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 14,
                        ),
                      ],
                    ],
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
