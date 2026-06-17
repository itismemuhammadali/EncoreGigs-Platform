import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

class CreateDisputeScreen extends StatefulWidget {
  const CreateDisputeScreen({super.key});

  @override
  State<CreateDisputeScreen> createState() => _CreateDisputeScreenState();
}

class _CreateDisputeScreenState extends State<CreateDisputeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedBookingId;
  String _selectedReason = 'Payment';
  List<File> _attachments = [];
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoadingBookings = true;
  String? _loadingError;

  final List<String> _reasons = [
    'Payment',
    'Cancellation',
    'Performance Quality',
    'Professionalism',
    'Technical Issue',
    'Agreement Breach',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingBookings = true;
      _loadingError = null;
    });

    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      final uid = authService.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _isLoadingBookings = false;
          _loadingError = 'User not authenticated';
        });
        return;
      }

      final bookings = await apiService.getBookings(organizerId: uid).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoadingBookings = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBookings = false;
          _loadingError = 'Error loading gigs: $e';
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'pdf', 'doc', 'png', 'jpeg'],
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.paths.where((path) => path != null).map((path) => File(path!)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _submitDispute() async {
    if (!_formKey.currentState!.validate() || _selectedBookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a gig and provide a description')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    // In a real app, we would upload files to Firebase Storage first
    List<String> attachmentUrls = [];
    for (var file in _attachments) {
      // Mocking upload for prototype
      attachmentUrls.add('https://placeholder.com/${file.path.split('/').last}');
    }

    final error = await authService.createDispute(
      bookingId: _selectedBookingId!,
      category: _selectedReason,
      description: _descriptionController.text,
      attachments: attachmentUrls,
      reporterRole: 'organizer',
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute submitted successfully')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
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
        title: const Text('Create Dispute', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoadingBookings
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFA2F301)))
          : _loadingError != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_loadingError!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Select Gig', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildGigDropdown(),
                        const SizedBox(height: 24),
                        const Text('Reason for Dispute', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildReasonDropdown(),
                        const SizedBox(height: 24),
                        const Text('Description', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Describe the issue and the agreement terms that were breached...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1F),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                        ),
                        const SizedBox(height: 24),
                        const Text('Evidence & Agreements', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Upload screenshots, agreement documents, or other proof', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        const SizedBox(height: 12),
                        _buildAttachmentSection(),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitDispute,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA2F301),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('Submit Dispute', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildGigDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2F)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBookingId,
          hint: Text('Choose a gig with issue', style: TextStyle(color: Colors.grey[600])),
          dropdownColor: const Color(0xFF1A1A1F),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: _bookings.isEmpty 
            ? [const DropdownMenuItem(value: null, child: Text('No active gigs found', style: TextStyle(color: Colors.grey)))]
            : _bookings.map((booking) {
                return DropdownMenuItem<String>(
                  value: booking['id'],
                  child: Text(
                    '${booking['gigTitle']} (Musician: ${booking['musicianName']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
          onChanged: _bookings.isEmpty ? null : (value) => setState(() => _selectedBookingId = value),
        ),
      ),
    );
  }

  Widget _buildReasonDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2F)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReason,
          dropdownColor: const Color(0xFF1A1A1F),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: _reasons.map((reason) {
            return DropdownMenuItem<String>(
              value: reason,
              child: Text(reason),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedReason = value!),
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      children: [
        if (_attachments.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _attachments.length,
            itemBuilder: (context, index) {
              final file = _attachments[index];
              final isImage = ['.jpg', '.jpeg', '.png'].any((ext) => file.path.toLowerCase().endsWith(ext));
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isImage ? Icons.image : Icons.description,
                      color: const Color(0xFFA2F301),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        file.path.split('/').last,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => setState(() => _attachments.removeAt(index)),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              border: Border.all(color: const Color(0xFF2A2A2F), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(Icons.upload_file, size: 32, color: Color(0xFFA2F301)),
                const SizedBox(height: 12),
                Text('Add Evidence (Screenshots/Agreement)', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                const SizedBox(height: 4),
                Text('PDF, PNG, JPG supported', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
