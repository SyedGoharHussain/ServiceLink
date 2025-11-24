import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified notification service - focused on chat and request notifications
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send chat notification - only when user is not viewing the chat
  Future<void> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore
          .collection('users')
          .doc(recipientId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        // Store notification for Cloud Functions to send
        await _firestore.collection('fcm_messages').add({
          'to': fcmToken,
          'notification': {
            'title': 'New message from $senderName',
            'body': message.length > 50
                ? '${message.substring(0, 50)}...'
                : message,
            'sound': 'default',
          },
          'data': {
            'type': 'chat',
            'chatId': chatId,
            'senderName': senderName,
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
          'timestamp': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  /// Send request notification - for new/updated requests
  Future<void> sendRequestNotification({
    required String recipientId,
    required String title,
    required String body,
    required String requestId,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore
          .collection('users')
          .doc(recipientId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null) {
        // Store notification for Cloud Functions to send
        await _firestore.collection('fcm_messages').add({
          'to': fcmToken,
          'notification': {'title': title, 'body': body, 'sound': 'default'},
          'data': {
            'type': 'request',
            'requestId': requestId,
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
          'timestamp': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }
    } catch (e) {
      print('Error sending request notification: $e');
    }
  }

  // Legacy methods kept for backward compatibility
  Future<void> sendRequestPendingNotification({
    required String workerId,
    required String customerName,
    required String serviceType,
    required String requestId,
  }) async {
    await sendRequestNotification(
      recipientId: workerId,
      title: 'New Service Request',
      body: '$customerName requested $serviceType service',
      requestId: requestId,
    );
  }
}
