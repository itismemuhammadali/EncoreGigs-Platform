import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../services/chat_service.dart';
import '../messages/chat/chat_screen.dart';
import 'widgets/hire_musician_dialog.dart';
import 'widgets/portfolio_viewer.dart';
import 'payment_screen.dart';
import 'package:onlygigz_organizer/services/api_service.dart';
import '../../constants.dart';

class MusicianProfileScreen extends StatefulWidget {
  final String musicianId;
  final String? gigId;
  final String? gigTitle;
  final String? gigBudget;
  final String? gigDate;
  final String? gigTime;
  final String? gigDuration;
  final String? proposedRate;
  final String? coverMessage;

  const MusicianProfileScreen({
    super.key,
    required this.musicianId,
    this.gigId,
    this.gigTitle,
    this.gigBudget,
    this.gigDate,
    this.gigTime,
    this.gigDuration,
    this.proposedRate,
    this.coverMessage,
  });

  @override
  State<MusicianProfileScreen> createState() => _MusicianProfileScreenState();
}

class _MusicianProfileScreenState extends State<MusicianProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>> _musicianFuture;

  @override
  void initState() {
    super.initState();
    _musicianFuture = _apiService.getProfile(widget.musicianId);
  }

  bool _isNetworkImage(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
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
        title: const Text(
          'Musician Profile',
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _musicianFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFA2F301)));
          }
          if (snapshot.hasError ||
              !snapshot.hasData) {
            return const Center(
                child: Text('Musician not found',
                    style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final String name = data['fullName'] ?? data['name'] ?? 'Unknown';
          final String? imagePath = fixEmulatorUrl(data['profileImageUrl']);
          final double rating = (data['averageRating'] ?? 0.0).toDouble();
          final int reviewCount = data['reviewCount'] ?? 0;
          final String location = data['location'] ?? 'Unknown';
          final String bio = data['bio'] ?? 'No bio provided.';
          final List<String> genres =
              List<String>.from(data['genres'] ?? []);
          final int experience = data['yearsOfExperience'] ?? 0;
          final int gigsCompleted = data['gigsCompleted'] ?? 0;
          final double responseRate = (data['responseRate'] ?? 100.0).toDouble();
          final Map<String, dynamic> portfolio =
              data['portfolio'] as Map<String, dynamic>? ?? {};

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover + profile header
                        Image.asset(
                          'assets/gig_image1.jpg',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(height: 200, color: const Color(0xFF1A1A1F)),
                        ),
                        Container(
                          color: Colors.black,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: _isNetworkImage(imagePath)
                                    ? Image.network(
                                        imagePath!,
                                        width: 64,
                                        height: 64,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholderImage(),
                                      )
                                    : (imagePath != null
                                        ? Image.asset(
                                            imagePath,
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _placeholderImage(),
                                          )
                                        : _placeholderImage()),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Color(0xFFA2F301), size: 16),
                                        const SizedBox(width: 4),
                                        Text('${rating.toStringAsFixed(1)} ($reviewCount reviews)',                                            style: const TextStyle(
                                                color: Color(0xFF888888),
                                                fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                            'assets/location_pointer.svg',
                                            width: 14,
                                            height: 14,
                                            colorFilter: const ColorFilter.mode(
                                                Color(0xFF888888),
                                                BlendMode.srcIn)),
                                        const SizedBox(width: 4),
                                        Text(location,
                                            style: const TextStyle(
                                                color: Color(0xFF888888),
                                                fontSize: 14)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('$experience years experience',
                                        style: const TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Genre tags
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: genres
                                    .map((g) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFA2F301)
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color:
                                                    const Color(0x4DA2F301)),
                                          ),
                                          child: Text(g,
                                              style: const TextStyle(
                                                  color: Color(0xFFA2F301),
                                                  fontSize: 12)),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),

                              // Application details
                              if (widget.coverMessage != null ||
                                  widget.proposedRate != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1F),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0xFFA2F301)
                                            .withValues(alpha: 0.3),
                                        width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Application Details',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight:
                                                      FontWeight.w600)),
                                          if (widget.proposedRate != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 5),
                                              decoration: BoxDecoration(
                                                color:
                                                    const Color(0xFFA2F301),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '\$${widget.proposedRate}',
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (widget.coverMessage != null) ...[
                                        const SizedBox(height: 12),
                                        const Text('Cover Letter',
                                            style: TextStyle(
                                                color: Color(0xFFA2F301),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Text(
                                          widget.coverMessage!,
                                          style: const TextStyle(
                                              color: Color(0xFFCCCCCC),
                                              fontSize: 13,
                                              height: 1.5),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // About
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1A1F),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('About',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    Text(bio,
                                        style: const TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 13,
                                            height: 1.6)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Portfolio
                              if (portfolio.isNotEmpty) ...[
                                const Text('Portfolio',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 12),
                                ..._buildPortfolioItems(portfolio, context),
                                const SizedBox(height: 20),
                              ],

                              // Reviews
                              FutureBuilder<List<Map<String, dynamic>>>(
                                future: _apiService.getReviews(widget.musicianId),
                                builder: (context, snap) {
                                  if (!snap.hasData ||
                                      snap.data!.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Recent Reviews',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 12),
                                      ...snap.data!.map((r) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 10),
                                          child: _reviewCard(
                                            r['reviewerName'] ?? 'Anonymous',
                                            (r['rating'] ?? 5).toInt(),
                                            r['text'] ?? '',
                                            r['date'] ?? 'Recent',
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom action bar — uses already-loaded data, no extra fetch
                _buildBottomActions(
                  context,
                  name: name,
                  imagePath: imagePath ?? '',
                  rating: rating,
                  reviewCount: reviewCount,
                  location: location,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2F),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 32),
    );
  }

  List<Widget> _buildPortfolioItems(
      Map<String, dynamic> portfolio, BuildContext context) {
    final List<Widget> items = [];

    void addItems(
      List<dynamic> list,
      PortfolioItemType type,
      String defaultTitle,
      String iconPath,
      String typeLabel,
    ) {
      for (final entry in list) {
        final String url =
            entry is Map ? (entry['url'] ?? '').toString() : entry.toString();
        final String title = entry is Map
            ? (entry['title'] ?? defaultTitle).toString()
            : defaultTitle;
        final String description =
            entry is Map ? (entry['description'] ?? '').toString() : '';

        items.add(_portfolioItem(
          context: context,
          iconPath: iconPath,
          title: title,
          typeLabel: typeLabel,
          onTap: () => showPortfolioViewer(
            context,
            PortfolioViewerItem(
              url: url,
              title: title,
              description: description,
              type: type,
            ),
          ),
        ));
        items.add(const SizedBox(height: 8));
      }
    }

    addItems(portfolio['videos'] as List<dynamic>? ?? [],
        PortfolioItemType.video, 'Video Performance', 'assets/video_icon.svg',
        'Video');
    addItems(portfolio['audioTracks'] as List<dynamic>? ?? [],
        PortfolioItemType.audio, 'Audio Track', 'assets/music_note_icon.svg',
        'Audio');
    addItems(portfolio['images'] as List<dynamic>? ?? [],
        PortfolioItemType.image, 'Portfolio Image', 'assets/image_icon.svg',
        'Image');

    return items;
  }

  Widget _buildBottomActions(
    BuildContext context, {
    required String name,
    required String imagePath,
    required double rating,
    required int reviewCount,
    required String location,
  }) {
    return Container(
      color: const Color(0xFF0A0A0F),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final chatService =
                    Provider.of<ChatService>(context, listen: false);
                try {
                  final chatId = await chatService.getOrCreateChat(
                    widget.musicianId,
                    name,
                    imagePath,
                  );
                  if (context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        otherUserId: widget.musicianId,
                        name: name,
                        imagePath: imagePath,
                      ),
                    ));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error starting chat: $e')),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Message',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                double budgetValue = 750;
                if (widget.proposedRate != null) {
                  try {
                    final clean = widget.proposedRate!
                        .replaceAll(RegExp(r'[^0-9.]'), '');
                    if (clean.isNotEmpty) budgetValue = double.parse(clean);
                  } catch (_) {}
                } else if (widget.gigBudget != null) {
                  try {
                    final clean =
                        widget.gigBudget!.replaceAll(RegExp(r'[^0-9.]'), '');
                    if (clean.isNotEmpty) budgetValue = double.parse(clean);
                  } catch (_) {}
                }

                HireMusicianDialog.show(
                  context,
                  name: name,
                  imagePath: imagePath,
                  rating: rating,
                  reviewCount: reviewCount,
                  location: location,
                  rate: widget.proposedRate,
                  onConfirm: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        musicianId: widget.musicianId,
                        musicianName: name,
                        musicianImage: imagePath,
                        gigId: widget.gigId ?? '',
                        gigTitle: widget.gigTitle ?? 'Your Gig',
                        gigDate: widget.gigDate ?? 'TBD',
                        gigTime: widget.gigTime ?? 'TBD',
                        gigDuration: widget.gigDuration,
                        amount: budgetValue,
                        walletBalance: 0,
                        location: location,
                        organizerName: '', // This will be fetched on payment screen or from profile
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFA2F301),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Hire Musician',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _portfolioItem({
    required BuildContext context,
    required String iconPath,
    required String title,
    required String typeLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFA2F301).withValues(alpha: 0.15), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFA2F301).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                      Color(0xFFA2F301), BlendMode.srcIn),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(typeLabel,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF555555), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFA2F301),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(
      String reviewer, int stars, String review, String date) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reviewer,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFA2F301), size: 14),
                  const SizedBox(width: 4),
                  Text('$stars',
                      style: const TextStyle(
                          color: Color(0xFFA2F301), fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(review,
              style: const TextStyle(
                  color: Color(0xFF888888), fontSize: 13, height: 1.4)),
          const SizedBox(height: 6),
          Text(date,
              style:
                  const TextStyle(color: Color(0xFF555555), fontSize: 11)),
        ],
      ),
    );
  }
}
