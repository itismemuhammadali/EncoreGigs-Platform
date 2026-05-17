import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationItem {
  final IconData? icon;
  final String? iconPath;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;

  const NotificationItem({
    this.icon,
    this.iconPath,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [
    const NotificationItem(
      icon: Icons.person_outline,
      iconColor: Color(0xFFA2F301),
      iconBg: Color(0x1AA2F301),
      title: 'New Application',
      subtitle: 'Sarah Johnson applied for Jazz Night - Friday',
      time: '5 minutes ago',
      isUnread: true,
    ),
    const NotificationItem(
      icon: Icons.chat_bubble_outline,
      iconColor: Color(0xFF4A9EFF),
      iconBg: Color(0x1A4A9EFF),
      title: 'New Message',
      subtitle: 'Mike Davis sent you a message',
      time: '1 hour ago',
      isUnread: true,
    ),
    const NotificationItem(
      icon: Icons.calendar_today_outlined,
      iconColor: Color(0xFFB47AFF),
      iconBg: Color(0x1AB47AFF),
      title: 'Booking Confirmed',
      subtitle: 'Your booking with Emma Wilson is confirmed',
      time: '2 hours ago',
    ),
    const NotificationItem(
      icon: Icons.attach_money,
      iconColor: Color(0xFF4CAF50),
      iconBg: Color(0x1A4CAF50),
      title: 'Payment Successful',
      subtitle: 'Payment of \$750 held in escrow',
      time: '5 hours ago',
    ),
    const NotificationItem(
      iconPath: 'assets/tick_icon.svg',
      iconColor: Color(0xFFA2F301),
      iconBg: Color(0x1AA2F301),
      title: 'Account Approved',
      subtitle: 'Your organizer account has been approved!',
      time: 'Yesterday',
    ),
  ];

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: _notifications.length + 1,
                separatorBuilder: (_, index) => index < _notifications.length - 1
                    ? const Divider(color: Color(0xFF2A2A2F), height: 1)
                    : const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  if (index == _notifications.length) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _notifications = _notifications
                              .map((n) => NotificationItem(
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
                  return _NotificationCard(item: _notifications[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}
