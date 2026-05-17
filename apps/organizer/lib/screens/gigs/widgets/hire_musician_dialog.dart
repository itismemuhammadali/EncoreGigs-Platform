import 'package:flutter/material.dart';

class HireMusicianDialog extends StatelessWidget {
  final String name;
  final String imagePath;
  final double rating;
  final int? reviewCount;
  final String? location;
  final String? rate;
  final VoidCallback onConfirm;

  const HireMusicianDialog({
    super.key,
    required this.name,
    required this.imagePath,
    required this.rating,
    this.reviewCount,
    this.location,
    this.rate,
    required this.onConfirm,
  });

  static void show(
    BuildContext context, {
    required String name,
    required String imagePath,
    required double rating,
    int? reviewCount,
    String? location,
    String? rate,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HireMusicianDialog(
        name: name,
        imagePath: imagePath,
        rating: rating,
        reviewCount: reviewCount,
        location: location,
        rate: rate,
        onConfirm: onConfirm,
      ),
    );
  }

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2F),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: _isNetworkImage(imagePath)
                ? Image.network(
                    imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFF2A2A2F),
                      child: const Icon(Icons.person, color: Color(0xFF666666), size: 36),
                    ),
                  )
                : Image.asset(
                    imagePath,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFF2A2A2F),
                      child: const Icon(Icons.person, color: Color(0xFF666666), size: 36),
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Color(0xFFA2F301), size: 16),
              const SizedBox(width: 4),
              Text(
                '${rating.toStringAsFixed(1)}${reviewCount != null ? ' ($reviewCount)' : ''}',
                style: const TextStyle(color: Color(0xFFA2F301), fontSize: 14),
              ),
              if (location != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on, color: Color(0xFF888888), size: 16),
                const SizedBox(width: 4),
                Text(
                  location!,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 14),
                ),
              ],
            ],
          ),
          if (rate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFA2F301).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA2F301).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Proposed Rate: \$$rate',
                style: const TextStyle(
                  color: Color(0xFFA2F301),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Hire $name?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "You'll proceed to payment and contract signing. The musician will be notified of your offer.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF888888),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFA2F301),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Continue to Payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Cancel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
