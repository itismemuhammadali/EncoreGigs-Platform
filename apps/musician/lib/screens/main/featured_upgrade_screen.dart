import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'featured_success_screen.dart';

class FeaturedUpgradeScreen extends StatefulWidget {
  const FeaturedUpgradeScreen({super.key});

  @override
  State<FeaturedUpgradeScreen> createState() => _FeaturedUpgradeScreenState();
}

class _FeaturedUpgradeScreenState extends State<FeaturedUpgradeScreen> {
  int _selectedPlan = 1; // 0 = 24h, 1 = 7 days, 2 = 30 days

  final List<Map<String, dynamic>> _plans = [
    {'duration': '24 Hours', 'price': '\$19.99', 'badge': null},
    {'duration': '7 Days', 'price': '\$49.99', 'badge': 'Most Popular', 'save': 'Save 30%'},
    {'duration': '30 Days', 'price': '\$149.99', 'badge': null, 'save': 'Save 50%'},
  ];

  @override
  Widget build(BuildContext context) {
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
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Crown icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: SvgPicture.asset(
                            'assets/crown_icon.svg',
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text('Become Featured',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Stand out from the crowd and get booked faster\nwith premium visibility',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF999999), fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    // What You Get card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('What You Get',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildFeatureRow(Icons.visibility_outlined, 'Top search visibility'),
                          _buildDivider(),
                          _buildFeatureRowSvg('assets/featured_icon.svg', 'Featured badge on profile'),
                          _buildDivider(),
                          _buildFeatureRow(Icons.trending_up, '3x more gig invitations'),
                          _buildDivider(),
                          _buildFeatureRowSvg('assets/star_rating_outline.svg', 'Priority support'),
                          _buildDivider(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Choose Duration
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Choose Your Duration',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),

                    // Plans
                    ...List.generate(_plans.length, (index) {
                      final plan = _plans[index];
                      final isSelected = _selectedPlan == index;
                      final isMostPopular = plan['badge'] == 'Most Popular';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedPlan = index),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFA1F301)
                                        : const Color(0xFFA1F301).withValues(alpha: 0.2),
                                    width: isSelected ? 2 : 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(plan['duration'],
                                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                            if (plan['save'] != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(plan['save'],
                                                    style: const TextStyle(color: Color(0xFFA1F301), fontSize: 11, fontWeight: FontWeight.w600)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(plan['price'],
                                            style: const TextStyle(color: Color(0xFFA1F301), fontSize: 22, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? const Color(0xFFA1F301) : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFFA1F301) : const Color(0xFF555555),
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, color: Colors.black, size: 14)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              if (isMostPopular)
                                Positioned(
                                  top: -12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFA1F301),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text('Most Popular',
                                          style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Expected Results card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.trending_up, color: Color(0xFFA1F301), size: 20),
                              const SizedBox(width: 8),
                              const Text('Expected Results',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('3x', style: TextStyle(color: Color(0xFFA1F301), fontSize: 32, fontWeight: FontWeight.bold)),
                                    Text('More Profile Views', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('2.5x', style: TextStyle(color: Color(0xFF00BCD4), fontSize: 32, fontWeight: FontWeight.bold)),
                                    Text('More Applications', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Fixed bottom button
            Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  top: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.2), width: 1),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FeaturedSuccessScreen(
                            duration: _plans[_selectedPlan]['duration'],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA1F301),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: SvgPicture.asset('assets/crown_icon.svg', fit: BoxFit.contain,
                                colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Upgrade Now',
                              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Cancel anytime. No long-term commitment required.',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFA1F301).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFA1F301), size: 20),
          ),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildFeatureRowSvg(String iconPath, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFA1F301).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SizedBox(
                width: 20, height: 20,
                child: SvgPicture.asset(iconPath, fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFA1F301).withValues(alpha: 0.15),
    );
  }
}
