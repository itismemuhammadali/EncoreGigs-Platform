import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'contract_view_screen.dart';
import 'widgets/release_payment_dialog.dart';
import 'widgets/success_toast.dart';
import 'write_review_screen.dart';
import '../messages/chat/chat_screen.dart';
import '../../services/chat_service.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  final String title;
  final String musician;
  final String imagePath;
  final String status;
  final String date;
  final String time;
  final String location;
  final String amount;
  final String paymentStatus;
  final String musicianId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
    required this.title,
    required this.musician,
    required this.imagePath,
    required this.status,
    required this.date,
    required this.time,
    required this.location,
    required this.amount,
    required this.paymentStatus,
    required this.musicianId,
  });

  bool _isNetworkImage(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

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
        title: const Text(
          'Booking Details',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: _isNetworkImage(imagePath)
                        ? Image.network(
                            imagePath,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
                          )
                        : Image.asset(
                            imagePath,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _placeholderAvatar(),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(musician,
                            style: const TextStyle(
                                color: Color(0xFF888888), fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _statusColor(status)),
                    ),
                    child: Text(
                      status == 'Waiting for musician signature' ? 'Pending Review' : status,
                      style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Date & Time
              _infoCard(
                icon: SvgPicture.asset('assets/bookings_icon.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFFA2F301), BlendMode.srcIn)),
                title: 'Date & Time',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date,
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(time,
                        style: const TextStyle(
                            color: Color(0xFF888888), fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Location
              _infoCard(
                icon: SvgPicture.asset('assets/location_pointer.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFFA2F301), BlendMode.srcIn)),
                title: 'Location',
                content: Text(location,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 14)),
              ),
              const SizedBox(height: 12),
              // Payment
              _infoCard(
                icon: const Icon(Icons.attach_money,
                    color: Color(0xFFA2F301), size: 20),
                title: 'Payment',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(amount,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFA2F301),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(paymentStatus,
                            style: const TextStyle(
                                color: Color(0xFFA2F301),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('Payment will be released after gig completion',
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Contract
              _infoCard(
                icon: SvgPicture.asset('assets/application_icon.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFFA2F301), BlendMode.srcIn)),
                title: 'Contract',
                trailing: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ContractViewScreen(
                        bookingId: bookingId,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFA2F301)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('View',
                        style: TextStyle(
                            color: Color(0xFFA2F301),
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                content: const Text('Signed',
                    style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
              ),
              const SizedBox(height: 12),
              // Message button
              GestureDetector(
                onTap: () async {
                  final chatService = Provider.of<ChatService>(context, listen: false);
                  try {
                    final chatId = await chatService.getOrCreateChat(
                      musicianId,
                      musician,
                      imagePath,
                    );
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chatId,
                            otherUserId: musicianId,
                            name: musician,
                            imagePath: imagePath,
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Message',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Release payment after confirming gig completion',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 12),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        child: GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => ReleasePaymentDialog(
              amount: amount,
              musicianName: musician,
              bookingId: bookingId,
              onConfirm: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(bookingId)
                      .update({'status': 'payment released'});
                  
                  if (context.mounted) {
                    SuccessToast.show(
                      context,
                      'Payment Released Successfully!',
                      onComplete: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WriteReviewScreen(
                              bookingId: bookingId,
                              musicianId: musicianId,
                              musicianName: musician,
                              gigTitle: title,
                              imagePath: imagePath,
                            ),
                          ),
                        );
                      },
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error releasing payment: $e')),
                    );
                  }
                }
              },
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFA2F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Release Payment',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2F),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Color(0xFF666666), size: 28),
    );
  }

  Widget _infoCard({
    required Widget icon,
    required String title,
    required Widget content,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'Waiting for musician signature') {
      return const Color(0xFFFFB347);
    }
    if (status == 'Payment in escrow') {
      return const Color(0xFF00BCD4);
    }
    if (status.toLowerCase() == 'payment released') {
      return const Color(0xFFA2F301);
    }
    switch (status.toLowerCase()) {
      case 'upcoming':
        return const Color(0xFFA2F301);
      case 'completed':
        return const Color(0xFF4A9EFF);
      case 'cancelled':
        return const Color(0xFFFF4444);
      default:
        return const Color(0xFF888888);
    }
  }
}
