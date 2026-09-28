import '../models/gig_model.dart';
import '../models/chat_model.dart';
import '../models/profile_model.dart';
import '../screens/main/notifications_screen.dart';

/// Set this flag to true for Play Store screenshots, or false for live production/database data.
const bool kUseStoreListingMockData = false;

// 1. Home Gigs
final List<Gig> kMockStoreGigs = [
  Gig(
    id: 'store_mock_gig_1',
    title: 'Jazz Night at Blue Moon',
    genre: 'Jazz',
    genres: ['Jazz'],
    location: 'Brooklyn, NY',
    distance: 2.3,
    rating: 4.8,
    description: 'Looking for a talented jazz ensemble or solo saxophonist for a weekend evening performance at Blue Moon.',
    requirements: ['Original compositions', 'Own instruments', '2 hours set'],
    date: DateTime(2025, 12, 24),
    dateString: 'Dec 24, 2025',
    time: '8:00 PM',
    pay: '800 - 1,200',
    budget: '\$800 - \$1,200',
    imageUrl: 'assets/gig_image1.jpg',
    organizer: 'Blue Moon Events',
    organizerId: 'org_blue_moon',
    organizerImage: 'assets/chat_image1.png',
    organizerGigsPosted: 12,
    duration: '3 hours',
    status: 'open',
    isUrgent: false,
    isScraped: false,
  ),
  Gig(
    id: 'store_mock_gig_2',
    title: 'Artisanal Food Fair',
    genre: 'Jazz',
    genres: ['Jazz'],
    location: 'Manhattan, NY',
    distance: 4.5,
    rating: 4.7,
    description: 'Outdoor food festival featuring local chefs and live acoustic music throughout the day.',
    requirements: ['Acoustic setup', 'Family-friendly repertoire'],
    date: DateTime(2025, 12, 28),
    dateString: 'Dec 28, 2025',
    time: '2:00 PM',
    pay: '500 - 800',
    budget: '\$500 - \$800',
    imageUrl: 'assets/gig_image2.jpg',
    organizer: 'Foodie Festivals',
    organizerId: 'org_foodie',
    organizerImage: 'assets/chat_image2.png',
    organizerGigsPosted: 8,
    duration: '4 hours',
    status: 'open',
    isUrgent: false,
    isScraped: false,
  ),
];

// 2. Messages
final List<ChatModel> kMockStoreChats = [
  ChatModel(
    id: 'store_mock_chat_1',
    participantIds: ['current_user', 'org_blue_moon'],
    participantNames: {
      'current_user': 'Musician',
      'org_blue_moon': 'Blue Moon Events',
    },
    participantImages: {
      'current_user': '',
      'org_blue_moon': 'assets/chat_image1.png',
    },
    lastMessage: 'Looking forward...',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
    lastMessageSenderId: 'org_blue_moon',
    unreadCount: {'current_user': 2},
  ),
  ChatModel(
    id: 'store_mock_chat_2',
    participantIds: ['current_user', 'org_soundwave'],
    participantNames: {
      'current_user': 'Musician',
      'org_soundwave': 'SoundWave Product.',
    },
    participantImages: {
      'current_user': '',
      'org_soundwave': 'assets/chat_image2.png',
    },
    lastMessage: 'Can you send over..',
    lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
    lastMessageSenderId: 'org_soundwave',
    unreadCount: {'current_user': 0},
  ),
  ChatModel(
    id: 'store_mock_chat_3',
    participantIds: ['current_user', 'org_emily'],
    participantNames: {
      'current_user': 'Musician',
      'org_emily': 'Emily & John',
    },
    participantImages: {
      'current_user': '',
      'org_emily': 'assets/chat_image3.png',
    },
    lastMessage: 'Thank you for accepting!',
    lastMessageTime: DateTime.now().subtract(const Duration(days: 1)),
    lastMessageSenderId: 'org_emily',
    unreadCount: {'current_user': 0},
  ),
];

// 3. Portfolio
final List<PortfolioItem> kMockStorePortfolio = [
  PortfolioItem(
    image: 'assets/portfolio_image1.png',
    type: 'video',
    title: 'Jazz Performance..',
    description: 'Live performance showcase from recent gig.',
  ),
  PortfolioItem(
    image: 'assets/portfolio_image2.png',
    type: 'image',
    title: 'Studio Session',
    description: 'Professional photo from studio session.',
  ),
  PortfolioItem(
    image: 'assets/portfolio_image3.png',
    type: 'music',
    title: 'Original Composition',
    description: 'Original composition and recording.',
  ),
];

// 4. Notifications
final List<AppNotification> kMockStoreNotifications = [
  AppNotification(
    id: 'store_mock_notif_1',
    title: 'Application Accepted! 🎉',
    body: 'TechCorp Events has accepted your application for Corporate Event Entertainment.',
    timeAgo: '2 hours ago',
    type: NotificationType.application,
    data: {},
    isRead: false,
    isUnread: true,
  ),
  AppNotification(
    id: 'store_mock_notif_2',
    title: 'New Message',
    body: 'Emily sent you a message about the Wedding Reception gig.',
    timeAgo: '5 hours ago',
    type: NotificationType.message,
    data: {},
    isRead: false,
    isUnread: true,
  ),
  AppNotification(
    id: 'store_mock_notif_3',
    title: 'Payment Received',
    body: "You've received \$1,200 for the Jazz Night at Blue Moon performance.",
    timeAgo: '1 day ago',
    type: NotificationType.payment,
    data: {},
    isRead: false,
    isUnread: true,
  ),
];

// 5. Wallet Overview Mock Data
const double kMockAvailableBalance = 717.51;
const double kMockInEscrow = 3135.00;
const double kMockTotalEarned = 2327.50;
const double kMockThisMonth = 3580.00;
const int kMockPendingGigs = 2;

final List<Map<String, dynamic>> kMockStoreEscrowBookings = [
  {
    'id': 'escrow_1',
    'gigTitle': 'Corporate Event Entertainment',
    'organizerName': 'TechCorp Events',
    'releaseDate': 'Releases Jan 11, 2026',
    'amount': '\$2375.00',
    'status': 'Pending',
    'avatarPath': 'assets/profile_image.png',
  },
  {
    'id': 'escrow_2',
    'gigTitle': 'Birthday Party DJ Set',
    'organizerName': 'Michael Rodriguez',
    'releaseDate': 'Releases Feb 15, 2026',
    'amount': '\$760.00',
    'status': 'Held',
    'avatarPath': 'assets/profile_image2.jpg',
  },
];

// 6. Live Chat Mock Data (reversed list for ListView: newest first)
final List<Map<String, dynamic>> kMockStoreChatMessages = [
  {
    'text': "Of course! I'd be happy to help with payment methods. What specifically would you like to know?",
    'senderName': 'Sarah',
    'senderType': 'admin',
    'time': '10:33 AM',
    'isUser': false,
  },
  {
    'text': 'Hi Sarah! I have a question about payment methods.',
    'senderName': 'You',
    'senderType': 'user',
    'time': '10:33 AM',
    'isUser': true,
  },
  {
    'text': "Hi! Welcome to GigHub Support. I'm Sarah, and I'm here to help you today. How can I assist you?",
    'senderName': 'Sarah',
    'senderType': 'admin',
    'time': '10:32 AM',
    'isUser': false,
  },
];

