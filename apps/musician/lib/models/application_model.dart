import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

enum ApplicationStatus { pending, shortlisted, hired, rejected }

class Application {
  final String id;
  final String gigId;
  final String gigTitle;
  final String artistName;
  final String organizerId;
  final String? organizerImageUrl;
  final ApplicationStatus status;
  final DateTime appliedDate;
  final DateTime gigDate;
  final String pay;
  final String message;
  final String location;
  final String coverLetter;
  final String proposedRate;
  final List<String> attachments;

  Application({
    required this.id,
    required this.gigId,
    required this.gigTitle,
    required this.artistName,
    required this.organizerId,
    this.organizerImageUrl,
    required this.status,
    required this.appliedDate,
    required this.gigDate,
    required this.pay,
    required this.message,
    this.location = 'New York, NY',
    this.coverLetter = '',
    this.proposedRate = '\$1,000',
    this.attachments = const [],
  });

  factory Application.fromFirestore(DocumentSnapshot doc) {
    return Application.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  factory Application.fromMap(Map<String, dynamic> data, String id) {
    ApplicationStatus status = ApplicationStatus.pending;
    switch (data['status']) {
      case 'shortlisted':
        status = ApplicationStatus.shortlisted;
        break;
      case 'hired':
        status = ApplicationStatus.hired;
        break;
      case 'rejected':
        status = ApplicationStatus.rejected;
        break;
      default:
        status = ApplicationStatus.pending;
    }

    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return Application(
      id: id,
      gigId: data['gigId'] ?? '',
      gigTitle: data['gigTitle'] ?? 'Unknown Gig',
      artistName: data['organizerName'] ?? 'Event Organizer',
      organizerId: data['organizerId'] ?? '',
      organizerImageUrl: fixEmulatorUrl(data['organizerImageUrl']),
      status: status,
      appliedDate: parseDateTime(data['appliedAt']),
      gigDate: (data['gigDate'] != null)
          ? DateTime.tryParse(data['gigDate']) ??
              DateTime.now().add(const Duration(days: 7))
          : DateTime.now().add(const Duration(days: 7)),
      pay: data['budget'] ?? 'TBD',
      message: data['coverMessage'] ?? '',
      location: data['location'] ?? 'Not specified',
      coverLetter: data['coverMessage'] ?? '',
      proposedRate: data['proposedRate'] ?? 'TBD',
      attachments: List<String>.from(data['attachments'] ?? []),
    );
  }
}
