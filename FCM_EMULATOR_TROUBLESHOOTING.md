# FCM Emulator Troubleshooting Guide

## Problem
FCM tokens are not available on Android emulators, showing the message:
```
I/flutter: ⚠️ No FCM token available yet
   → This is expected on emulators without Google Play Services
   → Notifications will work on real devices
```

---

## Why This Happens

Firebase Cloud Messaging (FCM) requires **Google Play Services** to function. Many Android emulators:
- Don't have Google Play Services installed
- Have outdated versions of Google Play Services
- Are not configured properly for Google services

**Real devices almost always work** because they have Google Play Services pre-installed.

---

## ✅ Solution 1: Use Emulator with Google Play (RECOMMENDED)

### Step 1: Open Device Manager
1. Open Android Studio
2. Click **Tools** → **Device Manager** (or the phone icon in the toolbar)

### Step 2: Create New Virtual Device
1. Click **"Create Device"**
2. Select a device definition (e.g., Pixel 5)
3. Click **Next**

### Step 3: Select System Image with Play Store
**⚠️ CRITICAL**: Choose a system image with the **Play Store icon**

Good examples:
- ✅ **Tiramisu (API 33)** with Play Store icon
- ✅ **S (API 31)** with Play Store icon  
- ✅ **R (API 30)** with Play Store icon

Bad examples:
- ❌ Images without the Play Store icon
- ❌ "Google APIs" without Play Store

### Step 4: Finish Setup
1. Click **Next** → **Finish**
2. Start the emulator
3. Run your Flutter app

### Step 5: Verify
You should now see in the console:
```
I/flutter: ✅ FCM Token obtained: [your-token]
I/flutter: ✅ FCM token registered with backend successfully
```

---

## ✅ Solution 2: Test on Real Device

The easiest way is to test on a real Android device:

### Enable USB Debugging
1. Go to **Settings** → **About Phone**
2. Tap **Build Number** 7 times (enables Developer Mode)
3. Go back to **Settings** → **Developer Options**
4. Enable **USB Debugging**

### Connect Device
1. Connect phone via USB
2. Allow USB debugging when prompted
3. Run: `flutter devices` to verify
4. Run: `flutter run` to deploy to device

---

## ✅ Solution 3: Update Google Play Services on Emulator

If you're using an emulator with Play Store:

1. Open the emulator
2. Open **Play Store** app
3. Search for "Google Play Services"
4. Update if available
5. Restart the emulator
6. Run your app again

---

## How to Verify FCM is Working

### Check Console Logs

**When FCM is working:**
```
I/flutter: ✅ FCM Token obtained: eL1234...xyz
I/flutter: ✅ FCM token registered with backend successfully
```

**When FCM is NOT working:**
```
I/flutter: ⚠️ FCM Token is null - possible reasons:
I/flutter:    1. Google Play Services not available (emulator issue)
I/flutter:    2. No internet connection
I/flutter:    3. Firebase not properly configured
```

### Test Notification

Once you have a token, test sending a notification:
```bash
# From your project directory
php send_notification_to_user.php <user_id> "Test Title" "Test Message"
```

---

## Common Mistakes

### ❌ Mistake #1: Using Emulator Without Play Store
**Problem:** Selected system image without Play Store icon  
**Solution:** Create new AVD with Play Store image

### ❌ Mistake #2: Outdated Play Services
**Problem:** Emulator has old Google Play Services  
**Solution:** Update via Play Store in emulator

### ❌ Mistake #3: No Internet Connection
**Problem:** Emulator not connected to internet  
**Solution:** Check emulator network settings

### ❌ Mistake #4: Firebase Not Configured
**Problem:** Missing `google-services.json`  
**Solution:** Download from Firebase Console

---

## Quick Checklist

- [ ] Using emulator **WITH** Play Store icon?
- [ ] Google Play Services updated?
- [ ] Emulator has internet connection?
- [ ] `google-services.json` in `android/app/` directory?
- [ ] Ran `flutter clean` and `flutter pub get`?
- [ ] Rebuilt the app after adding Firebase?

---

## Development Workflow

### For Testing Notifications
1. **Use real device** for testing notifications (recommended)
2. Use emulator **with Play Store** as backup

### For Other Development
- Regular emulators work fine for UI/logic testing
- FCM tokens are only needed when testing notifications
- The app will work normally, just without push notifications

---

## Summary

**The Issue:**  
Emulators without Google Play Services cannot get FCM tokens.

**The Solution:**  
Use an emulator with the Play Store icon OR test on a real device.

**Important:**  
Your code is correct! This is purely an emulator limitation. Notifications will work perfectly on real devices.

