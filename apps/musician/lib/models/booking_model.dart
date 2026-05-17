import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

enum BookingStatus { upcoming, completed, cancelled, waitingSignature, paymentInEscrow, paymentReleased }
enum ContractStatus { signed, pending, review }

class Booking {
  final String id;
  final String gigTitle;
  final String organizerName;
  final String location;
  final String? fullAddress;
  final DateTime date;
  final DateTime? endTime;
  final BookingStatus status;
  final double pay;
  final double? depositPaid;
  final String? paymentDate;
  final ContractStatus contractStatus;
  final double? rating;
  final String? imageUrl;
  final String? description;
  final List<String> requirements;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? gigId;
  final String? organizerId;
  final String? musicianId;
  final String? signatureUrl;
  final String? duration;
  final String? gigTime;
  final String? gigDateText;
  final String? gigTimeText;
  final bool organizerSigned;
  final bool musicianSigned;

  Booking({
    required this.id,
    required this.gigTitle,
    required this.organizerName,
    required this.location,
    this.fullAddress,
    required this.date,
    this.endTime,
    required this.status,
    required this.pay,
    this.depositPaid,
    this.paymentDate,
    required this.contractStatus,
    this.rating,
    this.imageUrl,
    this.description,
    this.requirements = const [],
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.gigId,
    this.organizerId,
    this.musicianId,
    this.signatureUrl,
    this.duration,
    this.gigTime,
    this.gigDateText,
    this.gigTimeText,
    this.organizerSigned = false,
    this.musicianSigned = false,
  });

  factory Booking.fromFirestore(Map<String, dynamic> data, String id) {
    String statusStr = data['status'] ?? 'pending';
    BookingStatus bStatus = BookingStatus.upcoming;
    ContractStatus cStatus = ContractStatus.pending;

    // Check if organizer and musician have signed
    bool organizerSigned = data['organizerSignedAt'] != null;
    bool musicianSigned = data['musicianSignedAt'] != null;

    if (statusStr == 'Waiting for musician signature') {
      bStatus = BookingStatus.waitingSignature;
      cStatus = ContractStatus.review;
    } else if (musicianSigned) {
      // If musician has signed, it's definitely signed from their perspective
      cStatus = ContractStatus.signed;
      if (statusStr == 'completed') {
        bStatus = BookingStatus.completed;
      } else if (statusStr == 'payment released') {
        bStatus = BookingStatus.paymentReleased;
      } else {
        // Any other status before completion (including 'Payment in escrow') is shown as 'upcoming'
        bStatus = BookingStatus.upcoming;
      }
    } else {
      // Not signed by musician yet
      cStatus = ContractStatus.review;
      bStatus = BookingStatus.waitingSignature;
    }

    if (statusStr == 'cancelled') {
      bStatus = BookingStatus.cancelled;
      cStatus = ContractStatus.pending;
    }

    return Booking(
      id: id,
      gigId: data['gigId'],
      organizerId: data['organizerId'],
      musicianId: data['musicianId'],
      gigTitle: data['gigTitle'] ?? 'Unnamed Gig',
      organizerName: data['organizerName'] ?? 'Unknown Organizer',
      location: data['location'] ?? 'Venue Location',
      description: data['description'],
      requirements: List<String>.from(data['requirements'] ?? []),
      date: (data['gigDate'] != null || data['gigdate'] != null || data['date'] != null)
          ? _parseDateTime(data['gigDate'] ?? data['gigdate'] ?? data['date'])
          : (data['createdAt'] != null
              ? (data['createdAt'] is Timestamp
                  ? (data['createdAt'] as Timestamp).toDate()
                  : (data['createdAt'] is String
                      ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
                      : DateTime.now()))
              : DateTime.now()),
      status: bStatus,
      pay: (data['amount'] ?? 0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      contractStatus: cStatus,
      signatureUrl: fixEmulatorUrl(data['musicianSignatureUrl'] ?? data['signatureUrl']),
      imageUrl: fixEmulatorUrl(data['musicianImage']),
      duration: data['duration'],
      gigTime: data['gigTime'],
      gigDateText: data['gigDate'] ?? data['gigdate'],
      gigTimeText: data['gigTime'],
      organizerSigned: organizerSigned,
      musicianSigned: musicianSigned,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
