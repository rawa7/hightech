# Firebase Cloud Messaging (FCM) Setup Guide

This guide will walk you through setting up Firebase Cloud Messaging for push notifications in your HighTech Flutter app.

## Prerequisites

- A Google account
- Your Android package name (from `android/app/build.gradle.kts`)
- For iOS: An Apple Developer account (if you want iOS support)

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click on **"Add project"** or **"Create a project"**
3. Enter project name: **"HighTech"** (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Choose or create a Google Analytics account
6. Click **"Create project"**

## Step 2: Add Android App to Firebase

1. In your Firebase project, click the **Android icon** to add an Android app
2. **Android package name**: 
   - Open `android/app/build.gradle.kts`
   - Find `applicationId` (usually something like `com.example.hightech`)
   - Copy and paste it into Firebase
3. **App nickname**: HighTech Android (optional)
4. **Debug signing certificate SHA-1** (optional for now, needed for some features)
5. Click **"Register app"**

## Step 3: Download google-services.json

1. After registering, Firebase will provide a **google-services.json** file
2. Click **"Download google-services.json"**
3. Move this file to your project's `android/app/` directory
   ```
   D:\hightech\android\app\google-services.json
   ```

## Step 4: Update Android Build Files

### 4.1 Update project-level build.gradle.kts

Open `android/build.gradle.kts` and add the Google services plugin:

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
    // Add this line
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

### 4.2 Update app-level build.gradle.kts

Open `android/app/build.gradle.kts` and add at the top (after existing plugins):

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // Add this line
    id("com.google.gms.google-services")
}
```

## Step 5: Add iOS App to Firebase (Optional)

If you want iOS support:

1. In Firebase Console, click the **iOS icon**
2. **iOS bundle ID**: 
   - Open `ios/Runner.xcodeproj` in Xcode
   - Find the Bundle Identifier
   - Or check `ios/Runner/Info.plist`
3. Download **GoogleService-Info.plist**
4. Open your project in Xcode
5. Drag **GoogleService-Info.plist** into `ios/Runner/` folder
6. Make sure "Copy items if needed" is checked

### iOS Additional Setup

Update `ios/Runner/AppDelegate.swift`:

```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Step 6: Install Dependencies

Run the following commands in your project directory:

```bash
# Install Flutter dependencies
flutter pub get

# For iOS only (if applicable)
cd ios
pod install
cd ..
```

## Step 7: Create firebase_options.dart (Alternative Method)

Instead of manually configuring, you can use FlutterFire CLI:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will automatically create `lib/firebase_options.dart` and configure your apps.

If you use this method, update `lib/main.dart`:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ... rest of your code
}
```

## Step 8: Enable Cloud Messaging in Firebase Console

1. In Firebase Console, go to **Build** → **Cloud Messaging**
2. If prompted, enable Cloud Messaging API
3. Click on **"Cloud Messaging API (Legacy)"** if needed and enable it

## Step 9: Test Notifications

### 9.1 Run Your App

```bash
flutter run
```

### 9.2 Get FCM Token

When your app starts, check the console/logs for the FCM token:
```
FCM Token: YOUR_DEVICE_TOKEN_HERE
```

Copy this token - you'll need it to send test notifications.

### 9.3 Send Test Notification from Firebase Console

1. Go to Firebase Console → **Engage** → **Cloud Messaging**
2. Click **"Send your first message"**
3. **Notification title**: Test Notification
4. **Notification text**: This is a test from Firebase!
5. Click **"Send test message"**
6. Paste your FCM token
7. Click **"Test"**

### 9.4 Test with REST API

You can also send notifications using the Firebase REST API:

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test notification!",
      "sound": "default"
    },
    "data": {
      "type": "order",
      "orderId": "12345"
    }
  }'
```

To get your **Server Key**:
1. Firebase Console → Project Settings → Cloud Messaging
2. Copy the **Server key** under Cloud Messaging API (Legacy)

## Step 10: Subscribe to Topics (Optional)

Topics allow you to send notifications to groups of devices:

```dart
// Subscribe to a topic
await NotificationService().subscribeToTopic('all_users');
await NotificationService().subscribeToTopic('promotions');

// Unsubscribe from a topic
await NotificationService().unsubscribeFromTopic('promotions');
```

Send to topic from Firebase Console:
1. Cloud Messaging → New campaign
2. Choose **"Firebase Notification messages"**
3. Create your notification
4. Under **Target**, select **"Topic"**
5. Enter your topic name

## Usage in Your App

### Get FCM Token

```dart
String? token = NotificationService().fcmToken;
print('My FCM Token: $token');
```

### Handle Notifications in Specific Screens

Update `lib/services/notification_service.dart` to handle navigation:

```dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  
  if (data['type'] == 'order') {
    navigatorKey.currentState?.pushNamed(
      '/order-detail',
      arguments: data['orderId'],
    );
  } else if (data['type'] == 'promotion') {
    navigatorKey.currentState?.pushNamed('/shop');
  }
}
```

### Send Token to Your Backend

After user login, send the FCM token to your backend:

```dart
// In your login success handler
String? fcmToken = NotificationService().fcmToken;
await ApiService().sendFCMToken(fcmToken, userId);
```

## Notification Payload Structure

When sending notifications from your backend, use this structure:

```json
{
  "to": "DEVICE_FCM_TOKEN",
  "notification": {
    "title": "New Order",
    "body": "You have a new order #12345",
    "sound": "default",
    "badge": "1"
  },
  "data": {
    "type": "order",
    "orderId": "12345",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "priority": "high"
}
```

## Troubleshooting

### Android Issues

1. **Notifications not received**:
   - Make sure `google-services.json` is in `android/app/`
   - Check if Google Play Services is installed on device
   - Verify app has notification permission

2. **Build errors**:
   - Run `flutter clean` and `flutter pub get`
   - Check Gradle files are properly configured

### iOS Issues

1. **Notifications not received**:
   - Enable Push Notifications in Xcode capabilities
   - Upload APNs certificate to Firebase Console
   - Test on physical device (not simulator)

2. **Permission denied**:
   - Check Info.plist has notification descriptions
   - Request permission properly in code

### General Issues

1. **Token not generated**:
   - Check internet connection
   - Verify Firebase is properly initialized
   - Check console for errors

2. **Foreground notifications not showing**:
   - Local notifications package might not be configured
   - Check notification channel is created (Android)

## Production Checklist

Before deploying to production:

- [ ] Upload APNs certificates to Firebase (iOS)
- [ ] Implement backend API to send notifications
- [ ] Store FCM tokens in your database
- [ ] Handle token refresh on your backend
- [ ] Test notifications on multiple devices
- [ ] Test background, foreground, and terminated states
- [ ] Implement notification action buttons if needed
- [ ] Add analytics for notification open rates
- [ ] Set up notification topics for user segments
- [ ] Test deep linking from notifications

## Next Steps

1. **Integrate with Backend**: Send FCM tokens to your backend server
2. **Custom Notifications**: Create custom notification layouts
3. **Rich Notifications**: Add images, action buttons
4. **Analytics**: Track notification delivery and open rates
5. **User Preferences**: Allow users to manage notification settings

## Resources

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Flutter Local Notifications Package](https://pub.dev/packages/flutter_local_notifications)

---

**Note**: Keep your **Server Key** and **google-services.json** secure and never commit them to public repositories!

