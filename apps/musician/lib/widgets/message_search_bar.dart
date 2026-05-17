import 'package:flutter/material.dart';

class MessageSearchBar extends StatelessWidget {
  final Function(String) onChanged;

  const MessageSearchBar({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search messages...',
        hintStyle: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF666666),
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFA1F301),
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
