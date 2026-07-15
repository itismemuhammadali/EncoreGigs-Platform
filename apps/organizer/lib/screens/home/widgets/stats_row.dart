import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import 'package:onlygigz_organizer/services/api_service.dart';

class StatsRow extends StatefulWidget {
  const StatsRow({super.key});

  @override
  State<StatsRow> createState() => _StatsRowState();
}

class _StatsRowState extends State<StatsRow> {
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) return;
    
    try {
      final stats = await apiService.getDashboardStats(currentUserId);
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats ?? {
      "activeGigs": 0,
      "totalApplications": 0,
      "totalBookings": 0
    };

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            iconPath: 'assets/bookings_icon.svg',
            iconColor: const Color(0xFFA2F301),
            value: '${stats["activeGigs"]}',
            label: 'Active Gigs',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            iconPath: 'assets/users_icon.svg',
            iconColor: const Color(0xFF4A9EFF),
            value: '${stats["totalApplications"]}',
            label: 'Applications',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            iconPath: 'assets/bookings_icon.svg',
            iconColor: const Color(0xFFFFB347),
            value: '${stats["totalBookings"]}',
            label: 'Bookings',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String? iconPath;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    this.iconPath,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: iconPath != null
                  ? SvgPicture.asset(
                      iconPath!,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                    )
                  : const SizedBox(),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
