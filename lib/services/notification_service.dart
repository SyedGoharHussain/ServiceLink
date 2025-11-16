import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

/// Service for managing notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to a user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      // Create notification in Firestore
      final notificationRef = _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('notifications')
          .doc();

      final notification = NotificationModel(
        notificationId: notificationRef.id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
      );

      await notificationRef.set(notification.toMap());
      print('Notification sent to user $userId: $title');

      // Try to send FCM push notification
      await _sendPushNotification(
        userId: userId,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Send FCM push notification
  /// Stores notification data in Firestore for Cloud Functions to process
  Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        print('📱 FCM Token available for user: $fcmToken');

        // Store notification message for Cloud Functions to send
        await _firestore.collection('fcm_messages').add({
          'to': fcmToken,
          'notification': {'title': title, 'body': body, 'sound': 'default'},
          'data': {
            ...data,
            'title': title,
            'body': body,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'priority': 'high',
          'android': {
            'notification': {
              'channelId': 'high_importance_channel',
              'visibility': 'public',
              'priority': 'high',
              'sound': 'default',
              'showWhen': true,
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'alert': {'title': title, 'body': body},
                'sound': 'default',
                'badge': 1,
              },
            },
          },
          'timestamp': FieldValue.serverTimestamp(),
          'processed': false,
        });

        print('✅ Push notification queued in Firestore');
      } else {
        print('⚠️  No FCM token found for user $userId');
      }
    } catch (e) {
      print('Error queueing push notification: $e');
    }
  }

  /// Send chat notification
  Future<void> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    await sendNotification(
      userId: recipientId,
      title: 'New message from $senderName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      type: 'chat',
      data: {'chatId': chatId, 'senderName': senderName},
    );
  }

  /// Send request pending notification (to worker)
  Future<void> sendRequestPendingNotification({
    required String workerId,
    required String customerName,
    required String serviceType,
    required String requestId,
  }) async {
    await sendNotification(
      userId: workerId,
      title: 'New Service Request',
      body: '$customerName requested $serviceType service',
      type: 'request_pending',
      data: {'requestId': requestId, 'customerName': customerName},
    );
  }

  /// Send request accepted notification (to customer)
  Future<void> sendRequestAcceptedNotification({
    required String customerId,
    required String workerName,
    required String serviceType,
    required String requestId,
  }) async {
    await sendNotification(
      userId: customerId,
      title: 'Request Accepted!',
      body: '$workerName accepted your $serviceType request',
      type: 'request_accepted',
      data: {'requestId': requestId, 'workerName': workerName},
    );
  }

  /// Send request rejected notification (to customer)
  Future<void> sendRequestRejectedNotification({
    required String customerId,
    required String workerName,
    required String serviceType,
    required String requestId,
  }) async {
    await sendNotification(
      userId: customerId,
      title: 'Request Declined',
      body: '$workerName declined your $serviceType request',
      type: 'request_rejected',
      data: {'requestId': requestId, 'workerName': workerName},
    );
  }

  /// Send request completed notification (to both)
  Future<void> sendRequestCompletedNotification({
    required String userId,
    required String otherUserName,
    required String serviceType,
    required String requestId,
    required bool isWorker,
  }) async {
    await sendNotification(
      userId: userId,
      title: 'Task Completed!',
      body: isWorker
          ? 'You completed $serviceType service for $otherUserName'
          : '$otherUserName completed your $serviceType request',
      type: 'request_completed',
      data: {'requestId': requestId},
    );
  }

  /// Get user's notifications stream
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }
}
