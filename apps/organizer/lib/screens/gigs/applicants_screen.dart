import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:onlygigz_organizer/services/api_service.dart';
import '../../services/chat_service.dart';
import '../messages/chat/chat_screen.dart';
import 'musician_profile_screen.dart';
import 'widgets/hire_musician_dialog.dart';
import 'payment_screen.dart';
import '../../services/auth_service.dart';
import '../../constants.dart';

class ApplicantModel {
  final String id;
  final String musicianId;
  final String name;
  final String imagePath;
  final double rating;
  final int reviewCount;
  final String location;
  final List<String> genres;
  final String status;
  final String? previousStatus;
  final String? proposedRate;
  final String? coverMessage;

  const ApplicantModel({
    required this.id,
    required this.musicianId,
    required this.name,
    required this.imagePath,
    required this.rating,
    required this.reviewCount,
    required this.location,
    required this.genres,
    required this.status,
    this.previousStatus,
    this.proposedRate,
    this.coverMessage,
  });
}

class ApplicantsScreen extends StatefulWidget {
  final String gigId;
  final String gigTitle;
  final String gigBudget;
  final String gigDate;
  final String gigTime;
  final String? gigDuration;
  final String? location;
  final String? organizerName;

  const ApplicantsScreen({
    super.key, 
    required this.gigId, 
    required this.gigTitle, 
    required this.gigBudget,
    required this.gigDate,
    required this.gigTime,
    this.gigDuration,
    this.location,
    this.organizerName,
  });

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Applicants',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _apiService.getApplications(gigId: widget.gigId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No applications yet.',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 16)),
              );
            }

            final applications = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${applications.length} Applications',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Review and hire musicians for your gig',
                        style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      final appData = applications[index];
                      final musicianId = appData['musicianId'] ?? '';
                      
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _apiService.getProfile(musicianId),
                        builder: (context, musSnapshot) {
                          if (!musSnapshot.hasData) {
                            return const SizedBox(height: 100);
                          }
                          
                          final musData = musSnapshot.data!;

                          final applicant = ApplicantModel(
                            id: appData['id'] ?? '',
                            musicianId: musicianId,
                            name: musData['fullName'] ?? musData['name'] ?? 'Unknown Musician',
                            imagePath: fixEmulatorUrl(musData['profileImageUrl'] ?? 'assets/recent_activity_image1.jpg'),
                            rating: (musData['averageRating'] ?? 0.0).toDouble(),
                            reviewCount: musData['reviewCount'] ?? 0,
                            location: musData['location'] ?? 'Unknown Location',
                            genres: List<String>.from(musData['genres'] ?? []),
                            status: appData['status'] ?? 'pending',
                            previousStatus: appData['previousStatus'],
                            proposedRate: appData['proposedRate'],
                            coverMessage: appData['coverMessage'],
                          );

                          return _ApplicantCard(
                            applicant: applicant, 
                            gigId: widget.gigId,
                            gigTitle: widget.gigTitle, 
                            gigBudget: widget.gigBudget,
                            gigDate: widget.gigDate,
                            gigTime: widget.gigTime,
                            gigDuration: widget.gigDuration,
                            location: widget.location,
                            organizerName: widget.organizerName,
                            onRefresh: () => setState(() {}),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ApplicantCard extends StatelessWidget {
  final ApplicantModel applicant;
  final String gigId;
  final String gigTitle;
  final String gigBudget;
  final String gigDate;
  final String gigTime;
  final String? gigDuration;
  final String? location;
  final String? organizerName;
  final VoidCallback onRefresh;

  const _ApplicantCard({
    required this.applicant, 
    required this.gigId,
    required this.gigTitle, 
    required this.gigBudget,
    required this.gigDate,
    required this.gigTime,
    this.gigDuration,
    this.location,
    this.organizerName,
    required this.onRefresh,
  });

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MusicianProfileScreen(
          musicianId: applicant.musicianId,
          gigId: gigId,
          gigTitle: gigTitle,
          gigBudget: gigBudget,
          gigDate: gigDate,
          gigTime: gigTime,
          gigDuration: gigDuration,
          proposedRate: applicant.proposedRate,
          coverMessage: applicant.coverMessage,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: _isNetworkImage(applicant.imagePath)
                      ? Image.network(
                          applicant.imagePath,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFF2A2A2F),
                          ),
                        )
                      : Image.asset(
                          applicant.imagePath,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 56,
                            height: 56,
                            color: const Color(0xFF2A2A2F),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(applicant.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                                if (applicant.status != 'pending' && applicant.status != 'hired')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      applicant.status.toUpperCase(),
                                      style: TextStyle(
                                        color: applicant.status == 'shortlisted' ? const Color(0xFFA2F301) : Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (applicant.proposedRate != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFA2F301).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFA2F301).withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    '\$${applicant.proposedRate}',
                                    style: const TextStyle(
                                      color: Color(0xFFA2F301),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Color(0xFF666666), size: 20),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Color(0xFFA2F301), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${applicant.rating.toStringAsFixed(1)} (${applicant.reviewCount})',                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SvgPicture.asset('assets/location_pointer.svg',
                              width: 12,
                              height: 12,
                              colorFilter: const ColorFilter.mode(
                                  Color(0xFF888888), BlendMode.srcIn)),
                          const SizedBox(width: 4),
                          Text(applicant.location,
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: applicant.genres
                            .map((g) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2A2A2F),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(g,
                                      style: const TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 11)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2A2A2F), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final newStatus = applicant.status == 'shortlisted' ? 'pending' : 'shortlisted';
                        await apiService.updateApplicationStatus(applicant.id, newStatus);
                        onRefresh();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating status: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: applicant.status == 'shortlisted'
                            ? const Color(0xFFA2F301).withValues(alpha: 0.2)
                            : const Color(0x4D2A2A2A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: applicant.status == 'shortlisted'
                              ? const Color(0xFFA2F301)
                              : const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: Text(
                        applicant.status == 'shortlisted' ? 'Shortlisted' : 'Shortlist',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: applicant.status == 'shortlisted' ? const Color(0xFFA2F301) : Colors.white, 
                          fontSize: 13,
                          fontWeight: applicant.status == 'shortlisted' ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final newStatus = applicant.status == 'rejected' 
                            ? (applicant.previousStatus ?? 'pending') 
                            : 'rejected';
                        await apiService.updateApplicationStatus(applicant.id, newStatus);
                        onRefresh();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error updating status: $e')),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: applicant.status == 'rejected'
                            ? Colors.red.withValues(alpha: 0.2)
                            : const Color(0x4D2A2A2A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: applicant.status == 'rejected'
                              ? Colors.red
                              : const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: Text(
                        applicant.status == 'rejected' ? 'Rejected' : 'Reject',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: applicant.status == 'rejected' ? Colors.red : Colors.white, 
                          fontSize: 13, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                      onTap: applicant.status == 'hired' 
                      ? null 
                      : () {
                          // Use proposedRate if available, otherwise fall back to gigBudget
                          double finalAmount = 0;
                          try {
                            if (applicant.proposedRate != null) {
                              final cleanRate = applicant.proposedRate!.replaceAll(RegExp(r'[^0-9.]'), '');
                              finalAmount = double.parse(cleanRate);
                            } else {
                              final cleanBudget = gigBudget.replaceAll(RegExp(r'[^0-9.]'), '');
                              finalAmount = double.parse(cleanBudget);
                            }
                          } catch (e) {
                            debugPrint('Error parsing amount: $e');
                            finalAmount = 750; // Fallback
                          }

                          HireMusicianDialog.show(
                            context,
                            name: applicant.name,
                            imagePath: applicant.imagePath,
                            rating: applicant.rating,
                            reviewCount: applicant.reviewCount,
                            location: applicant.location,
                            rate: applicant.proposedRate,                            onConfirm: () => Navigator.of(context).push(                              MaterialPageRoute(
                                builder: (_) => PaymentScreen(
                                  musicianId: applicant.musicianId,
                                  musicianName: applicant.name,
                                  musicianImage: applicant.imagePath,
                                  gigId: gigId,
                                  gigTitle: gigTitle,
                                  gigDate: gigDate,
                                  gigTime: gigTime,
                                  gigDuration: gigDuration,
                                  amount: finalAmount,
                                  walletBalance: 0,
                                  location: location,
                                  organizerName: organizerName,
                                ),
                              ),
                            ),
                          );
                        },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: applicant.status == 'hired'
                            ? const Color(0xFF2A2A2F)
                            : const Color(0xFFA2F301),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          applicant.status == 'hired' ? 'Hired' : 'Hire',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: applicant.status == 'hired'
                                  ? Colors.white54
                                  : Colors.black,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
