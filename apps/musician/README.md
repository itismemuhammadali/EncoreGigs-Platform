# 🎵 OnlyGigz - Musician Platform

<div align="center">
  <img src="assets/Logo.png" alt="OnlyGigz Logo" width="120" height="120">
  
  **A comprehensive Flutter application connecting musicians with gig opportunities**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?style=flat&logo=flutter)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## 📱 About OnlyGigz

OnlyGigz is a modern, feature-rich mobile application designed to bridge the gap between talented musicians and event organizers. Built with Flutter, it provides a seamless platform for musicians to showcase their talents, find gigs, manage bookings, and handle payments securely.

### 🎯 Key Features

#### 🎪 **Gig Management**
- **Discover Gigs**: Browse and filter available music gigs by location, genre, and date
- **Apply for Opportunities**: Submit applications with portfolio and pricing details
- **Track Applications**: Monitor application status and receive real-time updates
- **Contract Management**: Review and digitally sign performance contracts

#### 💰 **Financial Management**
- **Comprehensive Wallet**: Multi-tab wallet system with overview, escrow, history, and payment methods
- **Secure Payments**: Multiple payment options including cards and bank accounts
- **Escrow Protection**: Safe payment holding until gig completion
- **Payout System**: Easy withdrawal to preferred payment methods
- **Transaction History**: Detailed records with export functionality

#### 👤 **Profile & Portfolio**
- **Rich Profiles**: Showcase musical skills, experience, and media
- **Portfolio Management**: Upload and organize performance videos, audio samples, and images
- **Verification System**: Build trust with verified musician badges
- **Rating System**: Collect and display performance reviews

#### 💬 **Communication**
- **Real-time Messaging**: Direct chat with event organizers
- **Live Support**: 24/7 customer support chat system
- **Notifications**: Stay updated on bookings, payments, and opportunities

#### 🔒 **Security & Privacy**
- **Two-Factor Authentication**: Enhanced account security with SMS/Email verification
- **Privacy Controls**: Granular privacy settings for profile visibility
- **Data Protection**: GDPR-compliant data management and export options
- **Secure Transactions**: Industry-standard encryption for all financial operations

## 🏗️ Architecture & Structure

### 📁 Project Organization

```
lib/
├── data/                    # Static data and mock content
│   ├── dummy_applications.dart
│   ├── dummy_bookings.dart
│   ├── dummy_gigs.dart
│   ├── dummy_messages.dart
│   └── dummy_profile.dart
├── models/                  # Data models and structures
│   ├── application_model.dart
│   ├── booking_model.dart
│   ├── gig_model.dart
│   ├── message_model.dart
│   └── profile_model.dart
├── screens/                 # UI screens organized by flow
│   ├── auth/               # Authentication flow
│   ├── main/               # Main application screens
│   ├── onboarding/         # User onboarding
│   └── splash_screen.dart
├── widgets/                # Reusable UI components
└── main.dart               # Application entry point
```

### 🎨 Design System

- **Color Scheme**: Dark theme with neon green (#A1F301) accents
- **Typography**: Clean, modern font hierarchy
- **Components**: Consistent UI elements with rounded corners and subtle borders
- **Icons**: Comprehensive SVG icon library for all features
- **Responsive**: Adaptive layouts for various screen sizes

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Version 3.9.2 or higher
- **Dart SDK**: Version 3.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **iOS Development**: Xcode (for iOS builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Muhammadali2025222/Gigzflow_Musician.git
   cd Gigzflow_Musician
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate launcher icons**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

4. **Generate splash screen**
   ```bash
   flutter pub run flutter_native_splash:create
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

### 🔧 Configuration

#### Android Setup
- Minimum SDK: API 21 (Android 5.0)
- Target SDK: Latest stable version
- Custom launcher icon configured

#### iOS Setup
- Minimum iOS version: 12.0
- Custom app icons for all sizes
- Native splash screen integration

## 📱 Screen Flow & Navigation

### Authentication Flow
1. **Splash Screen** → **Onboarding** → **Sign In/Create Account**
2. **Profile Completion** (3-step process for new users)

### Main Application Flow
```
Home Screen (Bottom Navigation)
├── Gigs Tab
│   ├── Gig Details
│   ├── Apply for Gig
│   └── Application Submitted
├── Applications Tab
│   ├── Application Details
│   └── Contract Review
├── Bookings Tab
│   ├── Booking Details
│   └── Chat with Organizer
├── Messages Tab
│   ├── Individual Chats
│   └── Live Support Chat
└── Profile Tab
    ├── Edit Profile
    ├── Portfolio Management
    ├── Settings
    │   ├── Wallet Overview
    │   ├── Payment Methods
    │   ├── Privacy Settings
    │   ├── Two-Factor Auth
    │   └── Help Center
    └── Featured Upgrade
```

## 💳 Payment System Features

### Wallet Management
- **Overview Tab**: Balance display, statistics, recent activity
- **Escrow Tab**: Protected payments with early release options
- **History Tab**: Complete transaction records with filtering
- **Methods Tab**: Payment cards and bank account management

### Security Features
- **Encrypted Storage**: All payment data encrypted at rest
- **PCI Compliance**: Secure card data handling
- **Fraud Protection**: Advanced transaction monitoring
- **Backup Codes**: Recovery options for 2FA

## 🛠️ Dependencies

### Core Dependencies
```yaml
flutter_svg: ^2.0.0          # SVG asset support
cupertino_icons: ^1.0.8      # iOS-style icons
```

### Development Dependencies
```yaml
flutter_launcher_icons: ^0.13.1    # Custom app icons
flutter_native_splash: ^2.3.0      # Native splash screens
flutter_lints: ^6.0.0              # Code quality rules
```

## 🎨 Assets & Resources

### Icons & Graphics
- **72 SVG Icons**: Complete icon set for all features
- **Logo Assets**: PNG and SVG formats for various uses
- **Onboarding Images**: High-quality JPG images for user introduction

### Sample Content
- **Profile Images**: Musician profile photos and portfolio samples
- **Gig Images**: Event and venue photography
- **Chat Media**: Sample conversation images

## 🔐 Security Implementation

### Authentication
- **Multi-step Registration**: Comprehensive profile setup
- **Password Security**: Strong password requirements
- **Session Management**: Secure token handling

### Privacy Controls
- **Profile Visibility**: Control who can see your information
- **Data Export**: GDPR-compliant data download
- **Account Deletion**: Complete data removal options

### Two-Factor Authentication
- **SMS Verification**: Phone number-based 2FA
- **Email Backup**: Alternative verification method
- **Recovery Codes**: Offline backup access codes

## 🚀 Future Enhancements

### Planned Features
- [ ] **Real-time Notifications**: Push notification system
- [ ] **Advanced Search**: AI-powered gig recommendations
- [ ] **Social Features**: Musician networking and collaboration
- [ ] **Analytics Dashboard**: Performance metrics and insights
- [ ] **Multi-language Support**: Internationalization
- [ ] **Offline Mode**: Core functionality without internet

### Technical Improvements
- [ ] **State Management**: Implementation of Bloc/Provider pattern
- [ ] **API Integration**: Backend service connectivity
- [ ] **Testing Suite**: Comprehensive unit and widget tests
- [ ] **CI/CD Pipeline**: Automated build and deployment
- [ ] **Performance Optimization**: Advanced caching and lazy loading

## 🤝 Contributing

We welcome contributions from the community! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit your changes**: `git commit -m 'Add amazing feature'`
4. **Push to the branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Development Guidelines
- Follow Flutter/Dart style guidelines
- Write clear commit messages
- Add comments for complex logic
- Test your changes thoroughly
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

**Lead Developer**: Muhammad Ali  
**Email**: muhammadali2025222@gmail.com  
**GitHub**: [@Muhammadali2025222](https://github.com/Muhammadali2025222)

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Material Design** for design inspiration
- **SVG Icon Libraries** for comprehensive iconography
- **Open Source Community** for continuous support and contributions

---

<div align="center">
  <p><strong>Built with ❤️ for the music community</strong></p>
  <p>© 2025 OnlyGigz. All rights reserved.</p>
</div>
