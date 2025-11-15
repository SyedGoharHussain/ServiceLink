<div align="center">

# 🔗 ServiceLink

### *Connecting Communities with Local Service Providers*

[![Flutter](https://img.shields.io/badge/Flutter-3.5.4-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue)](https://flutter.dev)

**"Your Trusted Platform for Local Services"**

[Features](#-features) • [Screenshots](#-screenshots) • [Getting Started](#-getting-started) • [Architecture](#-architecture) • [Documentation](#-documentation)

</div>

---

## 📱 About ServiceLink

ServiceLink is a **modern, full-featured mobile application** that bridges the gap between customers seeking services and skilled local workers. Built with Flutter and Firebase, it provides a seamless platform for service discovery, booking, real-time communication, and review management.

### 🎯 The Problem We Solve

Finding reliable local service providers is often challenging and time-consuming. ServiceLink makes it easy to:
- 🔍 **Discover** trusted and verified service workers in your area
- 💬 **Communicate** directly with service providers through in-app chat
- 📋 **Manage** service requests and track job status in real-time
- ⭐ **Share & Read** authentic reviews from real customers
- 📸 **Showcase** work portfolios and build professional reputation

---

## ✨ Features

### 👥 For Customers

<details open>
<summary><strong>🔐 Secure Authentication</strong></summary>

- Email/Password registration and login
- Google Sign-In integration
- Email verification with OTP
- Password recovery system
- Secure Firebase Authentication backend
</details>

<details open>
<summary><strong>🔎 Smart Search & Discovery</strong></summary>

- Browse workers by service category (Carpenter, Plumber, Electrician, Mechanic, Gardener, Cleaner, Painter, AC Technician, and more)
- Search by location (city) and service type
- Filter workers by ratings and reviews
- View detailed worker profiles with contact information
- See worker portfolios and previous work samples
</details>

<details open>
<summary><strong>📋 Request Management</strong></summary>

- Send job requests with custom budget proposals
- Track request status in real-time (Pending/Accepted/Completed)
- View complete request history
- Receive notifications for request updates
- Manage multiple requests simultaneously
</details>

<details open>
<summary><strong>💬 Real-Time Communication</strong></summary>

- In-app chat with service providers
- Image sharing in conversations
- Message notifications
- Complete chat history
- WhatsApp-style modern UI
</details>

<details open>
<summary><strong>⭐ Reviews & Ratings</strong></summary>

- Rate completed services (1-5 stars)
- Write detailed text reviews
- View all worker ratings and feedback
- Help the community make informed decisions
- Build trust through authentic feedback
</details>

### 🔧 For Service Workers

<details open>
<summary><strong>👤 Professional Profiles</strong></summary>

- Customizable profile with photo upload
- Service category selection
- Set hourly rates
- Add detailed service descriptions
- Display skills and experience
- Contact information management
</details>

<details open>
<summary><strong>📸 Portfolio Management</strong></summary>

- Upload multiple work samples
- Showcase completed projects
- Build credibility with visual proof
- Organized gallery display
</details>

<details open>
<summary><strong>📬 Request Handling</strong></summary>

- View all incoming job requests
- Accept or decline requests
- See customer details and budget
- Manage multiple requests efficiently
- Dashboard with pending and active jobs
</details>

<details open>
<summary><strong>💰 Business Growth</strong></summary>

- Track completed jobs
- View earnings history
- Monitor job statistics
- Build professional reputation
- Expand customer base
</details>

<details open>
<summary><strong>⭐ Reputation Building</strong></summary>

- Collect customer reviews
- Build star ratings
- Display testimonials on profile
- Increase visibility through positive feedback
</details>

---

## 🎨 Screenshots

<div align="center">

*Screenshots will be added soon*

| Splash Screen | Authentication | Browse Workers |
|:---:|:---:|:---:|
| ![Splash](docs/screenshots/splash.png) | ![Auth](docs/screenshots/auth.png) | ![Browse](docs/screenshots/browse.png) |

| Worker Profile | Chat | Requests |
|:---:|:---:|:---:|
| ![Profile](docs/screenshots/profile.png) | ![Chat](docs/screenshots/chat.png) | ![Requests](docs/screenshots/requests.png) |

</div>

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- ✅ **Flutter SDK** (3.5.4 or higher) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- ✅ **Dart SDK** (3.5.4 or higher)
- ✅ **Android Studio** or **Xcode** (for mobile development)
- ✅ **Firebase CLI** - [Install Firebase CLI](https://firebase.google.com/docs/cli)
- ✅ **Git**
- ✅ **VS Code** or **Android Studio** (recommended IDEs)

### 📥 Installation

#### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/ServiceLink.git
cd ServiceLink
```

#### Step 2: Install Dependencies

```bash
flutter pub get
```

#### Step 3: Configure Firebase 🔥

Follow the detailed guide in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

**Quick Setup:**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Configure Firebase for your project
flutterfire configure
```

This will generate `firebase_options.dart` automatically.

#### Step 4: Set Up SMTP Credentials ⚠️ **REQUIRED**

**For Email OTP functionality:**

```bash
# Copy the example file
Copy-Item lib\services\email_service.example.dart lib\services\email_service.dart

# Now edit lib/services/email_service.dart with your credentials
```

**For Gmail (Recommended):**
1. Enable 2-Factor Authentication on your Google Account
2. Generate an App Password: https://myaccount.google.com/apppasswords
3. Use the App Password in `email_service.dart` (NOT your regular Gmail password)

See [SMTP_SETUP.md](SMTP_SETUP.md) for detailed instructions.

#### Step 5: Deploy Firebase Rules

```bash
# Deploy Firestore security rules
firebase deploy --only firestore

# Deploy Storage rules
firebase deploy --only storage

# Deploy Realtime Database rules
firebase deploy --only database
```

See [FIREBASE_RULES.md](FIREBASE_RULES.md) for rule details.

#### Step 6: Run the App 🎉

```bash
# List available devices
flutter devices

# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Run on specific device
flutter run -d <device-id>
```

### 🔧 Important Configuration Files

| File | Purpose | Example File | Required | Status |
|------|---------|--------------|----------|--------|
| `lib/services/email_service.dart` | SMTP email credentials | `email_service.example.dart` | ✅ **Yes** | Must create from example |
| `lib/firebase_options.dart` | Firebase configuration | `firebase_options.example.dart` | ✅ **Yes** | Auto-generated by FlutterFire CLI |
| `android/app/google-services.json` | Android Firebase config | - | ✅ **Yes** | Downloaded from Firebase Console |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config | - | ⚪ Optional | For iOS builds only |

**⚠️ CRITICAL SECURITY NOTE:**
- **NEVER commit** files with real credentials to Git
- Always use `.example.dart` files as templates
- The `.gitignore` is already configured to protect sensitive files
- Real credential files are ignored by Git automatically

---

## 🏗️ Architecture

ServiceLink follows **Clean Architecture** principles with the **MVVM (Model-View-ViewModel)** pattern:

```
lib/
├── main.dart                    # App entry point & Firebase initialization
├── firebase_options.dart        # Firebase configuration (gitignored)
├── models/                      # Data models & entities
│   ├── user_model.dart         # User/Worker data structure
│   ├── request_model.dart      # Job request data structure
│   ├── chat_model.dart         # Chat conversation model
│   ├── message_model.dart      # Individual message model
│   └── review_model.dart       # Review & rating model
├── screens/                     # UI Layer (Views)
│   ├── auth/                   # Authentication screens
│   │   ├── signin_screen.dart
│   │   ├── signup_screen.dart
│   │   └── role_selection_screen.dart
│   ├── customer/               # Customer-specific screens
│   │   ├── customer_home_screen.dart
│   │   ├── worker_detail_screen.dart
│   │   └── customer_requests_screen.dart
│   ├── worker/                 # Worker-specific screens
│   │   ├── worker_home_screen.dart
│   │   └── worker_requests_screen.dart
│   ├── chat/                   # Chat functionality
│   │   ├── chat_list_screen.dart
│   │   └── chat_room_screen.dart
│   └── others/                 # Shared screens
│       ├── splash_screen.dart
│       ├── main_screen.dart
│       └── profile_screen.dart
├── services/                    # Business Logic Layer
│   ├── auth_service.dart       # Authentication logic
│   ├── firestore_service.dart  # Database operations
│   ├── storage_service.dart    # File upload/download
│   ├── email_service.dart      # Email & OTP (gitignored)
│   ├── chat_service.dart       # Real-time chat
│   └── messaging_service.dart  # Push notifications
├── providers/                   # State Management (ViewModels)
│   ├── auth_provider.dart      # Auth state management
│   ├── request_provider.dart   # Request state management
│   ├── worker_provider.dart    # Workers list state
│   └── chat_provider.dart      # Chat state management
├── widgets/                     # Reusable UI Components
│   ├── worker_card.dart
│   └── request_card.dart
└── utils/                       # Utilities & Constants
    ├── constants.dart
    └── theme.dart
```

### 🔄 Design Patterns

- **MVVM Architecture**: Separation of UI, Business Logic, and Data
- **Provider Pattern**: Reactive state management
- **Repository Pattern**: Data layer abstraction
- **Singleton Pattern**: Service classes
- **Factory Pattern**: Model creation

### 🗄️ Backend Services

- **Firebase Authentication** - User authentication & Google Sign-In
- **Cloud Firestore** - NoSQL database for users, requests, reviews
- **Firebase Storage** - Profile pictures and work portfolios
- **Realtime Database** - Real-time chat functionality
- **Firebase Cloud Messaging** - Push notifications (FCM)
- **SMTP Email Service** - OTP verification and notifications

---

## 📦 Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase Services
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0
  firebase_storage: ^12.3.6
  firebase_database: ^11.1.5
  firebase_messaging: ^15.1.5
  
  # State Management
  provider: ^6.1.2
  
  # UI & Design
  google_fonts: ^6.2.1
  cached_network_image: ^3.4.1
  image_picker: ^1.1.2
  flutter_rating_bar: ^4.0.1
  
  # Authentication
  google_sign_in: ^6.2.2
  
  # Email Service
  mailer: ^6.1.2
  
  # Utilities
  intl: ^0.19.0
  path_provider: ^2.1.5
  sqflite: ^2.4.1
```

For the complete list, see [pubspec.yaml](pubspec.yaml).

---

## 🔐 Security

### Credentials Management

✅ **Best Practices Implemented:**

- All sensitive credentials stored in separate files
- Example files (`.example.dart`) provided as templates
- `.gitignore` configured to exclude real credential files
- Firebase Security Rules implemented for all services
- User authentication required for all operations
- Email verification with OTP
- Secure password storage (Firebase handles this)

### Firebase Security Rules

**Firestore Database Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if true;  // Public profiles
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Requests collection
    match /requests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

**Realtime Database Rules:**

```json
{
  "rules": {
    "chats": {
      "$chatId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

**Storage Rules:**

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_pictures/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Security Checklist

- [x] Credentials stored outside of source code
- [x] `.gitignore` configured properly
- [x] Firebase Security Rules implemented
- [x] User authentication required
- [x] Email verification system
- [x] HTTPS for all API calls
- [x] Input validation on client side
- [x] File upload size limits
- [ ] Server-side validation (future enhancement)
- [ ] Rate limiting (future enhancement)

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate coverage report
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html

# Run specific test file
flutter test test/widget_test.dart

# Run tests in watch mode
flutter test --watch
```

---

## 📱 Building for Release

### Android Release Build

```bash
# Build APK (for direct installation)
flutter build apk --release

# Build App Bundle (recommended for Google Play Store)
flutter build appbundle --release

# Build APK split by ABI (smaller file sizes)
flutter build apk --split-per-abi --release
```

**Output locations:**
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`

### iOS Release Build

```bash
# Build for iOS (requires macOS with Xcode)
flutter build ios --release

# Build IPA file
flutter build ipa --release
```

**Note:** iOS builds require:
- macOS with Xcode installed
- Apple Developer account
- Proper code signing certificates

---

## 🎯 Usage Guide

### For Customers 👥

1. **Sign Up**: Create account using email or Google Sign-In
2. **Select Role**: Choose "Customer" role
3. **Browse Workers**: Search by service type or location
4. **View Profiles**: Check ratings, reviews, and portfolios
5. **Send Request**: Submit job request with your budget
6. **Chat**: Communicate with worker after acceptance
7. **Complete Job**: Mark as completed when satisfied
8. **Leave Review**: Rate and review the service

### For Workers 🔧

1. **Sign Up**: Create account using email or Google Sign-In
2. **Select Role**: Choose "Worker" role
3. **Setup Profile**: Add photo, service type, rate, description
4. **Upload Portfolio**: Add work samples to showcase skills
5. **Receive Requests**: View incoming job requests
6. **Accept Jobs**: Accept requests that fit your schedule
7. **Chat with Customers**: Discuss job details
8. **Build Reputation**: Earn positive reviews and ratings

---

## 🗺️ Roadmap & Future Features

### Phase 1 (Current - ✅ Completed)
- [x] User authentication system
- [x] Worker profiles and browsing
- [x] Job request system
- [x] Real-time chat
- [x] Reviews and ratings
- [x] Email OTP verification

### Phase 2 (Planned)
- [ ] **Payment Gateway Integration** (Stripe, PayPal, JazzCash)
- [ ] **In-app Wallet** system
- [ ] **Advanced Search Filters** (price range, distance, availability)
- [ ] **Worker Availability Calendar**
- [ ] **Service Packages** and subscriptions

### Phase 3 (Future)
- [ ] **Multi-language Support** (Urdu, English)
- [ ] **Dark Mode** theme
- [ ] **In-app Video Calls**
- [ ] **Location-based Search** with maps integration
- [ ] **Push Notifications** for all events
- [ ] **Worker Verification Badges**
- [ ] **Loyalty Programs** and rewards
- [ ] **Advanced Analytics Dashboard**
- [ ] **Emergency Service Requests**
- [ ] **Export Reports** (PDF invoices, work history)

---

## 🤝 Contributing

We welcome contributions from the community! Here's how you can help:

### How to Contribute

1. **Fork** the repository
2. **Clone** your fork locally
   ```bash
   git clone https://github.com/your-username/ServiceLink.git
   cd ServiceLink
   ```
3. **Create a branch** for your feature
   ```bash
   git checkout -b feature/amazing-feature
   ```
4. **Make your changes** and commit
   ```bash
   git commit -m "Add some amazing feature"
   ```
5. **Push** to your fork
   ```bash
   git push origin feature/amazing-feature
   ```
6. **Open a Pull Request** on GitHub

### Development Guidelines

- Follow Flutter/Dart style guidelines
- Write meaningful commit messages
- Add comments for complex logic
- Update documentation for new features
- Ensure all tests pass before submitting PR
- Keep PRs focused on a single feature/fix
- Test on both Android and iOS when possible

### Code Style

- Use `flutter format .` before committing
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable and function names
- Keep functions small and focused
- Add documentation comments for public APIs

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2025 ServiceLink

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

This means you can:
- ✅ Use commercially
- ✅ Modify
- ✅ Distribute
- ✅ Use privately

---

## 👨‍💻 Authors & Team

**Project Creator & Maintainer**
- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

**Contributors**
- See [Contributors Page](https://github.com/yourusername/ServiceLink/graphs/contributors)

---

## 🙏 Acknowledgments

Special thanks to:

- **Flutter Team** - For the incredible cross-platform framework
- **Firebase** - For comprehensive backend infrastructure
- **Google Fonts** - For the beautiful Poppins font family
- **Material Design** - For UI/UX design guidelines
- **Open Source Community** - For amazing packages and inspiration
- **Early Testers** - For valuable feedback and bug reports

---

## 📞 Support & Documentation

### 📚 Documentation

| Document | Description |
|----------|-------------|
| [Quick Start Guide](QUICKSTART.md) | Get started quickly |
| [Firebase Setup](FIREBASE_SETUP.md) | Complete Firebase configuration |
| [SMTP Configuration](SMTP_SETUP.md) | Email service setup |
| [Firebase Rules](FIREBASE_RULES.md) | Security rules explanation |
| [Firestore Indexes](FIRESTORE_INDEXES_SETUP.md) | Database indexing |
| [Project Summary](PROJECT_SUMMARY.md) | Project overview |

### 🆘 Need Help?

**If you have questions or need assistance:**

1. 📖 Check the [Documentation](#-documentation) first
2. 🔍 Search [Existing Issues](https://github.com/yourusername/ServiceLink/issues)
3. 💬 Join our [Discussions](https://github.com/yourusername/ServiceLink/discussions)
4. 🐛 Report bugs via [New Issue](https://github.com/yourusername/ServiceLink/issues/new)
5. 📧 Email: support@servicelink.com

### 🐛 Found a Bug?

Please report bugs by opening an issue and include:

- **Description** of the bug
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Device & OS information**
- **Flutter/Dart version**
- **Error logs** (if any)

---

## 📊 Project Statistics

- **Total Files:** 35+
- **Lines of Code:** 4,000+
- **Screens:** 11
- **Data Models:** 5
- **Services:** 6
- **State Providers:** 4
- **Reusable Widgets:** 5+
- **Dependencies:** 20+

---

## 🌟 Show Your Support

If you find ServiceLink useful or interesting, please consider:

- ⭐ **Star** this repository
- 🐛 **Report bugs** and issues
- 💡 **Suggest** new features
- 🤝 **Contribute** to the codebase
- 📢 **Share** with others
- 📝 **Write** about your experience

<div align="center">

### Star History

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/ServiceLink&type=Date)](https://star-history.com/#yourusername/ServiceLink&Date)

</div>

---

## 📈 Project Status

🟢 **Active Development** - This project is actively maintained and updated regularly.

**Latest Update:** November 2025

---

<div align="center">

### 💙 Built with Flutter & Firebase

**ServiceLink** - *Making Local Services Accessible & Reliable!* 🔧🏠✨

[⬆ Back to Top](#-servicelink)

---

[Report Bug](https://github.com/yourusername/ServiceLink/issues) • 
[Request Feature](https://github.com/yourusername/ServiceLink/issues) • 
[Documentation](QUICKSTART.md) • 
[Discussions](https://github.com/yourusername/ServiceLink/discussions)

---

*Made with ❤️ by developers, for the community*

*Last Updated: November 15, 2025*

</div>
