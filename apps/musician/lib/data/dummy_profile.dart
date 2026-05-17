import '../models/profile_model.dart';

final Profile dummyProfile = Profile(
  name: 'Jordan Davis',
  profession: 'Jazz Saxophonist',
  bio: 'Professional jazz saxophonist with 10+ years of experience performing at weddings, corporate events, and jazz clubs. Specializing in classic standards and contemporary jazz. Available for solo performances or with my quartet.',
  email: 'jordan@example.com',
  contact: '+1 (555) 123-4567',
  avgRating: 4.9,
  gigsCompleted: 47,
  responseRate: 98.0,
  reviewCount: 38,
  genres: ['Jazz', 'Classical', 'Blues'],
  location: 'New York, NY',
  payRange: '\$500 - \$2,000',
  experience: '10+ Years',
  ratingPercentage: '98%',
  portfolioItems: [
    PortfolioItem(image: 'assets/portfolio_image1.png', type: 'video'),
    PortfolioItem(image: 'assets/portfolio_image2.png', type: 'image'),
    PortfolioItem(image: 'assets/portfolio_image3.png', type: 'music'),
  ],
  profileImage: 'assets/profile_image.png',
);
