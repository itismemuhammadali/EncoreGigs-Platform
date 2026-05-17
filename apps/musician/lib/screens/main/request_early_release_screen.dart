import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RequestEarlyReleaseScreen extends StatefulWidget {
  const RequestEarlyReleaseScreen({super.key});

  @override
  State<RequestEarlyReleaseScreen> createState() => _RequestEarlyReleaseScreenState();
}

class _RequestEarlyReleaseScreenState extends State<RequestEarlyReleaseScreen> {
  String? _selectedReason;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Request Early Release', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            // Divider
            Container(height: 1, color: const Color(0xFFA1F301).withValues(alpha: 0.3)),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D4A1F).withValues(alpha: 0.4),
                        border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.4), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: const Color(0xFFA1F301), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Early Release Request', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(
                                  'This request will be reviewed by the organizer. If approved, funds will be released within 24 hours. If denied, payment will release on the scheduled date.',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Reason for Request
                    const Text('Reason for Request', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    _buildReasonOption('Gig Completed Early'),
                    const SizedBox(height: 12),
                    _buildReasonOption('Organizer Requested Release'),
                    const SizedBox(height: 12),
                    _buildReasonOption('Need Payment Urgently'),
                    const SizedBox(height: 12),
                    _buildReasonOption('All Contract Terms Met'),
                    const SizedBox(height: 12),
                    _buildReasonOption('Other Reason'),
                    const SizedBox(height: 28),

                    // Additional Notes
                    const Text('Additional Notes (Optional)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Provide any additional context for your request...',
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[800]!, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFA1F301), width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.grey[800]!, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA1F301),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/send_message_icon.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 8),
                            const Text('Submit Request', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w600)),
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

  Widget _buildReasonOption(String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => setState(() => _selectedReason = reason),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFFA1F301) : Colors.grey[800]!,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFA1F301) : Colors.grey[600]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFA1F301) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, color: Colors.black, size: 10),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              reason,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
