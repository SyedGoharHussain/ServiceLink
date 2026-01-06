# ServiceLink

Connect with local service professionals through a cross-platform Flutter app.

Features, installation, and setup instructions are provided below. This README has been updated to reflect the repository layout and existing configuration files.
Download aap from: https://appgallery.huawei.com/app/C116494833

---

## About

ServiceLink is a Flutter application that helps customers discover, message, and hire local service professionals (carpenter, plumber, electrician, mechanic, etc.). The app uses Firebase for authentication, realtime data, storage, and messaging.

Technologies: Flutter, Dart, Firebase (Auth, Firestore, Storage, Cloud Messaging), Provider for state management.

---

## Key Features

- Secure authentication (email/password and social providers)
- Browse and filter service professionals by category
- Detailed worker profiles with ratings and completed jobs
- Create and manage service requests
- In-app chat and real-time updates
- Push notifications via FCM
- Worker dashboard: requests, earnings, and performance tracking

---

## Project Structure

Top-level important files and folders:

```
lib/
   models/
   providers/
   screens/
   services/
   widgets/
   firebase_options.dart
   main.dart
android/
ios/
web/
assets/
pubspec.yaml
firebase.json
firestore.rules
storage.rules
README.md
```

---

## Prerequisites

- Flutter SDK (3.x or later)
- Android Studio or Xcode for mobile builds
- Git
- Firebase account

Verify environment with:

```bash
flutter doctor
```

---

## Installation

Clone and install dependencies:

```bash
git clone https://github.com/SyedGoharHussain/ServiceLink.git
cd ServiceLink
flutter pub get
```

---

## Firebase configuration

This repository already includes `lib/firebase_options.dart.example` and, in the Android app, `android/app/google-services.json` (check `android/app/`). If you need to connect the app to your Firebase project, follow these steps:

1. Create a Firebase project in the Firebase Console and enable Authentication, Firestore, Cloud Storage, and Cloud Messaging.
2. Register Android and/or iOS apps and download configuration files:
   - Android: place the downloaded `google-services.json` into `android/app/`.
   - iOS: place the downloaded `GoogleService-Info.plist` into `ios/Runner/`.
3. Generate `lib/firebase_options.dart` with FlutterFire CLI (optional but recommended):

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

If you prefer, adapt `lib/firebase_options.example.dart` to fill your Firebase credentials and rename it to `lib/firebase_options.dart`.

---

## Run the app

Run on a connected device or emulator:

```bash
flutter run
```

List devices:

```bash
flutter devices
```

Build commands:

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release  # macOS + Xcode required
flutter build web --release
```

---

## Tests and analysis

Run unit/widget tests:

```bash
flutter test
```

Analyze project:

```bash
flutter analyze
```

---

## Troubleshooting

- FCM not working: verify `lib/firebase_options.dart` matches your project and FCM server key is configured
- Images not showing: ensure profile image URLs are valid or migrate to Firebase Storage URLs
- Android build issues: verify `android/app/google-services.json` is correct and Gradle settings are up to date
- iOS build issues: ensure `ios/Runner/GoogleService-Info.plist` is present and `pod install` has been run

---

## Contributing

1. Fork the repository
2. Create a branch: `git checkout -b feature/your-feature`
3. Implement changes and tests
4. Commit and push
5. Open a pull request

Follow Effective Dart style and include tests for new features.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Author

Syed Gohar Hussain  https://github.com/SyedGoharHussain
