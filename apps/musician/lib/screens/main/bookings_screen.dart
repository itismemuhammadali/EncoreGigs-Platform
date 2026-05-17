import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottom_navigation_bar.dart';
import '../../widgets/booking_card.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import 'booking_detail_screen.dart';
import 'contract_review_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _currentNavIndex = 3;
  String _selectedFilter = 'All';

  static const _filters = ['All', 'Upcoming', 'Pending Review', 'Completed', 'Cancelled'];

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    setState(() {
      _currentNavIndex = index;
    });
    // Handle navigation to different screens
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/home');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/applications');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/messages');
        break;
      case 3:
        // Bookings - already here
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('musicianId', isEqualTo: currentUserId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No bookings yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }

                  final List<Booking> bookings = snapshot.data!.docs.map((doc) {
                    return Booking.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
                  }).toList();

                  // Apply filter
                  final List<Booking> filtered = bookings.where((b) {
                    switch (_selectedFilter) {
                      case 'Upcoming':
                        return b.status == BookingStatus.upcoming;
                      case 'Pending Review':
                        return b.status == BookingStatus.waitingSignature;
                      case 'Completed':
                        return b.status == BookingStatus.completed || 
                               b.status == BookingStatus.paymentReleased;
                      case 'Cancelled':
                        return b.status == BookingStatus.cancelled;
                      default:
                        return true;
                    }
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'No $_selectedFilter bookings',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final booking = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BookingCard(
                          booking: booking,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BookingDetailScreen(booking: booking),
                            ),
                          ),
                          onReviewContract: booking.contractStatus == ContractStatus.review
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ContractReviewScreen(booking: booking),
                                    ),
                                  )
                              : null,
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
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
            const Text(
              'My Bookings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your scheduled gigs',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isActive = filter == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFA1F301)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isActive
                            ? null
                            : Border.all(
                                color: const Color(0xFF333333), width: 1),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isActive
                              ? Colors.black
                              : const Color(0xFF888888),
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
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
    );
  }
}
