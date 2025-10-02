# 🔔 Firebase Push Notifications - Quick Setup

## ⚡ Quick Start (2 Steps)

### Step 1: Download Service Account Key

1. Go to: **https://console.firebase.google.com/project/hightech-bab87/settings/serviceaccounts/adminsdk**
2. Click **"Generate new private key"**
3. Save the file as **`firebase-service-account.json`** in this folder (`D:\hightech\`)

### Step 2: Test It!

Run this command:
```powershell
php send_notification.php
```

You should receive a notification on your device! 🎉

---

## 📁 Files Overview

- **`send_notification.php`** - Main script to send notifications (already configured with your FCM token)
- **`notification_examples.php`** - Common notification patterns (orders, promotions, alerts)
- **`PHP_NOTIFICATION_GUIDE.md`** - Complete documentation with examples
- **`firebase-service-account.json`** - (You need to download this) Service account credentials

---

## 🚀 Usage Examples

### Send Order Confirmation
```php
require_once 'notification_examples.php';

sendOrderConfirmation(
    $userFcmToken,
    'ORD12345',  // Order ID
    249.99       // Total amount
);
```

### Send Order Status Update
```php
sendOrderStatusUpdate(
    $userFcmToken,
    'ORD12345',
    'shipped'  // Status: processing, shipped, delivered, cancelled
);
```

### Send Promotion
```php
sendPromotion(
    $userFcmToken,
    'Flash Sale',           // Title
    '50% off electronics',  // Description
    50                      // Discount percentage
);
```

### Send to Multiple Users
```php
$tokens = [$token1, $token2, $token3];

sendToMultipleUsers(
    $tokens,
    'System Update',
    'New features are now available!',
    ['type' => 'update', 'version' => '2.0']
);
```

---

## 🔗 Integration with Your Backend

### Step 1: Add FCM Token Column
```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255) DEFAULT NULL;
ALTER TABLE users ADD COLUMN fcm_token_updated_at TIMESTAMP NULL;
```

### Step 2: Save Token on Login
```php
$fcmToken = $_POST['fcm_token'];
$userId = $_SESSION['user_id'];

$stmt = $conn->prepare("UPDATE users SET fcm_token = ? WHERE id = ?");
$stmt->bind_param("si", $fcmToken, $userId);
$stmt->execute();
```

### Step 3: Send Notification
```php
require_once 'send_notification.php';

// Get user's FCM token
$stmt = $conn->prepare("SELECT fcm_token FROM users WHERE id = ?");
$stmt->bind_param("i", $userId);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();

// Send notification
if ($user['fcm_token']) {
    $result = sendPushNotification(
        $user['fcm_token'],
        'Order Confirmed! 🎉',
        'Your order has been confirmed',
        ['type' => 'order', 'order_id' => 'ORD12345'],
        'hightech-bab87',
        __DIR__ . '/firebase-service-account.json'
    );
}
```

---

## 🔍 Testing

### Your Current FCM Token:
```
ePm2XDf_RaG32VjbpIubjX:APA91bGV925vu7YCOFP1jmmL19CARI5F4EfR496k9XUFnzx6u9HPDp6OFkbQkm25rIM4A9QAzRZznWM-XyFimrVZoHiCd4prCKgzkm2sh7ycbl6HpoPR0JA
```

This token is already set in `send_notification.php` for testing.

### Test Commands:
```powershell
# Test basic notification
php send_notification.php

# Test from browser
# Open: http://localhost/send_notification.php
```

---

## ⚠️ Important Notes

1. **Security**: The `firebase-service-account.json` file contains sensitive credentials
   - ✅ Already added to `.gitignore`
   - ⚠️ Never commit it to version control
   - ⚠️ Never share it publicly

2. **API Version**: Uses **FCM V1 API** (the modern, supported version)
   - Legacy API was shut down in June 2024
   - V1 API uses OAuth 2.0 authentication

3. **Data Values**: All data payload values must be strings
   ```php
   // ✅ Correct
   ['order_id' => '12345', 'amount' => '249.99']
   
   // ❌ Wrong
   ['order_id' => 12345, 'amount' => 249.99]
   ```

---

## 🐛 Troubleshooting

### "Service account file not found"
- Download the JSON file from Firebase Console
- Save it as `firebase-service-account.json` in project root

### "Invalid authentication credentials" (HTTP 401)
- Regenerate service account key from Firebase Console

### "Invalid registration token" (HTTP 400)
- The FCM token is expired or invalid
- Get a fresh token from your Flutter app

### Notification sent but not received
- Check app has notification permissions
- Verify device is connected to internet
- Ensure app is running or in background

---

## 📚 Full Documentation

See **`PHP_NOTIFICATION_GUIDE.md`** for:
- Complete API reference
- Security best practices
- Advanced features (caching, queuing, scheduling)
- Performance optimization tips
- More examples and use cases

---

## ✅ Quick Checklist

- [ ] Download `firebase-service-account.json` from Firebase Console
- [ ] Place it in project root (`D:\hightech\`)
- [ ] Run `php send_notification.php`
- [ ] Receive notification on device
- [ ] Add `fcm_token` column to database
- [ ] Integrate with your backend

---

## 🆘 Need Help?

1. Check **`PHP_NOTIFICATION_GUIDE.md`** for detailed documentation
2. Verify FCM V1 API is enabled in Firebase Console
3. Check Firebase Status: https://status.firebase.google.com/

**Firebase Console**: https://console.firebase.google.com/project/hightech-bab87

**Project Info:**
- Project ID: `hightech-bab87`
- Project Number: `669250940659`
- Package: `tech.high.golden.hightech`

