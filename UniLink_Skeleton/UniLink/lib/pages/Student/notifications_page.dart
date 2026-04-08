import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../data/global_state.dart';

// --- STUDENT PAGE ---

class NotificationItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isUnread;

  NotificationItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isUnread = false,
  });
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.background,
              colors.muted,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.border,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.arrowLeft,
                          color: colors.foreground,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: colors.foreground,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: GlobalState.globalNotifications,
                      builder: (context, globalNotifs, child) {
                        final bool hasUnread = globalNotifs.any(
                          (n) => n['isUnread'] == true,
                        );
                        return IconButton(
                          icon: Icon(
                            LucideIcons.checkCheck,
                            color: hasUnread
                                ? colors.primary
                                : colors.mutedForeground,
                          ),
                          tooltip: 'Mark all as read',
                          onPressed: hasUnread
                              ? () {
                                  GlobalState.markAllNotificationsAsRead();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'All notifications marked as read',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  'Stay updated with academics, services, and campus alerts',
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: GlobalState.globalNotifications,
                  builder: (context, globalNotifs, child) {
                    final List<NotificationItem> allNotifications = globalNotifs.map(
                      (n) => NotificationItem(
                        title: n['title'],
                        description: n['description'],
                        time: n['time'],
                        icon: n['icon'],
                        iconColor: n['iconColor'],
                        isUnread: n['isUnread'],
                      ),
                    ).toList();

                    if (allNotifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.bellOff,
                              size: 64,
                              color: colors.mutedForeground
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'You\'re all caught up!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      itemCount: allNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = allNotifications[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: notification.isUnread
                                ? colors.primary.withValues(
                                    alpha: 0.06,
                                  )
                                : colors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colors.border,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: notification.iconColor.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                notification.icon,
                                color: notification.iconColor,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isUnread
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color: colors.foreground,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (notification.isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification.description,
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    notification.time,
                                    style: TextStyle(
                                      color: colors.mutedForeground,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {},
                          ),
                        );
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
