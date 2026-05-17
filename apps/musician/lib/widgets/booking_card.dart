import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback? onReviewContract;

  const BookingCard({super.key, required this.booking, required this.onTap, this.onReviewContract});

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeRange(DateTime startTime, DateTime? endTime) {
    if (endTime == null) {
      return _formatTime(startTime);
    }
    return '${_formatTime(startTime)} - ${_formatTime(endTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    booking.gigTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(booking.status),
                    border: Border.all(
                      color: _getStatusColor(booking.status),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(booking.status),
                    style: TextStyle(
                      color: _getStatusColor(booking.status),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Organizer Name
            Text(
              booking.organizerName,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),

            // Date/Time and Pay Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/bookings_icon.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFA1F301),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.gigDateText ?? _formatDate(booking.date),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.gigTimeText ?? _formatTimeRange(booking.date, booking.endTime),
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: Color(0xFF00BCD4), size: 20),
                    Text(
                      booking.pay.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location
            Row(
              children: [
                SvgPicture.asset(
                  'assets/location_pointer.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFF1493),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  booking.location,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),

            // Contract Status or Rating
            (booking.status == BookingStatus.completed || booking.status == BookingStatus.paymentReleased)
                ? _buildCompletedStatus()
                : _buildContractStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildContractStatus() {
    // If organizer signed but musician hasn't, show "Contract Pending"
    if (booking.organizerSigned && !booking.musicianSigned) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/application_icon.svg',
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFB8860B),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Contract Pending',
                    style: TextStyle(
                      color: Color(0xFFB8860B),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReviewContract,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Review Contract',
                style: TextStyle(
                  color: Color(0xFFA1F301),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    switch (booking.contractStatus) {
      case ContractStatus.signed:
        return Row(
          children: [
            SvgPicture.asset(
              'assets/tick_icon.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFFA1F301),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Contract Signed',
              style: TextStyle(
                color: Color(0xFFA1F301),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case ContractStatus.pending:
        return Row(
          children: [
            SvgPicture.asset(
              'assets/application_icon.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFFB8860B),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Contract Pending',
              style: TextStyle(
                color: Color(0xFFB8860B),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case ContractStatus.review:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/application_icon.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFB8860B),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Contract Pending Review',
                  style: TextStyle(
                    color: Color(0xFFB8860B),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: onReviewContract,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Review Contract',
                  style: TextStyle(
                    color: Color(0xFFA1F301),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildCompletedStatus() {
    final double rating = booking.rating ?? 0.0;
    return Row(
      children: [
        const Icon(
          Icons.star,
          color: Color(0xFFFFC107),
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Color(0xFFFFC107),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor() ? Icons.star : Icons.star_border,
              color: const Color(0xFFFFC107),
              size: 14,
            );
          }),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return const Color(0xFFA1F301);
      case BookingStatus.waitingSignature:
        return const Color(0xFFFFB347);
      case BookingStatus.paymentInEscrow:
        return const Color(0xFF00BCD4);
      case BookingStatus.paymentReleased:
        return const Color(0xFFA1F301);
      case BookingStatus.completed:
        return const Color(0xFF999999);
      case BookingStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getStatusBackgroundColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return const Color(0xFFA1F301).withValues(alpha: 0.15);
      case BookingStatus.waitingSignature:
        return const Color(0xFFFFB347).withValues(alpha: 0.15);
      case BookingStatus.paymentInEscrow:
        return const Color(0xFF00BCD4).withValues(alpha: 0.15);
      case BookingStatus.paymentReleased:
        return const Color(0xFFA1F301).withValues(alpha: 0.15);
      case BookingStatus.completed:
        return const Color(0xFF999999).withValues(alpha: 0.15);
      case BookingStatus.cancelled:
        return Colors.red.withValues(alpha: 0.15);
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming:
        return 'upcoming';
      case BookingStatus.waitingSignature:
        return 'waiting signature';
      case BookingStatus.paymentInEscrow:
        return 'payment in escrow';
      case BookingStatus.paymentReleased:
        return 'payment released';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }
}
