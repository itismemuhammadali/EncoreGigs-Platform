import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'contract_view_screen.dart';
import 'booking_details_screen.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';

class ContractModel {
  final String id;
  final String title;
  final String musician;
  final String musicianId;
  final String performanceDate;
  final String amount;
  final String imagePath;
  final String status;
  final String signedDate;
  final String? statusNote;

  const ContractModel({
    required this.id,
    required this.title,
    required this.musician,
    required this.musicianId,
    required this.performanceDate,
    required this.amount,
    required this.imagePath,
    required this.status,
    required this.signedDate,
    this.statusNote,
  });
}

class MyContractsScreen extends StatefulWidget {
  const MyContractsScreen({super.key});

  @override
  State<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends State<MyContractsScreen> {
  String _selectedFilter = 'All';

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
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text(
          'My Contracts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Subtitle banner
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1F),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'View and manage all your signed performance contracts',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF888888), fontSize: 13),
              ),
            ),
            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['All', 'Active', 'Completed', 'Pending'].map((tab) {
                  final isActive = tab == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = tab),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFA2F301) : const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isActive ? Colors.black : const Color(0xFF888888),
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Contract list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('bookings')
                    .where('organizerId', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No contracts found.',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'pending';
                    final bool musicianSigned = data['musicianSignedAt'] != null;
                    final bool organizerSigned = data['organizerSignedAt'] != null;
                    final bool isFullySigned = musicianSigned && organizerSigned;

                    if (_selectedFilter == 'All') return true;
                    if (_selectedFilter == 'Pending') {
                      return !isFullySigned;
                    }
                    if (_selectedFilter == 'Active') {
                      return isFullySigned && status.toLowerCase() != 'completed';
                    }
                    return status.toLowerCase() == _selectedFilter.toLowerCase();
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No contracts found for this filter.',
                          style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final musicianId = data['musicianId'] ?? '';

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('musicians').doc(musicianId).get(),
                        builder: (context, musSnapshot) {
                          final musData = musSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                          
                          final bool musicianSigned = data['musicianSignedAt'] != null;
                          final bool organizerSigned = data['organizerSignedAt'] != null;
                          final bool isFullySigned = musicianSigned && organizerSigned;
                          
                          final String dbStatus = data['status'] ?? 'pending';
                          final bool isPaymentReleased = dbStatus == 'payment released' || dbStatus == 'completed';
                          
                          String signedInfo = 'Pending signatures';
                          if (isFullySigned) {
                            signedInfo = 'Fully Signed';
                          } else if (organizerSigned) {
                            signedInfo = 'Awaiting Musician Signature';
                          } else if (musicianSigned) {
                            signedInfo = 'Awaiting Your Signature';
                          }

                          String displayStatus = isFullySigned ? 'Payment in Escrow' : (organizerSigned ? 'Pending Musician' : 'Pending');
                          if (isPaymentReleased) {
                            displayStatus = 'Payment Released';
                          }
                          if (dbStatus == 'completed') {
                            displayStatus = 'Payment Released';
                          }

                          final contract = ContractModel(
                            id: doc.id,
                            title: 'Performance Agreement - ${data['gigTitle'] ?? 'Unnamed Gig'}',
                            musician: musData['fullName'] ?? data['musicianName'] ?? 'Unknown Musician',
                            musicianId: musicianId,
                            performanceDate: data['gigDate'] ?? 'N/A', 
                            amount: '\$${(data['amount'] ?? 0).toInt()}',
                            imagePath: fixEmulatorUrl(musData['profileImageUrl'] ?? 'assets/recent_activity_image1.jpg'),
                            status: displayStatus,
                            signedDate: signedInfo, 
                          );

                          return _ContractCard(
                            contract: contract,
                            paymentStatus: isPaymentReleased ? 'Payment Released' : 'Held in escrow',
                            time: data['gigTime'] ?? 'N/A',
                            location: data['location'] ?? 'N/A',
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final ContractModel contract;
  final String paymentStatus;
  final String time;
  final String location;

  const _ContractCard({
    required this.contract,
    required this.paymentStatus,
    required this.time,
    required this.location,
  });

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(
            bookingId: contract.id,
            title: contract.title.replaceAll('Performance Agreement - ', ''),
            musician: contract.musician,
            imagePath: contract.imagePath,
            status: contract.status,
            date: contract.performanceDate,
            time: time,
            location: location,
            amount: contract.amount,
            paymentStatus: paymentStatus,
            musicianId: contract.musicianId,
          ),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isNetworkImage(contract.imagePath)
                    ? Image.network(
                        contract.imagePath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
                      )
                    : Image.asset(
                        contract.imagePath,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            contract.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _statusColor(contract.status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _statusColor(contract.status)),
                          ),
                          child: Text(
                            contract.status == 'Waiting for musician signature' ? 'Pending Review' : contract.status,
                            style: TextStyle(
                              color: _statusColor(contract.status),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(contract.musician,
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('Performance: ${contract.performanceDate}',
                            style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: Color(0xFF888888))),
                        const SizedBox(width: 8),
                        Text(contract.amount,
                            style: const TextStyle(color: Color(0xFFA2F301), fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF2A2A2F), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  paymentStatus == 'Payment Released' ? 'Payment Released' : (contract.status == 'Waiting for musician signature' ? 'Waiting for musician signature' : contract.statusNote ?? contract.signedDate),
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
              children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ContractViewScreen(
                      bookingId: contract.id,
                    ),
                  ),
                ),
                child: Container(                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.visibility_outlined, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('View', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            'assets/download_icon.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                          const SizedBox(width: 6),
                          const Text('Download', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.person, color: Color(0xFF666666), size: 24),
    );
  }

  Color _statusColor(String status) {
    if (status == 'Waiting for musician signature' || status == 'Pending Musician') {
      return const Color(0xFFFFB347); // Orange for pending
    }
    if (status == 'Payment in Escrow') {
      return const Color(0xFF00BCD4);
    }
    if (status == 'Payment Released') {
      return const Color(0xFFA2F301);
    }
    switch (status) {
      case 'Signed':
        return const Color(0xFFA2F301);
      case 'Completed':
        return const Color(0xFF4A9EFF);
      case 'Cancelled':
        return const Color(0xFFFF4444);
      default:
        return const Color(0xFF888888);
    }
  }
}
