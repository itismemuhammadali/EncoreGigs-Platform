import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/profile_model.dart';
import '../screens/main/manage_portfolio_screen.dart';

class PortfolioSection extends StatelessWidget {
  final List<PortfolioItem> portfolioItems;

  const PortfolioSection({super.key, required this.portfolioItems});

  String _getIconPath(String type) {
    switch (type) {
      case 'video':
        return 'assets/video_icon.svg';
      case 'image':
        return 'assets/image_icon.svg';
      case 'music':
        return 'assets/music_note_icon.svg';
      default:
        return 'assets/video_icon.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border.all(
          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ManagePortfolioScreen()),
                    );
                  },
                  child: const Text(
                    '+ Add More',
                    style: TextStyle(
                      color: Color(0xFFA1F301),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: portfolioItems.length,
            itemBuilder: (context, index) {
              // Select a portfolio asset based on index (1, 2, or 3)
              final assetIndex = (index % 3) + 1;
              final assetPath = 'assets/portfolio_image$assetIndex.png';

              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[800],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (portfolioItems[index].type == 'video' || portfolioItems[index].type == 'music')
                        ? Image.asset(
                            assetPath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : portfolioItems[index].image.startsWith('http')
                            ? Image.network(
                                portfolioItems[index].image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.asset(
                                portfolioItems[index].image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: SvgPicture.asset(
                      _getIconPath(portfolioItems[index].type),
                      fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
