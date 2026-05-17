# 🎵 OnlyGigz Organizer

**A comprehensive Flutter application for event organizers to manage gigs, bookings, and musician collaborations.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)

## 📱 Overview

OnlyGigz Organizer is a modern, intuitive mobile application designed specifically for event organizers who need to streamline their gig management process. From posting gigs to managing bookings and handling payments, this app provides a complete solution for the entertainment industry.

## ✨ Key Features

### 🎯 **Core Functionality**
- **Gig Management**: Create, edit, and manage performance opportunities
- **Booking System**: Handle musician bookings with status tracking
- **Payment Processing**: Secure escrow system with payment history
- **Contract Management**: Digital contract signing with signature canvas
- **Messaging System**: Real-time communication with musicians
- **Profile Management**: Comprehensive organizer and organization profiles

### 🎨 **User Experience**
- **Dark Theme**: Professional dark UI with lime green accents (#A2F301)
- **Smooth Transitions**: Custom page transitions without white flash
- **Responsive Design**: Optimized for various screen sizes
- **Intuitive Navigation**: Bottom navigation with clear visual hierarchy

### 🔧 **Technical Features**
- **Custom Page Routes**: Smooth slide transitions between screens
- **SVG Support**: Scalable vector graphics for crisp icons
- **State Management**: Efficient state handling across the application
- **Modular Architecture**: Well-organized code structure for maintainability

## 🏗️ Project Structure

```
lib/
├── main.dart                    # Application entry point
├── utils/
│   └── custom_page_route.dart   # Custom navigation transitions
└── screens/
    ├── auth/                    # Authentication flows
    │   ├── sign_in_screen.dart
    │   └── create_account/      # Multi-step registration
    ├── home/                    # Dashboard and main navigation
    │   ├── home_screen.dart
    │   └── widgets/             # Reusable home components
    ├── gigs/                    # Gig management
    │   ├── gigs_screen.dart
    │   ├── post_gig_screen.dart
    │   ├── gig_details_screen.dart
    │   └── widgets/             # Gig-related components
    ├── bookings/                # Booking management
    │   ├── bookings_screen.dart
    │   └── widgets/             # Booking components
    ├── messages/                # Communication system
    │   ├── messages_screen.dart
    │   └── chat/                # Chat functionality
    ├── profile/                 # User profile management
    │   ├── profile_screen.dart
    │   ├── wallet_screen.dart
    │   ├── contract_*.dart      # Contract management
    │   └── widgets/             # Profile components
    ├── notifications/           # Notification system
    ├── onboarding/             # First-time user experience
    └── splash_screen.dart      # App launch screen
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (^3.11.4)
- Dart SDK
- Android Studio / VS Code
- iOS Simulator / Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Muhammadali2025222/Gigzflow_Organizer.git
   cd Gigzflow_Organizer
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

**Android APK:**
```bash
flutter build apk --release
```

**iOS IPA:**
```bash
flutter build ios --release
```

## 📦 Dependencies

### Core Dependencies
- **flutter_svg**: ^2.0.10+1 - SVG rendering support
- **cupertino_icons**: ^1.0.8 - iOS-style icons

### Development Dependencies
- **flutter_lints**: ^6.0.0 - Code quality and style enforcement
- **flutter_launcher_icons**: ^0.14.1 - Custom app icon generation

## 🎨 Design System

### Color Palette
- **Primary**: #A2F301 (Lime Green)
- **Background**: #0A0A0F (Deep Black)
- **Surface**: #1A1A1F (Dark Gray)
- **Secondary Surface**: #2A2A2F (Medium Gray)
- **Text Primary**: #FFFFFF (White)
- **Text Secondary**: #888888 (Light Gray)

### Typography
- **Headers**: Bold, clean sans-serif
- **Body Text**: Regular weight for readability
- **Accent Text**: Medium weight for emphasis

## 🔄 App Flow

### Authentication Flow
1. **Splash Screen** → **Onboarding** → **Sign In/Register**
2. **Multi-step Registration**: Account Details → Organizer Info → Verification

### Main Application Flow
1. **Home Dashboard**: Overview of activities and quick actions
2. **Gigs Management**: Create, view, and manage performance opportunities
3. **Bookings**: Track confirmed bookings and their status
4. **Messages**: Communicate with musicians
5. **Profile**: Manage personal and organization information

### Contract Management Flow
1. **Contract Creation** → **Digital Signing** → **Confirmation**
2. **Signature Canvas**: Custom drawing interface for legal signatures
3. **Auto-navigation**: Seamless flow back to contracts list

## 🛠️ Technical Implementation

### Custom Page Transitions
The app implements custom page routes to eliminate the white flash during navigation:

```dart
class CustomPageRoute<T> extends MaterialPageRoute<T> {
  // Smooth slide transition from right to left
  // Eliminates white flash between screens
}
```

### State Management
- **StatefulWidget**: For screens requiring dynamic state
- **StatelessWidget**: For static content and optimized performance

### Asset Management
- **SVG Icons**: Scalable vector graphics for crisp display
- **Image Assets**: Optimized images for various screen densities
- **Organized Structure**: All assets properly categorized

## 🔐 Security Features

- **Secure Authentication**: Multi-step verification process
- **Contract Security**: Digital signature validation
- **Payment Security**: Escrow system for secure transactions
- **Data Privacy**: User information protection

## 📱 Platform Support

- **Android**: Minimum SDK 21 (Android 5.0)
- **iOS**: iOS 12.0 and above
- **Responsive Design**: Adapts to various screen sizes

## 🚧 Future Enhancements

- [ ] Push notifications for real-time updates
- [ ] Advanced search and filtering
- [ ] Analytics dashboard for organizers
- [ ] Integration with external payment gateways
- [ ] Multi-language support
- [ ] Dark/Light theme toggle

## 🤝 Contributing

This is a private project. For any contributions or suggestions, please contact the development team.

## 📄 License

This project is private and proprietary. All rights reserved.

## 👥 Development Team

**Project**: OnlyGigz Organizer  
**Repository**: [Gigzflow_Organizer](https://github.com/Muhammadali2025222/Gigzflow_Organizer)  
**Developer**: Muhammadali2025222

---

## 📞 Support

For technical support or feature requests, please create an issue in the GitHub repository.

**Built with ❤️ using Flutter**
