import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'providers/signup_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/create_account/step1_account_details.dart';
import 'screens/auth/create_account/step2_organizer_info.dart';
import 'screens/auth/create_account/step3_verification.dart';
import 'screens/auth/create_account/account_pending_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/contract_signed_screen.dart';
import 'screens/profile/my_contracts_screen.dart';
import 'utils/custom_page_route.dart';

import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with dummy options since we're using emulators
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
      ChangeNotifierProvider(create: (_) => SignUpProvider()),
    ],
    child: const MyApp(),
  ),
  );}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnlyGigz Organizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        canvasColor: const Color(0xFF0A0A0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFA2F301),
          surface: const Color(0xFF0A0A0F),
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final routes = {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const SignInScreen(),
          '/signup/step1': (context) => const Step1AccountDetails(),
          '/signup/step2': (context) => const Step2OrganizerInfo(),
          '/signup/step3': (context) => const Step3Verification(),
          '/signup/pending': (context) => const AccountPendingScreen(),
          '/home': (context) => const HomeScreen(),
          '/contract-signed': (context) => const ContractSignedScreen(),
          '/profile': (context) => const HomeScreen(),
          '/my-contracts': (context) => const MyContractsScreen(),
        };

        final builder = routes[settings.name];
        if (builder != null) {
          return CustomPageRoute(
            builder: builder,
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
