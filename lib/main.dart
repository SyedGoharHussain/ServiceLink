import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/request_provider.dart';
import 'providers/worker_provider.dart';
import 'providers/chat_provider.dart';
import 'services/messaging_service.dart';
import 'services/notification_service.dart';
import 'screens/others/splash_screen.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/others/main_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling background message: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');

  // Show local notification even when app is closed
  final localNotifications = FlutterLocalNotificationsPlugin();

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

  if (message.notification != null) {
    await localNotifications.show(
      message.hashCode,
      message.notification!.title ?? 'New Notification',
      message.notification!.body ?? '',
      notificationDetails,
      payload: message.data.toString(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppInitializer(),
      ),
    );
  }
}

/// Initialize Firebase and services before showing main app
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize FREE local notifications (no billing!)
      final notificationService = NotificationService();
      await notificationService.initialize();

      // Initialize FCM for basic token management (free tier)
      final messagingService = MessagingService();
      await messagingService.initialize();
      messagingService.setupMessageHandlers();

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen while initializing
    if (!_initialized && !_error) {
      return const SplashScreen();
    }

    // Show error screen if initialization failed
    if (_error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize app'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = false;
                    _initialized = false;
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show auth wrapper
    return const AuthWrapper();
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show splash while loading user profile (prevents flicker)
        if (authProvider.isAuthenticated && authProvider.userModel == null) {
          return const SplashScreen();
        }

        // Check if user needs email verification
        if (authProvider.isAuthenticated &&
            authProvider.firebaseUser != null &&
            !authProvider.firebaseUser!.emailVerified &&
            authProvider.firebaseUser!.providerData.any(
              (info) => info.providerId == 'password',
            )) {
          return EmailVerificationScreen(
            email: authProvider.firebaseUser!.email ?? '',
          );
        }

        // Show main screen if authenticated with complete profile
        if (authProvider.isAuthenticated && authProvider.userModel != null) {
          // Start FREE notification listener for this user
          NotificationService().listenToNotifications(
            authProvider.userModel!.uid,
          );
          return const MainScreen();
        }

        // Show sign in screen for unauthenticated users
        return const SignInScreen();
      },
    );
  }
}
