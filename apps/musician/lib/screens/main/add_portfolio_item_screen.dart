import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class AddPortfolioItemScreen extends StatefulWidget {
  const AddPortfolioItemScreen({super.key});

  @override
  State<AddPortfolioItemScreen> createState() => _AddPortfolioItemScreenState();
}

class _AddPortfolioItemScreenState extends State<AddPortfolioItemScreen> {
  int _selectedType = 0; // 0=Image, 1=Video, 2=Audio
  int _selectedMethod = 0; // 0=Upload, 1=Link
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final List<String> _selectedTags = [];
  
  File? _selectedFile;
  bool _isUploading = false;

  final List<String> _availableTags = ['Jazz', 'Live Performance', 'Studio', 'Original', 'Cover'];

  final List<Map<String, dynamic>> _types = [
    {'label': 'Image', 'formats': 'JPG, PNG,\nWebP', 'icon': 'assets/image_icon.svg', 'color': const Color(0xFFA1F301), 'type': 'image'},
    {'label': 'Video', 'formats': 'MP4, MOV,\nWebM', 'icon': 'assets/video_icon.svg', 'color': const Color(0xFF00BCD4), 'type': 'video'},
    {'label': 'Audio', 'formats': 'MP3, WAV,\nAAC', 'icon': 'assets/music_note_icon.svg', 'color': const Color(0xFFFF6B9D), 'type': 'music'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FileType type = FileType.any;
    if (_selectedType == 0) {
      type = FileType.image;
    } else if (_selectedType == 1) type = FileType.video;
    else if (_selectedType == 2) type = FileType.audio;

    final result = await FilePicker.pickFiles(type: type);

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _selectedFile = File(result.paths.first!);
      });
    }
  }

  Future<void> _handleAddToPortfolio() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    if (_selectedMethod == 0 && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a file to upload')));
      return;
    }

    if (_selectedMethod == 1 && _linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a link')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final type = _types[_selectedType]['type'] as String;

      final error = await authService.addPortfolioItem(
        type: type,
        file: _selectedMethod == 0 ? _selectedFile : null,
        externalUrl: _selectedMethod == 1 ? _linkController.text.trim() : null,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
      );

      if (error == null) {
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTypeColor = _types[_selectedType]['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Add Portfolio Item',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Upload your latest work samples',
                      style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select Type
                    const Text('Select Type',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(_types.length, (index) {
                        final type = _types[index];
                        final isSelected = _selectedType == index;
                        final color = type['color'] as Color;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index < _types.length - 1 ? 10 : 0),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedType = index;
                                _selectedFile = null; // Reset file when type changes
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? color : const Color(0xFFA1F301).withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 28, height: 28,
                                      child: SvgPicture.asset(type['icon'], fit: BoxFit.contain,
                                          colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(type['label'],
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(type['formats'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Color(0xFF666666), fontSize: 10)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Upload Method
                    const Text('Upload Method',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMethod = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _selectedMethod == 0 ? const Color(0xFFA1F301).withValues(alpha: 0.15) : Colors.transparent,
                                border: Border.all(
                                  color: _selectedMethod == 0 ? const Color(0xFFA1F301) : const Color(0xFFA1F301).withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 24, height: 24,
                                    child: SvgPicture.asset('assets/upload_icon.svg', fit: BoxFit.contain,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFFA1F301),
                                          BlendMode.srcIn,
                                        )),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Upload File',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMethod = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _selectedMethod == 1 ? const Color(0xFF00BCD4).withValues(alpha: 0.15) : Colors.transparent,
                                border: Border.all(
                                  color: _selectedMethod == 1 ? const Color(0xFF00BCD4) : const Color(0xFFA1F301).withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 24, height: 24,
                                    child: SvgPicture.asset('assets/link_icon.svg', fit: BoxFit.contain,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFF00BCD4),
                                          BlendMode.srcIn,
                                        )),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Add Link',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13, fontWeight: FontWeight.w600,
                                      )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Upload area or Link field
                    if (_selectedMethod == 0) ...[
                      const Text('Upload File',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 24, height: 24,
                                    child: SvgPicture.asset('assets/upload_icon.svg', fit: BoxFit.contain,
                                        colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(_selectedFile == null ? 'Click to Browse File' : 'File selected: ${_selectedFile!.path.split('/').last}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              const Text('Max size: 10MB',
                                  style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedTypeColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text('${_types[_selectedType]['label']} only',
                                    style: TextStyle(color: selectedTypeColor, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text('External Link',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildTextField(_linkController, 'https://soundcloud.com/...'),
                      const SizedBox(height: 6),
                      const Text('Supported: YouTube, Vimeo, SoundCloud, Spotify, etc.',
                          style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                    ],
                    const SizedBox(height: 24),

                    // Title
                    const Text('Title',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildTextField(_titleController, 'Give your work a title'),
                    const SizedBox(height: 24),

                    // Description
                    const Text('Description (Optional)',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildTextField(_descController, 'Describe your work, the context, and what makes it special...', maxLines: 4),
                    const SizedBox(height: 24),

                    // Tags
                    const Text('Tags (Optional)',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (isSelected) { _selectedTags.remove(tag); } else { _selectedTags.add(tag); }
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFA1F301).withValues(alpha: 0.15) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFA1F301) : const Color(0xFFA1F301).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFFA1F301) : Colors.white,
                                  fontSize: 13,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(top: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.2), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _handleAddToPortfolio,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: _isUploading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                              : const Text('Add to Portfolio',
                                  style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF555555), fontSize: 14),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFA1F301), width: 1.5),
        ),
      ),
    );
  }
}
