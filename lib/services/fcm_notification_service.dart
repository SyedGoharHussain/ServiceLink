import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging notification service
/// Uses CLIENT-SIDE FCM - No server key needed!
/// Sends notifications via Firestore triggers + local notifications
class FCMNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FCMNotificationService _instance =
      FCMNotificationService._internal();
  factory FCMNotificationService() => _instance;
  FCMNotificationService._internal();

  /// Initialize FCM and save user token
  Future<void> initialize(String userId) async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        final token = await _messaging.getToken();
        if (token != null) {
          // Save token to Firestore
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
          print('FCM Token saved: $token');
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _firestore.collection('users').doc(userId).update({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        });
      }
    } catch (e) {
      print('FCM initialization error: $e');
    }
  }

  /// Send notification to a specific user using Firestore
  /// This approach doesn't need server key and works with free Firebase plan
  Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Store notification in Firestore for the user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
            'title': title,
            'body': body,
            'data': data ?? {},
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
            'type': data?['type'] ?? 'general',
          });

      print('Notification stored in Firestore for user: $userId');
      return true;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }

  /// Send chat notification
  Future<bool> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    return await sendNotificationToUser(
      userId: recipientId,
      title: 'New message from $senderName',
      body: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      data: {'type': 'chat', 'chatId': chatId, 'senderName': senderName},
    );
  }

  /// Send request notification
  Future<bool> sendRequestNotification({
    required String recipientId,
    required String title,
    required String body,
    required String requestId,
  }) async {
    return await sendNotificationToUser(
      userId: recipientId,
      title: title,
      body: body,
      data: {'type': 'request', 'requestId': requestId},
    );
  }

  /// Send notification when worker accepts request
  Future<bool> sendRequestAcceptedNotification({
    required String customerId,
    required String workerName,
    required String serviceType,
    required String requestId,
  }) async {
    return await sendNotificationToUser(
      userId: customerId,
      title: 'Request Accepted',
      body: '$workerName accepted your $serviceType request',
      data: {'type': 'request_accepted', 'requestId': requestId},
    );
  }

  /// Send notification when task is completed
  Future<bool> sendTaskCompletedNotification({
    required String customerId,
    required String workerName,
    required String serviceType,
    required String requestId,
  }) async {
    return await sendNotificationToUser(
      userId: customerId,
      title: 'Task Completed',
      body: '$workerName completed your $serviceType request',
      data: {'type': 'task_completed', 'requestId': requestId},
    );
  }

  /// Send notification for new service request
  Future<bool> sendNewRequestNotification({
    required String workerId,
    required String customerName,
    required String serviceType,
    required String requestId,
  }) async {
    return await sendNotificationToUser(
      userId: workerId,
      title: 'New Service Request',
      body: '$customerName requested $serviceType service',
      data: {'type': 'new_request', 'requestId': requestId},
    );
  }

  /// Send multiple notifications (batch)
  Future<void> sendBatchNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    for (final userId in userIds) {
      await sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        data: data,
      );
    }
  }
}
