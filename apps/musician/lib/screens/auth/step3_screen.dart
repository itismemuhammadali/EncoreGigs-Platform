import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/complete_profile_header.dart';

class Step3Screen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onComplete;
  final VoidCallback onBack;
  final bool isLoading;

  const Step3Screen({
    super.key,
    required this.profileData,
    required this.onComplete,
    required this.onBack,
    this.isLoading = false,
  });

  @override
  State<Step3Screen> createState() => _Step3ScreenState();
}

class _Step3ScreenState extends State<Step3Screen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var xFile in pickedFiles) {
            widget.profileData['portfolio']['images'].add(File(xFile.path));
          }
        });
      }
    } catch (e) {
      _showError('Error picking images: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          widget.profileData['portfolio']['videos'].add(File(pickedFile.path));
        });
      }
    } catch (e) {
      _showError('Error picking video: $e');
    }
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          for (var path in result.paths) {
            if (path != null) {
              widget.profileData['portfolio']['audioTracks'].add(File(path));
            }
          }
        });
      }
    } catch (e) {
      _showError('Error picking audio tracks: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _removeFile(String type, int index) {
    setState(() {
      widget.profileData['portfolio'][type].removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = widget.profileData['portfolio'];
    final imagesCount = portfolio['images'].length;
    final videosCount = portfolio['videos'].length;
    final audioCount = portfolio['audioTracks'].length;

    return Column(
      children: [
        // Header with full-width divider
        CompleteProfileHeader(
          currentStep: 3,
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

          // Portfolio Title
          const Text(
            'Portfolio',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your best work to showcase your talent',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),

          // Portfolio Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildPortfolioCard(
                icon: Icons.image,
                label: 'Images',
                count: imagesCount,
                onTap: _pickImages,
              ),
              _buildPortfolioCard(
                icon: Icons.videocam,
                label: 'Videos',
                count: videosCount,
                onTap: _pickVideo,
              ),
              _buildPortfolioCard(
                icon: Icons.music_note,
                label: 'Audio Tracks',
                count: audioCount,
                onTap: _pickAudio,
              ),
            ],
          ),
          const SizedBox(height: 32),

          if (imagesCount > 0 || videosCount > 0 || audioCount > 0) ...[
            const Text(
              'Uploaded Files',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildFileList('images', portfolio['images'], Icons.image),
            _buildFileList('videos', portfolio['videos'], Icons.videocam),
            _buildFileList('audioTracks', portfolio['audioTracks'], Icons.music_note),
          ],
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
              onPressed: widget.isLoading ? null : widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA1F301),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: const Color(0xFFA1F301).withValues(alpha: 0.5),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Complete Profile',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileList(String type, List<dynamic> files, IconData icon) {
    if (files.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: files.asMap().entries.map((entry) {
        final index = entry.key;
        final file = entry.value as File;
        final fileName = file.path.split('/').last;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFA1F301), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                onPressed: () => _removeFile(type, index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPortfolioCard({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[700]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: SvgPicture.asset(
                'assets/upload_icon.svg',
                colorFilter: const ColorFilter.mode(
                  Color(0xFFA1F301),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$count uploaded',
                style: const TextStyle(
                  color: Color(0xFFA1F301),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
