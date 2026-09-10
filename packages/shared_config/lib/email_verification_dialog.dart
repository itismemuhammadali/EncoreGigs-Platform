import 'dart:async';
import 'package:flutter/material.dart';

class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;
  final Future<String?> Function(String email) onSendVerification;
  final Future<bool> Function() onCheckVerification;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.onVerified,
    required this.onSendVerification,
    required this.onCheckVerification,
  });

  @override
  State<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _error;
  String? _successMessage;
  bool _emailSent = false;
  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _sendVerification(isInitial: true);
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final verified = await widget.onCheckVerification();
      if (verified && mounted) {
        _pollTimer?.cancel();
        _cooldownTimer?.cancel();
        widget.onVerified();
      }
    });
  }

  void _startCooldown([int seconds = 60]) {
    setState(() { _resendCooldown = seconds; });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 1) {
          _resendCooldown--;
        } else {
          _resendCooldown = 0;
          timer.cancel();
        }
      });
    });
  }

  static String _formatErrorMessage(String text) {
    final upper = text.toUpperCase();
    if (upper.contains('TOO_MANY_ATTEMPTS') ||
        upper.contains('TOO-MANY-REQUESTS') ||
        upper.contains('TOO_MANY_REQUESTS') ||
        upper.contains('TOO MANY ATTEMPTS')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }
    // Strip common bracketed prefixes like [firebase_auth/too-many-requests]
    String cleaned = text.replaceAll(RegExp(r'\[.*?\]'), '').trim();
    if (cleaned.isEmpty) cleaned = text;
    // Strip any raw underscores so technical error codes look clean
    return cleaned.replaceAll('_', ' ');
  }

  Future<void> _sendVerification({bool isInitial = false}) async {
    if (_resendCooldown > 0 && !isInitial) return;

    setState(() {
      _isSending = true;
      _error = null;
      _successMessage = null;
    });

    var error = await widget.onSendVerification(widget.email);

    if (mounted) {
      setState(() {
        _isSending = false;
        if (isInitial) {
          // On initial dialog open, NEVER display an error box to a newly registered user
          _error = null;
          _emailSent = true;
        } else {
          // On manual resend, display error only if genuine failure, or show success
          if (error != null) {
            _error = _formatErrorMessage(error);
          } else {
            _successMessage = 'Verification email sent! Please check your inbox.';
            _emailSent = true;
          }
        }
      });
      if (!isInitial && error == null) {
        _startCooldown(60);
      }
    }
  }

  Future<void> _checkAndContinue() async {
    setState(() { _isChecking = true; _error = null; _successMessage = null; });
    final verified = await widget.onCheckVerification();
    if (!mounted) return;
    setState(() { _isChecking = false; });
    if (verified) {
      _pollTimer?.cancel();
      _cooldownTimer?.cancel();
      widget.onVerified();
    } else {
      setState(() { _error = 'Email not verified yet. Please check your inbox and click the verification link.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFA2F301).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_unread_outlined, color: Color(0xFFA2F301), size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Verify Your Email',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'A verification email has been sent to',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your inbox and click the verification link, then come back and tap "I\'ve Verified".',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (_successMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA2F301).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _successMessage!,
                  style: const TextStyle(color: Color(0xFFA2F301), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatErrorMessage(_error!),
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkAndContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA2F301),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isChecking
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text("I've Verified", style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: (_isSending || _resendCooldown > 0) ? null : () => _sendVerification(isInitial: false),
              child: _isSending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA2F301)))
                  : Text(
                      _resendCooldown > 0
                          ? 'Resend Email (${_resendCooldown}s)'
                          : (_emailSent ? 'Resend Email' : 'Send Email'),
                      style: TextStyle(
                        color: _resendCooldown > 0 ? Colors.grey : const Color(0xFFA2F301),
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void showEmailVerificationDialog({
  required BuildContext context,
  required String email,
  required VoidCallback onVerified,
  required Future<String?> Function(String email) onSendVerification,
  required Future<bool> Function() onCheckVerification,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => EmailVerificationDialog(
      email: email,
      onVerified: onVerified,
      onSendVerification: onSendVerification,
      onCheckVerification: onCheckVerification,
    ),
  );
}
