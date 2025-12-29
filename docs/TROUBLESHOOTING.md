# Troubleshooting Guide

This document explains common issues and their solutions.

## Table of Contents

1. [FCM Token Retrieval Issues](#fcm-token-retrieval-issues)
2. [Notification Reception Issues](#notification-reception-issues)
3. [Event Sending Issues](#event-sending-issues)
4. [Deep Link Issues](#deep-link-issues)
5. [Build Errors](#build-errors)

## FCM Token Retrieval Issues

### iOS: Unable to Retrieve FCM Token

**Symptoms:**
```
❌ Error fetching FCM token: ...
```

**Causes and Solutions:**

1. **Cannot Obtain APNs Token**
   - Verify testing on a physical device (APNs not supported in simulator)
   - Confirm Push Notifications capability is enabled
   - Check that Provisioning Profile is correct

2. **Incorrect Firebase Configuration**
   ```bash
   # Verify GoogleService-Info.plist
   ls -la ios/TDPushSample/GoogleService-Info.plist

   # If file is missing
   cp ios/TDPushSample/GoogleService-Info.plist.example \
      ios/TDPushSample/GoogleService-Info.plist
   # Enter actual Firebase configuration
   ```

3. **Firebase Initialization Error**
   ```swift
   // Check in AppDelegate.swift
   FirebaseApp.configure() // Verify this line is executed
   ```

### Android: Unable to Retrieve FCM Token

**Symptoms:**
```
❌ Error fetching FCM token: ...
```

**Causes and Solutions:**

1. **google-services.json Not Placed**
   ```bash
   ls -la android/app/google-services.json

   # If file is missing
   cp android/app/google-services.json.example \
      android/app/google-services.json
   # Enter actual Firebase configuration
   ```

2. **Package Name Mismatch**
   ```bash
   # Check package_name in google-services.json
   cat android/app/google-services.json | grep package_name

   # Verify matching applicationId in build.gradle.kts
   cat android/app/build.gradle.kts | grep applicationId
   ```

3. **Outdated Google Play Services**
   ```bash
   # Update Google Play Services on emulator/device
   # Settings > Apps > Google Play Services > Update
   ```

## Notification Reception Issues

### iOS: No Notifications Received

**Symptoms:**
- No display when sending test notifications

**Diagnostic Steps:**

```bash
# 1. Check Xcode Console Logs
# Look for these logs:
✅ Notification permission granted: true
📱 APNs token registered
🔑 FCM token: ...
```

**Causes and Solutions:**

1. **Not Using Physical Device**
   - **Solution**: Test on a physical device (APNs notifications not receivable in simulator)
   - For simulator testing: Use `xcrun simctl push` command

2. **No APNs Authentication Key Set**
   ```bash
   # Firebase Console > Project Settings > Cloud Messaging > iOS
   # Verify APNs authentication key is registered
   ```

3. **Notification Permissions Not Granted**
   ```bash
   # Check on device:
   # Settings > Notifications > TDPushSample > Allow Notifications
   ```

4. **Background Modes Not Enabled**
   ```
   Xcode > Target: TDPushSample > Signing & Capabilities
   > Background Modes > Check remote notifications
   ```

5. **Bundle ID Mismatch**
   ```bash
   # Xcode: Bundle Identifier
   # Firebase Console: iOS app's Bundle ID
   # Verify both match
   ```

### Android: No Notifications Received

**Symptoms:**
- No display when sending test notifications

**Diagnostic Steps:**

```bash
adb logcat -c  # Clear logs
# Send test notification
adb logcat | grep -E "FCM|Notification"
```

**Causes and Solutions:**

1. **Notification Permissions Not Granted (Android 13+)**
   ```bash
   # Check on device:
   # Settings > Apps > TD Push Sample > Notifications > Allow

   # Programmatically check:
   # Add notification permission request in MainActivity.kt
   ```

2. **Package Name Mismatch**
   ```bash
   # AndroidManifest.xml
   grep package android/app/src/main/AndroidManifest.xml

   # build.gradle.kts
   grep applicationId android/app/build.gradle.kts

   # google-services.json
   grep package_name android/app/google-services.json
   ```

3. **FirebaseMessagingService Not Registered**
   ```xml
   <!-- Check in AndroidManifest.xml -->
   <service
       android:name=".fcm.MyFirebaseMessagingService"
       android:exported="false">
       <intent-filter>
           <action android:name="com.google.firebase.MESSAGING_EVENT" />
       </intent-filter>
   </service>
   ```

4. **App Affected by Battery Optimization**
   ```bash
   # Settings > Battery > Battery optimization
   # Set TD Push Sample to "Not optimized"
   ```

## Event Sending Issues

### Events Not Sent to Treasure Data

**Symptoms:**
```
❌ Upload failed with status code: 401
or
❌ Upload failed with status code: 404
```

**Diagnostic Steps:**

```bash
# iOS: Xcode Console
# Android: adb logcat

# Check these logs:
📡 Sending X events to Treasure Data
URL: https://in.treasuredata.com/postback/v3/event/mobile/push_events
📊 HTTP Status Code: ???
```

**HTTP Status Code Solutions:**

| Code | Meaning | Solution |
|------|---------|----------|
| 200 | Success | No issues |
| 401 | Authentication Error | Incorrect API Key |
| 403 | Permission Error | Insufficient API Key permissions |
| 404 | Not Found | Incorrect database/table name |
| 500 | Server Error | Contact Treasure Data support |

**Solutions:**

1. **Verify API Key**

   **iOS:**
   ```swift
   // FCMTokenService.swift
   private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← Check correctness

   // PushEventUploader.swift
   private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← Check correctness
   ```

   **Android:**
   ```kotlin
   // PushEventUploader.kt
   private const val TD_WRITE_KEY = "YOUR_TD_WRITE_KEY" // ← Check correctness
   ```

2. **Verify Database/Table Names**

   ```swift
   // iOS
   private let tdDatabase = "mobile"  // ← Matches Treasure Data
   private let tdTable = "push_events"
   ```

   ```kotlin
   // Android
   private const val TD_DATABASE = "mobile"  // ← Matches Treasure Data
   private const val TD_TABLE = "push_events"
   ```

3. **Verify Network Connection**
   ```bash
   # Confirm device is connected to the internet
   ping -c 3 in.treasuredata.com
   ```

4. **Verify Endpoint**

   Endpoints vary by region:
   - US: `https://in.treasuredata.com`
   - Tokyo: `https://in.treasure-data.com`
   - EU: `https://in.eu01.treasuredata.com`

### Events Remain Queued

**Symptoms:**
- "Queued Events: 1000" does not decrease in the app

**Diagnostic Steps:**

```bash
# Check upload process logs
📤 Starting upload of 1000 events
📡 Sending 500 events to Treasure Data
❌ Upload failed with status code: 401
❌ Upload failed, re-enqueuing events
```

**Solutions:**

1. Refer to "Events Not Sent to Treasure Data" section above
2. After fixing API Key or settings, restart the app
3. Use "Upload Events Now" button for manual upload

## Deep Link Issues

### iOS: Deep Links Not Working

**Symptoms:**
- No deep link opens when tapping notification

**Solutions:**

1. **Verify URL Scheme**
   ```xml
   <!-- Info.plist -->
   <key>CFBundleURLSchemes</key>
   <array>
       <string>tdpushsample</string>
   </array>
   ```

2. **Verify SceneDelegate Implementation**
   ```swift
   func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
       // Verify this function is implemented
   }
   ```

3. **Verify Notification Payload**
   ```json
   {
     "deeplink": "tdpushsample://product/12345"  // Check scheme
   }
   ```

### Android: Deep Links Not Working

**Symptoms:**
- No deep link opens when tapping notification

**Solutions:**

1. **Verify Intent Filter**
   ```xml
   <!-- AndroidManifest.xml -->
   <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="tdpushsample" />
   </intent-filter>
   ```

2. **Verify MainActivity.launchMode**
   ```xml
   <activity
       android:name=".MainActivity"
       android:launchMode="singleTop">  <!-- Important -->
   ```

3. **Verify onNewIntent Implementation**
   ```kotlin
   override fun onNewIntent(intent: Intent) {
       super.onNewIntent(intent)
       handleIntent(intent)  // Verify this function is implemented
   }
   ```

## Build Errors

### iOS: CocoaPods Related Errors

**Symptoms:**
```
[!] Unable to find a specification for `Firebase/Messaging`
```

**Solutions:**

```bash
cd ios

# 1. Clear CocoaPods cache
pod cache clean --all

# 2. Update repositories
pod repo update

# 3. Reinstall
pod deintegrate
pod install

cd ..
```

### iOS: Signing Errors

**Symptoms:**
```
Signing for "TDPushSample" requires a development team.
```

**Solutions:**

1. Xcode > Targets > TDPushSample > Signing & Capabilities
2. Team: Select development team
3. Set the same for NotificationService target

### Android: Gradle Errors

**Symptoms:**
```
Could not resolve com.google.firebase:firebase-bom:34.7.0
```

**Solutions:**

```bash
cd android

# 1. Clear Gradle cache
./gradlew clean
./gradlew --stop
rm -rf ~/.gradle/caches/

# 2. Rebuild
./gradlew assembleDebug

cd ..
```

### Android: google-services.json Errors

**Symptoms:**
```
File google-services.json is missing.
```

**Solutions:**

```bash
# Copy template
cp android/app/google-services.json.example \
   android/app/google-services.json

# Replace with actual file downloaded from Firebase Console
```

## Rich Media (Image) Issues

### iOS: Images Not Displaying

**Solutions:**

1. **Verify Notification Service Extension**
   ```bash
   # Check in Xcode:
   # Verify "NotificationService" exists in Targets
   ```

2. **Verify Image URL**
   ```bash
   # Confirm HTTPS (HTTP not allowed)
   curl -I https://picsum.photos/400/300
   ```

3. **Verify Payload**
   ```json
   {
     "aps": {
       "mutable-content": 1  // Required
     },
     "image": "https://..."
   }
   ```

### Android: Images Not Displaying

**Solutions:**

1. **Verify Internet Permission**
   ```xml
   <!-- AndroidManifest.xml -->
   <uses-permission android:name="android.permission.INTERNET" />
   ```

2. **Verify Image URL**
   ```bash
   curl -I https://picsum.photos/400/300
   # Confirm HTTP 200 response
   ```

## Log Collection

### iOS

```bash
# Save logs from Xcode Console
# Connect device and run app
# Xcode > Window > Devices and Simulators > View Device Logs
```

### Android

```bash
# Save logcat to file
adb logcat -d > logcat.txt

# Filtering
adb logcat -d | grep -E "FCM|PushEvent|Treasure" > filtered_log.txt
```

## Support

If the above methods do not resolve your issue, please contact Treasure Data support with the following information:

- Platform (iOS/Android) and version
- Full error message
- Relevant logs
- Steps you've taken
- Expected vs. actual behavior

---

**Reference Materials:**
- [Firebase Cloud Messaging Troubleshooting](https://firebase.google.com/docs/cloud-messaging/troubleshooting)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Treasure Data API Documentation](https://api-docs.treasuredata.com/)