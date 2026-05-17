import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> iconPaths = [
      'assets/home_icon.svg',
      'assets/application_icon.svg',
      'assets/messages_icon.svg',
      'assets/bookings_icon.svg',
      'assets/profile_icon.svg',
    ];

    final List<String> labels = ['Home', 'Applications', 'Messages', 'Bookings', 'Profile'];

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      backgroundColor: const Color(0xFF0A0A0F),
      selectedItemColor: const Color(0xFFA1F301),
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      unselectedLabelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
      ),
      selectedLabelStyle: const TextStyle(
        color: Color(0xFFA1F301),
        fontSize: 12,
      ),
      items: List.generate(
        5,
        (index) => BottomNavigationBarItem(
          icon: Container(
            width: 40,
            height: 40,
            decoration: index == currentIndex
                ? BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFA1F301).withValues(alpha: 0.1),
                        Colors.black,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  iconPaths[index],
                  colorFilter: ColorFilter.mode(
                    index == currentIndex ? const Color(0xFFA1F301) : Colors.grey[600]!,
                    BlendMode.srcIn,
                  ),
                  semanticsLabel: labels[index],
                ),
              ),
            ),
          ),
          label: labels[index],
        ),
      ),
    );
  }
}
