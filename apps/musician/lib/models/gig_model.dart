import '../constants.dart';

class Gig {
  final String id;
  final String title;
  final String genre; // For simplicity in musician app, we take the first genre if multiple
  final List<String> genres;
  final String location;
  final double distance;
  final double rating;
  final String description;
  final List<String> requirements;
  final DateTime date;
  final String dateString;
  final String time;
  final String pay;
  final String budget;
  final String? imageUrl;
  final String? organizer;
  final String? organizerId;
  final String? organizerImage;
  final int? organizerGigsPosted;
  final String? duration;
  final String? status;
  final bool isUrgent;

  Gig({
    required this.id,
    required this.title,
    required this.genre,
    required this.genres,
    required this.location,
    required this.distance,
    required this.rating,
    required this.description,
    required this.requirements,
    required this.date,
    required this.dateString,
    required this.time,
    required this.pay,
    required this.budget,
    this.imageUrl,
    this.organizer,
    this.organizerId,
    this.organizerImage,
    this.organizerGigsPosted,
    this.duration,
    this.status,
    this.isUrgent = false,
  });

  factory Gig.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> genres = List<String>.from(data['genres'] ?? []);
    String primaryGenre = genres.isNotEmpty ? genres.first : 'Various';
    List<String> requirements = List<String>.from(data['requirements'] ?? []);
    
    // Parse date string to DateTime if possible
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(data['date'] ?? DateTime.now().toString());
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return Gig(
      id: id,
      title: data['title'] ?? '',
      genre: primaryGenre,
      genres: genres,
      location: data['location'] ?? '',
      distance: 0.0, // This would normally be calculated based on user location
      rating: 4.5,   // Placeholder rating
      description: data['description'] ?? '',
      requirements: requirements,
      date: parsedDate,
      dateString: data['date'] ?? '',
      time: data['time'] ?? '',
      pay: data['budget'] ?? '',
      budget: data['budget'] ?? '',
      imageUrl: fixEmulatorUrl(data['imageUrl']),
      organizer: data['organizerName'] ?? 'Event Organizer',
      organizerId: data['organizerId'] ?? data['organizer_id'],
      organizerImage: fixEmulatorUrl(data['organizerImage']),
      organizerGigsPosted: data['organizerGigsPosted'] ?? 0,
      duration: data['duration'] ?? 'Not specified',
      status: data['status'] ?? 'open',
      isUrgent: data['isUrgent'] ?? false,
    );
  }
}
