import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/musician_signup_provider.dart';
import '../../services/auth_service.dart';
import 'step1_screen.dart';
import 'step2_screen.dart';
import 'step3_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  int currentStep = 1;
  late PageController _pageController;
  bool _isLoading = false;

  final Map<String, dynamic> profileData = {
    'fullName': '',
    'profileImage': null,
    'bannerImage': null,
    'bio': '',
    'primaryGenre': '',
    'subgenres': <String>[],
    'tags': <String>[],
    'genres': <String>[],
    'instruments': <String>[],
    'hourlyRate': 50,
    'feeRange': 50,
    'yearsOfExperience': 0,
    'primaryCity': '',
    'primaryState': '',
    'primaryZip': '',
    'secondaryCity': '',
    'secondaryState': '',
    'secondaryZip': '',
    'travelRadius': 50,
    'location': '',
    'website': '',
    'portfolio': {
      'images': [],
      'videos': [],
      'audioTracks': [],
    },
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (currentStep > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> completeProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final signupProvider = Provider.of<MusicianSignUpProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Update provider with profile data
      signupProvider.updateProfile(profileData);

      final error = await authService.signUpMusician(
        email: signupProvider.email,
        password: signupProvider.password,
        fullName: signupProvider.fullName,
        bio: signupProvider.bio,
        genres: signupProvider.genres,
        instruments: signupProvider.instruments,
        feeRange: signupProvider.feeRange,
        yearsOfExperience: signupProvider.yearsOfExperience,
        location: signupProvider.location,
        website: signupProvider.website,
        portfolio: signupProvider.portfolio,
        profileImage: profileData['profileImage'] as File?,
        bannerImage: profileData['bannerImage'] as File?,
        primaryCity: profileData['primaryCity'] as String?,
        primaryState: profileData['primaryState'] as String?,
        primaryZip: profileData['primaryZip'] as String?,
        secondaryCity: profileData['secondaryCity'] as String?,
        secondaryState: profileData['secondaryState'] as String?,
        secondaryZip: profileData['secondaryZip'] as String?,
        travelRadius: profileData['travelRadius'] as int?,
        primaryGenre: profileData['primaryGenre'] as String?,
        subgenres: List<String>.from(profileData['subgenres'] ?? []),
        tags: List<String>.from(profileData['tags'] ?? []),
      );

      if (!mounted) return;

      if (error == null) {
        debugPrint('Signup successful, navigating to home...');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          SafeArea(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentStep = index + 1;
                });
              },
              children: [
                Step1Screen(
                  profileData: profileData,
                  onNext: nextStep,
                ),
                Step2Screen(
                  profileData: profileData,
                  onNext: nextStep,
                  onBack: previousStep,
                ),
                Step3Screen(
                  profileData: profileData,
                  onComplete: completeProfile,
                  onBack: previousStep,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
