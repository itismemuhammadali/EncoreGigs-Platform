import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Find Gigz That Match\nYour Sound',
      description:
          'Discover performance opportunities tailored\nto your genre, style, and location.',
      logoPath: 'assets/Logo.png',
      backgroundPath: 'assets/onboarding-img-1.jpg',
    ),
    OnboardingPage(
      title: 'Get Booked. Get Paid.\nNo Hassle',
      description:
          'Secure bookings with digital contracts and\nguaranteed payments through our platform.',
      logoPath: 'assets/Logo.png',
      backgroundPath: 'assets/onboarding-img-2.jpg',
    ),
    OnboardingPage(
      title: 'Build Your Reputation\n& Get Featured',
      description:
          'Earn reviews, grow your profile, and get\ndiscovered by premium event organizers.',
      logoPath: 'assets/Logo.png',
      backgroundPath: 'assets/onboarding-img-3.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return _buildPage(pages[index]);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? const Color(0xFFA2F301)
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentPage == pages.length - 1) {
                      // Navigate to login screen
                      Navigator.of(context).pushReplacementNamed('/login');
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA2F301),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: SvgPicture.asset(
                            'assets/next_arrow_no_tail.svg',
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(
                              Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Stack(
      children: [
        // Background image
        page.backgroundPath != null
            ? Image.asset(
                page.backgroundPath!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    width: double.infinity,
                    height: double.infinity,
                  );
                },
              )
            : Container(
                color: Colors.black,
                width: double.infinity,
                height: double.infinity,
              ),
        // Gradient overlay - bright at top, dark at bottom
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.9),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
        // Content - positioned lower
        Column(
          children: [
            SizedBox(
              height: 360,
              child: Container(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Image.asset(
                      page.logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: const Center(
                            child: Text('Logo not found'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF999999),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String logoPath;
  final String? backgroundPath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.logoPath,
    this.backgroundPath,
  });
}
