import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local notification plugin instance
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Call this once in main() to initialize local notifications
  static Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'fridge_status_channel',
          'Fridge Status',
          channelDescription: 'Notifications for fridge item status updates',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Get notifications for the current user
  Stream<List<Map<String, dynamic>>> getNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Mark notification as unread
  Future<void> markAsUnread(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': false,
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Create a friend request notification
  Future<void> createFriendRequestNotification({
    required String senderId,
    required String receiverId,
    required String senderName,
  }) async {
    await _firestore.collection('notifications').add({
      'type': 'friend_request',
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'message': '$senderName sent you a friend request',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // Create notification for item status (almost expired, expired)
  Future<void> createItemStatusNotification({
    required String receiverId,
    required String itemName,
    required String status, // 'almost_expired' or 'expired'
  }) async {
    String message;
    if (status == 'almost_expired') {
      message = 'Item "$itemName" is almost expired!';
    } else if (status == 'expired') {
      message = 'Item "$itemName" has expired!';
    } else {
      message = 'Item "$itemName" status updated.';
    }
    await _firestore.collection('notifications').add({
      'type': 'item_status',
      'receiverId': receiverId,
      'itemName': itemName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'status': status,
    });
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all notifications (read and unread) for the current user
  Stream<List<Map<String, dynamic>>> getAllNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
