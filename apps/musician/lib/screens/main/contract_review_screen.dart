import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import 'contract_success_screen.dart';

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA1F301)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}

class ContractReviewScreen extends StatefulWidget {
  final Booking booking;

  const ContractReviewScreen({super.key, required this.booking});

  @override
  State<ContractReviewScreen> createState() => _ContractReviewScreenState();
}

class _ContractReviewScreenState extends State<ContractReviewScreen> {
  bool _agreedToTerms = false;
  bool _signatureAdded = false;
  Uint8List? _signatureBytes;
  bool _isSubmitting = false;
  final List<Offset?> _points = [];
  final GlobalKey _signatureKey = GlobalKey();

  String _getTimeRange() {
    final String time = widget.booking.gigTime ?? 'TBD';
    final String duration = widget.booking.duration ?? '';

    if (time == 'TBD') return 'TBD';

    try {
      final timeStr = time.toUpperCase().trim();
      final DateFormat inputFormat = DateFormat.jm();
      DateTime startTime;

      try {
        startTime = inputFormat.parse(timeStr);
      } catch (e) {
        if (RegExp(r'^\d+\s*(AM|PM)$').hasMatch(timeStr)) {
          final ampm = timeStr.contains('PM') ? 'PM' : 'AM';
          final hour = timeStr.replaceAll(RegExp(r'[^0-9]'), '');
          startTime = inputFormat.parse('$hour:00 $ampm');
        } else {
          return time;
        }
      }

      if (duration.isEmpty) {
        return inputFormat.format(startTime).toLowerCase();
      }

      int totalMinutes = 0;
      final hourMatch =
          RegExp(r'(\d+\.?\d*)\s*(hour|hr|h)', caseSensitive: false)
              .firstMatch(duration);
      final minMatch = RegExp(r'(\d+)\s*(min|m)', caseSensitive: false)
          .firstMatch(duration);

      if (hourMatch != null) {
        totalMinutes += (double.parse(hourMatch.group(1)!) * 60).toInt();
      }
      if (minMatch != null) {
        totalMinutes += int.parse(minMatch.group(1)!);
      }

      if (totalMinutes == 0) return inputFormat.format(startTime).toLowerCase();

      final endTime = startTime.add(Duration(minutes: totalMinutes));
      final displayFormat = DateFormat('h:mm a');

      String startDisplay = displayFormat.format(startTime).toLowerCase();
      String endDisplay = displayFormat.format(endTime).toLowerCase();

      if (startDisplay.contains(':00')) {
        startDisplay = startDisplay.replaceFirst(':00', '');
      }
      if (endDisplay.contains(':00')) {
        endDisplay = endDisplay.replaceFirst(':00', '');
      }

      return '$startDisplay to $endDisplay';
    } catch (e) {
      debugPrint('Time calculation error: $e');
      return time;
    }
  }

  Future<void> _saveSignature() async {
    if (_points.isEmpty) return;

    try {
      final RenderRepaintBoundary? boundary =
          _signatureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) throw Exception('Signature canvas not found');

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        _signatureBytes = byteData.buffer.asUint8List();
        setState(() => _signatureAdded = true);
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error capturing signature: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture signature: $e')),
        );
      }
    }
  }

  Future<void> _handleFinalSign() async {
    if (!_agreedToTerms || !_signatureAdded || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_signatureBytes == null || _signatureBytes!.isEmpty) {
        throw Exception('Signature data is missing. Please sign again.');
      }

      final Uint8List pngBytes = _signatureBytes!;
      final String timestamp =
          DateTime.now().millisecondsSinceEpoch.toString();
      final String path =
          'signatures/${authService.user?.uid}_musician_$timestamp.png';

      final String? signatureUrl =
          await authService.uploadData(pngBytes, path);
      if (signatureUrl == null || signatureUrl.isEmpty) {
        throw Exception(
            'Failed to upload signature to Storage - URL is null or empty');
      }

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.booking.id)
          .update({
        'status': 'Payment in escrow',
        'musicianSignedAt': FieldValue.serverTimestamp(),
        'musicianSignatureUrl': signatureUrl,
      });

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ContractSuccessScreen(
              gigTitle: widget.booking.gigTitle,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('SIGNATURE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing contract: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSignatureDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Draw Your Signature',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Sign with your finger or mouse',
                              style: TextStyle(
                                  color: Color(0xFF999999), fontSize: 13)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ),
                Container(
                    height: 1,
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFA1F301)
                                  .withValues(alpha: 0.3),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onPanStart: (d) => setModalState(
                                    () => _points.add(d.localPosition)),
                                onPanUpdate: (d) => setModalState(
                                    () => _points.add(d.localPosition)),
                                onPanEnd: (_) =>
                                    setModalState(() => _points.add(null)),
                                child: RepaintBoundary(
                                  key: _signatureKey,
                                  child: Container(
                                    color: Colors.transparent,
                                    width: double.infinity,
                                    height: 220,
                                    child: CustomPaint(
                                      painter: SignaturePainter(_points),
                                      size: Size.infinite,
                                    ),
                                  ),
                                ),
                              ),
                              if (_points.isEmpty)
                                const Center(
                                  child: Text('Sign here',
                                      style: TextStyle(
                                          color: Color(0xFF444444),
                                          fontSize: 16)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => _points.clear()),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                    child: Text('Clear',
                                        style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600))),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _saveSignature,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA1F301),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                    child: Text('Save Signature',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildImportantBanner(),
                    const SizedBox(height: 20),
                    _buildContractCard(),
                    const SizedBox(height: 24),
                    _buildAgreementCheckbox(),
                    const SizedBox(height: 24),
                    _buildSignatureSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Color(0xFF999999), size: 20),
                SizedBox(width: 6),
                Text('Back',
                    style:
                        TextStyle(color: Color(0xFF999999), fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2D0E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/application_icon.svg',
                    width: 32,
                    height: 32,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFA1F301),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Agreement',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.booking.gigTitle,
                      style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Important banner ────────────────────────────────────────────────────────

  Widget _buildImportantBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A0A),
        border: Border.all(
            color: const Color(0xFFD4A017).withValues(alpha: 0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: const Color(0xFFD4A017), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Important',
                style: TextStyle(
                  color: Color(0xFFD4A017),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Please read this contract carefully before signing. By signing, you agree to all terms and conditions.',
            style: TextStyle(color: Color(0xFF999999), fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Contract sections ───────────────────────────────────────────────────────

  // ── Single contract card ────────────────────────────────────────────────────

  Widget _buildContractCard() {
    final date = widget.booking.date;
    final formattedDate = widget.booking.gigDateText ?? '${_monthName(date.month)} ${date.day}, ${date.year}';
    final formattedTime = widget.booking.gigTimeText ?? _getTimeRange();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(widget.booking.id).snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> sections = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          sections = data['sections'] as Map<String, dynamic>? ?? {};
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111116),
            border: Border.all(
              color: const Color(0xFFA1F301).withValues(alpha: 0.2),
              width: 1.09,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Parties Involved
              _cardSectionTitle('1. Parties Involved'),
              const SizedBox(height: 10),
              _contractRow('Client:', widget.booking.organizerName),
              const SizedBox(height: 6),
              _contractRow('Performer:', widget.booking.contactName ?? 'Musician'),

              const SizedBox(height: 20),

              // Event Details
              _cardSectionTitle('2. Event Details'),
              const SizedBox(height: 10),
              _contractRow('Event:', widget.booking.gigTitle),
              const SizedBox(height: 6),
              _contractRow('Date:', formattedDate),
              const SizedBox(height: 6),
              _contractRow('Time:', formattedTime),
              const SizedBox(height: 6),
              _contractRow('Location:', widget.booking.location),

              const SizedBox(height: 20),

              // Compensation
              _cardSectionTitle('Compensation'),
              const SizedBox(height: 10),
              _contractRow(
                  'Total Fee:', '\$${widget.booking.pay.toStringAsFixed(2)} USD'),
              const SizedBox(height: 8),
              const Text(
                'Payment will be processed within 7 business days after event completion.',
                style: TextStyle(
                    color: Color(0xFF999999), fontSize: 13, height: 1.5),
              ),

              const SizedBox(height: 20),

              // Dynamic Sections from DB
              _dynamicSection('3. Musician Obligations', sections['musicianObligations'] ?? '1. The Performer agrees to provide live musical entertainment for the duration specified.\n2. The Performer will arrive at least 30 minutes before the performance start time for setup.\n3. Both parties agree to maintain professional conduct throughout the engagement.'),
              const SizedBox(height: 20),
              _dynamicSection('4. Organizer Obligations', sections['organizerObligations'] ?? '1. Provide access to performance venue.\n2. Ensure safe and suitable performance environment.\n3. Pay agreed compensation via escrow system.'),
              const SizedBox(height: 20),
              _dynamicSection('5. Payment Terms', sections['paymentTerms'] ?? 'Payment of \$${widget.booking.pay.toStringAsFixed(2)} will be held in escrow through the OnlyGigz platform.'),
              const SizedBox(height: 20),
              _dynamicSection('6. Cancellation Policy', sections['cancellationPolicy'] ?? 'Cancellations made less than 14 days before the event are subject to a 50% cancellation fee.'),
              const SizedBox(height: 20),
              _dynamicSection('7. Dispute Resolution', sections['disputeResolution'] ?? 'Any disputes will be mediated through the OnlyGigz platform support team.'),
            ],
          ),
        );
      }
    );
  }

  Widget _dynamicSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardSectionTitle(title),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(
              color: Color(0xFF999999), fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _cardSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _contractRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13),
        children: [
          TextSpan(
              text: '$label ',
              style: const TextStyle(color: Color(0xFF999999))),
          TextSpan(
              text: value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  // ── Agreement checkbox ──────────────────────────────────────────────────────

  Widget _buildAgreementCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111116),
          border: Border.all(
            color: const Color(0xFFA1F301).withValues(alpha: 0.2),
            width: 1.09,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: _agreedToTerms
                    ? const Color(0xFFA1F301)
                    : Colors.transparent,
                border: Border.all(
                  color: const Color(0xFFA1F301).withValues(alpha: 0.7),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: _agreedToTerms
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'I have read and agree to all terms and conditions outlined in this contract. I understand that my digital signature is legally binding and equivalent to a handwritten signature.',
                style: TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Signature section ───────────────────────────────────────────────────────

  Widget _buildSignatureSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111116),
        border: Border.all(
          color: const Color(0xFFA1F301).withValues(alpha: 0.2),
          width: 1.09,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Electronic Signature',
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Draw your signature below to digitally sign this contract.',
            style: TextStyle(
                color: Color(0xFF999999), fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _showSignatureDialog(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFA1F301).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _signatureAdded
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFFA1F301), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Signature Added',
                            style: TextStyle(
                              color: Color(0xFFA1F301),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              color: Color(0xFFA1F301), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Signature',
                            style: TextStyle(
                              color: Color(0xFFA1F301),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final bool canSign = _agreedToTerms && _signatureAdded && !_isSubmitting;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        border: Border(
          top: BorderSide(
              color: const Color(0xFF2A2A35).withValues(alpha: 0.6), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: canSign ? _handleFinalSign : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFA1F301),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.black, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            color: Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sign Contract Digitally',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (!canSign) ...[
            const SizedBox(height: 8),
            Text(
              _agreedToTerms
                  ? 'Please agree to terms and add your signature'
                  : 'Please agree to terms and add your signature',
              style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
