import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/application_model.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';
import 'booking_detail_screen.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final Application application;

  const ApplicationDetailScreen({super.key, required this.application});

  @override
  State<ApplicationDetailScreen> createState() => _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _loadingBooking = false;

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getStatusColor() {
    switch (widget.application.status) {
      case ApplicationStatus.pending:    return const Color(0xFFB8860B);
      case ApplicationStatus.shortlisted: return const Color(0xFF00BCD4);
      case ApplicationStatus.hired:      return const Color(0xFFA1F301);
      case ApplicationStatus.rejected:   return Colors.red;
    }
  }

  String _getStatusLabel() {
    switch (widget.application.status) {
      case ApplicationStatus.pending:    return 'Pending';
      case ApplicationStatus.shortlisted: return 'Shortlisted';
      case ApplicationStatus.hired:      return 'Hired';
      case ApplicationStatus.rejected:   return 'Rejected';
    }
  }

  Future<void> _openBookingDetails() async {
    if (_loadingBooking) return;
    setState(() => _loadingBooking = true);

    try {
      final uid = Provider.of<AuthService>(context, listen: false).user?.uid;

      // Query the booking that matches this gig + this musician
      final query = await FirebaseFirestore.instance
          .collection('bookings')
          .where('gigId', isEqualTo: widget.application.gigId)
          .where('musicianId', isEqualTo: uid)
          .limit(1)
          .get();

      if (!mounted) return;

      if (query.docs.isNotEmpty) {
        final booking = Booking.fromFirestore(
          query.docs.first.data(),
          query.docs.first.id,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking not found. It may still be processing.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final application = widget.application;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & organizer
                    Text(
                      application.gigTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      application.artistName,
                      style: const TextStyle(color: Color(0xFF999999), fontSize: 15),
                    ),
                    const SizedBox(height: 20),

                    // Application Status card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Application Status',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.15),
                              border: Border.all(color: _getStatusColor(), width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusLabel(),
                              style: TextStyle(color: _getStatusColor(), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gig Details card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gig Details',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            icon: Icons.attach_money,
                            iconColor: const Color(0xFFA1F301),
                            label: application.status == ApplicationStatus.hired
                                ? 'Agreed Rate'
                                : 'Budget',
                            value: application.status == ApplicationStatus.hired &&
                                    application.proposedRate.isNotEmpty &&
                                    application.proposedRate != 'TBD'
                                ? application.proposedRate
                                : application.pay,
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRowSvg(
                            iconPath: 'assets/bookings_icon.svg',
                            iconColor: const Color(0xFF00BCD4),
                            label: 'Event Date',
                            value: _formatDate(application.gigDate),
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRowSvg(
                            iconPath: 'assets/location_pointer.svg',
                            iconColor: const Color(0xFFFF6B9D),
                            label: 'Location',
                            value: application.location,
                          ),
                          const SizedBox(height: 14),
                          _buildDetailRowSvg(
                            iconPath: 'assets/profile_icon.svg',
                            iconColor: const Color(0xFFA1F301),
                            label: 'Organizer',
                            value: application.artistName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Your Application card
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Application',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text('Applied on', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_formatDate(application.appliedDate),
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          const Text('Cover Letter', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            application.coverLetter,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                          ),
                          const SizedBox(height: 16),
                          const Text('Proposed Rate', style: TextStyle(color: Color(0xFF999999), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(application.proposedRate,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    // Status-specific bottom card
                    if (application.status == ApplicationStatus.shortlisted) ...[
                      const SizedBox(height: 16),
                      _buildStatusActionCard(
                        icon: Icons.access_time,
                        iconColor: const Color(0xFF00BCD4),
                        title: 'You\'re Shortlisted!',
                        subtitle: 'The organizer is reviewing final candidates. You should hear back soon!',
                        buttonLabel: 'Send Follow-up Message',
                        onTap: () async {
                          final chatService = Provider.of<ChatService>(context, listen: false);
                          try {
                            final chatId = await chatService.getOrCreateChat(
                              application.organizerId,
                              application.artistName,
                              application.organizerImageUrl ?? '',
                            );
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    chatId: chatId,
                                    otherUserId: application.organizerId,
                                    otherUserName: application.artistName,
                                    otherUserImage: application.organizerImageUrl,
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error starting chat: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ] else if (application.status == ApplicationStatus.hired) ...[
                      const SizedBox(height: 16),
                      _buildStatusActionCard(
                        iconSvg: 'assets/tick_icon.svg',
                        iconColor: const Color(0xFFA1F301),
                        title: 'Congratulations!',
                        subtitle: 'You\'ve been hired for this gig. View your booking details and contract.',
                        buttonLabel: 'View Booking Details',
                        isLoading: _loadingBooking,
                        onTap: _openBookingDetails,
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFA1F301).withValues(alpha: 0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildDetailRow({required IconData icon, required Color iconColor, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRowSvg({required String iconPath, required Color iconColor, required String label, required String value}) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: SvgPicture.asset(iconPath, fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 12)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusActionCard({
    IconData? icon,
    String? iconSvg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFA1F301).withValues(alpha: 0.1),
            Colors.black,
          ],
        ),
        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconSvg != null
                  ? SizedBox(
                      width: 20, height: 20,
                      child: SvgPicture.asset(iconSvg, fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
                    )
                  : Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Color(0xFF999999), fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFA1F301),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2.5),
                      )
                    : Text(buttonLabel,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
