import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/gig.dart';
import 'applicants_screen.dart';
import '../../services/auth_service.dart';

class GigDetailsScreen extends StatelessWidget {
  final GigModel gig;

  const GigDetailsScreen({super.key, required this.gig});

  bool _isNetworkImage(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).user?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0x4DA2F301), height: 1),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text('Booking Details',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image with genre badge
              Stack(
                children: [
                  _isNetworkImage(gig.imageUrl)
                      ? Image.network(
                          gig.imageUrl!,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/gig_image1.jpg',
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          gig.imageUrl ?? 'assets/gig_image1.jpg',
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 220,
                            color: const Color(0xFF1A1A1F),
                          ),
                        ),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA2F301).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA2F301)),
                      ),
                      child: Text(
                          gig.genres.isNotEmpty ? gig.genres.first : 'Genre',
                          style: const TextStyle(
                              color: Color(0xFFA2F301),
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gig.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SvgPicture.asset('assets/location_pointer.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                                Color(0xFF888888), BlendMode.srcIn)),
                        const SizedBox(width: 6),
                        Text(gig.location,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SvgPicture.asset('assets/bookings_icon.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                                Color(0xFF888888), BlendMode.srcIn)),
                        const SizedBox(width: 6),
                        Text('${gig.date} • ${gig.time}',
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money,
                            color: Color(0xFF888888), size: 16),
                        const SizedBox(width: 4),
                        Text(gig.budget,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('applications')
                          .where('gigId', isEqualTo: gig.gigId)
                          .where('organizerId', isEqualTo: currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : gig.applicationsCount;
                        return Row(
                          children: [
                            SvgPicture.asset('assets/users_icon.svg',
                                width: 14,
                                height: 14,
                                colorFilter: const ColorFilter.mode(
                                    Color(0xFFA2F301), BlendMode.srcIn)),
                            const SizedBox(width: 6),
                            Text('$count applications received',
                                style: const TextStyle(
                                    color: Color(0xFFA2F301),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        );
                      }
                    ),
                    const SizedBox(height: 20),
                    // Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(height: 8),
                          Text(
                            gig.description.isNotEmpty
                                ? gig.description
                                : 'No description provided.',
                            style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 13,
                                height: 1.6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Requirements
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Requirements',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          ...(gig.requirements.isNotEmpty
                                  ? gig.requirements
                                  : ['No requirements provided.'])
                              .map((req) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            color: Color(0xFF888888),
                                            fontSize: 14)),
                                    Expanded(
                                      child: Text(req,
                                          style: const TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 13,
                                              height: 1.4)),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('gigId', isEqualTo: gig.gigId)
            .where('organizerId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.hasData ? snapshot.data!.docs.length : gig.applicationsCount;
          final isHired = snapshot.hasData && snapshot.data!.docs.any((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'hired');
          
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: GestureDetector(
              onTap: () async {
                // Fetch organizer name from Firestore
                final organizerDoc = await FirebaseFirestore.instance
                    .collection('organizers')
                    .doc(gig.organizerId)
                    .get();
                final organizerName = organizerDoc.data()?['orgName'] ?? 'Event Organizer';
                
                if (context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ApplicantsScreen(
                      gigId: gig.gigId, 
                      gigTitle: gig.title,
                      gigBudget: gig.budget,
                      gigDate: gig.date,
                      gigTime: gig.time,
                      gigDuration: gig.duration,
                      location: gig.location,
                      organizerName: organizerName,
                    ),
                  ));
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isHired ? const Color(0xFF2A2A2F) : const Color(0xFFA2F301),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isHired ? 'Musician Hired' : 'View Applicants ($count)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isHired ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
