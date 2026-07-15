import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AddBankAccountScreen extends StatefulWidget {
  const AddBankAccountScreen({super.key});

  @override
  State<AddBankAccountScreen> createState() => _AddBankAccountScreenState();
}

class _AddBankAccountScreenState extends State<AddBankAccountScreen> {
  bool _isLoading = false;
  bool _onboardingStarted = false;

  Future<void> _startOnboarding() async {
    setState(() { _isLoading = true; _onboardingStarted = true; });
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final musicianId = authService.currentUser?.uid;
      if (musicianId == null) throw Exception('User not logged in');

      final response = await apiService.onboardMusician(
        musicianId,
        'https://httpbin.org/status/200',
        'https://httpbin.org/status/200',
      );

      final url = Uri.parse(response['onboardingUrl']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not open onboarding link');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _onboardingStarted = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  const Text('Connect Bank Account', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Required to receive payouts', style: TextStyle(color: Colors.grey[500]!, fontSize: 14)),
                ],
              ),
            ),
            Container(height: 1, color: const Color(0xFFA1F301).withValues(alpha: 0.3)),
            Expanded(
              child: _onboardingStarted
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFFA1F301)),
                        const SizedBox(height: 20),
                        const Text('Waiting for Stripe onboarding...', style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 12),
                        Text('Complete the steps in your browser, then come back here.',
                            style: TextStyle(color: Colors.grey[400]!, fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: () {
                            setState(() => _onboardingStarted = false);
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA1F301),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Done - Back to App', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA1F301).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/bank_icon2.svg',
                              width: 50,
                              height: 50,
                              colorFilter: const ColorFilter.mode(Color(0xFFA1F301), BlendMode.srcIn),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text('Connect your bank account', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(
                          'You need to connect a bank account to receive payouts from gigs. You will be redirected to Stripe to securely provide your banking information.',
                          style: TextStyle(color: Colors.grey[400]!, fontSize: 15, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        _buildInfoPoint(Icons.account_balance, 'Bank Account Required', 'Payments are sent directly to your bank account.'),
                        const SizedBox(height: 20),
                        _buildInfoPoint(Icons.speed, 'Fast Payouts', 'Funds arrive within 2-3 business days after gig completion.'),
                        const SizedBox(height: 20),
                        _buildInfoPoint(Icons.lock, 'Secure', 'Your banking details are handled by Stripe, never stored in our app.'),
                      ],
                    ),
                  ),
            ),
            if (!_onboardingStarted)
              Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: _isLoading ? null : _startOnboarding,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _isLoading ? const Color(0xFF2A2A2F) : const Color(0xFFA1F301),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text('Continue to Stripe', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPoint(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFA1F301), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[500]!, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
