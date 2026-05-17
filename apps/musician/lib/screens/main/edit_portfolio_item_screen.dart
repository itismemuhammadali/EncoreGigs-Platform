import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../models/profile_model.dart';
import '../../widgets/delete_confirmation_sheet.dart';
import '../../services/auth_service.dart';

class EditPortfolioItemScreen extends StatefulWidget {
  final PortfolioItem item;
  final String title;
  final String description;
  final VoidCallback onDelete;

  const EditPortfolioItemScreen({
    super.key,
    required this.item,
    required this.title,
    required this.description,
    required this.onDelete,
  });

  @override
  State<EditPortfolioItemScreen> createState() => _EditPortfolioItemScreenState();
}

class _EditPortfolioItemScreenState extends State<EditPortfolioItemScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  bool _isSaving = false;
  bool _isLoadingVideo = false;
  File? _newMediaFile;
  String? _previewUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _descriptionController = TextEditingController(text: widget.description);
    
    // Only show the link if it's an external URL (not Firebase Storage and not an asset)
    String displayUrl = widget.item.image;
    bool isInternal = displayUrl.contains('firebasestorage.googleapis.com') || 
                      displayUrl.contains(':9199') || 
                      !displayUrl.startsWith('http');
    if (isInternal) {
      displayUrl = '';
    }
    _urlController = TextEditingController(text: displayUrl);
    
    _previewUrl = widget.item.image;
  }

  Future<void> _initVideoPlayer(String url) async {
    if (url.isEmpty) return;
    if (mounted) setState(() => _isLoadingVideo = true);
    try {
      _videoPlayerController?.dispose();
      _chewieController?.dispose();
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFA1F301),
          handleColor: const Color(0xFFA1F301),
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white,
        ),
      );
    } catch (e) {
      debugPrint("Video init error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingVideo = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FileType type = FileType.any;
    if (widget.item.type == 'image') {
      type = FileType.image;
    } else if (widget.item.type == 'video') type = FileType.video;
    else if (widget.item.type == 'music') type = FileType.audio;

    final result = await FilePicker.pickFiles(type: type);

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _newMediaFile = File(result.paths.first!);
        // For local preview of images
        if (widget.item.type == 'image') {
          _previewUrl = result.files.single.path;
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      String currentUrl = widget.item.image;

      if (_newMediaFile != null) {
        // Upload new file
        final fileName = _newMediaFile!.path.split('/').last;
        final path = 'portfolios/${widget.item.type}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        final uploadUrl = await authService.uploadImage(_newMediaFile!, path);
        if (uploadUrl != null) {
          currentUrl = uploadUrl;
        }
      }

      // Update Firestore
      final error = await authService.updatePortfolioItem(
        oldUrl: widget.item.image,
        newUrl: currentUrl,
        type: widget.item.type,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        externalUrl: _urlController.text.trim(),
      );

      if (error == null) {
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteItem() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.deletePortfolioItem(
      url: widget.item.image,
      type: widget.item.type,
    );

    if (error == null) {
      widget.onDelete();
      if (mounted) Navigator.of(context).pop();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Color _getTypeColor(String type) {
    return const Color(0xFFA1F301);
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'video': return 'Video';
      case 'image': return 'Image';
      case 'music': return 'Audio';
      default: return type;
    }
  }

  String _getIconPath(String type) {
    switch (type) {
      case 'video': return 'assets/video_icon.svg';
      case 'image': return 'assets/image_icon.svg';
      case 'music': return 'assets/music_note_icon.svg';
      default: return 'assets/video_icon.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(widget.item.type);

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
                  const Text('Edit Portfolio Item',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Update your portfolio details',
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
                    // Preview card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview header
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 30, height: 30,
                                    child: SvgPicture.asset(
                                      widget.item.type == 'video' ? 'assets/video_icon.svg' : _getIconPath(widget.item.type),
                                      fit: BoxFit.contain,
                                      colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Preview',
                                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: typeColor.withValues(alpha: 0.2),
                                      border: Border.all(color: typeColor.withValues(alpha: 0.4), width: 1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(_getTypeLabel(widget.item.type),
                                        style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Media Preview Logic
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildMediaPreview(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title field
                    const Text('Title', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(_titleController, 'Jazz Performance at Blue Note'),
                    const SizedBox(height: 16),

                    // Description field
                    const Text('Description', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(_descriptionController, 'Live performance showcase from recent gig.', maxLines: 4),
                    const SizedBox(height: 16),

                    // URL field
                    const Text('URL/Link', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    _buildTextField(_urlController, 'https://example.com/video1.mp4'),
                    const SizedBox(height: 6),
                    const Text('Link to the file or external hosting',
                        style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                    const SizedBox(height: 20),

                    // Replace Media card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Replace Media',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickFile,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.2), width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 28, height: 28,
                                    child: SvgPicture.asset('assets/upload_icon.svg', fit: BoxFit.contain,
                                        colorFilter: const ColorFilter.mode(Color(0xFF999999), BlendMode.srcIn)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(_newMediaFile == null ? 'Click to upload new file' : 'File selected: ${_newMediaFile!.path.split('/').last}',
                                      style: const TextStyle(color: Color(0xFF999999), fontSize: 13)),
                                  const SizedBox(height: 4),
                                  const Text('Or drag and drop',
                                      style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Fixed bottom buttons
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(top: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.2), width: 1)),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isSaving ? null : _saveChanges,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20, height: 20,
                                  child: SvgPicture.asset('assets/save_icon.svg', fit: BoxFit.contain,
                                      colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                                ),
                                const SizedBox(width: 8),
                                const Text('Save Changes',
                                    style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => showDeleteConfirmationSheet(
                      context,
                      onDelete: _deleteItem,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.withValues(alpha: 0.6), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 6),
                          Text('Delete Item', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
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

  Widget _buildMediaPreview() {
    if (widget.item.type == 'image') {
      if (_newMediaFile != null) {
        return Image.file(_newMediaFile!, width: double.infinity, height: 200, fit: BoxFit.cover);
      }
      return _previewUrl!.startsWith('http')
          ? Image.network(_previewUrl!, width: double.infinity, height: 200, fit: BoxFit.cover)
          : Image.asset(_previewUrl!, width: double.infinity, height: 200, fit: BoxFit.cover);
    } 
    
    if (widget.item.type == 'video') {
      if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
        return SizedBox(height: 200, child: Chewie(controller: _chewieController!));
      }
      final hasUrl = (_previewUrl != null && _previewUrl!.isNotEmpty);
      return GestureDetector(
        onTap: (!hasUrl || _isLoadingVideo) ? null : () => _initVideoPlayer(_previewUrl!),
        child: SizedBox(
          width: double.infinity,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              if (hasUrl && _previewUrl!.startsWith('http'))
                Image.network(
                  _previewUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A1F)),
                )
              else
                Container(color: const Color(0xFF1A1A1F)),

              // Dark scrim
              Container(color: Colors.black.withValues(alpha: 0.45)),

              // Spinner while loading, icon+label otherwise
              Center(
                child: _isLoadingVideo
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: Color(0xFFA1F301),
                          strokeWidth: 3,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/video_icon.svg',
                            width: 56,
                            height: 56,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFA1F301),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hasUrl ? 'Tap to play video' : 'No video URL set',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
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
    
    if (widget.item.type == 'music') {
      return Container(
        height: 200,
        width: double.infinity,
        color: const Color(0xFF1A1A1F),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset('assets/portfolio_image3.png', width: 80, height: 80, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                try {
                  if (_isPlayingAudio) {
                    await _audioPlayer.pause();
                  } else {
                    Source source = _newMediaFile != null 
                        ? DeviceFileSource(_newMediaFile!.path)
                        : UrlSource(_previewUrl!);
                    await _audioPlayer.play(source);
                  }
                  setState(() => _isPlayingAudio = !_isPlayingAudio);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error playing audio: $e")));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFA1F301), borderRadius: BorderRadius.circular(30)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_isPlayingAudio ? Icons.pause : Icons.play_arrow, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(_isPlayingAudio ? 'Pause Audio' : 'Play Audio', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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
