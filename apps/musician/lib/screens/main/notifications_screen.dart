import 'package:flutter/material.dart';

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
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showUnreadOnly = false;

  final List<AppNotification> _notifications = [
    AppNotification(id: '1', title: 'Application Accepted! 🎉', body: 'TechCorp Events has accepted your application for Corporate Event Entertainment.', timeAgo: '2 hours ago', type: NotificationType.application, isUnread: true),
    AppNotification(id: '2', title: 'New Message', body: 'Emily sent you a message about the Wedding Reception gig.', timeAgo: '5 hours ago', type: NotificationType.message, isUnread: true),
    AppNotification(id: '3', title: 'Payment Received', body: 'You\'ve received \$1,200 for the Jazz Night at Blue Moon performance.', timeAgo: '1 day ago', type: NotificationType.payment),
    AppNotification(id: '4', title: 'Upcoming Gig Reminder', body: 'Your performance at Bar Acoustic Session is tomorrow at 8:00 PM.', timeAgo: '1 day ago', type: NotificationType.booking, isUnread: true),
    AppNotification(id: '5', title: 'New Gig Match', body: '3 new gigs match your preferences in Brooklyn, NY.', timeAgo: '2 days ago', type: NotificationType.gig),
    AppNotification(id: '6', title: 'Profile Verified', body: 'Congratulations! Your profile has been verified. You can now apply for premium gigs.', timeAgo: '3 days ago', type: NotificationType.system),
    AppNotification(id: '7', title: 'Application Status Update', body: 'SoundWave Productions is reviewing your application for Rock Festival Opening Act.', timeAgo: '4 days ago', type: NotificationType.application),
    AppNotification(id: '8', title: 'New Message', body: 'Blue Moon Events sent you contract details.', timeAgo: '5 days ago', type: NotificationType.message),
  ];

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
            // Header
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Mark All Read button
                    GestureDetector(
                      onTap: () => setState(() {
                        for (var n in _notifications) { n.isUnread = false; }
                      }),
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

                    // Filter tabs
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

                    // Notifications list
                    ..._filtered.map((notification) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                                Row(
                                  children: [
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
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _notifications.remove(notification)),
                                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
