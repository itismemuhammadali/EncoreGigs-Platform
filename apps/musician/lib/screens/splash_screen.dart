import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final status = await authService.getUserStatus(user.uid);
        if (!mounted) return;
        if (status == 'pending' || status == 'pending_approval') {
          Navigator.of(context).pushReplacementNamed('/account_pending');
        } else if (status == 'rejected' || status == 'denied') {
          Navigator.of(context).pushReplacementNamed('/account_denied');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: SizedBox(
          width: 220,
          height: 220,
          child: Image.asset(
            'assets/musician_logo.jpeg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
