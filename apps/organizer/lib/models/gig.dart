
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';

class GigModel {
  final String gigId;
  final String title;
  final String description;
  final List<String> requirements;
  final List<String> genres;
  final String date;
  final String time;
  final String? duration;
  final String budget;
  final String location;
  final String organizerId;
  final String? status;
  final DateTime? createdAt;
  final String? imageUrl;
  final String? applicationsText;
  final int applicationsCount;

  GigModel({
    required this.gigId,
    required this.title,
    required this.description,
    required this.requirements,
    required this.genres,
    required this.date,
    required this.time,
    this.duration,
    required this.budget,
    required this.location,
    required this.organizerId,
    this.status,
    this.createdAt,
    this.imageUrl,
    this.applicationsText,
    this.applicationsCount = 0,
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
      title: snapshot['title'] ?? '',
      description: snapshot['description'] ?? '',
      requirements: List<String>.from(snapshot['requirements'] ?? []),
      genres: List<String>.from(snapshot['genres'] ?? []),
      date: snapshot['date'] ?? '',
      time: snapshot['time'] ?? '',
      duration: snapshot['duration'],
      budget: snapshot['budget'] ?? '',
      location: snapshot['location'] ?? '',
      organizerId: snapshot['organizerId'] ?? '',
      status: snapshot['status'] ?? 'open',
      createdAt: parseDateTime(snapshot['createdAt']),
      imageUrl: fixEmulatorUrl(snapshot['imageUrl']),
      applicationsText: snapshot['applicationsText'],
      applicationsCount: snapshot['applicationsCount'] ?? 0,
    );
  }
}
