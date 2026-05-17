import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0F),
        border: Border(top: BorderSide(color: Color(0xFF1A1A1F))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(iconPath: 'assets/home_icon.svg', label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
              _NavItem(iconPath: 'assets/gigs_icon.svg', label: 'Gigs', index: 1, currentIndex: currentIndex, onTap: onTap),
              _NavItem(iconPath: 'assets/messages_icon.svg', label: 'Messages', index: 2, currentIndex: currentIndex, onTap: onTap),
              _NavItem(iconPath: 'assets/bookings_icon.svg', label: 'Bookings', index: 3, currentIndex: currentIndex, onTap: onTap),
              _NavItem(iconPath: 'assets/profile_icon.svg', label: 'Profile', index: 4, currentIndex: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              isActive ? const Color(0xFFA2F301) : const Color(0xFF666666),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFA2F301) : const Color(0xFF666666),
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
