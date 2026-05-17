import 'package:flutter/material.dart';
import 'widgets/home_header.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/stats_row.dart';
import 'widgets/action_buttons.dart';
import 'widgets/recent_activity.dart';
import 'widgets/bottom_nav_bar.dart';
import '../gigs/gigs_screen.dart';
import '../messages/messages_screen.dart';
import '../bookings/bookings_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  Widget _buildHomeBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x4DA2F301), width: 1),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeHeader(),
                SizedBox(height: 20),
                SearchBarWidget(),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StatsRow(),
                  const SizedBox(height: 16),
                  ActionButtons(
                    onMessages: () => setState(() => _currentNavIndex = 2),
                  ),
                  const SizedBox(height: 24),
                  const RecentActivity(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getScreen() {
    switch (_currentNavIndex) {
      case 1:
        return const GigsScreen();
      case 2:
        return const MessagesScreen();
      case 3:
        return const BookingsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildHomeBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: _getScreen(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
    );
  }
}
