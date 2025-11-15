import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';

/// Messaging service for handling push notifications
class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      // Get FCM token
      final token = await _messaging.getToken();
      print('FCM Token: $token');

      // Listen to token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('FCM Token refreshed: $newToken');
        // Update token in Firestore if user is logged in
      });
    } catch (e) {
      print('Failed to initialize messaging: $e');
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
      }
    } catch (e) {
      print('Failed to update user token: $e');
    }
  }

  /// Handle foreground messages
  void handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // Show local notification or update UI
      }
    });
  }

  /// Handle background messages
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Handle background notification
  }

  /// Setup message handlers
  void setupMessageHandlers() {
    // Handle foreground messages
    handleForegroundMessages();

    // Handle notification opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.data}');
      // Navigate to appropriate screen based on notification data
    });
  }
}
