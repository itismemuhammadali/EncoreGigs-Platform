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
  final String? expiryDate;
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
  final bool isScraped;

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
    this.expiryDate,
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
    this.isScraped = false,
  });

  factory Gig.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> rawGenres = List<String>.from(data['genres'] ?? []);
    List<String> genres = rawGenres.map(capitalizeWords).toList();
    String primaryGenre = genres.isNotEmpty ? genres.first : 'Various';
    List<String> requirements = List<String>.from(data['requirements'] ?? []);
    
    // Parse date string to DateTime if possible
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(data['date'] ?? DateTime.now().toString());
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final bool isScraped = data['isScraped'] == true ||
        data['isExternal'] == true ||
        data['organizerId'] == 'scraped' ||
        data['organizer_id'] == 'scraped';

    final String rawOrg = (data['organizerName'] ?? data['sourceType'] ?? 'Event Organizer').toString();
    final String orgLower = rawOrg.toLowerCase();

    final String organizerName;
    if (isScraped ||
        orgLower.contains('facebook') ||
        orgLower.contains('craigslist') ||
        orgLower.contains('scraped') ||
        orgLower.contains('reddit') ||
        orgLower.contains('eventbrite')) {
      organizerName = 'Gig Lead';
    } else {
      organizerName = capitalizeWords(rawOrg);
    }

    return Gig(
      id: id,
      title: capitalizeWords(data['title'] ?? ''),
      genre: primaryGenre,
      genres: genres,
      location: capitalizeWords(data['location'] ?? ''),
      distance: 0.0, // This would normally be calculated based on user location
      rating: 4.5,   // Placeholder rating
      description: data['description'] ?? '',
      requirements: requirements,
      date: parsedDate,
      dateString: data['date'] ?? '',
      time: data['time'] ?? '',
      expiryDate: data['expiryDate'],
      pay: data['budget'] ?? '',
      budget: data['budget'] ?? '',
      imageUrl: fixEmulatorUrl(data['imageUrl']),
      organizer: organizerName,
      organizerId: data['organizerId'] ?? data['organizer_id'],
      organizerImage: fixEmulatorUrl(data['organizerImage']),
      organizerGigsPosted: data['organizerGigsPosted'] ?? 0,
      duration: data['duration'] ?? 'Not specified',
      status: data['status'] ?? 'open',
      isUrgent: data['isUrgent'] ?? false,
      isScraped: isScraped,
    );
  }
}
