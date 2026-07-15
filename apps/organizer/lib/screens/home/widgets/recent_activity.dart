import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onlygigz_organizer/services/api_service.dart';
import '../../messages/chat/chat_screen.dart';
import '../../gigs/musician_profile_screen.dart';
import '../../profile/booking_details_screen.dart';
import '../../../services/chat_service.dart';
import '../../../models/chat_model.dart';
import '../../../services/auth_service.dart';
import '../../../constants.dart';

import '../../../models/gig.dart';
import '../../gigs/gig_details_screen.dart';

enum ActivityType { application, message, signature, gig }

class ActivityItem {
  final String id;
  final String imageAsset;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final ActivityType type;
  final Map<String, dynamic> metadata;

  const ActivityItem({
    required this.id,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.metadata = const {},
  });
}

class RecentActivity extends StatefulWidget {
  const RecentActivity({super.key});

  @override
  State<RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<RecentActivity> {
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final data = await apiService.getRecentActivity(currentUserId);
      if (mounted) setState(() { _activities = data; _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading activity: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Provider.of<AuthService>(context, listen: false).user?.uid;

    if (currentUserId == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFFA2F301)))
        else if (_activities.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No recent activity', style: TextStyle(color: Color(0xFF666666))),
          )
        else
          Builder(
            builder: (context) {
              final data = _activities;
              if (data.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No recent activity', style: TextStyle(color: Color(0xFF666666))),
                );
              }

            final activities = data.map((item) {
              ActivityType type;
              switch (item['type']) {
                case 'application': type = ActivityType.application; break;
                case 'message': type = ActivityType.message; break;
                case 'signature': type = ActivityType.signature; break;
                case 'gig': type = ActivityType.gig; break;
                default: type = ActivityType.application;
              }

              DateTime timestamp = DateTime.now();
              if (item['timestamp'] != null) {
                // Handle both Firestore Timestamp and ISO String from backend
                if (item['timestamp'] is Map && item['timestamp']['seconds'] != null) {
                   timestamp = DateTime.fromMillisecondsSinceEpoch(item['timestamp']['seconds'] * 1000);
                } else {
                   timestamp = DateTime.tryParse(item['timestamp'].toString()) ?? DateTime.now();
                }
              }

              return ActivityItem(
                id: item['id'] ?? '',
                imageAsset: fixEmulatorUrl(item['imageAsset'] ?? ''),
                title: item['title'] ?? '',
                subtitle: item['subtitle'] ?? '',
                timestamp: timestamp,
                type: type,
                metadata: Map<String, dynamic>.from(item['metadata'] ?? {}),
              );
            }).toList();

              return Column(
                children: activities.map((item) => _ActivityCard(item: item)).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final ActivityItem item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleNavigation(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1F),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _getBorderColor().withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTimestamp(item.timestamp),
              style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: item.imageAsset.isNotEmpty && item.imageAsset.startsWith('http')
          ? Image.network(
              item.imageAsset,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _placeholderAvatar(),
            )
          : (item.imageAsset.isNotEmpty
              ? Image.asset(
                  item.imageAsset,
                  width: 46,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _placeholderAvatar(),
                )
              : _placeholderAvatar()),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2F),
        shape: BoxShape.circle,
      ),
      child: Icon(_getIcon(), color: _getBorderColor(), size: 20),
    );
  }

  IconData _getIcon() {
    switch (item.type) {
      case ActivityType.application: return Icons.person_add_outlined;
      case ActivityType.message: return Icons.chat_bubble_outline;
      case ActivityType.signature: return Icons.assignment_turned_in_outlined;
      case ActivityType.gig: return Icons.campaign_outlined;
    }
  }

  Color _getBorderColor() {
    switch (item.type) {
      case ActivityType.application: return const Color(0xFF4A9EFF);
      case ActivityType.message: return const Color(0xFFA2F301);
      case ActivityType.signature: return const Color(0xFFFFB347);
      case ActivityType.gig: return const Color(0xFFA2F301);
    }
  }

  Color _getTextColor() {
    switch (item.type) {
      case ActivityType.application: return const Color(0xFF4A9EFF);
      case ActivityType.message: return const Color(0xFF888888);
      case ActivityType.signature: return const Color(0xFFA2F301);
      case ActivityType.gig: return const Color(0xFFA2F301);
    }
  }

  String _formatTimestamp(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _handleNavigation(BuildContext context) {
    switch (item.type) {
      case ActivityType.gig:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GigDetailsScreen(
            gig: GigModel.fromFirestore(item.metadata, item.id),
          ),
        ));
        break;
      case ActivityType.application:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MusicianProfileScreen(
            musicianId: item.metadata['musicianId'] ?? '',
            gigId: item.metadata['gigId'],
            gigTitle: item.metadata['gigTitle'],
            gigBudget: item.metadata['gigBudget'],
            gigDate: item.metadata['gigDate'],
            gigTime: item.metadata['gigTime'],
            proposedRate: item.metadata['proposedRate'],
            coverMessage: item.metadata['coverMessage'],
          ),
        ));
        break;
      case ActivityType.message:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: item.id,
            otherUserId: item.metadata['otherUserId'] ?? '',
            name: item.metadata['otherName'] ?? '',
            imagePath: item.metadata['otherImage'] ?? '',
          ),
        ));
        break;
      case ActivityType.signature:
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(
            bookingId: item.id,
            title: item.metadata['gigTitle'] ?? '',
            musician: item.metadata['musicianName'] ?? '',
            imagePath: item.metadata['musicianImage'] ?? '',
            status: item.metadata['status'] ?? '',
            date: item.metadata['gigDate'] ?? '',
            time: item.metadata['gigTime'] ?? '',
            location: item.metadata['location'] ?? '',
            amount: '\$${item.metadata['amount']}',
            paymentStatus: 'Escrow',
            musicianId: item.metadata['musicianId'] ?? '',
          ),
        ));
        break;
    }
  }
}

// Simple helper to merge streams without RxDart
class RxStreamMerger {
  static Stream<List<ActivityItem>> merge(List<Stream<List<ActivityItem>>> streams) {
    // We use StreamGroup-like functionality using CombineLatestStream logic
    // But since we want real-time updates from any, and merged sorted list:
    
    // We'll use a multi-stream listener that emits a sorted list of all latest items
    final controller = StreamController<List<ActivityItem>>();
    final List<List<ActivityItem>> latestLists = List.generate(streams.length, (_) => []);
    
    for (int i = 0; i < streams.length; i++) {
      streams[i].listen((list) {
        latestLists[i] = list;
        final merged = latestLists.expand((x) => x).toList();
        merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        controller.add(merged);
      });
    }
    
    return controller.stream;
  }
}
