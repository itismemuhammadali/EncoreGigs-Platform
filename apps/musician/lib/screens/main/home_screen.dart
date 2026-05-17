import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:onlygigz_musician/services/api_service.dart';
import 'package:onlygigz_musician/services/auth_service.dart';
import 'package:onlygigz_musician/models/gig_model.dart';
import 'notifications_screen.dart';
import 'gig_detail_screen.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/gig_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  int _currentNavIndex = 0;
  String _searchQuery = '';
  int _selectedFilterIndex = 0;

  final List<String> filters = ['All', 'Nearby', 'This Week', 'High Badge'];

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    // Handle navigation to different screens
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/applications');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/messages');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/bookings');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and notification row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Discover Gigs',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Find your next performance',
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search gigs, venues, genres...',
                          hintStyle: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF666666),
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filters.asMap().entries.map((entry) {
                          final index = entry.key;
                          final filter = entry.value;
                          final isSelected = _selectedFilterIndex == index;
                          return Padding(
                            padding: EdgeInsets.only(right: index == filters.length - 1 ? 0 : 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFilterIndex = index;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFA1F301) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFA1F301) : const Color(0xFF333333),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Gigs list with Backend
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _apiService.getGigs(status: 'open', searchQuery: _searchQuery),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'No gigs found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  // Parse gigs
                  List<Gig> gigs = snapshot.data!.map((data) {
                    return Gig.fromFirestore(data, data['id'] ?? '');
                  }).toList();

                  // Category filters
                  List<Gig> filteredGigs = gigs.where((gig) {
                    switch (_selectedFilterIndex) {
                      case 1: // Nearby
                        return gig.distance <= 5.0;
                      case 2: // This Week
                        final now = DateTime.now();
                        final weekFromNow = now.add(const Duration(days: 7));
                        return gig.date.isAfter(now) && gig.date.isBefore(weekFromNow);
                      case 3: // High Badge
                        return gig.rating >= 4.7;
                      default: // All
                        return true;
                    }
                  }).toList();

                  if (filteredGigs.isEmpty) {
                    return Center(
                      child: Text(
                        'No matching gigs found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: filteredGigs.length,
                    itemBuilder: (context, index) {
                      final gig = filteredGigs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Consumer<AuthService>(
                          builder: (context, authService, _) {
                            final isApplied = authService.appliedGigIds.contains(gig.id);
                            return GigCard(
                              gig: gig,
                              isApplied: isApplied,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => GigDetailScreen(gig: gig),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
