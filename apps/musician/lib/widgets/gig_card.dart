import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/gig_model.dart';

class GigCard extends StatelessWidget {
  final Gig gig;
  final VoidCallback onTap;
  final bool isApplied;

  const GigCard({
    super.key,
    required this.gig,
    required this.onTap,
    this.isApplied = false,
  });

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFA1F301),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: _isNetworkImage(gig.imageUrl ?? '')
                ? NetworkImage(gig.imageUrl!) as ImageProvider
                : AssetImage(gig.imageUrl ?? 'assets/gig_image1.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Dark overlay gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top row: Genre and Featured badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          gig.genre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/featured_icon.svg',
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFA1F301),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Featured',
                              style: TextStyle(
                                color: Color(0xFFA1F301),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Bottom section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        gig.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Organizer
                      Text(
                        gig.organizer ?? 'Event Organizer',
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${gig.rating}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Pay and Date row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              const Text(
                                '\$',
                                style: TextStyle(
                                  color: Color(0xFFA1F301),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                gig.pay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isApplied)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    'Applied',
                                    style: TextStyle(
                                      color: Color(0xFFA1F301),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0xFF00BCD4), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    gig.date.toString().split(' ')[0],
                                    style: const TextStyle(
                                      color: Color(0xFF00BCD4),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Divider
                      Container(
                        height: 1,
                        color: Colors.grey[700],
                      ),
                      const SizedBox(height: 12),
                      // Location and distance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF999999), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                gig.location,
                                style: const TextStyle(
                                  color: Color(0xFF999999),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${gig.distance} mi',
                            style: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
