import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'widgets/bookings_filter_tabs.dart';
import 'widgets/booking_card.dart';
import '../notifications/notifications_screen.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String _selectedFilter = 'All';
  Key _refreshKey = UniqueKey();

  void _refreshData() {
    setState(() => _refreshKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0x4DA2F301), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Bookings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        ),
                        child: Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1F),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0x4DA2F301), width: 1.5),
                            ),
                            child: const Icon(Icons.notifications_outlined,
                                color: Colors.white, size: 22),
                          ),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BookingsFilterTabs(
                    selected: _selectedFilter,
                    onSelected: (val) =>
                        setState(() => _selectedFilter = val),
                  ),
                ],
              ),
            ),
            // Booking cards
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFA2F301),
                backgroundColor: const Color(0xFF1A1A1F),
                onRefresh: () async => _refreshData(),
                child: StreamBuilder<QuerySnapshot>(
                  key: _refreshKey,
                  stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('organizerId', isEqualTo: currentUserId)
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
                    return const Center(
                      child: Text('No bookings found.',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final bookingData = docs[index].data() as Map<String, dynamic>;
                      final gigId = bookingData['gigId'] ?? '';
                      final musicianId = bookingData['musicianId'] ?? '';
                      final status = bookingData['status'] ?? 'pending';

                      return FutureBuilder<List<DocumentSnapshot>>(
                        future: Future.wait([
                          FirebaseFirestore.instance.collection('gigs').doc(gigId).get(),
                          FirebaseFirestore.instance.collection('musicians').doc(musicianId).get(),
                        ]),
                        builder: (context, multiSnapshot) {
                          if (!multiSnapshot.hasData) {
                            return const SizedBox(height: 100);
                          }

                          final gigDoc = multiSnapshot.data![0];
                          final musDoc = multiSnapshot.data![1];

                          final gigData = gigDoc.data() as Map<String, dynamic>? ?? {};
                          final musData = musDoc.data() as Map<String, dynamic>? ?? {};
final bookingModel = BookingModel(
  id: docs[index].id,
  title: gigData['title'] ?? bookingData['gigTitle'] ?? 'Unnamed Gig',
  musician: musData['fullName'] ?? bookingData['musicianName'] ?? 'Unknown Musician',
  dateTime: '${gigData['date'] ?? 'Feb 15, 2026'} • ${gigData['time'] ?? '8:00 PM'}',
  location: gigData['location'] ?? 'Unknown Location',
  imagePath: fixEmulatorUrl(musData['profileImageUrl'] ?? 'assets/recent_activity_image1.jpg'),
  status: status,
  musicianId: musicianId,
  amount: '\$${bookingData['amount'] ?? 0}',
  paymentStatus: (status == 'payment released' || status == 'completed') 
      ? 'Payment Released' 
      : (status == 'Waiting for musician signature' 
          ? 'Waiting for musician signature' 
          : 'Payment in escrow'),
);

                          // Filter logic
                          if (_selectedFilter != 'All') {
                            bool matches = false;
                            if (_selectedFilter == 'Upcoming') {
                              matches = status == 'Payment in escrow' ||
                                  status.toLowerCase() == 'upcoming' ||
                                  status.toLowerCase() == 'pending';
                            } else if (_selectedFilter == 'Pending Review') {
                              matches = status == 'Waiting for musician signature';
                            } else {
                              matches = status.toLowerCase() ==
                                  _selectedFilter.toLowerCase();
                            }
                            if (!matches) return const SizedBox.shrink();
                          }

                          return BookingCard(booking: bookingModel);
                        },
                      );
                    },
                  );
                },
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
