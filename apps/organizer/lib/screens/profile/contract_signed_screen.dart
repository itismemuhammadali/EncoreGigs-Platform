import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContractSignedScreen extends StatefulWidget {
  const ContractSignedScreen({super.key});

  @override
  State<ContractSignedScreen> createState() => _ContractSignedScreenState();
}

class _ContractSignedScreenState extends State<ContractSignedScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-close after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/my-contracts',
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon container
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2F),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/tick_icon.svg',
                    width: 80,
                    height: 80,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA2F301),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Title
              const Text(
                'Contract Signed!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              // Subtitle
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Both parties are now bound by the agreement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 16,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
