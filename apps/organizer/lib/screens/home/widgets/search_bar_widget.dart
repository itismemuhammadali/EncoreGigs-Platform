import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    this.hint = 'Search gigs, venues, genres...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA2F301).withValues(alpha: 0.4)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Color(0xFF666666), size: 20),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
