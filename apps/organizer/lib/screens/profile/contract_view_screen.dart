import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signature_canvas_screen.dart';

class ContractViewScreen extends StatelessWidget {
  final String bookingId;
  final String? title; // Optional fallback
  final String? date;  // Optional fallback

  const ContractViewScreen({
    super.key,
    required this.bookingId,
    this.title,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(bookingId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0F),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFA2F301))),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0F),
            appBar: AppBar(backgroundColor: const Color(0xFF0A0A0F)),
            body: const Center(child: Text('Contract not found', style: TextStyle(color: Colors.white))),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String gigTitle = data['gigTitle'] ?? 'Unnamed Gig';
        final String musicianName = data['musicianName'] ?? 'Musician';
        final String organizerName = data['organizerName'] ?? 'Organizer';
        
        final String gigDate = data['gigDate'] ?? data['gigdate'] ?? 'N/A';
        final String gigTime = data['gigTime'] ?? 'N/A';
        final String location = data['location'] ?? 'N/A';
        final String amount = (data['amount'] ?? 0).toString();
        
        final bool musicianSigned = data['musicianSignedAt'] != null;
        final bool organizerSigned = data['organizerSignedAt'] != null;
        final bool isFullySigned = musicianSigned && organizerSigned;

        final Map<String, dynamic> sections = data['sections'] as Map<String, dynamic>? ?? {};

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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
              ),
            ),
            title: const Text(
              'Performance Contract',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contract header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1A1F),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/application_icon.svg',
                            width: 26,
                            height: 26,
                            colorFilter: const ColorFilter.mode(
                                Color(0xFFA2F301), BlendMode.srcIn),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Musician Performance\nAgreement',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isFullySigned ? 'Fully Signed' : 'Pending Signatures',
                            style: const TextStyle(color: Color(0xFFA2F301), fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Contract body
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('1. Parties',
                            'This agreement is made between $organizerName ("Organizer") and $musicianName ("Musician") for the performance at $gigTitle.'),
                        _buildPerformanceDetails(gigDate, gigTime, location, amount),
                        
                        _buildSection('3. Musician Obligations',
                            sections['musicianObligations'] ?? 'Arrive 30 minutes prior to performance time\nPerform for the agreed duration\nProvide professional-quality performance\nBring necessary equipment or use venue-provided instruments'),
                        
                        _buildSection('4. Organizer Obligations',
                            sections['organizerObligations'] ?? 'Provide access to performance venue\nEnsure safe and suitable performance environment\nPay agreed compensation via escrow system\nRelease payment within 48 hours of performance completion'),
                        
                        _buildSection('5. Payment Terms',
                            sections['paymentTerms'] ?? 'Payment of \$$amount will be held in escrow through the OnlyGigz platform. Funds will be released to the Musician within 48 hours after the Organizer confirms successful performance completion.'),
                        
                        _buildSection('6. Cancellation Policy',
                            sections['cancellationPolicy'] ?? 'Either party may cancel up to 7 days before the performance date without penalty. Cancellations within 7 days require mutual agreement or may result in partial payment.'),
                        
                        _buildSection('7. Dispute Resolution',
                            sections['disputeResolution'] ?? 'Any disputes will be mediated through the OnlyGigz platform support team before pursuing other legal remedies.',
                            isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Footer note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA2F301).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4DA2F301)),
                    ),
                    child: const Text(
                      'By signing this contract, both parties agree to the terms and conditions outlined above. Digital signatures are legally binding.',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 13, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: isFullySigned 
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA2F301).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA2F301)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFFA2F301), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Signed Contract',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFA2F301),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: () {
                    if (organizerSigned) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('You have already signed this contract.')),
                      );
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (_) => SignatureCanvasScreen(
                        contractTitle: gigTitle,
                        bookingId: bookingId,
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: organizerSigned ? const Color(0xFF1A1A1F) : const Color(0xFFA2F301),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      organizerSigned ? 'Awaiting Musician Signature' : 'Sign Contract',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: organizerSigned ? Colors.white54 : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          ),
        );
      }
    );
  }

  Widget _buildSection(String title, String content, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.7,
          ),
        ),
        if (!isLast) const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPerformanceDetails(String date, String time, String location, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Performance Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _boldLine('Date:', date),
        _boldLine('Time:', time),
        _boldLine('Location:', location),
        _boldLine('Compensation:', '\$$amount'),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _boldLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, height: 1.7, color: Colors.white),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
