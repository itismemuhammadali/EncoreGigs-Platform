import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/api_service.dart';
import 'providers/musician_signup_provider.dart';
import 'package:onlygigz_musician/screens/splash_screen.dart';
import 'package:onlygigz_musician/screens/onboarding/onboarding_screen.dart';
import 'package:onlygigz_musician/screens/auth/create_account_screen.dart';
import 'package:onlygigz_musician/screens/auth/sign_in_screen.dart';
import 'package:onlygigz_musician/screens/main/home_screen.dart';
import 'package:onlygigz_musician/screens/main/applications_screen.dart';
import 'package:onlygigz_musician/screens/main/messages_screen.dart';
import 'package:onlygigz_musician/screens/main/bookings_screen.dart';
import 'package:onlygigz_musician/screens/main/profile_screen.dart';

import 'constants.dart';
import 'package:shared_config/shared_config.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 0. Initialize Stripe
  await initStripeKey();
  Stripe.publishableKey = STRIPE_PUBLISHABLE_KEY;
  await Stripe.instance.applySettings();
  
  // 1. Initialize Firebase BEFORE runApp to ensure stable state for providers
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized with native config');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  // 2. Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupFCM();

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => MusicianSignUpProvider()),
      ],
      child: const MyApp(),
    ),
  );

  // Initialize background networking AFTER the app has started
  _initNetworking();
}

Future<void> _setupFCM() async {
  final messaging = FirebaseMessaging.instance;

  // Request permission
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('FCM permission: ${settings.authorizationStatus}');

  // Get token and store it for later registration after login
  final token = await messaging.getToken();
  debugPrint('FCM token: $token');

  // Store token locally so it can be registered after login
  if (token != null) {
    // Token will be registered when user logs in (via auth listener)
  }

  // Listen for token refresh
  messaging.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final api = ApiService();
      await api.registerFcmToken(user.uid, 'musician', newToken);
    }
  });

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
  });

  // Handle notification tap when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
  });
}

Future<void> _initNetworking() async {
  try {
    await initHosts().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Networking initialization warning: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnlyGigz Musician',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const SignInScreen(),
        '/signup': (context) => const CreateAccountScreen(),
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => const HomeScreen(),
        '/applications': (context) => const ApplicationsScreen(),
        '/messages': (context) => const MessagesScreen(),
        '/bookings': (context) => const BookingsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
