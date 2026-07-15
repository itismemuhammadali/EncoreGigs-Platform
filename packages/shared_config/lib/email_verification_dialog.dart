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
  bool _emailSent = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _sendVerification();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final verified = await widget.onCheckVerification();
      if (verified && mounted) {
        _pollTimer?.cancel();
        widget.onVerified();
      }
    });
  }

  Future<void> _sendVerification() async {
    setState(() { _isSending = true; _error = null; });
    final error = await widget.onSendVerification(widget.email);
    if (mounted) {
      setState(() { _isSending = false; _error = error; _emailSent = error == null; });
    }
  }

  Future<void> _checkAndContinue() async {
    setState(() { _isChecking = true; _error = null; });
    final verified = await widget.onCheckVerification();
    if (!mounted) return;
    setState(() { _isChecking = false; });
    if (verified) {
      _pollTimer?.cancel();
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
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
              onPressed: _isSending ? null : _sendVerification,
              child: _isSending
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFA2F301)))
                  : Text(_emailSent ? 'Resend Email' : 'Send Email', style: const TextStyle(color: Color(0xFFA2F301), fontSize: 13)),
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
