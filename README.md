# Treasure Data Mobile Push Sample App

A fully-featured iOS/Android push notification sample application for testing integration with Treasure Data Engage Studio.

[日本語版はこちら (Japanese README)](README_ja.md)

## Overview

This sample app implements the following features:

- ✅ FCM token acquisition and registration
- ✅ Push notification reception and display
- ✅ Rich media notifications (image display)
- ✅ Deep link support
- ✅ Web link support (Safari/Chrome Custom Tabs)
- ✅ Event tracking (delivery, open, dismiss, link_open, deeplink_open, link_arrive, link_fail, token_register)
- ✅ Automatic upload to Treasure Data Ingest API
- ✅ Offline-ready event queue
- ✅ Secure link handling (domain/host allowlist)

## Supported Platforms

- **iOS**: 13.0 and above
- **Android**: 8.0 and above (API 26)

## Prerequisites

### 1. Firebase Project

1. Create a project in [Firebase Console](https://console.firebase.google.com/)
2. Register iOS app (Bundle ID: `com.treasuredata.pushsample`)
3. Register Android app (Package name: `com.treasuredata.pushsample`)
4. Download `GoogleService-Info.plist` (iOS) and `google-services.json` (Android)

**iOS APNs Setup:**
- Create APNs authentication key (.p8 file) in Apple Developer Portal
- Firebase Console > Project Settings > Cloud Messaging > Upload APNs authentication key

### 2. Treasure Data

1. Log in to [Treasure Data Console](https://console.treasuredata.com/)
2. Create database and table (e.g., `mobile.push_events`)
3. Obtain Write-only API key (Settings > API Keys)

## Setup Instructions

### iOS

```bash
# 1. Place Firebase configuration file
cp ios/TDPushSample/GoogleService-Info.plist.example ios/TDPushSample/GoogleService-Info.plist
# Edit GoogleService-Info.plist with your actual Firebase configuration

# 2. Edit Info.plist with your Treasure Data configuration
# - TDWriteKey: YOUR_TD_WRITE_KEY
# - TDDatabase: mobile
# - TDTable: push_events
# - TDEndpoint: https://us01.records.in.treasuredata.com

# 3. Install dependencies
cd ios
pod install
cd ..

# 4. Open project in Xcode
open ios/TDPushSample.xcworkspace
```

**Xcode Configuration:**
1. Signing & Capabilities > Select Team
2. If changing Bundle Identifier, update URL Scheme in Info.plist as well
3. Enable Capabilities > Push Notifications
4. Enable Capabilities > Background Modes > Remote notifications

### Android

```bash
# 1. Place Firebase configuration file
cp android/app/google-services.json.example android/app/google-services.json
# Edit google-services.json with your actual Firebase configuration

# 2. Configure Treasure Data API Key (build-time injection)
cd android
cp local.properties.example local.properties
# Edit local.properties and set TD_WRITE_KEY and other values
# Example:
# TD_WRITE_KEY=your_api_key
# TD_DATABASE=mobile
# TD_TABLE=push_events
# TD_ENDPOINT=https://us01.records.in.treasuredata.com

# 3. Build and install
./gradlew assembleDebug
./gradlew installDebug
```

**Note:** `local.properties` is not committed to Git (for security)

## Verification

### 1. Check FCM Token

**iOS:**
```bash
# Check in Xcode console
# "🔑 FCM token: xxxxx" will be displayed
```

**Android:**
```bash
adb logcat | grep "FCM token"
# "🔑 FCM token: xxxxx" will be displayed
```

### 2. Send Test Notification

#### Send from Firebase Console (Easy)

1. Firebase Console > Cloud Messaging > New Campaign > Notifications
2. Enter notification text
3. Test message > Enter FCM token > Test

#### Send from Command Line (Recommended)

**iOS Simulator:**
```bash
# Launch simulator
open -a Simulator
xcrun simctl boot "iPhone 15"

# Send test notification
xcrun simctl push booted com.treasuredata.pushsample shared/test-payloads/test-notification.apns
```

**Android:**
```bash
# Use Firebase Admin SDK or curl (requires Server Key)
# See docs/TESTING.md for details
```

### 3. Verify Event Data

Run query in Treasure Data Console:

```sql
SELECT
  time,
  type,
  campaign_id,
  message_id,
  platform,
  fcm_token,
  user_id,
  value,
  reason
FROM mobile.push_events
WHERE time > td_time_add(now(), '-1h', 'JST')
ORDER BY time DESC
LIMIT 100
```

## Event Schema

All events include the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Event type (delivery, open, dismiss, link_open, deeplink_open, link_arrive, link_fail, token_register) |
| `campaign_id` | string | Campaign ID |
| `message_id` | string | Message ID |
| `platform` | string | Platform (ios/android) |
| `fcm_token` | string | FCM token |
| `user_id` | string | User ID (optional) |
| `value` | string | Link or deep link URL (only for link_open/deeplink_open/link_arrive/link_fail) |
| `reason` | string | Failure reason (only for link_fail: invalid_link, domain_not_allowed, unknown_path, browser_open_failed) |
| `time` | string | ISO8601 timestamp (UTC) |

## Deep Links and Web Links

### Custom URL Scheme (Deep Links)

Default scheme: `tdpushsample://`

**Supported Routes:**
- `tdpushsample://product/{id}` - Product detail
- `tdpushsample://category/{id}` - Category
- `tdpushsample://home` - Home

**Configuration:**
- **Android**: Change `DEEP_LINK_SCHEME` in `app/build.gradle.kts`
- **iOS**: Change `TDDeepLinkScheme` and `CFBundleURLSchemes` in `Info.plist`

### Web Links (URL Method)

HTTPS URLs are opened in browser:
- **Android**: Chrome Custom Tabs
- **iOS**: Safari

**Security:**
- Validated against domain allowlist (`ALLOWED_DOMAINS` / `TDAllowedDomains`)
- Disallowed domains trigger `link_fail` event tracking

For details, see [docs/LINK_IMPLEMENTATION_SUMMARY.md](docs/LINK_IMPLEMENTATION_SUMMARY.md)

## Troubleshooting

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for details.

### Common Issues

**iOS: Notifications not arriving**
- Verify APNs authentication key is registered in Firebase Console
- Ensure device is physical (simulator does not support APNs)
- Check Background Modes > Remote notifications is enabled

**Android: Notifications not arriving**
- Verify google-services.json is correctly placed
- Ensure Package name matches com.treasuredata.pushsample
- Check internet permission is granted

**Events not sent to Treasure Data**
- Verify TD_WRITE_KEY is correctly configured
- Check network connection
- Check HTTP status code in app logs (200 = success)

**Links not working**
- Verify domain/host is in allowlist
- Check `reason` field in `link_fail` event to identify cause
- See troubleshooting section in [docs/LINK_IMPLEMENTATION_SUMMARY.md](docs/LINK_IMPLEMENTATION_SUMMARY.md)

## Project Structure

```
.
├── android/                    # Android app
│   ├── app/src/main/
│   │   ├── java/.../fcm/      # FCM-related services
│   │   └── res/               # Resources
│   └── build.gradle.kts
├── ios/                        # iOS app
│   ├── TDPushSample/
│   │   ├── Models/            # Service classes
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   └── TrackingService.swift
│   ├── NotificationService/   # Notification extension
│   └── Podfile
├── shared/
│   └── test-payloads/         # Test payloads
├── docs/                       # Documentation
│   ├── LINK_IMPLEMENTATION_SUMMARY.md
│   ├── LINK_IMPLEMENTATION_SUMMARY_ja.md
│   ├── SETUP.md
│   ├── TESTING.md
│   └── TROUBLESHOOTING.md
├── README.md                   # English README (this file)
└── README_ja.md               # Japanese README
```

## References

- [Treasure Data Mobile Push Documentation](https://docs.treasuredata.com/products/marketing-cloud/engage-studio/channels/mobile-push/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Treasure Data Ingest API](https://api-docs.treasuredata.com/)

## License

This sample code is provided under the MIT License.

## Support

If you encounter any issues, please contact Treasure Data support.
