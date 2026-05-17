import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/application_model.dart';

class ApplicationCard extends StatelessWidget {
  final Application application;
  final VoidCallback onTap;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    application.gigTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusBackgroundColor(application.status),
                    border: Border.all(
                      color: _getStatusColor(application.status),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (application.status == ApplicationStatus.pending)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStatusColor(application.status),
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      else if (application.status == ApplicationStatus.hired)
                        SvgPicture.asset(
                          'assets/tick_icon.svg',
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            _getStatusColor(application.status),
                            BlendMode.srcIn,
                          ),
                        )
                      else
                        Icon(
                          _getStatusIcon(application.status),
                          color: _getStatusColor(application.status),
                          size: 14,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusLabel(application.status),
                        style: TextStyle(
                          color: _getStatusColor(application.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Artist Name
            Text(
              application.artistName,
              style: const TextStyle(
                color: Color(0xFF999999),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            // Pay and Date row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      '\$',
                      style: TextStyle(
                        color: Color(0xFFA1F301),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _displayRate(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF00BCD4), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(application.gigDate),
                      style: const TextStyle(
                        color: Color(0xFF00BCD4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Divider
            Container(
              height: 0.5,
              color: const Color(0xFFA1F301).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            // Applied date
            Text(
              'Applied on ${_formatDate(application.appliedDate)}',
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show proposedRate when hired (what the musician bid), otherwise fall back to pay (gig budget)
  String _displayRate() {
    if (application.status == ApplicationStatus.hired) {
      final rate = application.proposedRate.trim();
      if (rate.isNotEmpty && rate != 'TBD') {
        // Strip leading $ if present to avoid double dollar sign
        return rate.startsWith('\$') ? rate.substring(1) : rate;
      }
    }
    return application.pay;
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return const Color(0xFFB8860B);
      case ApplicationStatus.shortlisted:
        return const Color(0xFF00BCD4);
      case ApplicationStatus.hired:
        return const Color(0xFFA1F301);
      case ApplicationStatus.rejected:
        return const Color(0xFFFF6B6B);
    }
  }

  Color _getStatusBackgroundColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return const Color(0xFFB8860B).withValues(alpha: 0.15);
      case ApplicationStatus.shortlisted:
        return const Color(0xFF00BCD4).withValues(alpha: 0.15);
      case ApplicationStatus.hired:
        return const Color(0xFFA1F301).withValues(alpha: 0.15);
      case ApplicationStatus.rejected:
        return const Color(0xFFFF6B6B).withValues(alpha: 0.15);
    }
  }

  IconData _getStatusIcon(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return Icons.schedule;
      case ApplicationStatus.shortlisted:
        return Icons.schedule;
      case ApplicationStatus.hired:
        return Icons.check_circle_outline;
      case ApplicationStatus.rejected:
        return Icons.cancel_outlined;
    }
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
