import 'package:flutter/material.dart';
import '../../gigs/post_gig_screen.dart';
import '../../gigs/musician_search_screen.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback? onMessages;
  final VoidCallback? onPostGig;

  const ActionButtons({super.key, this.onMessages, this.onPostGig});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PostGigScreen()));
              onPostGig?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFA2F301),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add, color: Colors.black, size: 22),
                  SizedBox(height: 6),
                  Text(
                    'Post Gig',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MusicianSearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFA2F301).withValues(alpha: 0.4),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.search, color: Color(0xFFA2F301), size: 22),
                  SizedBox(height: 6),
                  Text(
                    'Find Talent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: onMessages,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A2A2F)),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
