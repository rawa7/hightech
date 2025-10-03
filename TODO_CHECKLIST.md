# ✅ TODO Checklist - FCM Token Management Setup

## 🎯 What You Need to Do

Follow this checklist to complete the FCM token management setup.

---

## 📋 Setup Checklist

### Step 1: Database Setup (2 minutes)

- [ ] Open your MySQL client or terminal
- [ ] Run this command:
  ```bash
  mysql -u your_username -p hightech_db < fcm_tokens_table.sql
  ```
- [ ] Verify table was created:
  ```sql
  SHOW TABLES LIKE 'fcm_tokens';
  DESC fcm_tokens;
  ```
- [ ] ✅ You should see the `fcm_tokens` table with 9 columns

---

### Step 2: Configure Database Credentials (1 minute)

#### File 1: `api/fcm_token_api.php`

- [ ] Open `api/fcm_token_api.php`
- [ ] Find lines 17-20
- [ ] Update these values:
  ```php
  $db_host = 'localhost';       // ← Your database host
  $db_name = 'hightech_db';     // ← Your database name
  $db_user = 'your_username';   // ← Your database username
  $db_pass = 'your_password';   // ← Your database password
  ```
- [ ] Save the file

#### File 2: `send_notification_to_user.php`

- [ ] Open `send_notification_to_user.php`
- [ ] Find lines 14-17
- [ ] Update with the **same credentials** as above:
  ```php
  $DB_HOST = 'localhost';
  $DB_NAME = 'hightech_db';
  $DB_USER = 'your_username';
  $DB_PASS = 'your_password';
  ```
- [ ] Save the file

---

### Step 3: Upload Files to Server (1 minute)

- [ ] Upload `api/fcm_token_api.php` to:
  ```
  https://dasroor.com/hightech/api/fcm_token_api.php
  ```

- [ ] Upload `send_notification_to_user.php` to:
  ```
  https://dasroor.com/hightech/api/send_notification_to_user.php
  ```
  or
  ```
  https://dasroor.com/hightech/send_notification_to_user.php
  ```

- [ ] Make sure `firebase-service-account.json` is already uploaded to:
  ```
  https://dasroor.com/hightech/firebase-service-account.json
  ```

---

### Step 4: Test on Android Device (2 minutes)

- [ ] Connect your Android device (the one you were testing with)
- [ ] Run the app:
  ```bash
  cd /Users/golden.bylt/StudioProjects/hightech
  flutter run -d R5CW82N6VWY
  ```

- [ ] Wait for app to launch
- [ ] Watch the console for this message:
  ```
  FCM Token: fxXJS...
  ```

---

### Step 5: Test Login Flow (1 minute)

- [ ] Login with a test account in the app
- [ ] Watch console for this message:
  ```
  ✅ FCM token registered with backend successfully
  ```
- [ ] If you see error messages, check:
  - Database credentials are correct
  - API file is uploaded correctly
  - Table exists in database

---

### Step 6: Verify in Database (30 seconds)

- [ ] Run this query in your MySQL:
  ```sql
  SELECT * FROM fcm_tokens;
  ```

- [ ] You should see a new row with:
  - ✅ Your user ID
  - ✅ The FCM token from console
  - ✅ Device type: 'android'
  - ✅ Device info: Something like "Samsung SM S918B (Android 15)"
  - ✅ is_active: 1

---

### Step 7: Test Sending Notification (1 minute)

- [ ] Update user ID in `send_notification_to_user.php` (line 202):
  ```php
  $userId = 1; // ← Change to your test user's ID
  ```

- [ ] Run the script:
  ```bash
  cd /Users/golden.bylt/StudioProjects/hightech
  php send_notification_to_user.php
  ```

- [ ] Watch for output:
  ```
  ✅ Sent successfully!
  ```

- [ ] Check your Android device
- [ ] You should receive a notification! 🎉

---

### Step 8: Test Logout Flow (30 seconds)

- [ ] Logout from the app
- [ ] Watch console for:
  ```
  FCM token deleted from backend on logout
  ```

- [ ] Verify in database:
  ```sql
  SELECT * FROM fcm_tokens WHERE user_id = 1;
  ```

- [ ] The token should now have:
  - ✅ is_active: 0

---

## 🎯 Success Criteria

You'll know everything is working when:

✅ Login shows: "FCM token registered with backend successfully"  
✅ Token appears in database with `is_active = 1`  
✅ Notification is received on device  
✅ Logout shows: "FCM token deleted from backend on logout"  
✅ Token in database changes to `is_active = 0`  

---

## 🐛 If Something Doesn't Work

### Problem: "Database connection failed"

**Solution:**
- Check database credentials in both PHP files
- Test connection:
  ```bash
  mysql -u your_username -p hightech_db
  ```
- Make sure MySQL server is running

### Problem: "No FCM token available yet"

**Solution:**
- Wait 2-3 seconds after app launch
- Check Firebase initialization
- Verify `google-services.json` is correct

### Problem: "Failed to register FCM token"

**Solution:**
- Check if API file is uploaded correctly
- Test API directly:
  ```bash
  curl -X POST https://dasroor.com/hightech/api/fcm_token_api.php?action=save \
    -H "Content-Type: application/json" \
    -d '{"user_id": 1, "fcm_token": "test123", "device_type": "android"}'
  ```
- Check PHP error logs

### Problem: Notification not received

**Solution:**
- Verify token exists and is active in database
- Check device notification permissions (Settings → Apps → HighTech → Notifications)
- Make sure app is running or in background (not force-closed)
- Try with app in foreground first

---

## 📚 Documentation Reference

After completing setup, read these for more info:

- **QUICK_START.md** - Quick reference guide
- **FCM_SETUP_GUIDE.md** - Complete detailed guide
- **FCM_README.md** - System overview
- **IMPLEMENTATION_SUMMARY.md** - What was built

---

## 🎉 Next Steps (After Setup Works)

Once everything is working:

1. **Test on iOS device** (if you have one)
2. **Test with multiple users**
3. **Test with multiple devices per user**
4. **Integrate with your order system**
5. **Create notification templates**
6. **Add user notification preferences**

---

## 📞 Quick Commands Reference

```bash
# Run Flutter app on Android
flutter run -d R5CW82N6VWY

# Run Flutter app on iPhone
flutter run -d 00008140-001A555911E0801C

# Send test notification
php send_notification_to_user.php

# Check database
mysql -u username -p
> USE hightech_db;
> SELECT * FROM fcm_tokens;

# View PHP logs
tail -f /var/log/apache2/error.log
```

---

## ⏱️ Estimated Time

- Setup: **5-10 minutes**
- Testing: **5 minutes**
- **Total: 10-15 minutes**

---

## 🚀 Ready to Start?

1. ✅ Check off items as you complete them
2. 📝 Take notes of any issues
3. 🎯 Follow the checklist in order
4. 🎉 Celebrate when all items are checked!

**Let's get started! 💪**

---

*Last updated: October 2, 2025*

