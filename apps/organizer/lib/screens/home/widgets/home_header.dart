import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_service.dart';
import '../../notifications/notifications_screen.dart';
import '../../calendar/organizer_calendar_screen.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  int _unreadCount = 0;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final count = await _api.getUnreadNotificationCount(user.uid);
      if (mounted) setState(() => _unreadCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Thursday, February 5, 2026',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrganizerCalendarScreen()),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0x4DA2F301), width: 1.5),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Stack(
              children: [
                GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                    _fetchUnreadCount();
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1F),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x4DA2F301), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
