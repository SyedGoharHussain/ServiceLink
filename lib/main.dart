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
      // Initialize unified messaging service
      final messagingService = MessagingService();
      await messagingService.initialize();
      messagingService.setupMessageHandlers();

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print('App initialization error: $e');
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.errorColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: AppConstants.errorColor,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Failed to initialize app',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please check your internet connection and try again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 200,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _error = false;
                        _initialized = false;
                      });
                      _initializeApp();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
          // Start notification listener for this user
          MessagingService().listenToNotifications(
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
