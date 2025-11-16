import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../utils/constants.dart';
import '../chat/chat_room_screen.dart';

/// Screen to display user notifications
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.userModel?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications'), elevation: 1),
        body: const Center(child: Text('Please login to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All'),
                  content: const Text(
                    'Are you sure you want to delete all notifications?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.errorColor,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                // Clear all notifications
                final notifications = await _notificationService
                    .getUserNotifications(userId)
                    .first;
                for (final notification in notifications) {
                  await _notificationService.deleteNotification(
                    userId,
                    notification.notificationId,
                  );
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications cleared'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              }
            },
            tooltip: 'Clear all notifications',
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                userId: userId,
                notificationService: _notificationService,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final String userId;
  final NotificationService notificationService;

  const _NotificationCard({
    Key? key,
    required this.notification,
    required this.userId,
    required this.notificationService,
  }) : super(key: key);

  IconData _getNotificationIcon() {
    switch (notification.type) {
      case 'chat':
        return Icons.chat_bubble;
      case 'request_pending':
        return Icons.pending;
      case 'request_accepted':
        return Icons.check_circle;
      case 'request_rejected':
        return Icons.cancel;
      case 'request_completed':
        return Icons.task_alt;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor() {
    switch (notification.type) {
      case 'chat':
        return AppConstants.primaryColor;
      case 'request_pending':
        return AppConstants.warningColor;
      case 'request_accepted':
        return AppConstants.successColor;
      case 'request_rejected':
        return AppConstants.errorColor;
      case 'request_completed':
        return AppConstants.successColor;
      default:
        return AppConstants.textSecondaryColor;
    }
  }

  void _handleNotificationTap(BuildContext context) async {
    // Mark as read
    if (!notification.isRead) {
      await notificationService.markAsRead(userId, notification.notificationId);
    }

    // Handle navigation based on notification type
    if (notification.type == 'chat') {
      final chatId = notification.data['chatId'];
      final otherUserName = notification.data['senderName'];

      if (chatId != null && otherUserName != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatRoomScreen(chatId: chatId, otherUserName: otherUserName),
          ),
        );
      }
    }
    // For request notifications, could navigate to requests screen
    // This can be expanded based on app requirements
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppConstants.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        notificationService.deleteNotification(
          userId,
          notification.notificationId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
        color: notification.isRead
            ? null
            : AppConstants.primaryColor.withOpacity(0.05),
        child: InkWell(
          onTap: () => _handleNotificationTap(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(),
                    color: _getNotificationColor(),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: notification.isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                  ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppConstants.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy hh:mm a',
                        ).format(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppConstants.textSecondaryColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
