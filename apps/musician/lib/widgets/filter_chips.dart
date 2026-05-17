import 'package:flutter/material.dart';

class FilterChips extends StatefulWidget {
  final Function(String) onFilterChanged;
  final String? selectedFilter;

  const FilterChips({
    super.key,
    required this.onFilterChanged,
    this.selectedFilter,
  });

  @override
  State<FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<FilterChips> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.selectedFilter ?? 'All';
  }

  @override
  void didUpdateWidget(FilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter && widget.selectedFilter != null) {
      _selectedFilter = widget.selectedFilter!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', 'Nearby', 'This Week', 'High Badge'].map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
                widget.onFilterChanged(filter);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFA1F301) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFFA1F301) : Colors.grey[700]!,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
