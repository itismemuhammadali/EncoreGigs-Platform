import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/gig_model.dart';
import '../../services/auth_service.dart';
import 'apply_gig_screen.dart';
import 'organizer_profile_screen.dart';

class GigDetailScreen extends StatefulWidget {
  final Gig gig;

  const GigDetailScreen({super.key, required this.gig});

  @override
  State<GigDetailScreen> createState() => _GigDetailScreenState();
}

class _GigDetailScreenState extends State<GigDetailScreen> {
  Map<String, dynamic>? _organizerProfile;
  int _gigsPosted = 0;
  bool _isLoadingOrganizer = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizerDetails();
  }

  Future<void> _loadOrganizerDetails() async {
    if (widget.gig.organizerId == null) {
      setState(() => _isLoadingOrganizer = false);
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final profile = await authService.getProfile(widget.gig.organizerId!);
    final gigs = await authService.getGigsByOrganizer(widget.gig.organizerId!);

    if (mounted) {
      setState(() {
        _organizerProfile = profile;
        _gigsPosted = gigs.length;
        _isLoadingOrganizer = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  void _viewOrganizerProfile() {
    if (widget.gig.organizerId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrganizerProfileScreen(organizerId: widget.gig.organizerId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gig = widget.gig;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dark header with back button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0F),
                      border: Border(
                        bottom: BorderSide(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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

                  // Hero image card with margins and rounded corners
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          // Image
                          SizedBox(
                            width: double.infinity,
                            height: 220,
                            child: _isNetworkImage(gig.imageUrl ?? '')
                                ? Image.network(
                                    gig.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      'assets/gig_image1.jpg',
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    gig.imageUrl ?? 'assets/gig_image1.jpg',
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          // Gradient overlay - stronger at bottom for text readability
                          Container(
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),
                          // Genre badge top right
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                                border: Border.all(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                gig.genre,
                                style: const TextStyle(
                                  color: Color(0xFFA1F301),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (gig.isUrgent)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'URGENT GIG',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Title
                      Text(
                        gig.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Organizer name
                      Text(
                        gig.organizer ?? '',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info grid - 2x2
                      Row(
                        children: [
                          Expanded(child: _buildInfoCard(
                            icon: Icons.attach_money,
                            iconColor: const Color(0xFFA1F301),
                            label: 'Budget',
                            value: gig.pay,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInfoCard(
                            iconSvg: 'assets/bookings_icon.svg',
                            iconColor: const Color(0xFF00BCD4),
                            label: 'Date',
                            value: _formatDate(gig.date),
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildInfoCard(
                            iconSvg: 'assets/location_pointer.svg',
                            iconColor: const Color(0xFFFF6B9D),
                            label: 'Location',
                            value: gig.location,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _buildInfoCard(
                            iconSvg: 'assets/gigs_icon.svg',
                            iconColor: const Color(0xFF9B59B6),
                            label: 'Duration',
                            value: gig.duration ?? '3 hours',
                          )),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Organizer card
                      GestureDetector(
                        onTap: _viewOrganizerProfile,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0F),
                            border: Border.all(
                              color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Organizer label + rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Organizer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${gig.rating}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Bottom row: image + name + gigs posted
                              _isLoadingOrganizer 
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)))
                                : Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF333333),
                                          ),
                                          child: (_organizerProfile?['profileImageUrl'] != null)
                                              ? Image.network(
                                                  _organizerProfile!['profileImageUrl'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => 
                                                      const Icon(Icons.person, color: Colors.white),
                                                )
                                              : (gig.organizerImage != null)
                                                  ? Image.asset(
                                                      gig.organizerImage!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => 
                                                          const Icon(Icons.person, color: Colors.white),
                                                    )
                                                  : const Icon(Icons.person, color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _organizerProfile?['name'] ?? _organizerProfile?['fullName'] ?? _organizerProfile?['orgName'] ?? gig.organizer ?? 'Organizer',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _organizerProfile?['type'] ?? 'Event Organizer',
                                              style: const TextStyle(
                                                color: Color(0xFFA1F301),
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$_gigsPosted gigs posted',
                                              style: const TextStyle(
                                                color: Color(0xFF999999),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Color(0xFF666666)),
                                    ],
                                  ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              gig.description,
                              style: const TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Requirements card
                      if (gig.requirements.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Requirements',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...gig.requirements.map((req) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(
                                                color: Color(0xFFA1F301),
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold)),
                                        Expanded(
                                          child: Text(
                                            req,
                                            style: const TextStyle(
                                              color: Color(0xFF999999),
                                              fontSize: 14,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),

                      // Bottom padding for the fixed button
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed Apply button at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
              child: Consumer<AuthService>(
                builder: (context, authService, _) {
                  final isApplied = authService.appliedGigIds.contains(gig.id);
                  return GestureDetector(
                    onTap: isApplied ? null : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ApplyGigScreen(gig: gig),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: isApplied ? Colors.grey[800] : const Color(0xFFA1F301),
                        borderRadius: BorderRadius.circular(16),
                        border: isApplied ? Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5) : null,
                      ),
                      child: Center(
                        child: Text(
                          isApplied ? 'Applied to this gig' : 'Apply to Gig',
                          style: TextStyle(
                            color: isApplied ? const Color(0xFFA1F301) : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildInfoCard({
    IconData? icon,
    String? iconSvg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconSvg != null
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: SvgPicture.asset(
                    iconSvg,
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                  ),
                )
              : Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
