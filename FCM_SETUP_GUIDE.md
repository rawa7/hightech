# FCM Token Management - Complete Setup Guide

This guide explains how to set up and use the FCM token management system in your HighTech app.

## 🎯 What Does This System Do?

- **Saves FCM tokens** to your database when users log in
- **Updates tokens** automatically when they refresh
- **Deletes tokens** when users log out
- **Tracks device information** (device type, model, OS version)
- **Prevents duplicate tokens** across different users

---

## 📋 Setup Steps

### 1. Create the Database Table

Run the SQL script to create the `fcm_tokens` table:

```bash
mysql -u your_username -p your_database < fcm_tokens_table.sql
```

Or manually execute the SQL in `fcm_tokens_table.sql` in your MySQL client.

### 2. Configure API Endpoint

Edit `api/fcm_token_api.php` and update the database credentials:

```php
$db_host = 'localhost';       // Your database host
$db_name = 'hightech_db';     // Your database name
$db_user = 'your_username';   // Your database username
$db_pass = 'your_password';   // Your database password
```

### 3. Upload PHP Files

Upload these files to your server:
- `api/fcm_token_api.php` → `https://dasroor.com/hightech/api/fcm_token_api.php`
- `send_notification_to_user.php` → `https://dasroor.com/hightech/send_notification_to_user.php`

### 4. Install Flutter Dependencies

```bash
flutter pub get
```

This will install the new `device_info_plus` package.

### 5. Test the Integration

Run your Flutter app and test the flow:

1. **Login** → Check console for: `✅ FCM token registered with backend successfully`
2. **Check Database** → Query: `SELECT * FROM fcm_tokens WHERE user_id = 1;`
3. **Logout** → Check console for: `FCM token deleted from backend on logout`
4. **Check Database Again** → Token should have `is_active = 0`

---

## 🔄 How It Works

### On User Login
```
User logs in → UserService.saveUser(user)
    ↓
Gets FCM token from NotificationService
    ↓
Sends to backend with device info
    ↓
Token saved to database
```

### On User Logout
```
User logs out → UserService.logout()
    ↓
Gets current FCM token
    ↓
Sends delete request to backend
    ↓
Token marked as inactive in database
```

### On Token Refresh
```
Firebase refreshes token automatically
    ↓
NotificationService detects refresh
    ↓
Updates token in backend if user logged in
```

---

## 📊 Database Schema

```sql
fcm_tokens
├── id (Primary Key)
├── user_id (Foreign Key → users.id)
├── fcm_token (Unique)
├── device_type ('android', 'ios', 'web')
├── device_info (Device model and OS version)
├── created_at
├── updated_at
├── last_used_at
└── is_active (1 = active, 0 = inactive)
```

---

## 🔌 API Endpoints

### 1. Save/Update FCM Token
**POST** `api/fcm_token_api.php?action=save`

**Request Body:**
```json
{
  "user_id": 1,
  "fcm_token": "fxXJS...",
  "device_type": "android",
  "device_info": "Samsung Galaxy S23 (Android 15)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "FCM token saved successfully",
  "action": "inserted",
  "token_id": 42
}
```

### 2. Delete FCM Token (Single Device)
**POST** `api/fcm_token_api.php?action=delete`

**Request Body:**
```json
{
  "fcm_token": "fxXJS..."
}
```

### 3. Delete All User Tokens (All Devices)
**POST** `api/fcm_token_api.php?action=delete_by_user`

**Request Body:**
```json
{
  "user_id": 1
}
```

### 4. Get User Tokens
**GET** `api/fcm_token_api.php?action=get_user_tokens&user_id=1`

**Response:**
```json
{
  "success": true,
  "tokens": [
    {
      "id": 1,
      "fcm_token": "fxXJS...",
      "device_type": "android",
      "device_info": "Samsung Galaxy S23 (Android 15)",
      "created_at": "2025-10-02 10:30:00",
      "last_used_at": "2025-10-02 15:45:00"
    }
  ],
  "count": 1
}
```

---

## 📤 Sending Notifications

### Send to Specific User

Use the helper script `send_notification_to_user.php`:

```php
php send_notification_to_user.php
```

Or programmatically:

```php
require 'send_notification_to_user.php';

sendNotificationToUser(
    userId: 1,
    title: 'New Order Update',
    body: 'Your order #12345 has been shipped!',
    data: [
        'type' => 'order',
        'order_id' => '12345'
    ]
);
```

### Send to Multiple Users

```php
$userIds = [1, 2, 3, 4, 5];

foreach ($userIds as $userId) {
    sendNotificationToUser(
        userId: $userId,
        title: 'Special Offer!',
        body: '50% off on all products today only!'
    );
}
```

### Send to All Active Users

```sql
-- Get all active FCM tokens
SELECT fcm_token FROM fcm_tokens WHERE is_active = TRUE;
```

Then loop through and send notifications.

---

## 🐛 Troubleshooting

### Token Not Saving

1. Check Flutter console for errors
2. Verify database credentials in `fcm_token_api.php`
3. Check PHP error logs: `tail -f /var/log/apache2/error.log`
4. Test API directly with curl:

```bash
curl -X POST https://dasroor.com/hightech/api/fcm_token_api.php?action=save \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "fcm_token": "test123", "device_type": "android"}'
```

### Token Not Deleting on Logout

1. Verify `UserService.logout()` is called
2. Check if token exists in database before logout
3. Add debug logs in `api/fcm_token_api.php`

### Notifications Not Received

1. Verify token exists and is active: `SELECT * FROM fcm_tokens WHERE user_id = 1 AND is_active = TRUE`
2. Test with `test_notification.php` using the token from database
3. Check Firebase console for delivery status

---

## 📱 Testing Checklist

- [ ] Login → Token saved to database
- [ ] Token appears in `fcm_tokens` table
- [ ] Send test notification → Received successfully
- [ ] App restart → Token still valid
- [ ] Logout → Token marked inactive
- [ ] Logout → Can't receive notifications
- [ ] Login again → New token saved or existing updated

---

## 🔐 Security Notes

- ✅ Use HTTPS for all API calls (already configured)
- ✅ Tokens are unique and automatically reassigned if user changes
- ✅ Soft delete (inactive) instead of hard delete preserves history
- ⚠️ Consider adding API authentication for production
- ⚠️ Implement rate limiting on notification endpoints

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Docs](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging](https://firebase.flutter.dev/docs/messaging/overview)
- [Device Info Plus Plugin](https://pub.dev/packages/device_info_plus)

---

## 🎉 You're All Set!

Your FCM token management system is now complete. Users will automatically have their notification tokens managed when they log in and out.

**Happy coding! 🚀**

