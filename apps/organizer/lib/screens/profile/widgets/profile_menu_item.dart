import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData? icon;
  final String? iconPath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;
  final Color? iconBgColor;

  const ProfileMenuItem({
    super.key,
    this.icon,
    this.iconPath,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.iconColor,
    this.titleColor,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? const Color(0xFFA2F301);
    final effectiveTitleColor = titleColor ?? Colors.white;
    final effectiveIconBgColor = iconBgColor ?? effectiveIconColor.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: effectiveIconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: iconPath != null
                    ? SvgPicture.asset(
                        iconPath!,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                            effectiveIconColor, BlendMode.srcIn),
                      )
                    : Icon(icon, color: effectiveIconColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: effectiveTitleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFF555555), size: 20),
          ],
        ),
      ),
    );
  }
}
