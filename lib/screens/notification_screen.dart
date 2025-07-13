import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await _notificationService.markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    final message = notification['message'] as String?;
    final timestamp = notification['timestamp'] as Timestamp?;
    final isRead = notification['isRead'] as bool? ?? false;

    // Format timestamp
    String timeAgo = 'Just now';
    if (timestamp != null) {
      final now = DateTime.now();
      final notificationTime = timestamp.toDate();
      final difference = now.difference(notificationTime);

      if (difference.inDays > 0) {
        timeAgo =
            '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        timeAgo =
            '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        timeAgo =
            '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      }
    }

    IconData iconData;
    Color iconColor;

    // Set icon and color based on notification type
    switch (type) {
      case 'friend_request':
        iconData = Icons.person_add;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Dismissible(
      key: Key(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification['id']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                // Note: In a real app, you might want to implement undo functionality
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[200]! : Colors.blue[200]!,
            width: 1,
          ),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(iconData, color: iconColor),
          ),
          title: Text(
            message ?? 'Notification',
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            timeAgo,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'mark_read':
                  await _notificationService.markAsRead(notification['id']);
                  break;
                case 'delete':
                  await _notificationService.deleteNotification(
                    notification['id'],
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification deleted')),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              if (!isRead)
                const PopupMenuItem<String>(
                  value: 'mark_read',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark as read'),
                    ],
                  ),
                ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
          onTap: () async {
            // Mark as read when tapped
            if (!isRead) {
              await _notificationService.markAsRead(notification['id']);
            }
          },
        ),
      ),
    );
  }
}
