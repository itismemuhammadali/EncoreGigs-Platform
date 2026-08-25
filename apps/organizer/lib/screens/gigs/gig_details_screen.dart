import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/gig.dart';
import 'applicants_screen.dart';
import 'post_gig_screen.dart';
import '../../services/auth_service.dart';

class GigDetailsScreen extends StatelessWidget {
  final GigModel gig;

  const GigDetailsScreen({super.key, required this.gig});

  bool _isNetworkImage(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  Future<void> _editGig(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PostGigScreen(gigToEdit: gig),
      ),
    );
    if (updated == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _deleteGig(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Gig',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${gig.title}"? This action cannot be undone and will remove all applications.',
          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D4D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.deleteGig(gig.gigId);
      if (context.mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gig deleted successfully')),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).user?.uid;
    final bool isOwner = currentUserId == gig.organizerId || currentUserId != null;

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
                  if (gig.isUrgent)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, color: Colors.red, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'URGENT',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
                    // Description / Gig Details
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
                          const Text('Gig Details',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            gig.description.isNotEmpty
                                ? gig.description
                                : 'No details provided.',
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
          
          return Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0F),
              border: Border(top: BorderSide(color: Color(0xFF1A1A1F), width: 1)),
            ),
            child: Row(
              children: [
                // 1st: View Applicants Button (Expanded)
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
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
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isHired ? const Color(0xFF2A2A2F) : const Color(0xFFA2F301),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHired ? 'Musician Hired' : 'View Applicants ($count)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: isHired ? Colors.white : Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                
                // 2nd: Edit Icon Button
                if (isOwner) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _editGig(context),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2A2A2F)),
                      ),
                      child: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                    ),
                  ),
                  
                  // 3rd: Delete Icon Button
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _deleteGig(context),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4D4D).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF4D4D).withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.delete_outline, color: Color(0xFFFF4D4D), size: 22),
                    ),
                  ),
                ],
              ],
            ),
          );
        }
      ),
    );
  }
}
