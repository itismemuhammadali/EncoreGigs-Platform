import 'package:flutter/material.dart';

class CompleteProfileHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const CompleteProfileHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFA1F301).withValues(alpha: 0.1),
            const Color(0xFFA1F301).withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Solid color overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0F),
                    const Color(0xFF0A0A0F),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: GestureDetector(
                  onTap: onBack,
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Title and Step indicator in same row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Step $currentStep of $totalSteps',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: List.generate(
                    totalSteps,
                    (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < totalSteps - 1 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index < currentStep
                              ? const Color(0xFFA1F301)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Full-width green divider
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0x4DA1F301),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }
}
