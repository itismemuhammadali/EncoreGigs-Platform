import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class NotificationItem {
  final String id;
  final IconData? icon;
  final String? iconPath;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  bool isUnread;

  const NotificationItem({
    required this.id,
    this.icon,
    this.iconPath,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    final category = map['category'] ?? 'system';
    final colorMap = {
      'application': const Color(0xFFA2F301),
      'message': const Color(0xFF4A9EFF),
      'payment': const Color(0xFF4CAF50),
      'booking': const Color(0xFFB47AFF),
      'gig': const Color(0xFFFF6B9D),
      'system': const Color(0xFF999999),
    };
    final iconMap = {
      'application': Icons.person_outline,
      'message': Icons.chat_bubble_outline,
      'payment': Icons.attach_money,
      'booking': Icons.calendar_today_outlined,
      'gig': Icons.music_note,
      'system': Icons.info_outline,
    };
    final color = colorMap[category] ?? const Color(0xFF999999);
    final createdAt = map['createdAt'];
    String time = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) time = '${diff.inMinutes}m ago';
        else if (diff.inHours < 24) time = '${diff.inHours}h ago';
        else time = '${diff.inDays}d ago';
      } catch (_) {}
    }
    return NotificationItem(
      id: map['id'] ?? '',
      icon: iconMap[category] ?? Icons.notifications_none,
      iconColor: color,
      iconBg: color.withValues(alpha: 0.1),
      title: map['title'] ?? '',
      subtitle: map['body'] ?? '',
      time: time,
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
  List<NotificationItem> _notifications = [];
  bool _loading = true;
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
        _notifications = data.map((m) => NotificationItem.fromMap(m)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  int get _unreadCount => _notifications.where((n) => n.isUnread).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(
                    '$_unreadCount unread notification${_unreadCount > 1 ? 's' : ''}',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                  ),
                ),
              const Divider(color: Color(0x4DA2F301), height: 1),
            ],
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 26),
          ),
        ),
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFA2F301)))
            : RefreshIndicator(
                onRefresh: _fetchNotifications,
                color: const Color(0xFFA2F301),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _notifications.isEmpty
                          ? const Center(
                              child: Text('No notifications yet',
                                  style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                              itemCount: _notifications.length + 1,
                              separatorBuilder: (_, index) => index < _notifications.length - 1
                                  ? const Divider(color: Color(0xFF2A2A2F), height: 1)
                                  : const SizedBox.shrink(),
                              itemBuilder: (context, index) {
                                if (index == _notifications.length) {
                                  return GestureDetector(
                                    onTap: () async {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        await _api.markAllNotificationsRead(user.uid);
                                        setState(() {
                                          _notifications = _notifications
                                              .map((n) => NotificationItem(
                                                    id: n.id,
                                                    icon: n.icon,
                                                    iconColor: n.iconColor,
                                                    iconBg: n.iconBg,
                                                    title: n.title,
                                                    subtitle: n.subtitle,
                                                    time: n.time,
                                                    isUnread: false,
                                                  ))
                                              .toList();
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: Text(
                                          'Mark all as read',
                                          style: TextStyle(
                                              color: Color(0xFFA2F301),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return _NotificationCard(
                                  item: _notifications[index],
                                  onTap: () async {
                                    if (_notifications[index].isUnread) {
                                      await _api.markNotificationRead(_notifications[index].id);
                                      setState(() {
                                        _notifications[index].isUnread = false;
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;

  const _NotificationCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconBg,
                shape: BoxShape.circle,
              ),
              child: item.iconPath != null
                  ? Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: SvgPicture.asset(
                          item.iconPath!,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(item.iconColor, BlendMode.srcIn),
                        ),
                      ),
                    )
                  : Icon(item.icon, color: item.iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: item.isUnread ? Colors.white : const Color(0xFF888888),
                      fontSize: 15,
                      fontWeight: item.isUnread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: item.isUnread
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF666666),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.time,
                    style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (item.isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFA2F301),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
