# How to Run on Physical iPhone in Xcode

## The Problem
The error "Unable to flip between RX and RW memory protection on pages" occurs because Flutter's debug mode uses JIT (Just-In-Time) compilation, which iOS doesn't allow on physical devices for security reasons.

## Solution: Run in Release Mode from Xcode

### Step 1: Open Xcode Scheme Editor
1. In Xcode, look at the top toolbar where you see "Runner" and your device name
2. Click on "Runner" (not the device dropdown)
3. Select "Edit Scheme..."

### Step 2: Change Build Configuration to Release
1. In the scheme editor, select "Run" from the left sidebar
2. Go to the "Info" tab
3. Change "Build Configuration" from **Debug** to **Release**
4. Click "Close"

### Step 3: Clean and Run
1. In Xcode menu, go to Product → Clean Build Folder (Shift+Cmd+K)
2. Press the Run button (▶️) or Cmd+R

## Alternative: Run from Terminal in Release Mode

If you prefer using the terminal:

```bash
# Clean everything
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..

# Build and install release version
flutter run --release -d [your-device-id]
```

## Important Notes

- **Debug mode will NOT work on physical iOS devices** due to JIT restrictions
- Always use **Release mode** for physical device testing
- For development with hot reload, use the iOS Simulator instead
- Release mode doesn't support hot reload but runs much faster

## If You Still See Issues

1. Make sure your provisioning profile is set correctly:
   - Xcode → Signing & Capabilities → Team should be selected
   - "Automatically manage signing" should be checked

2. Trust the developer certificate on your iPhone:
   - iPhone Settings → General → VPN & Device Management
   - Select your developer profile and tap "Trust"

3. Ensure your iPhone has developer mode enabled:
   - iPhone Settings → Privacy & Security → Developer Mode → ON
