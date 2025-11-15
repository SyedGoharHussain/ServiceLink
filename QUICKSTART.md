# ServiceLink - Quick Start Guide

## 🚀 Quick Setup (5 Minutes)

### Step 1: Install Dependencies
```bash
flutter pub get
```
✅ **Done!** All packages are already configured.

### Step 2: Firebase Setup (Choose One Method)

#### Option A: FlutterFire CLI (Recommended - Fastest)
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (will create project and setup all platforms)
flutterfire configure
```

This automatically:
- Creates Firebase project
- Configures Android & iOS
- Downloads config files
- Generates `lib/firebase_options.dart`

Then update `lib/main.dart`:
```dart
import 'firebase_options.dart';

await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

#### Option B: Manual Setup (See FIREBASE_SETUP.md)

### Step 3: Enable Firebase Services

In Firebase Console:

1. **Authentication** → Enable Email/Password & Google
2. **Firestore Database** → Create database (production mode)
3. **Realtime Database** → Create database
4. **Storage** → Get started
5. **Cloud Messaging** → (Auto-configured)

### Step 4: Set Security Rules

**Firestore:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /requests/{requestId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Realtime Database:**
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

**Storage:**
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

### Step 5: Run the App
```bash
flutter run
```

## 🎉 You're Done!

The app is now ready to use. Test the following flows:

### Test as Customer:
1. Sign up with email
2. Select "Customer" role
3. Browse workers
4. Send a job request

### Test as Worker:
1. Sign up with different email
2. Select "Worker" role
3. Complete profile
4. Check requests tab

## 📱 App Flow

```
Sign In/Sign Up
    ↓
Role Selection (Customer/Worker)
    ↓
Main Screen (Bottom Navigation)
    ├── Home (Browse workers OR View dashboard)
    ├── Requests (Manage job requests)
    ├── Chat (Real-time messaging)
    └── Profile (Edit profile & settings)
```

## 🔥 Key Features to Test

### Customer Flow:
1. **Browse** → Search workers by city/service
2. **View Profile** → Check ratings and rates
3. **Hire** → Send request with budget
4. **Chat** → Message after acceptance
5. **Complete** → Mark done and leave review

### Worker Flow:
1. **Setup Profile** → Add service type, rate, description
2. **Receive Requests** → View on home/requests tab
3. **Accept/Reject** → Manage incoming requests
4. **Chat** → Communicate with customer
5. **Build Rating** → Get reviews from customers

## 🛠️ Development Tips

### Hot Reload
```bash
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
```

### Debug Mode
```bash
flutter run --debug
```

### Build for Release
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Check for Issues
```bash
flutter doctor
flutter analyze
```

## 🐛 Common Issues & Fixes

### Issue: "No Firebase App"
**Fix:** Make sure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in place.

### Issue: Google Sign-In not working
**Fix:** 
1. Add SHA-1 to Firebase Console
2. Download new `google-services.json`
3. Rebuild app

```bash
# Get SHA-1
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
# Password: android
```

### Issue: Build errors
**Fix:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: iOS CocoaPods
**Fix:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

## 📊 Database Structure

### Users Collection (`users/`)
```json
{
  "uid": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "role": "worker",
  "city": "Los Angeles",
  "serviceType": "Plumber",
  "rate": 50,
  "rating": 4.5,
  "reviewCount": 10,
  "profileImage": "https://..."
}
```

### Requests Collection (`requests/`)
```json
{
  "requestId": "req123",
  "customerId": "customer123",
  "workerId": "worker456",
  "serviceType": "Plumbing",
  "price": 200,
  "status": "accepted",
  "description": "Fix leaky faucet",
  "createdAt": "timestamp"
}
```

### Chats (Realtime DB) (`chats/`)
```json
{
  "chat_id_123_456": {
    "participants": ["user123", "user456"],
    "lastMessage": "Hello!",
    "messages": {
      "msg1": {
        "senderId": "user123",
        "text": "Hello!",
        "timestamp": 1234567890
      }
    }
  }
}
```

## 🎨 Customization

### Change Colors
Edit `lib/utils/constants.dart`:
```dart
static const Color primaryColor = Color(0xFF4A90E2);  // Change this
static const Color backgroundColor = Color(0xFFF5F7FA);
```

### Add Service Types
Edit `lib/utils/constants.dart`:
```dart
static const List<String> serviceTypes = [
  'Carpenter',
  'Plumber',
  'Your New Service',  // Add here
];
```

### Change Font
Edit `lib/utils/theme.dart`:
```dart
textTheme: GoogleFonts.robotoTextTheme(),  // Change from poppins
```

## 📦 Build & Deploy

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS (requires Mac & Xcode)
```bash
flutter build ios --release
# Then open Xcode and archive
```

## 🔐 Production Checklist

- [ ] Update security rules to be more restrictive
- [ ] Enable App Check for security
- [ ] Set up proper error handling
- [ ] Add analytics
- [ ] Configure app signing
- [ ] Test on real devices
- [ ] Add privacy policy & terms
- [ ] Set up CI/CD
- [ ] Configure rate limiting
- [ ] Enable crashlytics

## 📞 Need Help?

1. Check `FIREBASE_SETUP.md` for detailed Firebase configuration
2. Check `README.md` for complete documentation
3. Review Firebase Console for proper setup
4. Check Flutter/Firebase documentation

## 🎯 Next Steps

1. **Test thoroughly** on both Android and iOS
2. **Customize** the UI to match your brand
3. **Add features** like payment integration, scheduling, etc.
4. **Deploy** to Play Store and App Store

---

**Happy Coding! 🚀**

ServiceLink - "Connecting You to Reliable Local Help"
