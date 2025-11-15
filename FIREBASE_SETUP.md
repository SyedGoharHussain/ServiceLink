# ServiceLink - Firebase Setup Instructions

## Overview
ServiceLink is a complete Flutter mobile app for connecting customers with local service workers. It includes Firebase authentication, Firestore database, Storage, Realtime Database for chat, and Cloud Messaging for notifications.

## Firebase Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `ServiceLink`
4. Enable Google Analytics (optional)
5. Create project

### 2. Add Android App
1. In Firebase Console, click "Add app" → Android icon
2. Enter package name: `com.example.mids_project` (found in `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place it in `android/app/` directory

### 3. Add iOS App
1. Click "Add app" → iOS icon
2. Enter bundle ID: `com.example.midsProject` (found in `ios/Runner.xcodeproj`)
3. Download `GoogleService-Info.plist`
4. Open iOS project in Xcode and add file to Runner folder

### 4. Enable Firebase Services

#### Authentication
1. Go to Authentication → Sign-in method
2. Enable **Email/Password**
3. Enable **Google Sign-In**
   - Add support email
   - For Android: SHA-1 certificate (get with `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore`)

#### Firestore Database
1. Go to Firestore Database → Create database
2. Start in **production mode** (we'll set rules later)
3. Choose location closest to your users

#### Realtime Database
1. Go to Realtime Database → Create database
2. Start in **locked mode**
3. Update rules:
```json
{
  "rules": {
    "chats": {
      "$chatId": {
        ".read": "auth != null && (data.child('participants').val().contains(auth.uid))",
        ".write": "auth != null && (data.child('participants').val().contains(auth.uid) || !data.exists())"
      }
    }
  }
}
```

#### Storage
1. Go to Storage → Get started
2. Start in **production mode**
3. Update rules:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_images/{imageId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

#### Cloud Messaging (FCM)
1. Go to Cloud Messaging
2. For iOS: Upload APNs certificate
3. For Android: Configuration is automatic with `google-services.json`

### 5. Firestore Security Rules

Go to Firestore Database → Rules and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Requests collection
    match /requests/{requestId} {
      allow read: if request.auth != null && 
        (resource.data.customerId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
      allow create: if request.auth != null && 
        request.resource.data.customerId == request.auth.uid;
      allow update: if request.auth != null && 
        (resource.data.customerId == request.auth.uid || 
         resource.data.workerId == request.auth.uid);
    }
  }
}
```

### 6. Run FlutterFire CLI (Alternative Method)

You can also use FlutterFire CLI for automatic configuration:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will automatically:
- Create Firebase apps for all platforms
- Download configuration files
- Generate `firebase_options.dart`

### 7. Update Main App

If using FlutterFire CLI, update `lib/main.dart`:

```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## Running the App

### Android
```bash
flutter run
```

### iOS
```bash
cd ios
pod install
cd ..
flutter run
```

## Features Implemented

### Authentication
- ✅ Email/Password sign-in and sign-up
- ✅ Google Sign-In
- ✅ Role selection (Customer/Worker)
- ✅ Profile management

### Customer Features
- ✅ Browse workers by category
- ✅ Search by city and service type
- ✅ View worker profiles with ratings
- ✅ Send job requests with custom budget
- ✅ Chat with workers after acceptance
- ✅ Mark jobs as completed
- ✅ Leave reviews and ratings

### Worker Features
- ✅ Set up professional profile
- ✅ Update service type, rate, description
- ✅ Receive job requests
- ✅ Accept/reject requests
- ✅ View dashboard with pending and active jobs
- ✅ Chat with customers
- ✅ View ratings and reviews

### Chat System
- ✅ Real-time messaging with Firebase Realtime Database
- ✅ Chat list with last message preview
- ✅ Message bubbles with timestamps
- ✅ Automatic chat creation on request acceptance

### UI/UX
- ✅ Material 3 design
- ✅ Poppins font family
- ✅ Primary color: #4A90E2
- ✅ Background: #F5F7FA
- ✅ Bottom navigation (Home, Requests, Chat, Profile)
- ✅ Smooth transitions and rounded cards

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── request_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── request_provider.dart
│   ├── worker_provider.dart
│   └── chat_provider.dart
├── screens/                  # UI screens
│   ├── signin_screen.dart
│   ├── signup_screen.dart
│   ├── role_selection_screen.dart
│   ├── main_screen.dart
│   ├── customer_home_screen.dart
│   ├── worker_home_screen.dart
│   ├── worker_detail_screen.dart
│   ├── requests_screen.dart
│   ├── chat_list_screen.dart
│   ├── chat_room_screen.dart
│   └── profile_screen.dart
├── services/                 # Firebase services
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── storage_service.dart
│   ├── chat_service.dart
│   └── messaging_service.dart
├── widgets/                  # Reusable widgets
│   ├── worker_card.dart
│   └── request_card.dart
└── utils/                    # Constants and helpers
    ├── constants.dart
    └── theme.dart
```

## Next Steps

1. **Configure Firebase** following the steps above
2. **Test the app** on both Android and iOS
3. **Customize** colors, fonts, or features as needed
4. **Deploy** when ready for production

## Troubleshooting

### Common Issues

**Error: No Firebase App '[DEFAULT]' has been created**
- Make sure you've added `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Run `flutter clean` and rebuild

**Google Sign-In not working**
- Add SHA-1 certificate to Firebase Console
- Enable Google Sign-In in Authentication

**Build errors**
- Run `flutter pub get`
- Check that all Firebase packages are compatible
- Clear build: `flutter clean`

## Support

For issues or questions, refer to:
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

**App Name:** ServiceLink  
**Slogan:** "Connecting You to Reliable Local Help"
