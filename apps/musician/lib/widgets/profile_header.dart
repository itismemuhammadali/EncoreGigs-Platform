import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/profile_model.dart';
import '../services/auth_service.dart';

class ProfileHeader extends StatefulWidget {
  final Profile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      if (!mounted) return;
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.updateProfilePicture(File(pickedFile.path));

      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Color(0xFFA1F301),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
            const Text(
              'Select Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFA1F301)),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFA1F301)),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border.all(
          color: const Color(0xFFA1F301).withOpacity(0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFA1F301).withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: _isUploading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFA1F301)))
                    : (widget.profile.profileImage != null
                        ? CircleAvatar(
                            radius: 58,
                            backgroundImage: widget.profile.profileImage!.startsWith('http')
                                ? NetworkImage(widget.profile.profileImage!) as ImageProvider
                                : AssetImage(widget.profile.profileImage!) as ImageProvider,
                          )
                        : CircleAvatar(
                            radius: 58,
                            backgroundColor: const Color(0xFF333333),
                            child: Text(
                              widget.profile.name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
              ),
              GestureDetector(
                onTap: _isUploading ? null : _showImageSourceActionSheet,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFA1F301),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: SvgPicture.asset(
                        'assets/change_picture_icon.svg',
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
            ],
          ),
          const SizedBox(height: 20),

          // Name
          Text(
            widget.profile.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Profession
          Text(
            widget.profile.profession,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),

          // Rating and Gigs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
              const SizedBox(width: 6),
              Text(
                '${widget.profile.avgRating.toStringAsFixed(1)} (${widget.profile.reviewCount} reviews)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Genre tags
          Wrap(
            spacing: 12,
            alignment: WrapAlignment.center,
            children: widget.profile.genres.map((genre) {
              Color borderColor = genre == 'Jazz'
                  ? const Color(0xFFA1F301)
                  : genre == 'Classical'
                      ? const Color(0xFF00BCD4)
                      : const Color(0xFFFF6B9D);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.15),
                  border: Border.all(
                    color: borderColor,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  genre,
                  style: TextStyle(
                    color: borderColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Divider
          Container(
            height: 1,
            color: const Color(0xFFA1F301).withOpacity(0.3),
          ),
          const SizedBox(height: 24),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${widget.profile.gigsCompleted}',
                    style: const TextStyle(
                      color: Color(0xFFA1F301),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gigs Completed',
                    style: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${widget.profile.avgRating.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Color(0xFFA1F301),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Avg Rating',
                    style: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${widget.profile.responseRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFFA1F301),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Response Rate',
                    style: TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
