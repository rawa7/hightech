# 🚀 Quick Start - FCM Token Management

Your FCM token management system is now ready! Here's what you need to do next.

## ⚡ Quick Setup (5 minutes)

### Step 1: Create Database Table

Run this command in your MySQL:

```bash
mysql -u your_username -p hightech_db < fcm_tokens_table.sql
```

Or copy the SQL from `fcm_tokens_table.sql` and run it manually.

### Step 2: Configure Database in API

Edit **`api/fcm_token_api.php`** (lines 17-20):

```php
$db_host = 'localhost';       // ← Update this
$db_name = 'hightech_db';     // ← Update this
$db_user = 'your_username';   // ← Update this
$db_pass = 'your_password';   // ← Update this
```

Also edit **`send_notification_to_user.php`** (lines 14-17) with the same credentials.

### Step 3: Upload Files to Server

Upload these files to your server:
- `api/fcm_token_api.php` → `https://dasroor.com/hightech/api/fcm_token_api.php`
- `send_notification_to_user.php` → `https://dasroor.com/hightech/send_notification_to_user.php`

### Step 4: Test It!

1. **Run your Flutter app**
   ```bash
   flutter run
   ```

2. **Login with a test account**
   - Check console for: `✅ FCM token registered with backend successfully`

3. **Check database**
   ```sql
   SELECT * FROM fcm_tokens WHERE user_id = 1;
   ```
   You should see your token!

4. **Send a test notification**
   ```bash
   php send_notification_to_user.php
   ```
   (Don't forget to update user_id in the script first!)

---

## 📱 What Happens Now?

### ✅ On Login
- User logs in
- App gets FCM token
- Token is sent to your server
- Token is saved in database with device info
- User can receive notifications! 🎉

### ✅ On Logout
- User logs out
- App sends delete request
- Token is marked as inactive in database
- User stops receiving notifications

### ✅ On Token Refresh
- Firebase refreshes token automatically
- App detects refresh
- New token is updated in database
- Notifications continue working seamlessly

---

## 📤 Send Notifications to Users

### Option 1: Send to Specific User

```php
<?php
require 'send_notification_to_user.php';

sendNotificationToUser(
    userId: 1,
    title: 'Order Update',
    body: 'Your order has been shipped!',
    data: [
        'type' => 'order',
        'order_id' => '12345'
    ]
);
?>
```

### Option 2: Send to Multiple Users

```php
$userIds = [1, 2, 3, 4, 5];

sendNotificationToUsers(
    userIds: $userIds,
    title: 'Flash Sale!',
    body: '50% off everything for the next 2 hours!'
);
```

### Option 3: Broadcast to All Users

```php
broadcastNotification(
    title: 'System Announcement',
    body: 'New features available now!'
);
```

---

## 🔍 Verify Everything Works

### Test Checklist:
- [ ] Login → See success message in console
- [ ] Check database → Token exists
- [ ] Send notification → Received on device
- [ ] App closed → Still receive notification
- [ ] Logout → Token marked inactive
- [ ] Try to send → No notification received (correct!)
- [ ] Login again → New token saved

---

## 📊 Database Queries

### View all active tokens
```sql
SELECT * FROM fcm_tokens WHERE is_active = TRUE;
```

### View tokens for specific user
```sql
SELECT * FROM fcm_tokens WHERE user_id = 1 AND is_active = TRUE;
```

### Count active devices per user
```sql
SELECT user_id, COUNT(*) as device_count 
FROM fcm_tokens 
WHERE is_active = TRUE 
GROUP BY user_id;
```

### View user's device history
```sql
SELECT device_type, device_info, created_at, last_used_at, is_active
FROM fcm_tokens 
WHERE user_id = 1 
ORDER BY created_at DESC;
```

---

## 🐛 Troubleshooting

### "No FCM token available yet"
- Wait a few seconds after app launches
- Check Firebase initialization
- Verify `google-services.json` is correct

### "Database connection failed"
- Check database credentials in PHP files
- Verify database server is running
- Test connection with: `mysql -u username -p`

### "Token not saving"
- Check API endpoint is accessible
- View PHP error logs
- Test API with curl:
```bash
curl -X POST https://dasroor.com/hightech/api/fcm_token_api.php?action=save \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "fcm_token": "test", "device_type": "android"}'
```

### "Notifications not received"
- Verify token exists in database
- Check token is active (`is_active = 1`)
- Test with `test_notification.php`
- Check device notification settings

---

## 📚 Files Reference

| File | Purpose |
|------|---------|
| `fcm_tokens_table.sql` | Database schema |
| `api/fcm_token_api.php` | API endpoints for token management |
| `send_notification_to_user.php` | Helper script to send notifications |
| `lib/services/api_service.dart` | Flutter API client |
| `lib/services/user_service.dart` | User authentication + FCM integration |
| `lib/services/notification_service.dart` | FCM token handling |
| `FCM_SETUP_GUIDE.md` | Detailed documentation |

---

## 🎯 Next Steps

1. ✅ Complete the setup steps above
2. 📊 Test the entire flow
3. 🔔 Try sending notifications to real users
4. 📱 Test on multiple devices
5. 🚀 Deploy to production!

---

## 💡 Pro Tips

- **Multiple Devices**: Users can have tokens for multiple devices (phone, tablet, etc.)
- **Token Refresh**: Tokens automatically refresh every few weeks - your system handles it!
- **Inactive Tokens**: Old tokens are kept inactive for analytics/history
- **Security**: Consider adding API authentication in production
- **Rate Limiting**: Implement rate limiting for notification endpoints

---

## 🎉 You're All Set!

Your app now has professional-grade push notification management!

**Need help?** Check `FCM_SETUP_GUIDE.md` for detailed documentation.

**Happy coding! 🚀**

