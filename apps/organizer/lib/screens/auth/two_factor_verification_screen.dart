import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  final String email;
  final String uid;
  final String? phoneNumber;
  final String userRole; // "musician" or "organizer"

  const TwoFactorVerificationScreen({
    super.key,
    required this.email,
    required this.uid,
    required this.phoneNumber,
    required this.userRole,
  });

  @override
  State<TwoFactorVerificationScreen> createState() => _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState extends State<TwoFactorVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _useSms = false;
  String? _verificationId;
  int? _resendToken;
  
  // Cooldown state
  int _cooldownSecondsRemaining = 0;
  Timer? _cooldownTimer;
  bool _isFirstAttempt = true;  // Track if first OTP send

  @override
  void initState() {
    super.initState();
    // Send email OTP by default
    _sendEmailOtp();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    
    // 60 seconds for first attempt, 30 seconds for resends
    final secondsToWait = _isFirstAttempt ? 60 : 30;
    
    setState(() => _cooldownSecondsRemaining = secondsToWait);
    
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _cooldownSecondsRemaining--;
          if (_cooldownSecondsRemaining <= 0) {
            timer.cancel();
            _cooldownSecondsRemaining = 0;
          }
        });
      }
    });
    
    // Mark first attempt as done after first OTP send
    if (_isFirstAttempt) {
      _isFirstAttempt = false;
    }
  }

  Future<void> _sendEmailOtp() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.sendEmailOtp(widget.email, widget.uid);
    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Verification link sent to your email!')));
      _startCooldown();
    }
  }

  Future<void> _switchToSms() async {
    if (widget.phoneNumber == null || widget.phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number saved for this account.')),
      );
      return;
    }

    setState(() {
      _useSms = true;
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.sendSmsOtp(
      widget.phoneNumber!,
      resendToken: _resendToken,
      codeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent via SMS!')));
          _startCooldown();
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed')));
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (mounted) setState(() => _verificationId = verificationId);
      },
    );
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the OTP')));
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    String? error;

    if (_useSms) {
      if (_verificationId == null) {
        error = 'Please wait for the SMS to be sent.';
      } else {
        error = await authService.verifySmsOtp(_verificationId!, code);
      }
    } else {
      error = await authService.verifyEmailOtp(widget.email, code);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (error == null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('2FA Verification', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await Provider.of<AuthService>(context, listen: false).signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading section
                      Text(
                        'Verify Your Identity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _useSms ? 'Enter the code sent to your phone' : 'Check your email for verification link',
                        style: TextStyle(color: Colors.grey[400], fontSize: 15),
                      ),
                      const SizedBox(height: 48),

                      // Method Selection Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFA1F301).withValues(alpha: 0.3), width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                          color: const Color(0xFF1A1A1F),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFA1F301).withValues(alpha: 0.15),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _useSms ? Icons.sms : Icons.mail,
                                      color: const Color(0xFFA1F301),
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _useSms ? 'SMS Verification' : 'Email Verification',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _useSms
                                            ? 'Code sent to ${widget.phoneNumber ?? 'your phone'}'
                                            : 'Link sent to ${widget.email}',
                                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA1F301).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _useSms
                                    ? 'Enter the 6-digit code below'
                                    : 'Click the link in your email to verify',
                                style: const TextStyle(
                                  color: Color(0xFFA1F301),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // OTP Input - Shown ONLY for SMS Verification
                      if (_useSms) ...[
                        Text(
                          'Enter Code',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            letterSpacing: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF1A1A24),
                            hintText: '000000',
                            hintStyle: TextStyle(color: Colors.grey[700]),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[700]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[700]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFFA1F301), width: 2.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Resend/Method Switch
                      Center(
                        child: GestureDetector(
                          onTap: (_isLoading || _cooldownSecondsRemaining > 0)
                              ? null
                              : () {
                                  if (_useSms) {
                                    _sendEmailOtp();
                                    setState(() => _useSms = false);
                                  } else if (!_useSms && widget.phoneNumber != null) {
                                    _switchToSms();
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Text(
                              _cooldownSecondsRemaining > 0
                                  ? 'Resend in ${_cooldownSecondsRemaining}s'
                                  : (_useSms
                                      ? 'Verify via Email instead'
                                      : (widget.phoneNumber != null ? 'Verify via SMS instead' : 'No SMS available')),
                              style: TextStyle(
                                color: (_isLoading || _cooldownSecondsRemaining > 0)
                                    ? Colors.grey[600]
                                    : const Color(0xFFA1F301),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                decoration: (_isLoading || _cooldownSecondsRemaining > 0)
                                    ? null
                                    : TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom buttons - Fixed
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  if (_useSms) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || _otpController.text.isEmpty ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA1F301),
                          disabledBackgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Verify',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _sendEmailOtp(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA1F301),
                          disabledBackgroundColor: Colors.grey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Resend Link',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
