# Firebase FCM Quick Start Guide

## 🚀 Quick Setup (5 Minutes)

### Your App Package Name
```
tech.high.golden.hightech
```

### Step 1: Firebase Console Setup (2 minutes)

1. Go to https://console.firebase.google.com/
2. Click **"Add project"** → Name it "HighTech" → Click **Create**
3. Click **Android icon** → Enter package name: `tech.high.golden.hightech`
4. Download **google-services.json**
5. Move file to: `D:\hightech\android\app\google-services.json`

### Step 2: Install Dependencies (2 minutes)

Open PowerShell in your project directory:

```powershell
cd D:\hightech
flutter pub get
```

### Step 3: Run the App (1 minute)

```powershell
flutter run
```

Watch the console output for your FCM token:
```
FCM Token: [YOUR_TOKEN_HERE]
```

### Step 4: Send Test Notification via PHP

1. **Download Service Account Key**:
   - Go to Firebase Console → Project Settings → **Service Accounts** tab
   - Click **"Generate new private key"**
   - Save as `firebase-service-account.json` in your project folder

2. **Run the PHP script**:
```powershell
php send_notification.php
```

3. You should receive the notification! 🎉

**See `PHP_NOTIFICATION_GUIDE.md` for complete setup guide**

## 📱 View Notification Settings in Your App

Add this to your home screen or settings:

```dart
// Navigate to notification settings
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationSettingsScreen(),
  ),
);
```

## 🔧 Backend Integration (FCM V1 API)

Send notifications from your PHP backend using the modern V1 API:

```php
require_once 'send_notification.php';

// Simple usage
$result = sendPushNotification(
    $userFcmToken,
    'New Order',
    'You have a new order #12345',
    [
        'type' => 'order',
        'orderId' => '12345'
    ],
    'hightech-bab87', // Project ID
    __DIR__ . '/firebase-service-account.json'
);

if ($result['success']) {
    echo "✅ Notification sent!";
} else {
    echo "❌ Failed: " . $result['error'];
}
```

**More examples in `notification_examples.php`**

## 📊 Store FCM Tokens in Database

Add to your users table:

```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255) DEFAULT NULL;
ALTER TABLE users ADD COLUMN fcm_token_updated_at TIMESTAMP NULL;
```

Update token after login:

```php
// In your login endpoint
$fcmToken = $_POST['fcm_token'] ?? null;
if ($fcmToken) {
    $stmt = $conn->prepare("UPDATE users SET fcm_token = ?, fcm_token_updated_at = NOW() WHERE id = ?");
    $stmt->bind_param("si", $fcmToken, $userId);
    $stmt->execute();
}
```

## 🎯 Common Use Cases

### 1. Order Status Updates
```php
require_once 'notification_examples.php';

// Send when order status changes
sendOrderStatusUpdate($userFcmToken, 'ORD12345', 'shipped');
```

### 2. New Promotion
```php
// Send to topic
sendToTopic(
    'promotions',
    'Special Offer!',
    '50% off on all electronics today!',
    ['type' => 'promotion', 'category' => 'electronics']
);
```

### 3. Low Stock Alert (Admin)
```php
sendLowStockAlert($adminFcmToken, 'iPhone 15 Pro', 5);
```

## 🐛 Troubleshooting

### No FCM Token?
- Check internet connection
- Restart the app
- Check console for errors

### Notifications not received?
- Ensure `google-services.json` is in correct location
- Check app has notification permission
- Verify Firebase project is active

### Build errors?
```powershell
flutter clean
flutter pub get
flutter run
```

## 📚 Full Documentation

See `FIREBASE_SETUP.md` for complete documentation.

## ✅ Checklist

- [ ] Created Firebase project
- [ ] Added `google-services.json` to `android/app/`
- [ ] Run `flutter pub get`
- [ ] App runs successfully
- [ ] FCM token appears in console
- [ ] Sent test notification from Firebase Console
- [ ] Notification received on device

---

**Need Help?** Check the full setup guide in `FIREBASE_SETUP.md`

