import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import 'gig_posted_screen.dart';

class PostGigScreen extends StatefulWidget {
  final bool returnToGigs;

  const PostGigScreen({super.key, this.returnToGigs = false});

  @override
  State<PostGigScreen> createState() => _PostGigScreenState();
}

class _PostGigScreenState extends State<PostGigScreen> {
  static const List<String> _genreOptions = <String>[
    'Rock',
    'Jazz',
    'Classical',
    'Pop',
    'Hip-Hop',
    'Electronic',
    'Country',
    'R&B',
  ];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementInputController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController();
  final List<String> _requirements = [];
  final Set<String> _selectedGenres = <String>{};
  bool _isLoading = false;
  bool _isUrgent = false;
  File? _imageFile;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementInputController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        setState(() {
          _imageFile = file;
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

  void _showImagePickerOptions() {
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
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFA2F301)),
              title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFA2F301)),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addRequirement() {
    final value = _requirementInputController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _requirements.add(value);
      _requirementInputController.clear();
    });
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  Future<void> _handlePostGig() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _requirements.isEmpty ||
        _selectedGenres.isEmpty ||
        _dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _budgetController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    
    String? finalImageUrl;
    
    // 1. Upload image to Storage if exists
    if (_imageFile != null) {
      final String fileName = 'gig_${DateTime.now().millisecondsSinceEpoch}.jpg';
      finalImageUrl = await authService.uploadImage(_imageFile!, 'gigs/$fileName');
    }

    // 2. Create gig with the URL
    final error = await authService.createGig(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      requirements: _requirements,
      genres: _selectedGenres.toList(),
      date: _dateController.text.trim(),
      time: _timeController.text.trim(),
      budget: _budgetController.text.trim(),
      location: _locationController.text.trim(),
      imageUrl: finalImageUrl,
      duration: _durationController.text.trim(),
      isUrgent: _isUrgent,
    );

    if (mounted) {
      if (error == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GigPostedScreen(returnToGigs: widget.returnToGigs),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text('Post New Gig',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Gig Image'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imageFile != null
                          ? const Color(0xFFA2F301)
                          : const Color(0xFF2A2A2F),
                      width: 1,
                    ),
                  ),
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _imageFile!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _imageFile = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo_outlined,
                                color: Color(0xFF666666), size: 40),
                            const SizedBox(height: 12),
                            Text(
                              'Add a picture for the gig',
                              style: TextStyle(
                                color: const Color(0xFF666666),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildLabel('Gig Title'),
              const SizedBox(height: 8),
              _buildField(_titleController, 'e.g., Jazz Night - Friday'),
              const SizedBox(height: 20),
              _buildLabel('Description'),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText:
                      'Describe the gig, genre, duration, and event details...',
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
              ),
              const SizedBox(height: 20),
              _buildLabel('Requirements'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _requirementInputController,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _addRequirement(),
                      decoration: InputDecoration(
                        hintText: 'Add one requirement',
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _addRequirement,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA2F301),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.black),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_requirements.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_requirements.length, (index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2A2A2F)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _requirements[index],
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _removeRequirement(index),
                            child: const Icon(Icons.close, size: 14, color: Color(0xFFA2F301)),
                          ),
                        ],
                      ),
                    );
                  }),
                )
              else
                const Text(
                  'No requirements added yet.',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              const SizedBox(height: 20),
              _buildLabel('Genres (select one or more)'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genreOptions.map((genre) {
                  final bool isSelected = _selectedGenres.contains(genre);
                  return GestureDetector(
                    onTap: () => _toggleGenre(genre),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                        ),
                      ),
                      child: Text(
                        genre,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Date'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: _buildField(_dateController, 'MM/DD/YYYY'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Time'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _selectTime(context),
                          child: AbsorbPointer(
                            child: _buildField(_timeController, 'e.g., 8:00 PM'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('Budget / Rate'),
              const SizedBox(height: 8),
              _buildField(_budgetController, 'e.g., \$500-800'),
              const SizedBox(height: 20),
              _buildLabel('Duration'),
              const SizedBox(height: 8),
              _buildField(_durationController, 'e.g., 2 hours, 3 sets of 45 mins'),
              const SizedBox(height: 20),
              _buildLabel('Location'),
              const SizedBox(height: 8),
              _buildField(_locationController, 'e.g., Blue Note Jazz Club, NYC'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isUrgent ? const Color(0xFFFF4D4D) : const Color(0xFF2A2A2F),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isUrgent ? const Color(0xFFFF4D4D).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bolt,
                        color: _isUrgent ? const Color(0xFFFF4D4D) : const Color(0xFF666666),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mark as Urgent',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Highlight this gig for immediate needs',
                            style: TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isUrgent,
                      onChanged: (value) => setState(() => _isUrgent = value),
                      activeColor: const Color(0xFFFF4D4D),
                      activeTrackColor: const Color(0xFFFF4D4D).withOpacity(0.3),
                      inactiveThumbColor: const Color(0xFF666666),
                      inactiveTrackColor: const Color(0xFF2A2A2F),
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
          onTap: _isLoading ? null : _handlePostGig,
          child: Container(
            width: double.infinity,
            height: 56, // Added fixed height
            decoration: BoxDecoration(
              color: const Color(0xFFA2F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'Post Gig',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA2F301),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1F),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A1A1F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFA2F301),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1F),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF1A1A1F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
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
