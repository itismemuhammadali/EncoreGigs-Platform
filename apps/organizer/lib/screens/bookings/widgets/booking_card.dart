import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../profile/booking_details_screen.dart';

class BookingModel {
  final String id;
  final String title;
  final String musician;
  final String dateTime;
  final String location;
  final String imagePath;
  final String status;
  final String? paymentStatus;
  final bool isPaymentPending;
  final String musicianId;

  const BookingModel({
    required this.id,
    required this.title,
    required this.musician,
    required this.dateTime,
    required this.location,
    required this.imagePath,
    required this.status,
    required this.musicianId,
    this.paymentStatus,
    this.isPaymentPending = false,
  });
}

class BookingCard extends StatelessWidget {
  final BookingModel booking;

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BookingDetailsScreen(
          bookingId: booking.id,
          title: booking.title,
          musician: booking.musician,
          imagePath: booking.imagePath,
          status: booking.status,
          date: booking.dateTime.split(' • ').first,
          time: booking.dateTime.contains('•') ? booking.dateTime.split('• ').last : '8:00 PM - 11:00 PM',
          location: booking.location,
          amount: '\$750',
          paymentStatus: booking.paymentStatus ?? 'Held in escrow',
          musicianId: booking.musicianId,
        ),
      )),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: circular image + title/musician + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: booking.imagePath.startsWith('http')
                    ? Image.network(
                        booking.imagePath,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2A2A2F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              color: Color(0xFF666666), size: 28),
                        ),
                      )
                    : Image.asset(
                        booking.imagePath,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2A2A2F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person,
                              color: Color(0xFF666666), size: 28),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            color: Color(0xFF888888), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          booking.musician,
                          style: const TextStyle(
                              color: Color(0xFF888888), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(booking.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _statusColor(booking.status), width: 1),
                ),
                child: Text(
                  booking.status == 'Waiting for musician signature' ? 'Pending Review' : booking.status,
                  style: TextStyle(
                    color: _statusColor(booking.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Date row
          Row(
            children: [
              SvgPicture.asset('assets/bookings_icon.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                      Color(0xFF888888), BlendMode.srcIn)),
              const SizedBox(width: 8),
              Text(booking.dateTime,
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          // Location row
          Row(
            children: [
              SvgPicture.asset('assets/location_pointer.svg',
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                      Color(0xFF888888), BlendMode.srcIn)),
              const SizedBox(width: 8),
              Text(booking.location,
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 14)),
            ],
          ),
          if (booking.paymentStatus != null) ...[
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF2A2A2F), height: 1),
            const SizedBox(height: 12),
            Text(
              (booking.status == 'Waiting for musician signature' || booking.status == 'Pending Review')
                  ? 'Waiting for musician signature'
                  : booking.paymentStatus!,
              style: TextStyle(
                color: (booking.status == 'Waiting for musician signature' || booking.status == 'Pending Review')
                    ? const Color(0xFFFFB347)
                    : (booking.isPaymentPending
                        ? const Color(0xFFFF8C00)
                        : const Color(0xFFA2F301)),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status == 'Waiting for musician signature' || status == 'Pending Review') {
      return const Color(0xFFFFB347);
    }
    if (status == 'Payment in escrow' || status == 'Held in escrow') {
      return const Color(0xFF00BCD4);
    }
    if (status == 'payment released' || status == 'Payment Released') {
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
