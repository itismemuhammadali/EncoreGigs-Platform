import '../constants.dart';

class PortfolioItem {
  final String image; // The URL or path
  final String type; // 'video', 'image', 'music'
  final String title;
  final String description;
  final String? externalUrl;

  PortfolioItem({
    required this.image,
    required this.type,
    this.title = '',
    this.description = '',
    this.externalUrl,
  });
}

class Profile {
  final String name;
  final String profession;
  final String bio;
  final String email;
  final String contact;
  final double avgRating;
  final int gigsCompleted;
  final double responseRate;
  final int reviewCount;
  final List<String> genres;
  final List<String> tags;
  final String location;
  final String primaryCity;
  final String primaryState;
  final String primaryZip;
  final String secondaryCity;
  final String secondaryState;
  final String secondaryZip;
  final int travelRadius;
  final String payRange;
  final String experience;
  final String ratingPercentage;
  final List<PortfolioItem> portfolioItems;
  final String? profileImage;
  final String? bannerImage;

  Profile({
    required this.name,
    required this.profession,
    required this.bio,
    required this.email,
    required this.contact,
    required this.avgRating,
    required this.gigsCompleted,
    required this.responseRate,
    required this.reviewCount,
    required this.genres,
    this.tags = const [],
    required this.location,
    this.primaryCity = '',
    this.primaryState = '',
    this.primaryZip = '',
    this.secondaryCity = '',
    this.secondaryState = '',
    this.secondaryZip = '',
    this.travelRadius = 50,
    required this.payRange,
    required this.experience,
    required this.ratingPercentage,
    required this.portfolioItems,
    this.profileImage,
    this.bannerImage,
  });

  factory Profile.fromFirestore(Map<String, dynamic> data) {
    // Process portfolio
    List<PortfolioItem> portfolioItems = [];
    if (data['portfolio'] != null) {
      final portfolio = data['portfolio'] as Map<String, dynamic>;
      
      void addItems(List<dynamic>? list, String type) {
        if (list == null) return;
        for (var rawItem in list) {
          if (rawItem is String) {
            portfolioItems.add(PortfolioItem(image: fixEmulatorUrl(rawItem), type: type));
          } else if (rawItem is Map<String, dynamic>) {
            portfolioItems.add(PortfolioItem(
              image: fixEmulatorUrl(rawItem['url'] ?? ''),
              type: type,
              title: rawItem['title'] ?? '',
              description: rawItem['description'] ?? '',
              externalUrl: rawItem['externalUrl'],
            ));
          }
        }
      }

      // Order: Video, then Image, then Music
      addItems(portfolio['videos'], 'video');
      addItems(portfolio['images'], 'image');
      addItems(portfolio['audioTracks'], 'music');
    }

    final genres = List<String>.from(data['genres'] ?? []);
    final tags = List<String>.from(data['tags'] ?? []);
    final instruments = List<String>.from(data['instruments'] ?? []);
    
    return Profile(
      name: data['fullName'] ?? 'Unknown',
      profession: instruments.isNotEmpty ? instruments.join(', ') : 'Musician',
      bio: data['bio'] ?? '',
      email: data['email'] ?? '',
      contact: data['contact'] ?? '',
      avgRating: (data['averageRating'] ?? 0.0).toDouble(),
      gigsCompleted: data['gigsCompleted'] ?? 0,
      responseRate: (data['responseRate'] ?? 100.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      genres: genres,
      tags: tags,
      location: data['location'] ?? 'Not specified',
      primaryCity: data['primaryCity'] ?? '',
      primaryState: data['primaryState'] ?? '',
      primaryZip: data['primaryZip'] ?? '',
      secondaryCity: data['secondaryCity'] ?? '',
      secondaryState: data['secondaryState'] ?? '',
      secondaryZip: data['secondaryZip'] ?? '',
      travelRadius: data['travelRadius'] ?? 50,
      payRange: '\$${data['feeRange'] ?? 0}/hr',
      experience: '${data['yearsOfExperience'] ?? 0} years',
      ratingPercentage: '${((data['averageRating'] ?? 0.0).toDouble() * 20).toStringAsFixed(0)}%',
      portfolioItems: portfolioItems,
      profileImage: fixEmulatorUrl(data['profileImageUrl']),
      bannerImage: fixEmulatorUrl(data['bannerImageUrl']),
    );
  }
}
