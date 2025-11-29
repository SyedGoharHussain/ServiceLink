import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// FREE Local notification service - NO Firebase Cloud Functions billing!
/// Uses Firestore real-time listeners + local notifications only
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize local notifications
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Important notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Store notification in Firestore for recipient to receive via listener
  Future<void> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      // Store in recipient's notifications collection
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
            'type': 'chat',
            'title': 'New message from $senderName',
            'body': message.length > 50
                ? '${message.substring(0, 50)}...'
                : message,
            'chatId': chatId,
            'senderName': senderName,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  /// Store request notification in Firestore
  Future<void> sendRequestNotification({
    required String recipientId,
    required String title,
    required String body,
    required String requestId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
            'type': 'request',
            'title': title,
            'body': body,
            'requestId': requestId,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
    } catch (e) {
      print('Error sending request notification: $e');
    }
  }

  /// Show local notification (called by listener)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Important notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Listen to user's notifications collection (call this after login)
  void listenToNotifications(String userId) {
    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              showLocalNotification(
                title: data['title'] ?? 'New Notification',
                body: data['body'] ?? '',
                payload: data['type'],
              );
              // Mark as read
              change.doc.reference.update({'read': true});
            }
          }
        });
  }

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
