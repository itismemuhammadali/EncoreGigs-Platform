
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

String capitalizeWords(String text) {
  if (text.isEmpty) return text;
  const abbrevs = {'tx', 'la', 'ny', 'ca', 'fl', 'ga', 'nc', 'sc', 'va', 'dc', 'usa', 'uk'};
  return text.splitMapJoin(
    RegExp(r'\b[a-zA-Z]+\b'),
    onMatch: (m) {
      final w = m.group(0)!;
      if (abbrevs.contains(w.toLowerCase())) {
        return w.toUpperCase();
      }
      return w[0].toUpperCase() + w.substring(1);
    },
    onNonMatch: (n) => n,
  );
}

class GigModel {
  final String gigId;
  final String title;
  final String description;
  final List<String> requirements;
  final List<String> genres;
  final String date;
  final String time;
  final String? expiryDate;
  final String? duration;
  final String budget;
  final String location;
  final String organizerId;
  final String? status;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? applicationsText;
  final int applicationsCount;
  final bool isUrgent;

  GigModel({
    required this.gigId,
    required this.title,
    required this.description,
    required this.requirements,
    required this.genres,
    required this.date,
    required this.time,
    this.expiryDate,
    this.duration,
    required this.budget,
    required this.location,
    required this.organizerId,
    this.status,
    this.createdAt,
    this.imageUrl,
    this.applicationsText,
    this.applicationsCount = 0,
    this.isUrgent = false,
  });

  factory GigModel.fromFirestore(Map<String, dynamic> snapshot, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return GigModel(
      gigId: id,
      title: capitalizeWords(snapshot['title'] ?? ''),
      description: snapshot['description'] ?? '',
      requirements: List<String>.from(snapshot['requirements'] ?? []),
      genres: List<String>.from(snapshot['genres'] ?? []).map(capitalizeWords).toList(),
      date: snapshot['date'] ?? '',
      time: snapshot['time'] ?? '',
      expiryDate: snapshot['expiryDate'],
      duration: snapshot['duration'],
      budget: snapshot['budget'] ?? '',
      location: capitalizeWords(snapshot['location'] ?? ''),
      organizerId: snapshot['organizerId'] ?? '',
      status: snapshot['status'] ?? 'open',
      createdAt: parseDateTime(snapshot['createdAt']),
      imageUrl: fixEmulatorUrl(snapshot['imageUrl']),
      applicationsText: snapshot['applicationsText'],
      applicationsCount: snapshot['applicationsCount'] ?? 0,
      isUrgent: snapshot['isUrgent'] ?? false,
    );
  }
}
