import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/complete_profile_header.dart';

class CustomSliderThumb extends RoundSliderThumbShape {
  const CustomSliderThumb({
    super.enabledThumbRadius = 8,
  });

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    // Draw border circle with bright green color (filled area color)
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFA1F301)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, enabledThumbRadius, borderPaint);
  }
}

class CustomSliderTrackShape extends RoundedRectSliderTrackShape {
  const CustomSliderTrackShape();

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    double additionalActiveTrackHeight = 0,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = true,
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required Offset thumbCenter,
  }) {
    final Canvas canvas = context.canvas;
    final Paint paint = Paint()
      ..color = const Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;

    final Paint activePaint = Paint()
      ..color = const Color(0xFFA1F301)
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = const Color(0xFFA1F301)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final Rect trackRect = Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - sliderTheme.trackHeight!) / 2,
      parentBox.size.width,
      sliderTheme.trackHeight!,
    );

    final RRect rRect = RRect.fromRectAndRadius(
      trackRect,
      Radius.circular(sliderTheme.trackHeight! / 2),
    );

    // Draw inactive track
    canvas.drawRRect(rRect, paint);

    // Draw active track
    final Rect activeRect = Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - sliderTheme.trackHeight!) / 2,
      thumbCenter.dx - offset.dx,
      sliderTheme.trackHeight!,
    );

    final RRect activeRRect = RRect.fromRectAndRadius(
      activeRect,
      Radius.circular(sliderTheme.trackHeight! / 2),
    );

    canvas.drawRRect(activeRRect, activePaint);

    // Draw border
    canvas.drawRRect(rRect, borderPaint);
  }
}

class Step2Screen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2Screen({
    super.key,
    required this.profileData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step2Screen> createState() => _Step2ScreenState();
}

class _Step2ScreenState extends State<Step2Screen> {
  late TextEditingController _yearsController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _yearsController = TextEditingController(
      text: widget.profileData['yearsOfExperience'].toString(),
    );
    _locationController = TextEditingController(
      text: widget.profileData['location'] ?? '',
    );
    _websiteController = TextEditingController(
      text: widget.profileData['website'] ?? '',
    );
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    return '\$${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with full-width divider
        CompleteProfileHeader(
          currentStep: 2,
          totalSteps: 3,
          onBack: widget.onBack,
        ),
        
        // Scrollable content
        Expanded(
          child: Container(
            color: const Color(0xFF0A0A0F),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

          // Typical Fee Range
          const Text(
            'Typical Fee Range',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 13,
              thumbShape: const CustomSliderThumb(enabledThumbRadius: 5),
              trackShape: const CustomSliderTrackShape(),
              activeTrackColor: const Color(0xFFA1F301),
              inactiveTrackColor: const Color(0xFF1a1a1a),
              overlayColor: Colors.transparent,
              valueIndicatorColor: Colors.transparent,
            ),
            child: Slider(
              value: widget.profileData['feeRange'].toDouble(),
              min: 100,
              max: 5000,
              onChanged: (value) {
                setState(() {
                  widget.profileData['feeRange'] = value.toInt();
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Min: \$100',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                _formatCurrency(widget.profileData['feeRange'].toDouble()),
                style: const TextStyle(
                  color: Color(0xFFA1F301),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              const Text(
                'Max: \$5000',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Years of Experience
          const Text(
            'Years of Experience',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _yearsController,
            onChanged: (value) {
              widget.profileData['yearsOfExperience'] =
                  int.tryParse(value) ?? 0;
            },
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA1F301)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Location
          const Text(
            'Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            onChanged: (value) {
              widget.profileData['location'] = value;
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'City, State',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA1F301)),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Website / Social Media
          const Text(
            'Website / Social Media',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _websiteController,
            onChanged: (value) {
              widget.profileData['website'] = value;
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[700]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFA1F301)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
              ),
            ),
          ),
        ),
        
        // Fixed button at bottom
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA1F301),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: SvgPicture.asset('assets/next_arrow_no_tail.svg'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
