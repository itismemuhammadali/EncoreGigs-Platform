import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
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
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "dummy-api-key",
      appId: "dummy-app-id",
      messagingSenderId: "dummy-sender-id",
      projectId: "demo-onlygigz",
      storageBucket: "demo-onlygigz.appspot.com",
    ),
  );

  await initHosts();

  // Connect to Firebase Emulators
  final String host = getEmulatorHost();
  try {
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.settings = Settings(
      host: '$host:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  } catch (e) {
    debugPrint('Error connecting to emulators: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => MusicianSignUpProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
        pageTransitionsTheme: const PageTransitionsTheme(
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
