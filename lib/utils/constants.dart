import 'package:flutter/material.dart';

/// App-wide constants and configuration
class AppConstants {
  // App Info
  static const String appName = 'ServiceLink';
  static const String appSlogan = 'Connecting You to Reliable Local Help';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleWorker = 'worker';

  // Request Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusRejected = 'rejected';
  static const String statusCompleted = 'completed';

  // Service Types
  static const List<String> serviceTypes = [
    'Carpenter',
    'Plumber',
    'Electrician',
    'Mechanic',
    'Gardener',
    'Cleaner',
    'Painter',
    'Handyman',
  ];

  // Colors (Material 3 Design)
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color secondaryColor = Color(0xFF5AB9EA);
  static const Color accentColor = Color(0xFF00D9FF);
  static const Color textPrimaryColor = Color(0xFF2C3E50);
  static const Color textSecondaryColor = Color(0xFF7F8C8D);
  static const Color successColor = Color(0xFF27AE60);
  static const Color warningColor = Color(0xFFF39C12);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color cardColor = Colors.white;

  // Padding & Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 20.0;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String requestsCollection = 'requests';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Validation
  static const int minPasswordLength = 6;
  static const int maxDescriptionLength = 500;
}
