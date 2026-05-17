import 'package:flutter/material.dart';
import '../models/application_model.dart';

class StatusFilterChips extends StatefulWidget {
  final Function(ApplicationStatus?) onStatusSelected;
  final ApplicationStatus? selectedStatus;

  const StatusFilterChips({
    super.key,
    required this.onStatusSelected,
    this.selectedStatus,
  });

  @override
  State<StatusFilterChips> createState() => _StatusFilterChipsState();
}

class _StatusFilterChipsState extends State<StatusFilterChips> {
  late ApplicationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
  }

  @override
  void didUpdateWidget(StatusFilterChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStatus != widget.selectedStatus) {
      _selectedStatus = widget.selectedStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedStatus = null);
                widget.onStatusSelected(null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedStatus == null ? const Color(0xFFA1F301) : Colors.transparent,
                  border: Border.all(
                    color: _selectedStatus == null ? const Color(0xFFA1F301) : const Color(0xFF333333),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'All',
                  style: TextStyle(
                    color: _selectedStatus == null ? Colors.black : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          ...ApplicationStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedStatus = status);
                  widget.onStatusSelected(status);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFA1F301) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFFA1F301) : const Color(0xFF333333),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusLabel(status),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getStatusLabel(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.shortlisted:
        return 'Shortlisted';
      case ApplicationStatus.hired:
        return 'Hired';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}
