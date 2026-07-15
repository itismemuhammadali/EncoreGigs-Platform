import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'booking_confirmed_screen.dart';
import '../../services/auth_service.dart';

class ContractScreen extends StatefulWidget {
  final String musicianId;
  final String musicianName;
  final String musicianImage;
  final String gigId;
  final String gigTitle;
  final String gigDate;
  final String gigTime;
  final String? gigDuration;
  final double amount;
  final String? location;
  final String? organizerName;

  const ContractScreen({
    super.key,
    required this.musicianId,
    required this.musicianName,
    required this.musicianImage,
    required this.gigId,
    required this.gigTitle,
    required this.gigDate,
    required this.gigTime,
    this.gigDuration,
    required this.amount,
    this.location,
    this.organizerName,
  });

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  bool _agreed = false;
  bool _isSubmitting = false;
  final List<List<Offset?>> _strokes = [];
  List<Offset?> _currentStroke = [];
  final GlobalKey _signatureKey = GlobalKey();

  String _getTimeRange() {
    if (widget.gigTime == 'TBD') return 'TBD';
    
    try {
      final timeStr = widget.gigTime.toUpperCase().trim();
      // Handle formats like "1:00 PM", "1 PM", "01:00 PM"
      final DateFormat inputFormat = DateFormat.jm();
      DateTime startTime;
      
      try {
        startTime = inputFormat.parse(timeStr);
      } catch (e) {
        // Fallback for formats without minutes like "1 PM"
        if (RegExp(r'^\d+\s*(AM|PM)$').hasMatch(timeStr)) {
          final ampm = timeStr.contains('PM') ? 'PM' : 'AM';
          final hour = timeStr.replaceAll(RegExp(r'[^0-9]'), '');
          startTime = inputFormat.parse('$hour:00 $ampm');
        } else {
          return widget.gigTime;
        }
      }

      if (widget.gigDuration == null || widget.gigDuration!.isEmpty) {
        return inputFormat.format(startTime).toLowerCase();
      }

      // Extract hours and minutes from duration string (e.g., "2 hours", "2.5 hours", "90 mins")
      int totalMinutes = 0;
      final hourMatch = RegExp(r'(\d+\.?\d*)\s*(hour|hr|h)', caseSensitive: false).firstMatch(widget.gigDuration!);
      final minMatch = RegExp(r'(\d+)\s*(min|m)', caseSensitive: false).firstMatch(widget.gigDuration!);

      if (hourMatch != null) {
        totalMinutes += (double.parse(hourMatch.group(1)!) * 60).toInt();
      }
      if (minMatch != null) {
        totalMinutes += int.parse(minMatch.group(1)!);
      }

      if (totalMinutes == 0) return inputFormat.format(startTime).toLowerCase();

      final endTime = startTime.add(Duration(minutes: totalMinutes));
      final displayFormat = DateFormat('h:mm a');
      
      // Clean formatting: remove :00 if both times are on the hour for a cleaner look
      String startDisplay = displayFormat.format(startTime).toLowerCase();
      String endDisplay = displayFormat.format(endTime).toLowerCase();
      
      if (startDisplay.contains(':00')) startDisplay = startDisplay.replaceFirst(':00', '');
      if (endDisplay.contains(':00')) endDisplay = endDisplay.replaceFirst(':00', '');

      return '$startDisplay to $endDisplay';
    } catch (e) {
      debugPrint('Time calculation error: $e');
      return widget.gigTime;
    }
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _currentStroke = [d.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _currentStroke.add(d.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails d) {
    setState(() {
      _strokes.add(List.from(_currentStroke));
      _currentStroke = [];
    });
  }

  void _clearSignature() {
    setState(() {
      _strokes.clear();
      _currentStroke.clear();
    });
  }

  bool get _hasSignature => _strokes.isNotEmpty;

  Future<void> _handleConfirm() async {
    if (!_agreed || !_hasSignature || _isSubmitting) {
      debugPrint('--- Confirm Denied: agreed:$_agreed, signature:$_hasSignature, submitting:$_isSubmitting ---');
      return;
    }

    debugPrint('--- Signature Confirm Started ---');
    setState(() => _isSubmitting = true);

    String signatureUrl = '';

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      debugPrint('Step 1: Capturing Signature...');
      final RenderRepaintBoundary? boundary =
          _signatureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        throw Exception('Signature canvas not found');
      }

      if (boundary.debugNeedsPaint) {
        debugPrint('Warning: Boundary needs paint, waiting...');
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to convert signature to bytes');
      }
      
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      debugPrint('Signature captured, bytes length: ${pngBytes.length}');

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String path =
          'signatures/${authService.user?.uid}_${widget.musicianId}_$timestamp.png';

      debugPrint('Step 2: Uploading to Storage at $path...');
      signatureUrl = await authService.uploadData(pngBytes, path) ?? '';
      if (signatureUrl.isEmpty) {
        throw Exception('Failed to upload signature to Storage');
      }
      debugPrint('Upload success, URL: $signatureUrl');

      debugPrint('Step 3: Confirming booking via backend...');
      
      final Map<String, String> contractSections = {
        'musicianObligations': 'Arrive 30 minutes prior to performance time\nPerform for the agreed duration\nProvide professional-quality performance\nBring necessary equipment or use venue-provided instruments',
        'organizerObligations': 'Provide access to performance venue\nEnsure safe and suitable performance environment\nPay agreed compensation via escrow system\nRelease payment within 48 hours of performance completion',
        'paymentTerms': 'Payment of \$${widget.amount} will be held in escrow through the OnlyGigz platform. Funds will be released to the Musician within 48 hours after the Organizer confirms successful performance completion.',
        'cancellationPolicy': 'Either party may cancel up to 7 days before the performance date without penalty. Cancellations within 7 days require mutual agreement or may result in partial payment.',
        'disputeResolution': 'Any disputes will be mediated through the OnlyGigz platform support team before pursuing other legal remedies.'
      };

      final error = await authService.confirmBooking(
        gigId: widget.gigId,
        gigTitle: widget.gigTitle,
        musicianId: widget.musicianId,
        musicianName: widget.musicianName,
        organizerName: widget.organizerName ?? 'Event Organizer',
        location: widget.location ?? 'Venue Location',
        amount: widget.amount,
        signatureUrl: signatureUrl,
        gigDate: widget.gigDate,
        gigTime: widget.gigTime,
        duration: widget.gigDuration,
        sections: contractSections,
      );

      if (error != null) {
        throw Exception(error);
      }
      debugPrint('Booking confirmed successfully in Firestore');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BookingConfirmedScreen(
              musicianName: widget.musicianName,
              gigTitle: widget.gigTitle,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('SIGNATURE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = '${today.month}/${today.day}/${today.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Color(0x4DA2F301), height: 1),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text('Payment',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stepper
              Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA2F301),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('1',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Payment',
                          style: TextStyle(
                              color: Color(0xFFA2F301), fontSize: 11)),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: const Color(0xFFA2F301),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFFA2F301),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('2',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('Contract',
                          style: TextStyle(
                              color: Color(0xFFA2F301), fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Contract card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Performance Agreement',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(
                      'This agreement is made between ${widget.organizerName ?? 'Event Organizer'} (Organizer) and ${widget.musicianName} (Performer) for the performance at:',
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0F),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Event: ${widget.gigTitle}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Date: ${widget.gigDate}',
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Time: ${_getTimeRange()}',
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('Location: ${widget.location ?? 'TBD'}',
                              style: const TextStyle(
                                  color: Color(0xFF888888), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            'Compensation: \$${widget.amount.toInt()}',
                            style: const TextStyle(
                                color: Color(0xFFA2F301),
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Payment will be held in escrow and released within 24 hours of successful performance completion.',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Both parties agree to the terms and conditions outlined in this contract.',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Agreement checkbox
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1F),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _agreed
                              ? const Color(0xFFA2F301)
                              : Colors.transparent,
                          border: Border.all(
                            color: _agreed
                                ? const Color(0xFFA2F301)
                                : const Color(0xFF555555),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _agreed
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'I agree to the terms and conditions of this performance agreement and authorize the payment of \$${widget.amount.toInt()} to be held in escrow.',
                          style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                              height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Signature
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Signature',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  if (_hasSignature)
                    GestureDetector(
                      onTap: _clearSignature,
                      child: const Text('Clear',
                          style: TextStyle(
                              color: Color(0xFFA2F301), fontSize: 13)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DA2F301)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RepaintBoundary(
                    key: _signatureKey,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Container(
                        color: Colors.transparent, // Background color for capture (transparent for clear PNG)
                        child: CustomPaint(
                          painter: _SignaturePainter(
                              strokes: _strokes, currentStroke: _currentStroke),
                          child: _hasSignature
                              ? const SizedBox.expand()
                              : const Center(
                                  child: Text(
                                    'Draw your signature here',
                                    style: TextStyle(
                                        color: Color(0xFF444444), fontSize: 13),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Digital signature • $dateStr',
                style: const TextStyle(
                    color: Color(0xFF555555), fontSize: 11),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        child: GestureDetector(
          onTap: _handleConfirm,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56, // Fixed height to prevent shifts
            decoration: BoxDecoration(
              color: (_agreed && _hasSignature)
                  ? const Color(0xFFA2F301)
                  : const Color(0x4DA1F301),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Text is invisible but takes up space when loading, or just replaced
                Opacity(
                  opacity: _isSubmitting ? 0 : 1,
                  child: Text(
                    'Sign & Confirm Booking',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (_agreed && _hasSignature)
                          ? Colors.black
                          : const Color(0xFF666666),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_isSubmitting)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset?>> strokes;
  final List<Offset?> currentStroke;

  _SignaturePainter({required this.strokes, required this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA2F301)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset?> stroke) {
      final path = ui.Path();
      bool started = false;
      for (final point in stroke) {
        if (point == null) {
          started = false;
          continue;
        }
        if (!started) {
          path.moveTo(point.dx, point.dy);
          started = true;
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    if (currentStroke.isNotEmpty) {
      drawStroke(currentStroke);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
