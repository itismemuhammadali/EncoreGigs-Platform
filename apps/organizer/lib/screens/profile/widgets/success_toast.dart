import 'package:flutter/material.dart';

class SuccessToast {
  static void show(BuildContext context, String message, {VoidCallback? onComplete}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 120,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0x1A00C950),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF00C950), width: 1.5),
            ),
            child: Center(
              child: Text(
                '✓  Payment Released Successfully!',
                style: const TextStyle(
                  color: Color(0xFF00C950),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
      if (onComplete != null) {
        onComplete();
      }
    });
  }
}
