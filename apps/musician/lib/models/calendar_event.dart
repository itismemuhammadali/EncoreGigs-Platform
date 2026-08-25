import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEventModel {
  final String id;
  final String userId;
  final String userType; // 'musician' | 'organizer'
  final String source; // 'onlygigz_booking' | 'outside_gig' | 'availability_block' | 'unavailable_block' | 'hold'
  final String? gigId;
  final String? bookingId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String status; // 'AVAILABLE' | 'UNAVAILABLE' | 'HOLD' | 'PENDING' | 'CONFIRMED' | 'COMPLETED' | 'OUTSIDE_GIG'
  final String privacyLevel; // 'private' | 'public_availability'
  final String? location;
  final String? rate;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CalendarEventModel({
    required this.id,
    required this.userId,
    required this.userType,
    required this.source,
    this.gigId,
    this.bookingId,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.isAllDay = false,
    required this.status,
    this.privacyLevel = 'private',
    this.location,
    this.rate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CalendarEventModel.fromFirestore(Map<String, dynamic> snapshot, String docId) {
    DateTime parseDateTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CalendarEventModel(
      id: docId,
      userId: snapshot['userId'] ?? '',
      userType: snapshot['userType'] ?? 'musician',
      source: snapshot['source'] ?? 'onlygigz_booking',
      gigId: snapshot['gigId'],
      bookingId: snapshot['bookingId'],
      title: snapshot['title'] ?? 'Event',
      startTime: parseDateTime(snapshot['startTime']),
      endTime: parseDateTime(snapshot['endTime']),
      isAllDay: snapshot['isAllDay'] ?? false,
      status: snapshot['status'] ?? 'AVAILABLE',
      privacyLevel: snapshot['privacyLevel'] ?? 'private',
      location: snapshot['location'],
      rate: snapshot['rate'],
      notes: snapshot['notes'],
      createdAt: snapshot['createdAt'] != null ? parseDateTime(snapshot['createdAt']) : null,
      updatedAt: snapshot['updatedAt'] != null ? parseDateTime(snapshot['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userType': userType,
      'source': source,
      if (gigId != null) 'gigId': gigId,
      if (bookingId != null) 'bookingId': bookingId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isAllDay': isAllDay,
      'status': status,
      'privacyLevel': privacyLevel,
      if (location != null) 'location': location,
      if (rate != null) 'rate': rate,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
