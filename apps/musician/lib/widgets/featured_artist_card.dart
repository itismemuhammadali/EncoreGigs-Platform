import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/main/featured_upgrade_screen.dart';

class FeaturedArtistCard extends StatelessWidget {
  const FeaturedArtistCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2EF202).withValues(alpha: 0.2),
            const Color(0xFF03342C),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crown icon on the left
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFA1F301).withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(
                  'assets/crown_icon.svg',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with featured icon
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Become a Featured Artist',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: SvgPicture.asset(
                        'assets/featured_icon.svg',
                        fit: BoxFit.contain,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFA1F301),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get 3x more visibility and appear at the top of search results',
                  style: TextStyle(
                    color: Color(0xFFB0B0B0),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const FeaturedUpgradeScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA1F301),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
