# Setup Guide

This document provides detailed setup instructions for the sample app.

## Prerequisites

### Development Environment

**iOS:**
- macOS 12.0 or later
- Xcode 14.0 or later
- CocoaPods 1.11 or later
- Physical device (required for APNs testing)

**Android:**
- Android Studio Flamingo or later
- JDK 17
- Android SDK (API 26+)

### Accounts

- Access to [Firebase Console](https://console.firebase.google.com/)
- [Apple Developer Program](https://developer.apple.com/) membership (for iOS device testing)
- Access to [Treasure Data Console](https://console.treasuredata.com/)

## 1. Create Firebase Project

### 1.1 Project Creation

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name (e.g., `td-push-sample`)
4. Enable Google Analytics (recommended)
5. Click "Create project"

### 1.2 Register iOS App

1. Firebase Console > Project Settings > "Add app" > iOS
2. Enter the following information:
   - **Apple Bundle ID**: `com.treasuredata.pushsample` (or your preferred Bundle ID)
   - **App Nickname**: `TD Push Sample iOS`
   - **App Store ID**: (optional)
3. Click "Register app"
4. Download `GoogleService-Info.plist`
5. Copy the file to `ios/TDPushSample/`

### 1.3 Register Android App

1. Firebase Console > Project Settings > "Add app" > Android
2. Enter the following information:
   - **Android Package Name**: `com.treasuredata.pushsample`
   - **App Nickname**: `TD Push Sample Android`
   - **Debug Signing Certificate SHA-1**: (optional)
3. Click "Register app"
4. Download `google-services.json`
5. Copy the file to `android/app/`

### 1.4 Configure APNs Authentication Key (iOS)

#### Step 1: Create Authentication Key in Apple Developer Portal

1. Log in to [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. In the "Keys" section, click the "+" button
3. Key Name: `TD Push Sample APNs Key`
4. Select "Apple Push Notifications service (APNs)"
5. Click "Continue" → "Register" → "Download"
6. Download the `.p8` file (note the Key ID)
7. Confirm Team ID (Account > Membership)

#### Step 2: Upload to Firebase Console

1. Firebase Console > Project Settings > Cloud Messaging > iOS
2. In the "APNs Authentication Key" section, click "Upload"
3. Select the `.p8` file
4. Enter Key ID and Team ID
5. Click "Upload"

## 2. Treasure Data Configuration

### 2.1 Create Database and Table

Run the following SQL in Treasure Data Console:

```sql
-- Create database if it doesn't exist
CREATE DATABASE IF NOT EXISTS mobile;

-- Tables are automatically created when using Ingest API
-- To verify schema:
SELECT * FROM mobile.push_events LIMIT 1;
```

### 2.2 Obtain API Key

1. Treasure Data Console > Settings > API Keys
2. Click "Generate New Key"
3. Key Type: **Write-only** (recommended)
4. Permissions: Write access to `mobile` database
5. Copy the Key (for later use)

**⚠️ Security Notes:**
- Use Write-only Key to minimize data exposure risks
- Do not hardcode the Key in code (use environment variables or config files)
- In production, manage Key server-side

## 3. iOS App Setup

### 3.1 Install Dependencies

```bash
cd ios
pod install
cd ..
```

### 3.2 Configure Xcode Project

```bash
open ios/TDPushSample.xcworkspace
```

#### Signing & Capabilities

1. Select `TDPushSample` in project navigator
2. Go to Signing & Capabilities tab
3. Team: Select development team
4. Bundle Identifier: `com.treasuredata.pushsample` (or as desired)
5. Click "+ Capability"
   - Add **Push Notifications**
   - Add **Background Modes** → Check Remote notifications

#### Notification Service Extension

1. Configure `NotificationService` target similarly
2. Team: Same development team
3. Bundle Identifier: `com.treasuredata.pushsample.NotificationService`

### 3.3 Set Treasure Data API Key

Edit the following files, replacing `YOUR_TD_WRITE_KEY` with your actual API Key:

**ios/TDPushSample/Models/FCMTokenService.swift:**
```swift
private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← Change this
```

**ios/TDPushSample/Models/PushEventUploader.swift:**
```swift
private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← Change this
```

### 3.4 Modify Bundle ID and URL Scheme (Optional)

If you change the Bundle ID, update the following:

**ios/TDPushSample/Info.plist:**
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>tdpushsample</string> <!-- Can be changed to any scheme -->
</array>
```

**iOS/TDPushSample/AppDelegate.swift and SceneDelegate.swift:**
```swift
if url.scheme == "tdpushsample" { // ← Adjust to match new scheme
```

## 4. Android App Setup

### 4.1 Set Treasure Data API Key (Recommended: Inject during build)

**Secure Method:** Inject API Key during build without committing to Git.

#### Step 1: Create local.properties file

```bash
cd android

# Copy template
cp local.properties.example local.properties

# Edit in your preferred editor
nano local.properties  # or vi, code, etc.
```

#### Step 2: Set Actual Values

**android/local.properties:**
```properties
# Treasure Data Configuration
TD_WRITE_KEY=Your Treasure Data Write-only API Key
TD_DATABASE=mobile
TD_TABLE=push_events
TD_ENDPOINT=https://us01.records.in.treasuredata.com

# Treasure Data Data Ingestion API endpoints by region:
# US01: https://us01.records.in.treasuredata.com
# Tokyo (AP01): https://ap01.records.in.treasuredata.com
# EU01: https://eu01.records.in.treasuredata.com
# Korea (AP02): https://ap02.records.in.treasuredata.com
# AP03: https://ap03.records.in.treasuredata.com
```

**Important:**
- `local.properties` is in `.gitignore` and will not be committed
- For team sharing, use encrypted configuration management tools (1Password, AWS Secrets Manager, etc.)

#### How It Works

Values from `local.properties` are automatically generated as `BuildConfig` fields:

```kotlin
// Automatically generated (can be used in code)
BuildConfig.TD_WRITE_KEY
BuildConfig.TD_DATABASE
BuildConfig.TD_TABLE
BuildConfig.TD_ENDPOINT
```

Used in code as follows:

**android/app/src/main/java/com/treasuredata/pushsample/fcm/PushEventUploader.kt:**
```kotlin
private val TD_WRITE_KEY = BuildConfig.TD_WRITE_KEY  // Injected during build
private val TD_DATABASE = BuildConfig.TD_DATABASE
private val TD_TABLE = BuildConfig.TD_TABLE
private val TD_ENDPOINT = BuildConfig.TD_ENDPOINT
```

### 4.2 Change Package Name (Optional)

If changing package name, update the following:

**android/app/build.gradle.kts:**
```kotlin
android {
    namespace = "com.treasuredata.pushsample" // ← Change this
    defaultConfig {
        applicationId = "com.treasuredata.pushsample" // ← Change this
    }
}
```

**android/app/src/main/AndroidManifest.xml:**
```xml
<data android:scheme="tdpushsample" /> <!-- Can be changed to any scheme -->
```

**All Kotlin Files:**
```kotlin
package com.treasuredata.pushsample // ← Update to match new package name
```

### 4.3 Build

```bash
cd android
./gradlew clean assembleDebug
```

If no errors occur, the build is successful.

## 5. Verification

### 5.1 iOS

```bash
# 1. Connect physical device
# 2. Build & run in Xcode (Cmd + R)
# 3. Check console for FCM token
# "🔑 FCM token: xxxxx" should be displayed
```

### 5.2 Android

```bash
cd android
./gradlew installDebug
adb shell am start -n com.treasuredata.pushsample/.MainActivity
adb logcat | grep "FCM token"
# "🔑 FCM token: xxxxx" should be displayed
```

## 6. Send Test Notification

Refer to [TESTING.md](TESTING.md).

## Next Steps

- [TESTING.md](TESTING.md): Testing methods
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md): Troubleshooting
- [Treasure Data Documentation](https://docs.treasuredata.com/)

## Frequently Asked Questions

### Q: Do I need to change Bundle ID or Package Name?

A: Use a unique ID in production. For sample execution, changes are not necessary.

### Q: Can I use a Full Access Key instead of Write-only?

A: Technically possible, but not recommended due to high security risks.

### Q: Can I test on Simulator/Emulator?

A:
- **iOS**: FCM token can be obtained on simulator, but actual notification receipt requires a physical device.
- **Android**: Works completely on emulator.

### Q: Data Sending to Treasure Data Fails

A:
1. Verify API Key is correct
2. Check network connection
3. Confirm database/table names are correct
4. Check HTTP response in app logs