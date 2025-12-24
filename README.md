# ServiceLink

> ServiceLink is a cross-platform Flutter mobile application that connects customers with local service workers (carpenters, plumbers, electricians, mechanics, etc.). The app uses Firebase for authentication, data storage, messaging, and push notifications.

---

## Key Features

- User authentication (email/password + providers)
- Role-based UI (Customer and Worker flows)
- Browse workers and view detailed profiles
- Create and manage service requests
- In-app chat between customers and workers (FCM + Firestore)
- Real-time notifications (Firebase Cloud Messaging + local notifications)
- Worker earnings, completed tasks, and reviews
- Modern UI with drawer and bottom navigation

---

## Repo structure (important folders)

- `lib/` — Flutter app source code
  - `models/` — Data models (e.g. `user_model.dart`)
  - `providers/` — State management (Provider)
  - `screens/` — All screens organized by feature
  - `services/` — 3rd-party and platform services (messaging, storage, etc.)
  - `widgets/` — Reusable UI widgets
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` — Platform projects
- `assets/` — Images and static assets

---

## Prerequisites

- Flutter SDK (stable channel) installed and configured. Recommended: Flutter 3.x or later.
- Android SDK & Xcode (macOS) if building for mobile platforms.
- A Firebase project configured for Android/iOS/web with Firestore, Auth, Cloud Messaging, and Storage enabled.

---

## Firebase configuration

This project expects Firebase configuration files and generated options in the repo:

- Android: `android/app/google-services.json`
- iOS: `Runner/GoogleService-Info.plist`
- Generated options: `lib/firebase_options.dart` (the repo already contains `firebase_options.dart` and `firebase_options.example.dart`).

Steps:

1. Create a Firebase project and enable Authentication, Cloud Firestore, Cloud Messaging, and Storage.
2. Register Android & iOS apps in Firebase console and download the platform config files.
3. Place `google-services.json` in `android/app/` and `GoogleService-Info.plist` in the iOS runner directory.
4. Generate `firebase_options.dart` via `flutterfire` CLI or adapt `firebase_options.example.dart` (if provided).

If you prefer the `flutterfire` CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

---

## Local setup (run)

1. Install Dart/Flutter and ensure `flutter doctor` is clean.
2. Fetch packages:

```bash
flutter pub get
```

3. Run on connected device or emulator:

```bash
flutter run
```

4. Build release APK (Android):

```bash
flutter build apk --release
```

5. Build iOS (macOS):

```bash
flutter build ios --release
```

Note: Ensure platform config files (Google services) are in place and you have valid signing configs for release builds.

---

## Environment & secrets

- The repo may store user profile images as base64 strings in Firestore (`UserModel.profileImage`).
- Do NOT commit private keys or service account JSON files. Use environment variables or CI secrets for distribution.

---

## Tests

Run unit/widget tests with:

```bash
flutter test
```

Add or extend tests under the `test/` directory.

---

## Common troubleshooting

- If you see FCM issues, ensure `firebase_options.dart` matches your Firebase project and that push notifications are configured on the platform (APNs for iOS).
- If profile images are not showing, ensure `UserModel.profileImage` contains a valid base64 string or change code to use remote URLs instead.
- If navigation/back-button behavior is unexpected, confirm `WillPopScope` logic in `lib/screens/others/main_screen.dart`.

---

## Contributing

Contributions are welcome. Typical workflow:

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Open a pull request with a clear description

---

## Next improvements (ideas)

- Add CI (GitHub Actions) to run `flutter analyze` and `flutter test` on PRs
- Add release pipeline for Android & iOS builds
- Store profile images in Firebase Storage and keep only download URLs in Firestore
- Improve accessibility and localization

---

## License

This project includes a `LICENSE` file. Check it for licensing details.

---

