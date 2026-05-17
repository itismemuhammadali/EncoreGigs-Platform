import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/gig_model.dart';
import '../../services/auth_service.dart';
import 'application_submitted_screen.dart';

class ApplyGigScreen extends StatefulWidget {
  final Gig gig;

  const ApplyGigScreen({super.key, required this.gig});

  @override
  State<ApplyGigScreen> createState() => _ApplyGigScreenState();
}

class _ApplyGigScreenState extends State<ApplyGigScreen> {
  final TextEditingController _bidController = TextEditingController();
  final TextEditingController _coverMessageController = TextEditingController();
  final List<File> _selectedFiles = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _bidController.dispose();
    _coverMessageController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp3', 'wav', 'mp4', 'mov', 'pdf'],
      );

      if (result != null && result.paths.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.paths.where((path) => path != null).map((path) => File(path!)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking files: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _submitApplication() async {
    if (_bidController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your price offer')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Upload attachments if any
      List<String> attachmentUrls = [];
      final uid = authService.user?.uid ?? 'unknown';
      for (var file in _selectedFiles) {
        final fileName = file.path.split('/').last;
        final url = await authService.uploadImage(
          file,
          'applications/${widget.gig.id}/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName',
        );
        if (url != null) {
          attachmentUrls.add(url);
        }
      }

      final error = await authService.applyToGig(
        gigId: widget.gig.id,
        gigTitle: widget.gig.title,
        organizerId: widget.gig.organizerId ?? '',
        organizerName: widget.gig.organizer ?? 'Event Organizer',
        gigDate: widget.gig.dateString,
        gigTime: widget.gig.time,
        duration: widget.gig.duration,
        proposedRate: _bidController.text.trim(),
        coverMessage: _coverMessageController.text.trim().isEmpty ? null : _coverMessageController.text.trim(),
        attachments: attachmentUrls.isEmpty ? null : attachmentUrls,
      );

      if (error == null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ApplicationSubmittedScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Full-width header with green bottom border
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Title
                    const Text(
                      'Apply to Gig',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.gig.title,
                      style: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Bidding Field
                    const Text(
                      'Your Price Offer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Client\'s budget: ${widget.gig.budget}',
                      style: TextStyle(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bidController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: !_isSubmitting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What is your lowest price for this gig?',
                        hintStyle: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFA1F301)),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFA1F301),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Enter the minimum amount you are willing to perform for.',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Cover Message
                    const Text(
                      'Cover Message (Optional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _coverMessageController,
                      maxLines: 6,
                      enabled: !_isSubmitting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Introduce yourself and explain why you\'d be a great fit for this gig...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFA1F301),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Personalized messages get 3x more responses',
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Attach Portfolio Samples
                    const Text(
                      'Attach Portfolio Samples (Optional)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickFiles,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: SvgPicture.asset(
                                'assets/upload_icon.svg',
                                fit: BoxFit.contain,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFA1F301),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Upload files',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Audio, video, or images',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...List.generate(_selectedFiles.length, (index) {
                        final file = _selectedFiles[index];
                        final fileName = file.path.split('/').last;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, color: Color(0xFFA1F301), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  fileName,
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: _isSubmitting ? null : () => _removeFile(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    const SizedBox(height: 16),

                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301).withValues(alpha: 0.08),
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Your profile information, ratings, and existing portfolio will be included with your application.',
                        style: TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Fixed Submit button
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: _isSubmitting ? null : _submitApplication,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _isSubmitting ? const Color(0xFFA1F301).withValues(alpha: 0.5) : const Color(0xFFA1F301),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit application',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
