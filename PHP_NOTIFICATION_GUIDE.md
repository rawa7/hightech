# 📧 PHP Push Notification Guide (FCM V1 API)

## 🚀 Quick Start (3 Steps)

### Step 1: Download Firebase Service Account Key

1. Go to: https://console.firebase.google.com/
2. Select your project: **hightech-bab87**
3. Click the **gear icon (⚙️)** → **Project settings**
4. Go to the **"Service accounts"** tab
5. Click **"Generate new private key"**
6. Click **"Generate key"** to download the JSON file
7. Save it as **`firebase-service-account.json`** in your project directory

⚠️ **Important**: Keep this file secure! It contains sensitive credentials.

### Step 2: Place the Service Account File

Move the downloaded JSON file to your project root:
```
D:\hightech\firebase-service-account.json
```

### Step 3: Run the Script

**Option A: Run from Command Line**
```bash
php send_notification.php
```

**Option B: Run from Browser**
```
http://localhost/send_notification.php
```

You should see a success response and receive the notification on your device! 📱🎉

---

## 🔄 Why V1 API?

The **Firebase Cloud Messaging API (Legacy)** was deprecated on June 20, 2023 and shut down on June 20, 2024. 

✅ **New V1 API Benefits:**
- OAuth 2.0 authentication (more secure)
- Better error handling
- More features and flexibility
- Officially supported by Google

---

## 📱 Your Current FCM Token

```
ePm2XDf_RaG32VjbpIubjX:APA91bGV925vu7YCOFP1jmmL19CARI5F4EfR496k9XUFnzx6u9HPDp6OFkbQkm25rIM4A9QAzRZznWM-XyFimrVZoHiCd4prCKgzkm2sh7ycbl6HpoPR0JA
```

This token is already configured in `send_notification.php` for testing.

---

## 🔧 Integration with Your Backend

### Save FCM Token to Database

When user logs in or app starts, save their FCM token:

```php
<?php
// In your login endpoint or user update endpoint
$fcmToken = $_POST['fcm_token'] ?? null;
$userId = $_SESSION['user_id'];

if ($fcmToken && $userId) {
    $stmt = $conn->prepare("
        UPDATE users 
        SET fcm_token = ?, 
            fcm_token_updated_at = NOW() 
        WHERE id = ?
    ");
    $stmt->bind_param("si", $fcmToken, $userId);
    $stmt->execute();
}
?>
```

### Send Notification When Order is Placed

```php
<?php
require_once 'send_notification.php';

// After order is created
$orderId = 'ORD12345';
$userId = 123;

// Get user's FCM token from database
$stmt = $conn->prepare("SELECT fcm_token FROM users WHERE id = ?");
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

if ($user && $user['fcm_token']) {
    $result = sendPushNotification(
        $user['fcm_token'],
        'Order Confirmed! 🎉',
        "Your order #$orderId has been confirmed",
        [
            'type' => 'order_confirmed',
            'order_id' => (string)$orderId,
            'action' => 'view_order'
        ],
        'hightech-bab87', // PROJECT_ID
        __DIR__ . '/firebase-service-account.json'
    );
    
    if ($result['success']) {
        echo "Notification sent!";
    } else {
        echo "Failed: " . json_encode($result);
    }
}
?>
```

---

## 📊 Database Schema

Add FCM token column to your users table:

```sql
ALTER TABLE users ADD COLUMN fcm_token VARCHAR(255) DEFAULT NULL;
ALTER TABLE users ADD COLUMN fcm_token_updated_at TIMESTAMP NULL;
ALTER TABLE users ADD INDEX idx_fcm_token (fcm_token);
```

---

## 🎯 Common Use Cases

### 1. Order Notifications
```php
require_once 'notification_examples.php';

// Order confirmed
sendOrderConfirmation($fcmToken, 'ORD12345', 249.99);

// Order shipped
sendOrderStatusUpdate($fcmToken, 'ORD12345', 'shipped');

// Payment received
sendPaymentReceived($fcmToken, 'ORD12345', 249.99);
```

### 2. Promotional Notifications
```php
// Send to specific user
sendPromotion(
    $fcmToken,
    'Flash Sale',
    '50% off all electronics',
    50
);

// Send to all users subscribed to 'promotions' topic
sendToTopic(
    'promotions',
    'Weekend Sale! 🎊',
    'Get 30% off on all products this weekend',
    ['type' => 'promotion', 'code' => 'WEEKEND30']
);
```

### 3. Admin Alerts
```php
// Low stock alert
sendLowStockAlert($adminFcmToken, 'iPhone 15 Pro', 5);

// New order alert
sendPushNotification(
    $adminFcmToken,
    'New Order! 🔔',
    'Order #ORD12345 placed by John Doe',
    [
        'type' => 'new_order',
        'order_id' => 'ORD12345',
        'action' => 'view_order'
    ],
    'hightech-bab87',
    __DIR__ . '/firebase-service-account.json'
);
```

---

## 🔍 Testing & Debugging

### Test Single Notification

Run the test script:
```bash
php send_notification.php
```

Expected output (SUCCESS):
```json
{
    "success": true,
    "http_code": 200,
    "response": {
        "name": "projects/669250940659/messages/0:1234567890"
    }
}
```

### Common Issues

**❌ Service account file not found**
```
Error: Service account file not found
```
- Solution: Download the JSON file from Firebase Console and save as `firebase-service-account.json`

**❌ HTTP Code 401 - Unauthorized**
```json
{
    "error": {
        "code": 401,
        "message": "Request had invalid authentication credentials"
    }
}
```
- Solution: Regenerate your service account key

**❌ HTTP Code 400 - Invalid Token**
```json
{
    "error": {
        "code": 400,
        "message": "Invalid registration token"
    }
}
```
- Solution: The FCM token is invalid or expired. Get a fresh token from your app

**❌ HTTP Code 403 - Permission Denied**
```json
{
    "error": {
        "code": 403,
        "message": "Permission denied"
    }
}
```
- Solution: Make sure FCM V1 API is enabled in Firebase Console

**✅ Success but no notification received**
- Check app has notification permissions
- Ensure app is running or in background
- Verify `google-services.json` is correctly configured
- Check device is connected to internet

---

## 🔐 Security Best Practices

### 1. Protect Service Account File

```php
// Add to .gitignore
firebase-service-account.json
```

### 2. Store Outside Web Root (Recommended)

```php
// Instead of:
$SERVICE_ACCOUNT_FILE = __DIR__ . '/firebase-service-account.json';

// Use:
$SERVICE_ACCOUNT_FILE = '/var/secure/firebase-service-account.json';
```

### 3. Set Proper File Permissions

```bash
chmod 600 firebase-service-account.json
chown www-data:www-data firebase-service-account.json
```

---

## 📚 Advanced Features

### Scheduled Notifications

Create a cron job to send scheduled notifications:

```php
<?php
// scheduled_notifications.php
require_once 'send_notification.php';

$PROJECT_ID = 'hightech-bab87';
$SERVICE_ACCOUNT = __DIR__ . '/firebase-service-account.json';

// Get users who should receive daily reminders
$stmt = $conn->query("
    SELECT fcm_token, name 
    FROM users 
    WHERE notification_preferences LIKE '%daily_reminder%'
    AND fcm_token IS NOT NULL
");

while ($user = $stmt->fetch_assoc()) {
    sendPushNotification(
        $user['fcm_token'],
        'Daily Reminder 📅',
        "Hi {$user['name']}, check out our new products!",
        ['type' => 'daily_reminder'],
        $PROJECT_ID,
        $SERVICE_ACCOUNT
    );
}
?>
```

Add to crontab:
```bash
# Send daily notifications at 9 AM
0 9 * * * /usr/bin/php /path/to/scheduled_notifications.php
```

### Batch Notifications

Send to multiple users efficiently:

```php
<?php
require_once 'notification_examples.php';

// Get all admin FCM tokens
$stmt = $conn->query("
    SELECT fcm_token 
    FROM users 
    WHERE role = 'admin' 
    AND fcm_token IS NOT NULL
");

$adminTokens = [];
while ($row = $stmt->fetch_assoc()) {
    $adminTokens[] = $row['fcm_token'];
}

// Send to all admins
$results = sendToMultipleUsers(
    $adminTokens,
    'System Alert 🚨',
    'Server load is high - 85%',
    ['type' => 'system_alert', 'level' => 'warning']
);

// Check results
foreach ($results as $i => $result) {
    if ($result['success']) {
        echo "✅ Sent to admin " . ($i + 1) . "\n";
    } else {
        echo "❌ Failed to send to admin " . ($i + 1) . "\n";
    }
}
?>
```

---

## 🎨 Notification Data Handling in Flutter

Your Flutter app will automatically handle these notifications. The data payload can trigger specific actions:

```dart
// Already implemented in your app
RemoteMessage message = ...;

switch (message.data['type']) {
  case 'order_confirmed':
    // Navigate to order details
    Navigator.pushNamed(context, '/order', 
      arguments: {'orderId': message.data['order_id']});
    break;
    
  case 'promotion':
    // Navigate to products
    Navigator.pushNamed(context, '/products');
    break;
    
  case 'payment_received':
    // Show receipt
    Navigator.pushNamed(context, '/receipt',
      arguments: {'orderId': message.data['order_id']});
    break;
}
```

---

## ⚡ Performance Tips

### 1. Cache Access Token

Access tokens are valid for 1 hour. Cache them to avoid regenerating:

```php
function getCachedAccessToken($serviceAccountFile) {
    $cacheFile = sys_get_temp_dir() . '/fcm_token_cache.json';
    
    // Check if cached token exists and is valid
    if (file_exists($cacheFile)) {
        $cache = json_decode(file_get_contents($cacheFile), true);
        if ($cache && $cache['expires_at'] > time() + 300) { // 5 min buffer
            return $cache['token'];
        }
    }
    
    // Get new token
    $token = getAccessToken($serviceAccountFile);
    
    // Cache it
    file_put_contents($cacheFile, json_encode([
        'token' => $token,
        'expires_at' => time() + 3600
    ]));
    
    return $token;
}
```

### 2. Use Async/Queue for Multiple Notifications

```php
// Use a queue system like Redis or RabbitMQ for better performance
// Example with basic background processing:

function queueNotification($fcmToken, $title, $body, $data) {
    $notification = compact('fcmToken', 'title', 'body', 'data');
    
    // Add to database queue
    $stmt = $GLOBALS['conn']->prepare("
        INSERT INTO notification_queue (data, created_at)
        VALUES (?, NOW())
    ");
    $json = json_encode($notification);
    $stmt->bind_param("s", $json);
    $stmt->execute();
}

// Process queue with a cron job
// php process_notification_queue.php
```

---

## ✅ Checklist

- [ ] Download Firebase Service Account JSON file
- [ ] Save as `firebase-service-account.json` in project root
- [ ] Run `php send_notification.php` to test
- [ ] Receive notification on your device
- [ ] Add `fcm_token` column to database
- [ ] Integrate with login/registration flow
- [ ] Test order notification
- [ ] Test promotional notification
- [ ] Add to `.gitignore`
- [ ] Set proper file permissions

---

## 🆘 Need Help?

1. **Verify FCM V1 API is enabled**:
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Ensure "Firebase Cloud Messaging API (V1)" shows "Enabled"

2. **Test with curl**:
```bash
# First get access token (this is complex, use the PHP script instead)
php -r "require 'send_notification.php'; echo getAccessToken('firebase-service-account.json');"
```

3. **Check Firebase Status**: https://status.firebase.google.com/

---

## 📖 Documentation Links

- [FCM HTTP v1 API Documentation](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [FCM Server Setup](https://firebase.google.com/docs/cloud-messaging/server)
- [Message Types](https://firebase.google.com/docs/cloud-messaging/concept-options)

---

**Project Info:**
- Project ID: `hightech-bab87`
- Project Number: `669250940659`
- Package Name: `tech.high.golden.hightech`
- App ID: `1:669250940659:android:1e2e614d3ef3ca11631186`
