import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../models/gig.dart';
import '../../../services/auth_service.dart';
import '../gig_details_screen.dart';

class GigCard extends StatelessWidget {
  final GigModel gig;

  const GigCard({super.key, required this.gig});

  bool _isNetworkImage(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).user?.uid;
    
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => GigDetailsScreen(gig: gig),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA2F301), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Background image
              _isNetworkImage(gig.imageUrl)
                  ? Image.network(
                      gig.imageUrl!,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/gig_image1.jpg',
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      gig.imageUrl ?? 'assets/gig_image1.jpg',
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 280,
                        color: const Color(0xFF2A2A2F),
                      ),
                    ),
              // Gradient overlay — dark at bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.95),
                      ],
                      stops: const [0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              // Genre badge top right
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA2F301).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFA2F301), width: 1),
                  ),
                  child: Text(
                    gig.genres.isNotEmpty ? gig.genres.first : 'Genre',
                    style: const TextStyle(
                      color: Color(0xFFA2F301),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Urgent badge top left
              if (gig.isUrgent)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.red, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'URGENT',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Content overlaid at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gig.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SvgPicture.asset('assets/location_pointer.svg',
                              width: 14,
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFF888888), BlendMode.srcIn)),
                          const SizedBox(width: 6),
                          Text(gig.location,
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                SvgPicture.asset('assets/bookings_icon.svg',
                                    width: 14,
                                    height: 14,
                                    colorFilter: const ColorFilter.mode(
                                        Color(0xFF4A9EFF), BlendMode.srcIn)),
                                const SizedBox(width: 6),
                                Text(gig.date,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.attach_money,
                                    color: Color(0xFFA2F301), size: 16),
                                const SizedBox(width: 2),
                                Text(gig.budget,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: Color(0x4DA2F301), height: 1),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('applications')
                            .where('gigId', isEqualTo: gig.gigId)
                            .where('organizerId', isEqualTo: currentUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                          final isHired = snapshot.hasData && snapshot.data!.docs.any((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'hired');
                          
                          return Text(
                            isHired ? 'Musician Hired' : '$count ${count == 1 ? 'application' : 'applications'} received',
                            style: TextStyle(
                              color: isHired ? Colors.white : const Color(0xFFA2F301),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
