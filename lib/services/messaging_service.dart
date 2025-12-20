import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';

/// Unified Messaging service for handling all push notifications via Firebase Messaging
class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  bool _isInitialized = false;

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    if (_isInitialized) return;
    
    // Android settings
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
    
    _isInitialized = true;
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Navigation will be handled by the app based on payload
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      visibility: NotificationVisibility.public,
      showWhen: true,
      ticker: 'New notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Initialize messaging
  Future<void> initialize() async {
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request notification permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
        return;
      }

      // Get FCM token
      final token = await _messaging.getToken();
      print('FCM Token: $token');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
      });

      // Setup message handlers
      setupMessageHandlers();
    } catch (e) {
      print('Failed to initialize messaging: $e');
    }
  }

  /// Request notification permission with user-friendly dialog
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Failed to request notification permission: $e');
      return false;
    }
  }

  /// Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('Failed to check notification permission: $e');
      return false;
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Update user's FCM token in Firestore
  Future<void> updateUserToken(String userId) async {
    try {
      final token = await getToken();

      if (token != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(userId)
            .update({'fcmToken': token});
        print('FCM token updated for user: $userId');
      }
    } catch (e) {
      print('Failed to update user token: $e');
    }
  }

  /// Handle foreground messages
  void handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message notification: ${message.notification}');

        // Show local notification when app is in foreground
        await showLocalNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });
  }

  /// Setup message handlers
  void setupMessageHandlers() {
    // Handle foreground messages with local notifications
    handleForegroundMessages();

    // Handle notification opened from background/terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened from background: ${message.data}');
    });

    // Check for initial message (when app is opened from terminated state)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state via notification: ${message.data}');
      }
    });
  }

  // ==================== Notification Sending Methods ====================

  /// Send chat notification (stores in Firestore for the recipient)
  Future<void> sendChatNotification({
    required String recipientId,
    required String senderName,
    required String message,
    required String chatId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .add({
            'type': 'chat',
            'title': 'New message from $senderName',
            'body': message.length > 50 ? '${message.substring(0, 50)}...' : message,
            'chatId': chatId,
            'senderName': senderName,
            'timestamp': FieldValue.serverTimestamp(),
            'read': false,
          });
    } catch (e) {
      print('Error sending chat notification: $e');
    }
  }

  /// Send request notification
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

  /// Send new request pending notification to worker
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

  /// Send request accepted notification to customer
  Future<void> sendRequestAcceptedNotification({
    required String customerId,
    required String workerName,
    required String serviceType,
    required String requestId,
  }) async {
    await sendRequestNotification(
      recipientId: customerId,
      title: 'Request Accepted!',
      body: '$workerName accepted your $serviceType request',
      requestId: requestId,
    );
  }

  /// Send request completed notification to customer
  Future<void> sendRequestCompletedNotification({
    required String customerId,
    required String workerName,
    required String serviceType,
    required String requestId,
  }) async {
    await sendRequestNotification(
      recipientId: customerId,
      title: 'Task Completed!',
      body: '$workerName completed your $serviceType task',
      requestId: requestId,
    );
  }

  /// Listen to user's notifications collection
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
}
