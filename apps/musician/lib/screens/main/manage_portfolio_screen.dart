import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import 'edit_portfolio_item_screen.dart';
import 'add_portfolio_item_screen.dart';
import '../../widgets/delete_confirmation_sheet.dart';

class ManagePortfolioScreen extends StatefulWidget {
  const ManagePortfolioScreen({super.key});

  @override
  State<ManagePortfolioScreen> createState() => _ManagePortfolioScreenState();
}

class _ManagePortfolioScreenState extends State<ManagePortfolioScreen> {
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('musicians')
              .doc(currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Musician profile not found', style: TextStyle(color: Colors.white)));
            }

            final profileData = snapshot.data!.data() as Map<String, dynamic>;
            final profile = Profile.fromFirestore(profileData);
            final items = profile.portfolioItems;

            return Column(
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
                      const Text('Manage Portfolio',
                          style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Add, edit, or remove your work samples',
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
                        // Add New Item button
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const AddPortfolioItemScreen()),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Color(0xFFA1F301), size: 28),
                                ),
                                const SizedBox(height: 12),
                                const Text('Add New Item',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                const Text('Upload images, videos, or audio',
                                    style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Your Portfolio
                        Text('Your Portfolio (${items.length} items)',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        // Portfolio items
                        if (items.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text('No portfolio items yet.', style: TextStyle(color: Color(0xFF999999))),
                            ),
                          ),

                        ...items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final typeColor = _getTypeColor(item.type);
                          
                          // Placeholder thumbnails for video/music using portfolio assets
                          final assetIndex = (index % 3) + 1;
                          final placeholderAsset = 'assets/portfolio_image$assetIndex.png';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EditPortfolioItemScreen(
                                    item: item,
                                    title: item.title.isNotEmpty ? item.title : '${_getTypeLabel(item.type)} Item ${index + 1}',
                                    description: item.description.isNotEmpty ? item.description : 'Sample ${item.type} from your portfolio.',
                                    onDelete: () {
                                      // Implementation for delete would go here (update Firestore)
                                    },
                                  ),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thumbnail
                                    Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: (item.type == 'video' || item.type == 'music')
                                              ? Image.asset(
                                                  placeholderAsset,
                                                  width: 100, height: 100,
                                                  fit: BoxFit.cover,
                                                )
                                              : item.image.startsWith('http')
                                                  ? Image.network(
                                                      item.image,
                                                      width: 100, height: 100,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.asset(
                                                      item.image,
                                                      width: 100, height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                        ),
                                        SizedBox(
                                          width: 28, height: 28,
                                          child: SvgPicture.asset(
                                            _getIconPath(item.type),
                                            fit: BoxFit.contain,
                                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(item.title.isNotEmpty ? item.title : '${_getTypeLabel(item.type)} Item ${index + 1}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                              ),
                                              GestureDetector(
                                                onTap: () => showDeleteConfirmationSheet(
                                                  context,
                                                  onDelete: () async {
                                                    final authService = Provider.of<AuthService>(context, listen: false);
                                                    final error = await authService.deletePortfolioItem(
                                                      url: item.image,
                                                      type: item.type,
                                                    );
                                                    if (error != null && context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text(error)),
                                                      );
                                                    }
                                                  },
                                                ),
                                                child: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Type badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: typeColor.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(_getTypeLabel(item.type),
                                                style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(item.description.isNotEmpty ? item.description : 'Sample content from your portfolio.',
                                              style: const TextStyle(color: Color(0xFF999999), fontSize: 13, height: 1.5)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
