import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../models/gig.dart';
import 'gig_posted_screen.dart';

class PostGigScreen extends StatefulWidget {
  final bool returnToGigs;
  final GigModel? gigToEdit;

  const PostGigScreen({
    super.key,
    this.returnToGigs = false,
    this.gigToEdit,
  });

  @override
  State<PostGigScreen> createState() => _PostGigScreenState();
}

class _PostGigScreenState extends State<PostGigScreen> {
  static const List<String> _genreOptions = <String>[
    'Country',
    'Cajun / Zydeco',
    'Swamp Pop',
    'Rock',
    'Pop',
    'Hip Hop',
    'R&B',
    'Jazz',
    'Blues',
    'Electronic',
    'Latin',
    'Gospel/Christian',
    'Soul',
    'Other...',
  ];

  static const List<String> _eventTypeOptions = <String>[
    'Bar',
    'Nightclub',
    'Wedding',
    'Private Party (Anniversary)',
    'Private Party (Birthday)',
    'Private Party (Corporate)',
    'Private Party (Holiday Benefit / Fundraiser)',
    'Restaurant',
    'Festival',
    'Other',
  ];

  static const List<String> _venueTypeOptions = <String>[
    'Indoor',
    'Outdoor',
    'Covered Outdoor',
    'Private Residence',
    'Event Center',
  ];

  static const List<String> _entertainerTypeOptions = <String>[
    'Solo - Acoustic (Voice w/ Instrument)',
    'Solo - Full Production (Backing Tracks)',
    'Duo / Trio',
    'Full Band',
    'DJ',
  ];

  static const List<String> _ageRestrictionOptions = <String>[
    'None',
    '18+',
    '21+',
  ];

  static const List<String> _breaksAllowedOptions = <String>[
    'No Breaks',
    'Yes - 15 min break (Halfway)',
    'Yes - 30 min break (Split into 2x15min)',
  ];

  // Controllers
  final _titleController = TextEditingController();
  final _requirementInputController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _arrivalTimeController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationHoursController = TextEditingController();
  final _additionalDetailsController = TextEditingController();
  final _incentiveOtherController = TextEditingController();

  // State selections
  final List<String> _requirements = [];
  final Set<String> _selectedGenres = <String>{};
  final Set<String> _selectedIncentives = <String>{};

  String? _selectedEventType;
  String? _selectedVenueType;
  String? _selectedEntertainerType;
  String? _selectedAgeRestriction = 'None';
  String? _selectedBreaksAllowed = 'No Breaks';

  bool _isPublicEvent = true;
  bool _travelIncludedInBudget = false;
  bool _paBacklineProvided = false;
  bool _isUrgent = false;
  bool _isLoading = false;
  File? _imageFile;
  String? _existingImageUrl;

  bool _isNetworkImage(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  void initState() {
    super.initState();
    if (widget.gigToEdit != null) {
      final g = widget.gigToEdit!;
      _existingImageUrl = g.imageUrl;
      _titleController.text = g.title;
      _dateController.text = g.date;
      _timeController.text = g.time;
      _expiryDateController.text = g.expiryDate ?? g.date;
      _budgetController.text = g.budget;
      _locationController.text = g.location;
      _durationHoursController.text = (g.duration ?? '').replaceAll(' hrs', '').replaceAll(' hours', '').trim();
      _isUrgent = g.isUrgent;
      _selectedGenres.addAll(g.genres);
      _requirements.addAll(g.requirements);

      final descLines = g.description.split('\n');
      for (final line in descLines) {
        if (line.startsWith('Event Type: ')) {
          final val = line.substring('Event Type: '.length).trim();
          if (_eventTypeOptions.contains(val)) _selectedEventType = val;
        } else if (line.startsWith('Venue Type: ')) {
          final val = line.substring('Venue Type: '.length).trim();
          if (_venueTypeOptions.contains(val)) _selectedVenueType = val;
        } else if (line.startsWith('Entertainer Type: ')) {
          final val = line.substring('Entertainer Type: '.length).trim();
          if (_entertainerTypeOptions.contains(val)) _selectedEntertainerType = val;
        } else if (line.startsWith('Load-in Time: ')) {
          _arrivalTimeController.text = line.substring('Load-in Time: '.length).trim();
        } else if (line.startsWith('Breaks Allowed: ')) {
          final val = line.substring('Breaks Allowed: '.length).trim();
          if (_breaksAllowedOptions.contains(val)) _selectedBreaksAllowed = val;
        } else if (line.startsWith('Age Restriction: ')) {
          final val = line.substring('Age Restriction: '.length).trim();
          if (_ageRestrictionOptions.contains(val)) _selectedAgeRestriction = val;
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _requirementInputController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _arrivalTimeController.dispose();
    _expiryDateController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _durationHoursController.dispose();
    _additionalDetailsController.dispose();
    _incentiveOtherController.dispose();
    super.dispose();
  }

  void _updateAutoTitle() {
    final parts = <String>[];
    if (_selectedEventType != null && _selectedEventType!.isNotEmpty) {
      parts.add(_selectedEventType!);
    }
    if (_selectedGenres.isNotEmpty) {
      parts.add(_selectedGenres.join('/'));
    }
    if (_selectedEntertainerType != null && _selectedEntertainerType!.isNotEmpty) {
      parts.add('(${_selectedEntertainerType!})');
    }
    if (_dateController.text.isNotEmpty) {
      parts.add(_dateController.text);
    }
    if (parts.isNotEmpty) {
      _titleController.text = parts.join(' - ');
    }
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
        if (_selectedGenres.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select 1–3 genres max.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedGenres.add(genre);
      }
      _updateAutoTitle();
    });
  }

  void _toggleIncentive(String incentive) {
    setState(() {
      if (_selectedIncentives.contains(incentive)) {
        _selectedIncentives.remove(incentive);
      } else {
        _selectedIncentives.add(incentive);
      }
    });
  }

  Future<void> _handlePostGig() async {
    final missingFields = <String>[];

    if (_imageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      missingFields.add('Gig Image');
    }
    if (_selectedEventType == null) missingFields.add('Event Type');
    if (_selectedVenueType == null) missingFields.add('Venue Type');
    if (_selectedEntertainerType == null) missingFields.add('Type of Entertainer');
    if (_selectedGenres.isEmpty) missingFields.add('Preferred Genre(s)');
    if (_dateController.text.trim().isEmpty) missingFields.add('Performance Date');
    if (_timeController.text.trim().isEmpty) missingFields.add('Performance Time');
    if (_durationHoursController.text.trim().isEmpty) missingFields.add('Length of Performance');
    if (_locationController.text.trim().isEmpty) missingFields.add('Location');
    if (_budgetController.text.trim().isEmpty) missingFields.add('Budget');

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in the following required field(s): ${missingFields.join(", ")}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: const Color(0xFFFF4D4D),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    
    String? finalImageUrl;
    
    // Upload image to Storage if picked
    if (_imageFile != null) {
      final String fileName = 'gig_${DateTime.now().millisecondsSinceEpoch}.jpg';
      finalImageUrl = await authService.uploadImage(_imageFile!, 'gigs/$fileName');
    } else {
      finalImageUrl = _existingImageUrl;
    }

    // Prepare incentives string
    final incentiveList = _selectedIncentives.toList();
    if (_selectedIncentives.contains('Other') && _incentiveOtherController.text.trim().isNotEmpty) {
      incentiveList.remove('Other');
      incentiveList.add('Other: ${_incentiveOtherController.text.trim()}');
    }

    // Build description automatically from structured details
    final autoDescription = StringBuffer()
      ..writeln('Event Type: ${_selectedEventType ?? "N/A"}')
      ..writeln('Venue Type: ${_selectedVenueType ?? "N/A"}')
      ..writeln('Entertainer Type: ${_selectedEntertainerType ?? "N/A"}')
      ..writeln('Event Privacy: ${_isPublicEvent ? "Public Event" : "Private Event"}')
      ..writeln('Load-in Time: ${_arrivalTimeController.text.isEmpty ? "N/A" : _arrivalTimeController.text}')
      ..writeln('Performance Duration: ${_durationHoursController.text} hours')
      ..writeln('Breaks Allowed: ${_selectedBreaksAllowed ?? "No Breaks"}')
      ..writeln('PA / Backline Provided: ${_paBacklineProvided ? "Yes" : "No"}')
      ..writeln('Travel/Lodging in Budget: ${_travelIncludedInBudget ? "Yes" : "No"}')
      ..writeln('Age Restriction: ${_selectedAgeRestriction ?? "None"}')
      ..writeln('Incentives: ${incentiveList.isEmpty ? "None" : incentiveList.join(", ")}');

    if (_additionalDetailsController.text.trim().isNotEmpty) {
      autoDescription.writeln('\nAdditional Details:\n${_additionalDetailsController.text.trim()}');
    }

    if (widget.gigToEdit != null) {
      final error = await authService.updateGig(widget.gigToEdit!.gigId, {
        'title': _titleController.text.trim(),
        'description': autoDescription.toString(),
        'requirements': _requirements,
        'genres': _selectedGenres.toList(),
        'date': _dateController.text.trim(),
        'time': _timeController.text.trim(),
        'expiryDate': _expiryDateController.text.trim().isNotEmpty
            ? _expiryDateController.text.trim()
            : _dateController.text.trim(),
        'budget': _budgetController.text.trim(),
        'location': _locationController.text.trim(),
        'imageUrl': finalImageUrl,
        'duration': '${_durationHoursController.text.trim()} hrs',
        'isUrgent': _isUrgent,
      });

      if (mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gig updated successfully')),
          );
          Navigator.of(context).pop(true);
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
      return;
    }

    final error = await authService.createGig(
      title: _titleController.text.trim(),
      description: autoDescription.toString(),
      requirements: _requirements,
      genres: _selectedGenres.toList(),
      date: _dateController.text.trim(),
      time: _timeController.text.trim(),
      expiryDate: _expiryDateController.text.trim().isNotEmpty
          ? _expiryDateController.text.trim()
          : _dateController.text.trim(),
      budget: _budgetController.text.trim(),
      location: _locationController.text.trim(),
      imageUrl: finalImageUrl,
      duration: '${_durationHoursController.text.trim()} hrs',
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
        title: Text(
          widget.gigToEdit != null ? 'Edit Gig' : 'Post New Gig',
          style: const TextStyle(
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gig Image
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
                      color: (_imageFile != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty))
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
                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _isNetworkImage(_existingImageUrl)
                                      ? Image.network(
                                          _existingImageUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Image.asset(
                                            'assets/gig_image1.jpg',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Image.asset(
                                          _existingImageUrl!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: const Color(0xFF1A1A1F),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() {
                                      _existingImageUrl = null;
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

              // Event Type Dropdown/Selector
              _buildLabel('Event Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _eventTypeOptions.map((type) {
                  final bool isSelected = _selectedEventType == type;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEventType = isSelected ? null : type;
                        _updateAutoTitle();
                      });
                    },
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
                        type,
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

              // Venue Type
              _buildLabel('Venue Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _venueTypeOptions.map((venue) {
                  final bool isSelected = _selectedVenueType == venue;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVenueType = isSelected ? null : venue;
                      });
                    },
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
                        venue,
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

              // Type of Entertainer
              _buildLabel('Type of Entertainer'),
              const SizedBox(height: 10),
              Column(
                children: _entertainerTypeOptions.map((ent) {
                  final bool isSelected = _selectedEntertainerType == ent;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEntertainerType = isSelected ? null : ent;
                        _updateAutoTitle();
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                        ),
                      ),
                      child: Text(
                        ent,
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

              // Public or Private Event
              _buildLabel('Event Privacy'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isPublicEvent = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isPublicEvent ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isPublicEvent ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Public Event',
                            style: TextStyle(
                              color: _isPublicEvent ? Colors.black : Colors.white,
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
                      onTap: () => setState(() => _isPublicEvent = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isPublicEvent ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !_isPublicEvent ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Private Event',
                            style: TextStyle(
                              color: !_isPublicEvent ? Colors.black : Colors.white,
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
              const SizedBox(height: 20),

              // Preferred Genre(s)
              _buildLabel('Preferred Genre(s) (Select 1–3 genres)'),
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

              // Auto-generated Gig Title
              _buildLabel('Gig Title (Auto-Generated)'),
              const SizedBox(height: 8),
              _buildField(_titleController, 'Auto-generated from Event Type, Genre, Entertainer Type & Date'),
              const SizedBox(height: 4),
              const Text(
                'Auto-generates as you select Event Type, Genre, Entertainer Type & Date.',
                style: TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
              const SizedBox(height: 20),

              // Performance Date & Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Performance Date'),
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
                        _buildLabel('Performance Time'),
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

              // Arrival / Load-in Time
              _buildLabel('Arrival / Load-in Time', isRequired: false),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectArrivalTime(context),
                child: AbsorbPointer(
                  child: _buildField(_arrivalTimeController, 'e.g., 6:30 PM (1.5 hrs before show)'),
                ),
              ),
              const SizedBox(height: 20),

              // Length of Performance (in Hours)
              _buildLabel('Length of Performance (in Hours)'),
              const SizedBox(height: 8),
              _buildField(_durationHoursController, 'e.g., 1.5, 2.0, 3.5 (Decimal hours)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 20),

              // Breaks Allowed
              _buildLabel('Breaks Allowed (for 2hr+ set)', isRequired: false),
              const SizedBox(height: 10),
              Column(
                children: _breaksAllowedOptions.map((brk) {
                  final bool isSelected = _selectedBreaksAllowed == brk;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBreaksAllowed = brk),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                        ),
                      ),
                      child: Text(
                        brk,
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

              // Location with Zip Code
              _buildLabel('Location (Full Address with Zip Code)'),
              const SizedBox(height: 8),
              _buildField(_locationController, 'Street Address, City, State, ZIP Code'),
              const SizedBox(height: 20),

              // Budget (Max Allowed)
              _buildLabel('Budget (Max Allowed)'),
              const SizedBox(height: 8),
              _buildField(_budgetController, 'e.g., 600 (USD)', keyboardType: TextInputType.number),
              const SizedBox(height: 20),

              // Travel / Lodging Included in Budget
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2F)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flight_takeoff, color: Color(0xFFA2F301), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Travel / Lodging / Meals Included in Budget?',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _travelIncludedInBudget ? 'Yes, budget covers travel' : 'No, performance fee only',
                            style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _travelIncludedInBudget,
                      onChanged: (val) => setState(() => _travelIncludedInBudget = val),
                      activeThumbColor: const Color(0xFFA2F301),
                      activeTrackColor: const Color(0xFFA2F301).withValues(alpha: 0.3),
                      inactiveThumbColor: const Color(0xFF666666),
                      inactiveTrackColor: const Color(0xFF2A2A2F),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Incentives
              _buildLabel('Incentives Provided', isRequired: false),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Bar Tab', 'Free Meal', 'Other'].map((inc) {
                  final bool isSelected = _selectedIncentives.contains(inc);
                  return GestureDetector(
                    onTap: () => _toggleIncentive(inc),
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
                        inc,
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
              if (_selectedIncentives.contains('Other')) ...[
                const SizedBox(height: 10),
                _buildField(_incentiveOtherController, 'Describe other incentives...'),
              ],
              const SizedBox(height: 20),

              // PA / Backline Provided
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2A2F)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.speaker_group_outlined, color: Color(0xFFA2F301), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PA / Backline Provided by Venue?',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _paBacklineProvided ? 'Yes, venue has sound equipment' : 'No, artist must bring PA',
                            style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _paBacklineProvided,
                      onChanged: (val) => setState(() => _paBacklineProvided = val),
                      activeThumbColor: const Color(0xFFA2F301),
                      activeTrackColor: const Color(0xFFA2F301).withValues(alpha: 0.3),
                      inactiveThumbColor: const Color(0xFF666666),
                      inactiveTrackColor: const Color(0xFF2A2A2F),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Age Restriction
              _buildLabel('Age Restriction', isRequired: false),
              const SizedBox(height: 10),
              Row(
                children: _ageRestrictionOptions.map((age) {
                  final bool isSelected = _selectedAgeRestriction == age;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedAgeRestriction = age),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFA2F301) : const Color(0xFF2A2A2F),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            age,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Expiration Date (Auto-delete)
              _buildLabel('Expiration Date (Auto-delete from Feed)', isRequired: false),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectExpiryDate(context),
                child: AbsorbPointer(
                  child: _buildField(_expiryDateController, 'MM/DD/YYYY (Defaults to Gig Date)'),
                ),
              ),
              const SizedBox(height: 20),

              // Additional Details (Optional)
              _buildLabel('Additional Details (Special Requirements)', isRequired: false),
              const SizedBox(height: 8),
              TextField(
                controller: _additionalDetailsController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Any special requests (e.g. Light show, specific gear, sound check instructions)...',
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

              // Requirements
              _buildLabel('Requirements (Optional / Add Items)', isRequired: false),
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
              const SizedBox(height: 24),

              // Mark as Urgent
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
                        color: _isUrgent ? const Color(0xFFFF4D4D).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
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
                      activeThumbColor: const Color(0xFFFF4D4D),
                      activeTrackColor: const Color(0xFFFF4D4D).withValues(alpha: 0.3),
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
            height: 56,
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
                : Center(
                    child: Text(
                      widget.gigToEdit != null ? 'Save Changes' : 'Post Gig',
                      style: const TextStyle(
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
        final formattedDate =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
        _dateController.text = formattedDate;
        if (_expiryDateController.text.isEmpty) {
          _expiryDateController.text = formattedDate;
        }
        _updateAutoTitle();
      });
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
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
        _expiryDateController.text =
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

  Future<void> _selectArrivalTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
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
        _arrivalTimeController.text = picked.format(context);
      });
    }
  }

  Widget _buildLabel(String text, {bool isRequired = true}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFFF4D4D),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
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
