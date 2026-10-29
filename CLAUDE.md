# CLAUDE.md - Treasure Data Mobile Push Sample App

## 🚨 CRITICAL RULES (MANDATORY)

### Parallel Cross-Platform Execution
- **ALWAYS implement iOS (Swift) and Android (Kotlin) simultaneously** in the same turn
- Ensure **feature parity**: Component names, data models, event schemas, and business logic MUST match across platforms
- When adding a feature (e.g., deep link handler), implement it for both platforms before moving to the next task

### Event Schema Consistency
- All tracked events (`delivery`, `open`, `dismiss`, `link_open`, `deeplink_open`, `token_register`) MUST have **identical field names** and **data types** across platforms
- Event payload format MUST match the schema defined in the documentation
- FCM token handling MUST be consistent (registration, updates, user association)

### Deterministic Verification
- **NEVER assume code works** - ALWAYS run build commands after changes
- After modifying Firebase configuration, run the app on simulator/emulator to verify FCM token generation
- If build fails, analyze error logs, fix the issue, and rebuild immediately
- Test notification delivery using Engage Studio **Send test**

### No Direct Project File Edits
- **DO NOT edit** `.xcodeproj` or `.pbxproj` files directly
- **iOS**: Use `project.yml` (XcodeGen) to manage project structure and Swift Package Manager for dependencies
  - Run `xcodegen generate` to regenerate `.xcodeproj` after modifying `project.yml`
  - Add SPM dependencies in the `packages` section of `project.yml`
- **Android**: Use Gradle dependency declarations for Android
- When adding new files, ensure they are properly registered in build system (`project.yml` for iOS, Gradle for Android)

### Configuration Management
- **NEVER commit** API keys (`TD_WRITE_KEY`, Firebase keys) to Git
- Use placeholder values (e.g., `YOUR_TD_WRITE_KEY`) in sample code
- Provide `.env.example` or configuration templates for users to fill in
- Document all required configuration in README

---

## 🏗 ARCHITECTURE & PATTERNS

### iOS (Swift)
- **Language**: Swift 5.7+
- **UI Framework**: SwiftUI or UIKit (UIKit for broader compatibility)
- **Concurrency**: DispatchQueue for event queue, URLSession for network requests
- **Pattern**: Service-based architecture
  - `AppDelegate`: Firebase initialization, notification delegate setup
  - `NotificationService` (Extension): Rich media attachment
  - `FCMTokenService`: Token registration and management
  - `EventQueue`: Thread-safe FIFO queue using UserDefaults
  - `PushEventUploader`: Batch upload to Treasure Data API
  - `SceneDelegate`: Deep link routing

### Android (Kotlin)
- **Language**: Kotlin 1.9+
- **UI Framework**: XML layouts with Material Components
- **Concurrency**: Kotlin Coroutines, WorkManager for background upload
- **Pattern**: Service-based architecture
  - `MyFirebaseMessagingService`: FCM message reception
  - `PushEventReceiver`: BroadcastReceiver for notification actions
  - `FcmTokenService`: Token registration and management
  - `EventQueue`: Thread-safe FIFO queue using SharedPreferences
  - `PushEventUploader`: Batch upload with WorkManager
  - `MainActivity`: Deep link routing, notification tap handling

### Shared Concepts (Cross-Platform)
- **Event Queue**: Max 1000 events, FIFO, persistent storage
- **Batch Upload**: Max 500 events per request to Treasure Data Ingest API
- **Token Management**: Register on app launch, re-register on token refresh
- **User Association**: Link events via `fcm_token`, optional `user_id` for logged-in users
- **Deep Link Format**: Custom URL scheme (e.g., `myapp://product/12345`)

---

## 📦 DEPENDENCIES

### iOS (Swift Package Manager)
This project uses **Swift Package Manager (SPM)** for dependency management.

**Package Dependencies (defined in project.yml):**
- Firebase iOS SDK: `https://github.com/firebase/firebase-ios-sdk` (12.7.0+)
  - FirebaseMessaging
  - FirebaseAnalytics
- Treasure Data iOS SDK: `https://github.com/treasure-data/td-ios-sdk` (1.2.1+)

**Minimum iOS version**: 15.0 (required by Firebase 12.7+)

**Note:** Dependencies are automatically resolved by Xcode on first build. No manual installation required.

### Android (build.gradle.kts)
```kotlin
dependencies {
    // Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.7.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")

    // Background tasks
    implementation("androidx.work:work-runtime-ktx:2.11.0")

    // HTTP client
    implementation("com.squareup.okhttp3:okhttp:4.12.0")

    // Web links
    implementation("androidx.browser:browser:1.8.0")
}
```

**Minimum SDK**: 26 (Android 8.0)

---

## 🛠 TOOLCHAIN & BUILD COMMANDS

### iOS Build Commands
```bash
# Generate Xcode project (if project.yml was modified)
cd ios && xcodegen generate && cd ..

# Build for simulator (dependencies auto-resolve on first build)
xcodebuild -project ios/TDPushSample.xcodeproj \
  -scheme TDPushSample \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  clean build | xcbeautify

# Run on simulator
open -a Simulator
xcrun simctl boot "iPhone 15"
xcodebuild -project ios/TDPushSample.xcodeproj \
  -scheme TDPushSample \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

# Test notification delivery (iOS 13+)
xcrun simctl push booted com.treasuredata.pushsample shared/test-payloads/test-notification.apns
```

**Note:**
- This project uses **XcodeGen** to generate the Xcode project from `project.yml`
- Swift Package Manager dependencies are resolved automatically by Xcode
- No `pod install` required

### Android Build Commands
```bash
# Build debug APK
cd android
./gradlew assembleDebug --quiet

# Install on emulator/device
./gradlew installDebug

# Run app
adb shell am start -n com.example.myapp/.MainActivity

# View logs
adb logcat | grep -E "FCMService|PushEvent"

# Clean build
./gradlew clean assembleDebug
```

### Code Quality
```bash
# iOS lint (optional)
swiftlint --config .swiftlint.yml

# Android lint
cd android
./gradlew ktlintCheck
./gradlew ktlintFormat
```

---

## 📂 PROJECT STRUCTURE

### Repository Root
```
mobile-push-samples/
├── android/                        # Android sample app
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── java/com/treasuredata/pushsample/
│   │   │   │   ├── MainActivity.kt
│   │   │   │   ├── MyApplication.kt
│   │   │   │   └── fcm/
│   │   │   │       ├── MyFirebaseMessagingService.kt
│   │   │   │       ├── PushEventReceiver.kt
│   │   │   │       ├── PushAction.kt
│   │   │   │       ├── FcmTokenService.kt
│   │   │   │       ├── EventQueue.kt
│   │   │   │       └── PushEventUploader.kt
│   │   │   ├── res/
│   │   │   └── AndroidManifest.xml
│   │   ├── build.gradle.kts
│   │   └── google-services.json.example
│   ├── gradle/
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── ios/                            # iOS sample app
│   ├── MyApp/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   ├── ViewController.swift
│   │   ├── Models/
│   │   │   ├── FCMTokenService.swift
│   │   │   ├── EventQueue.swift
│   │   │   └── PushEventUploader.swift
│   │   ├── Assets.xcassets
│   │   ├── Info.plist
│   │   └── GoogleService-Info.plist.example
│   ├── NotificationService/        # Extension
│   │   └── NotificationService.swift
│   ├── MyApp.xcodeproj/
│   └── Podfile
├── shared/                         # Shared assets and configs
│   ├── test-payloads/
│   │   └── test-notification.apns  # iOS Simulator local notification payload
│   └── images/
├── docs/                           # Additional documentation
│   ├── SETUP.md
│   ├── TESTING.md
│   └── TROUBLESHOOTING.md
├── .gitignore
├── README.md
└── CLAUDE.md                       # This file
```

### iOS Directory Pattern
- **AppDelegate.swift**: Firebase init, notification permissions, FCM delegates
- **SceneDelegate.swift**: Deep link routing (iOS 13+)
- **Models/**: Service classes (token, queue, uploader)
- **NotificationService/**: Rich media extension

### Android Directory Pattern
- **fcm/**: All push notification related services
- **MainActivity.kt**: Deep link handling, notification tap events
- **MyApplication.kt**: App-level initialization

---

## 🧪 TESTING WORKFLOW

### Pre-Flight Checklist
1. ✅ **Xcode (full version) installed** - Required for iOS development and testing
   - Install from App Store: https://apps.apple.com/us/app/xcode/id497799835
   - Command Line Tools alone are insufficient (no iOS Simulator)
   - After install: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
2. ✅ **XcodeGen installed** - Required for iOS project generation
   - Install: `brew install xcodegen`
3. ✅ Firebase project created with iOS and Android apps registered
4. ✅ `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) downloaded
5. ✅ APNs authentication key uploaded to Firebase Console (iOS)
6. ✅ Treasure Data database and table created (`mobile.push_events`)
7. ✅ Write-only API key obtained from Treasure Data
8. ✅ `TD_WRITE_KEY` configured in app (not committed to Git)

### iOS Testing Steps
1. **Build and run** on a physical iOS device
2. **Check logs** for FCM token: `print("FCM token: \(token)")`
3. **Send test notification** via Engage Studio **Send test** with the current FCM token
4. **Verify notification** appears on the device
5. **Tap notification** and verify deep link opens
6. **Query Treasure Data** to confirm events:
   ```sql
   SELECT * FROM mobile.push_events
   WHERE platform = 'ios'
   ORDER BY time DESC LIMIT 10
   ```

### Android Testing Steps
1. **Build and install** on emulator/device: `./gradlew installDebug`
2. **Check logcat** for FCM token: `adb logcat | grep "FCM token"`
3. **Send test notification** via Engage Studio **Send test** with the current FCM token
4. **Verify notification** appears in system tray
5. **Tap notification** and verify deep link opens
6. **Query Treasure Data** to confirm events uploaded

### Event Verification Query
```sql
SELECT
  time,
  type,
  campaign_id,
  message_id,
  platform,
  user_id,
  value
FROM mobile.push_events
WHERE time > td_time_add(now(), '-1h', 'JST')
ORDER BY time DESC
```

---

## 🤖 AGENT BEHAVIORS

### When Adding New Features
1. **Read existing code** for both iOS and Android to understand current patterns
2. **Implement for both platforms** in the same turn
3. **Test build** for both platforms immediately
4. **Update documentation** if behavior changes

### When Fixing Bugs
1. **Reproduce the issue** by reading logs or running the app
2. **Identify root cause** across both platforms (may be platform-specific or shared logic)
3. **Apply fix** to affected platform(s)
4. **Verify fix** by rebuilding and testing

### Log Analysis Priorities
- **iOS**: Look for `FCMService`, `EventQueue`, `PushEventUploader`, `APNS`, errors in Xcode console
- **Android**: Look for `FCMService`, `PushEventUploader`, `WorkManager`, `Firebase`, exceptions in logcat
- **Network**: Check HTTP status codes from Treasure Data API (200 = success)

### Code Generation Standards
- **Comments**: Inline comments for complex logic, header comments for public APIs
- **Error Handling**: Always handle network failures, JSON parsing errors, token refresh failures
- **Logging**: Use consistent log prefixes (`TAG = "FCMService"`)
- **Naming**:
  - iOS: `camelCase` for variables/functions, `PascalCase` for types
  - Android: `camelCase` for variables/functions, `PascalCase` for classes
- **Constants**:
  - iOS: Static properties in service classes
  - Android: `companion object` constants

### Refactoring Rules
1. **Before deleting code**, search for references using `grep -r "functionName" .`
2. **After refactoring**, verify all build targets compile
3. **Update README** if public API changes
4. **Keep feature parity** between iOS and Android

---

## 🔒 SECURITY & BEST PRACTICES

### API Key Management
- ❌ **NEVER commit** `TD_WRITE_KEY`, Firebase config files to Git
- ✅ Use `.example` suffix for template files (`GoogleService-Info.plist.example`)
- ✅ Add actual config files to `.gitignore`
- ✅ Document required keys in README setup instructions

### Deep Link Validation
- ✅ Validate deep link scheme before navigation (`myapp://` only)
- ✅ Sanitize deep link parameters (URL decode, check for malicious input)
- ✅ Use allowlist for sensitive actions

### Event Data Privacy
- ❌ **NEVER send** PII (personally identifiable information) in event payloads
- ✅ Use hashed or anonymized `user_id` when possible
- ✅ Avoid logging sensitive data in console

### Network Security
- ✅ Always use HTTPS for Treasure Data API
- ✅ Implement App Transport Security (iOS)
- ✅ Use certificate pinning for production apps (optional)

---

## 📋 IMPLEMENTATION CHECKLIST

### Phase 1: Project Setup
- [ ] Create iOS Xcode project with Push Notifications capability
- [ ] Create Android app module with FCM dependencies
- [ ] Add Firebase config files (`.example` versions)
- [ ] Configure `.gitignore` to exclude sensitive files
- [ ] Set up directory structure following pattern above

### Phase 2: Core Components
- [ ] **iOS**: Implement `AppDelegate` with Firebase initialization
- [ ] **Android**: Implement `MyApplication` with Firebase initialization
- [ ] **iOS**: Implement `FCMTokenService` for token registration
- [ ] **Android**: Implement `FcmTokenService` for token registration
- [ ] **iOS**: Implement `EventQueue` with UserDefaults persistence
- [ ] **Android**: Implement `EventQueue` with SharedPreferences persistence
- [ ] **iOS**: Implement `PushEventUploader` with URLSession
- [ ] **Android**: Implement `PushEventUploader` with WorkManager + OkHttp

### Phase 3: Notification Handling
- [ ] **iOS**: Implement `UNUserNotificationCenterDelegate` in AppDelegate
- [ ] **Android**: Implement `MyFirebaseMessagingService`
- [ ] **iOS**: Create Notification Service Extension for images
- [ ] **Android**: Implement notification builder with image support
- [ ] **iOS**: Track `delivery` events in foreground/background
- [ ] **Android**: Track `delivery` events in `onMessageReceived`

### Phase 4: User Interactions
- [ ] **iOS**: Handle notification tap in `didReceive response`
- [ ] **Android**: Create `PushEventReceiver` for notification actions
- [ ] **iOS**: Implement deep link routing in `SceneDelegate`
- [ ] **Android**: Implement deep link routing in `MainActivity`
- [ ] **iOS**: Open web links with Safari
- [ ] **Android**: Open web links with Chrome Custom Tabs
- [ ] Track `open`, `dismiss`, `link_open`, `deeplink_open` events

### Phase 5: Testing & Documentation
- [ ] Create test notification payloads in `shared/test-payloads/`
- [ ] Write README with setup instructions
- [ ] Document Treasure Data configuration
- [ ] Add troubleshooting guide
- [ ] Test on physical devices (iOS requires APNs)
- [ ] Verify events appear in Treasure Data

---

## 📚 REFERENCE DOCUMENTATION

- [Treasure Data Mobile Push Documentation](https://docs.treasuredata.com/products/marketing-cloud/engage-studio/channels/mobile-push/)
- [Firebase Cloud Messaging (iOS)](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Firebase Cloud Messaging (Android)](https://firebase.google.com/docs/cloud-messaging/android/client)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Treasure Data Ingest API](https://api-docs.treasuredata.com/)

---

## 🎯 SUCCESS CRITERIA

This sample app is complete when:
1. ✅ Notifications are received on both iOS and Android
2. ✅ Images display correctly in notifications (rich media)
3. ✅ All 6 event types are tracked and uploaded to Treasure Data
4. ✅ Deep links navigate to correct screens in the app
5. ✅ Web links open in Safari (iOS) or Chrome Custom Tabs (Android)
6. ✅ FCM tokens are registered with Treasure Data
7. ✅ Events can be queried in Treasure Data with correct schema
8. ✅ Code is documented with inline comments
9. ✅ README provides clear setup instructions
10. ✅ No API keys or secrets are committed to Git

---

**Last Updated**: 2025-01-XX
**Target Platforms**: iOS 13.0+ | Android 8.0+ (API 26)
**Firebase SDK**: 12.7.0+ (iOS) | BoM 34.7.0+ (Android)
