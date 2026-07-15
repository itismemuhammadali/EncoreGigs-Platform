import 'package:flutter/material.dart';

class GigsFilterTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const GigsFilterTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _tabs = ['All', 'Active', 'Closed', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final isActive = tab == selected;
          return GestureDetector(
            onTap: () => onSelected(tab),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFA2F301) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isActive ? Colors.black : const Color(0xFF888888),
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
