import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';
import 'contract_review_screen.dart';
import 'contract_success_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Booking booking;
  const BookingDetailScreen({super.key, required this.booking});
  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  // Cache the future so it isn't recreated on every rebuild
  late Future<List<Map<String, dynamic>?>> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = Future.wait([
      widget.booking.gigId != null
          ? Provider.of<AuthService>(context, listen: false)
              .getGig(widget.booking.gigId!)
          : Future.value(null),
      widget.booking.organizerId != null
          ? Provider.of<AuthService>(context, listen: false)
              .getProfile(widget.booking.organizerId!)
          : Future.value(null),
    ]);
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
    final min = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSigned = widget.booking.contractStatus == ContractStatus.signed;
    final bool isWaitingSignature = widget.booking.status == BookingStatus.waitingSignature;
    final bool isPaymentReleased = widget.booking.status == BookingStatus.paymentReleased;

    Color statusColor = const Color(0xFFA1F301);
    String statusText = widget.booking.status.name.toLowerCase();
    
    if (isWaitingSignature) {
      statusColor = const Color(0xFFF0B100);
      statusText = 'Waiting Signature';
    } else if (isPaymentReleased) {
      statusColor = const Color(0xFFA1F301);
      statusText = 'Payment Released';
    } else if (widget.booking.status == BookingStatus.upcoming) {
      statusText = 'Upcoming';
    } else if (widget.booking.status == BookingStatus.completed) {
      statusText = 'Completed';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>?>>(
          future: _detailFuture,
          builder: (context, snapshot) {
            final gigData = snapshot.data?[0];
            final orgProfile = snapshot.data?[1];

            final description = gigData?['description'] ?? widget.booking.description;
            final requirements = gigData?['requirements'] != null 
                ? List<String>.from(gigData!['requirements']) 
                : widget.booking.requirements;
            
            final orgName = orgProfile?['name'] ?? widget.booking.organizerName;
            final orgDisplayName = orgProfile?['orgName'] ?? '';
            final orgEmail = orgProfile?['businessEmail'] ?? orgProfile?['email'] ?? 'No email';
            final orgPhone = orgProfile?['businessPhone'] ?? orgProfile?['contact'] ?? 'No phone';

            return Column(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title with status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.booking.gigTitle,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  orgName,
                                  style: const TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3), width: 1.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                statusText,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Contract status card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isPaymentReleased || isSigned) 
                                ? const Color(0xFFA1F301).withValues(alpha: 0.1) 
                                : const Color(0xFFF0B100).withValues(alpha: 0.1),
                            border: Border.all(
                              color: (isPaymentReleased || isSigned)
                                ? const Color(0xFFA1F301).withValues(alpha: 0.3)
                                : const Color(0xFFF0B100).withValues(alpha: 0.3),
                              width: 1.09,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 20, height: 20,
                                    child: SvgPicture.asset(
                                      (isSigned || isPaymentReleased) ? 'assets/tick_icon.svg' : 'assets/application_icon.svg',
                                      fit: BoxFit.contain,
                                      colorFilter: ColorFilter.mode(
                                        (isSigned || isPaymentReleased) ? const Color(0xFFA1F301) : const Color(0xFFF0B100),
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isPaymentReleased ? 'Payment Released' : (isSigned ? 'Contract Signed' : 'Contract Pending'),
                                    style: TextStyle(
                                      color: (isSigned || isPaymentReleased) ? const Color(0xFFA1F301) : const Color(0xFFF0B100),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isPaymentReleased
                                    ? 'Gig completed and payment has been released to your account.'
                                    : (isSigned
                                        ? 'Contract has been signed by all parties. Your gig is confirmed!'
                                        : 'Please review and sign the contract to confirm the booking.'),
                                style: const TextStyle(color: Color(0xFF999999), fontSize: 13, height: 1.5),
                              ),
                              if (!isSigned && !isPaymentReleased) ...[
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ContractReviewScreen(booking: widget.booking),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFA1F301),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Review & Sign Contract',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Date & Time card
                        _buildCard(
                          title: 'Date & Time',
                          child: Column(
                            children: [
                              _buildDetailRowSvg(
                                iconPath: 'assets/bookings_icon.svg',
                                iconColor: const Color(0xFF00BCD4),
                                label: 'Event Date',
                                value: widget.booking.gigDateText ?? _formatDate(widget.booking.date),
                              ),
                              const SizedBox(height: 14),
                              _buildDetailRow(
                                icon: Icons.access_time,
                                iconColor: const Color(0xFF9B59B6),
                                label: 'Performance Time',
                                value: widget.booking.gigTimeText ?? (widget.booking.endTime != null
                                    ? '${_formatTime(widget.booking.date)} - ${_formatTime(widget.booking.endTime!)}'
                                    : _formatTime(widget.booking.date)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Location card
                        _buildCard(
                          title: 'Location',
                          child: _buildDetailRowSvg(
                            iconPath: 'assets/location_pointer.svg',
                            iconColor: const Color(0xFFFF6B9D),
                            label: widget.booking.fullAddress ?? widget.booking.location,
                            value: '',
                            singleLine: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 4. Description card
                        if (description != null && description.isNotEmpty)
                          _buildCard(
                            title: 'Description',
                            child: Text(
                              description,
                              style: const TextStyle(color: Color(0xFF999999), fontSize: 14, height: 1.6),
                            ),
                          ),
                        if (description != null && description.isNotEmpty) const SizedBox(height: 16),

                        // 5. Requirements card
                        if (requirements.isNotEmpty)
                          _buildCard(
                            title: 'Requirements',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: requirements.map((req) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFA1F301),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(req, style: const TextStyle(color: Color(0xFF999999), fontSize: 15)),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                          ),
                        if (requirements.isNotEmpty) const SizedBox(height: 16),

                        // 6. Payment Details card
                        _buildCard(
                          title: 'Payment Details',
                          child: Column(
                            children: [
                              _buildPaymentRow('Total Amount', '\$${widget.booking.pay.toStringAsFixed(0)}', isGreen: true),
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 14),
                              _buildPaymentRow('Deposit Paid', '\$${(widget.booking.depositPaid ?? 0).toStringAsFixed(0)}', isGreen: true),
                              const SizedBox(height: 14),
                              _buildPaymentRow('Remaining Balance', '\$${(widget.booking.pay - (widget.booking.depositPaid ?? 0)).toStringAsFixed(0)}'),
                              const SizedBox(height: 14),
                              Container(
                                height: 1,
                                color: const Color(0xFFA1F301).withValues(alpha: 0.2),
                              ),
                              const SizedBox(height: 14),
                              _buildPaymentRow('Payment Date', widget.booking.paymentDate ?? 'TBD'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 7. Organizer Contact card
                        _buildCard(
                          title: 'Organizer Contact',
                          child: Column(
                            children: [
                              _buildContactRowSvg(
                                iconPath: 'assets/profile_icon.svg', 
                                iconColor: const Color(0xFFA1F301), 
                                value: orgName
                              ),
                              const SizedBox(height: 10),
                              _buildContactRow(
                                icon: Icons.phone_outlined, 
                                iconColor: const Color(0xFF00BCD4), 
                                value: orgPhone
                              ),
                              const SizedBox(height: 10),
                              _buildContactRow(
                                icon: Icons.email_outlined, 
                                iconColor: const Color(0xFFFF6B9D), 
                                value: orgEmail
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Container(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0F),
                    border: Border(
                      top: BorderSide(color: const Color(0xFFA1F301).withValues(alpha: 0.2), width: 1),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final chatService = Provider.of<ChatService>(context, listen: false);
                      final resolvedName = orgName;
                      final resolvedImage = orgProfile?['profileImageUrl'] ?? '';
                      try {
                        final chatId = await chatService.getOrCreateChat(
                          widget.booking.organizerId ?? '',
                          resolvedName,
                          resolvedImage,
                        );
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatId: chatId,
                                otherUserId: widget.booking.organizerId ?? '',
                                otherUserName: resolvedName,
                                otherUserImage: resolvedImage,
                                otherUserOrgName: orgDisplayName,
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
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.5), width: 1.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: SvgPicture.asset('assets/messages_icon.svg', fit: BoxFit.contain,
                                colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn)),
                          ),
                          const SizedBox(width: 8),
                          const Text('Message', style: TextStyle(color: Color(0xFFA1F301), fontSize: 15, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          child,
        ],
      ),
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
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRowSvg({required String iconPath, required Color iconColor, required String label, required String value, bool singleLine = false}) {
    return Row(
      children: [
        SizedBox(
          width: 20, height: 20,
          child: SvgPicture.asset(iconPath, fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
        ),
        const SizedBox(width: 12),
        singleLine
            ? Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 12)),
                ],
              ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF999999), fontSize: 15)),
        Text(value, style: TextStyle(
          color: isGreen ? const Color(0xFFA1F301) : Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        )),
      ],
    );
  }

  Widget _buildContactRow({required IconData icon, required Color iconColor, required String value}) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  Widget _buildContactRowSvg({required String iconPath, required Color iconColor, required String value}) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: SvgPicture.asset(iconPath, fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
        ),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}
