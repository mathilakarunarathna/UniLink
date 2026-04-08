import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../data/global_state.dart';
import '../../theme/app_colors.dart';

class NotificationDialog extends StatelessWidget {
  const NotificationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final theme = Theme.of(context);

    // Mark as read when opening
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GlobalState.markAllNotificationsAsRead();
    });

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: colors.foreground,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: GlobalState.globalNotifications,
                          builder: (context, notifications, _) {
                            return Text(
                              '${notifications.length} updates found',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: colors.mutedForeground),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              // BODY
              Flexible(
                child: ValueListenableBuilder(
                  valueListenable: GlobalState.globalNotifications,
                  builder: (context, notifications, _) {
                    if (notifications.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.bellOff, size: 48, color: colors.muted.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                color: colors.mutedForeground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Stay tuned for campus updates!',
                              style: TextStyle(
                                color: colors.mutedForeground.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        return _buildNotificationTile(notif, colors);
                      },
                    );
                  },
                ),
              ),
              
              // FOOTER
              if (GlobalState.globalNotifications.value.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () {
                      GlobalState.globalNotifications.value = [];
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colors.campusRose,
                    ),
                    child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif, AppCustomColors colors) {
    final isUnread = notif['isUnread'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? colors.primary.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (notif['iconColor'] as Color).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              notif['icon'] as IconData,
              color: notif['iconColor'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['title'] as String,
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notif['description'] as String,
                  style: TextStyle(
                    color: colors.mutedForeground,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notif['time'] as String,
                  style: TextStyle(
                    color: colors.mutedForeground.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
