import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

enum NotificationType { application, message, payment, booking, gig, system }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final NotificationType type;
  bool isRead;
  bool isUnread;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
    this.isUnread = false,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final category = map['category'] ?? 'system';
    final typeMap = {
      'application': NotificationType.application,
      'message': NotificationType.message,
      'payment': NotificationType.payment,
      'booking': NotificationType.booking,
      'gig': NotificationType.gig,
      'system': NotificationType.system,
    };
    final createdAt = map['createdAt'];
    String timeAgo = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) timeAgo = '${diff.inMinutes}m ago';
        else if (diff.inHours < 24) timeAgo = '${diff.inHours}h ago';
        else timeAgo = '${diff.inDays}d ago';
      } catch (_) {
        timeAgo = '';
      }
    }
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timeAgo: timeAgo,
      type: typeMap[category] ?? NotificationType.system,
      isRead: map['isRead'] ?? false,
      isUnread: !(map['isRead'] ?? false),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;
  bool _loading = true;
  final List<AppNotification> _notifications = [];
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final data = await _api.getNotifications(user.uid);
      setState(() {
        _notifications.clear();
        _notifications.addAll(data.map((m) => AppNotification.fromMap(m)));
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<AppNotification> get _filtered =>
      _showUnreadOnly ? _notifications.where((n) => n.isUnread).toList() : _notifications;

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.application: return const Color(0xFFA1F301);
      case NotificationType.message:     return const Color(0xFF00BCD4);
      case NotificationType.payment:     return const Color(0xFFF0B100);
      case NotificationType.booking:     return const Color(0xFFFF6B9D);
      case NotificationType.gig:         return const Color(0xFF9B59B6);
      case NotificationType.system:      return const Color(0xFF999999);
    }
  }

  Color _getCardBackground(NotificationType type, bool isUnread) {
    if (!isUnread) return Colors.transparent;
    switch (type) {
      case NotificationType.application: return const Color(0xFFA1F301).withValues(alpha: 0.08);
      case NotificationType.message:     return const Color(0xFF00BCD4).withValues(alpha: 0.08);
      case NotificationType.payment:     return const Color(0xFFF0B100).withValues(alpha: 0.08);
      case NotificationType.booking:     return const Color(0xFFFF6B9D).withValues(alpha: 0.08);
      case NotificationType.gig:         return const Color(0xFF9B59B6).withValues(alpha: 0.08);
      case NotificationType.system:      return Colors.transparent;
    }
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.application: return 'application';
      case NotificationType.message:     return 'message';
      case NotificationType.payment:     return 'payment';
      case NotificationType.booking:     return 'booking';
      case NotificationType.gig:         return 'gig';
      case NotificationType.system:      return 'system';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFA1F301).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        SizedBox(width: 6),
                        Text('Back', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Notifications',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$_unreadCount unread notifications',
                      style: const TextStyle(color: Color(0xFF999999), fontSize: 14)),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFA1F301)))
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      color: const Color(0xFFA1F301),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await _api.markAllNotificationsRead(user.uid);
                                  setState(() {
                                    for (var n in _notifications) { n.isUnread = false; }
                                  });
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA1F301).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.done_all, color: Color(0xFFA1F301), size: 18),
                                    SizedBox(width: 8),
                                    Text('Mark All Read',
                                        style: TextStyle(color: Color(0xFFA1F301), fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _showUnreadOnly = false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_showUnreadOnly ? const Color(0xFFA1F301) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'All (${_notifications.length})',
                                          style: TextStyle(
                                            color: !_showUnreadOnly ? Colors.black : const Color(0xFF999999),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _showUnreadOnly = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _showUnreadOnly ? const Color(0xFFA1F301) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Unread ($_unreadCount)',
                                          style: TextStyle(
                                            color: _showUnreadOnly ? Colors.black : const Color(0xFF999999),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_notifications.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Text('No notifications yet', style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
                              ),
                            ..._filtered.map((notification) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () async {
                                  if (notification.isUnread) {
                                    await _api.markNotificationRead(notification.id);
                                    setState(() {
                                      notification.isUnread = false;
                                      notification.isRead = true;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _getCardBackground(notification.type, notification.isUnread),
                                    border: Border.all(
                                      color: notification.isUnread
                                          ? _getTypeColor(notification.type).withValues(alpha: 0.4)
                                          : const Color(0xFFA1F301).withValues(alpha: 0.15),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (notification.isUnread)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(top: 4),
                                              decoration: BoxDecoration(
                                                color: _getTypeColor(notification.type),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notification.body,
                                        style: const TextStyle(color: Color(0xFF999999), fontSize: 13, height: 1.5),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(notification.timeAgo,
                                              style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getTypeColor(notification.type).withValues(alpha: 0.15),
                                              border: Border.all(
                                                color: _getTypeColor(notification.type).withValues(alpha: 0.4),
                                                width: 1,
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _getTypeLabel(notification.type),
                                              style: TextStyle(
                                                color: _getTypeColor(notification.type),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
