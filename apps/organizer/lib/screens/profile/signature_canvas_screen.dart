import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class SignatureCanvasScreen extends StatefulWidget {
  final String contractTitle;
  final String bookingId;

  const SignatureCanvasScreen({
    super.key,
    required this.contractTitle,
    required this.bookingId,
  });

  @override
  State<SignatureCanvasScreen> createState() => _SignatureCanvasScreenState();
}

class _SignatureCanvasScreenState extends State<SignatureCanvasScreen> {
  late List<Offset?> _points;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _points = [];
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _handleSignatureAndPayment() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // 1. Fetch booking details to get the amount
      final bookingDoc = await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');
      
      final bookingData = bookingDoc.data()!;
      final double amount = (bookingData['amount'] ?? 0).toDouble();
      final String organizerId = authService.currentUser?.uid ?? '';

      // 2. Create Deposit from wallet (deducts balance, sets escrow to held)
      final depositResult = await apiService.createDeposit(
        widget.bookingId,
        organizerId,
        amount,
        '',
      );

      if (depositResult['status'] != 'held') {
        throw Exception(depositResult['message'] ?? 'Failed to hold funds in escrow');
      }

      // 3. Update Firestore with signature
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'organizerSignedAt': FieldValue.serverTimestamp(),
        'status': 'Payment in escrow',
      });

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed('/contract-signed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0F),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x4DA2F301), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Sign & Fund Gig',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sign to release funds to escrow',
                        style: TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: const Color(0x4DA2F301),
            ),
            // Signature canvas
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0F),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFA2F301),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: RepaintBoundary(
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            if (_isSaving) return;
                            setState(() {
                              _points.add(details.localPosition);
                            });
                          },
                          onPanEnd: (details) {
                            if (_isSaving) return;
                            setState(() {
                              _points.add(null);
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            child: CustomPaint(
                              painter: SignaturePainter(_points),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_points.isEmpty)
                      IgnorePointer(
                        child: Center(
                          child: Text(
                            'Sign here to authorize payment',
                            style: TextStyle(
                              color: const Color(0xFF888888).withOpacity(0.5),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    if (_isSaving)
                      const Center(
                        child: CircularProgressIndicator(color: Color(0xFFA2F301)),
                      ),
                  ],
                ),
              ),
            ),
            // Security Note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Color(0xFF888888), size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Funds will be held securely by OnlyGigz until gig completion.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  // Clear button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaving ? null : _clearSignature,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1F),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFF3B30).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.delete_outline,
                              color: Color(0xFFFF3B30),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Clear',
                              style: TextStyle(
                                color: Color(0xFFFF3B30),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Save Signature & Pay button
                  Expanded(
                    child: GestureDetector(
                      onTap: _isSaving ? null : _handleSignatureAndPayment,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA2F301),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.payment,
                              color: Colors.black,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sign & Pay',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA2F301)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
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
