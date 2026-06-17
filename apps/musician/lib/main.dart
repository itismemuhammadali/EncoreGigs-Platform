import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase BEFORE runApp to ensure stable state for providers
  if (Firebase.apps.isEmpty) {
    const firebaseOptions = FirebaseOptions(
      apiKey: "AIzaSyB-DUMMY-KEY-FOR-EMULATOR-VALID",
      appId: "1:1234567890:ios:abcdef123456",
      messagingSenderId: "1234567890",
      projectId: "demo-onlygigz",
      storageBucket: "demo-onlygigz.appspot.com",
      iosBundleId: "com.onlygigz.musician",
    );

    try {
      await Firebase.initializeApp(options: firebaseOptions);
      
      // Connect to Emulators immediately after init
      final String host = getEmulatorHost();
      debugPrint('Connecting to Firebase emulators on host: $host');
      
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.settings = Settings(
        host: '$host:8080',
        sslEnabled: false,
        persistenceEnabled: false,
      );
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('Firebase emulators connected (Auth:9099, Firestore:8080, Storage:9199)');
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

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

Future<void> _initNetworking() async {
  try {
    await initHosts().timeout(const Duration(seconds: 2));
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
