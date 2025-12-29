# Push Notification Link Implementation Summary

Implementation completed on: 2025-12-27

## Overview

This document summarizes the implementation of secure link handling for push notifications, following the "Push通知 Link パラメータ実装ガイド" requirements.

## Features Implemented

### 1. URL方式 (HTTPS URLs)
- ✅ Domain allowlist validation
- ✅ Open in browser (Chrome Custom Tabs on Android, Safari on iOS)
- ✅ Tracking: `link_open`, `link_arrive`, `link_fail`

### 2. カスタムスキーム方式 (Custom Scheme Deep Links)
- ✅ Configurable URI scheme
- ✅ Host/path pattern validation
- ✅ In-app navigation to destinations
- ✅ Tracking: `deeplink_open`, `link_arrive`, `link_fail`

### 3. Security Features
- ✅ Domain allowlist for HTTPS URLs
- ✅ Host allowlist for deep links
- ✅ Path pattern validation
- ✅ Fallback strategy for invalid links
- ✅ No PII in tracking events

### 4. Event Tracking
- ✅ `push_open`: Notification tapped
- ✅ `link_open`: Web link opened in browser
- ✅ `deeplink_open`: Deep link opened
- ✅ `link_arrive`: Successfully arrived at destination
- ✅ `link_fail`: Failed with reason (`invalid_link`, `domain_not_allowed`, `unknown_path`, `browser_open_failed`)

## Platform-Specific Implementation

### Android (Kotlin)

**Configuration Location**: `app/build.gradle.kts`

```kotlin
buildConfigField("String", "DEEP_LINK_SCHEME", "\"tdpushsample\"")
buildConfigField("String", "ALLOWED_DOMAINS", "\"example.com,treasuredata.com\"")
buildConfigField("String", "ALLOWED_DEEP_LINK_HOSTS", "\"product,category,home\"")
```

**Modified Files**:
1. `app/build.gradle.kts` - Added configuration constants
2. `MainActivity.kt` - Added validation, tracking, and fallback logic
3. `ProductDetailActivity.kt` - Deep link destination (already existed)
4. `CategoryActivity.kt` - Deep link destination (already existed)

**Key Methods**:
- `handleWebLink()`: Validates domain and opens in Chrome Custom Tabs
- `handleDeepLink()`: Validates and processes custom scheme deep links
- `handleDeepLinkUri()`: Routes to specific app screens with validation
- `fallbackToHome()`: Fallback when links are invalid
- `trackLinkArriveEvent()`: Track successful arrival
- `trackLinkFailEvent()`: Track failure with reason

### iOS (Swift)

**Configuration Location**: `TDPushSample/Info.plist`

```xml
<key>TDDeepLinkScheme</key>
<string>tdpushsample</string>

<key>TDAllowedDomains</key>
<array>
    <string>example.com</string>
    <string>treasuredata.com</string>
</array>

<key>TDAllowedDeepLinkHosts</key>
<array>
    <string>product</string>
    <string>category</string>
    <string>home</string>
</array>
```

**Modified Files**:
1. `Info.plist` - Added configuration arrays
2. `AppDelegate.swift` - Added validation, uses TrackingService
3. `SceneDelegate.swift` - Added validation and tracking for navigation
4. `TrackingService.swift` - **NEW** Shared tracking methods
5. `ProductDetailViewController.swift` - Deep link destination (already existed)
6. `CategoryViewController.swift` - Deep link destination (already existed)

**Key Methods**:
- `TrackingService.shared.trackLinkArriveEvent()`: Track successful arrival
- `TrackingService.shared.trackLinkFailEvent()`: Track failure with reason
- `TrackingService.shared.trackDeepLinkOpenEvent()`: Track deep link open
- `TrackingService.shared.trackWebLinkOpenEvent()`: Track web link open
- `fallbackToHome()`: Fallback when links are invalid

## Link Processing Flow

### 1. Notification Received
```
FCM Payload: {
  "data": {
    "link": "https://example.com/page" OR "tdpushsample://product/12345",
    "campaign_id": "campaign123",
    "message_id": "msg456"
  }
}
```

### 2. Scheme Detection
```
if (scheme == "http" || scheme == "https") {
    → Web Link (URL方式)
} else if (scheme == DEEP_LINK_SCHEME) {
    → Deep Link (Scheme方式)
} else {
    → Unknown → track link_fail with reason "invalid_link"
}
```

### 3. Web Link Processing (URL方式)
```
1. Parse URL
2. Validate domain against ALLOWED_DOMAINS
   ❌ → track link_fail with reason "domain_not_allowed"
   ✅ → Continue

3. Track link_open event
4. Open in browser (Chrome Custom Tabs / Safari)
   ❌ → track link_fail with reason "browser_open_failed"
   ✅ → track link_arrive event
```

### 4. Deep Link Processing (Scheme方式)
```
1. Validate scheme matches DEEP_LINK_SCHEME
   ❌ → track link_fail with reason "invalid_link"
   ✅ → Continue

2. Validate host in ALLOWED_DEEP_LINK_HOSTS
   ❌ → track link_fail with reason "unknown_path"
   ✅ → Continue

3. Track deeplink_open event
4. Navigate to screen (SceneDelegate/MainActivity)

5. Validate path parameters (productId, categoryId, etc.)
   ❌ → track link_fail with reason "invalid_link"
   ✅ → Navigate

6. On successful navigation
   ✅ → track link_arrive event
```

## Event Schema

All events sent to Treasure Data have this schema:

```json
{
  "type": "link_arrive",           // or "link_open", "deeplink_open", "link_fail"
  "campaign_id": "campaign123",
  "message_id": "msg456",
  "platform": "android",           // or "ios"
  "fcm_token": "token...",
  "value": "https://example.com/page",  // The link URL
  "reason": "domain_not_allowed",  // Only for link_fail
  "time": 1735311234567
}
```

### link_fail Reasons

| Reason | Description |
|--------|-------------|
| `invalid_link` | Invalid URL format or missing required path parameters |
| `domain_not_allowed` | HTTPS URL domain not in allowlist |
| `unknown_path` | Deep link host not in allowlist |
| `browser_open_failed` | Failed to open browser for web link |

## Testing

### Test Scenarios

1. **Valid Deep Link**
   - Payload: `{"link": "tdpushsample://product/12345"}`
   - Expected: Navigate to product screen, track `deeplink_open` → `link_arrive`

2. **Valid Web Link**
   - Payload: `{"link": "https://example.com/page"}`
   - Expected: Open in browser, track `link_open` → `link_arrive`

3. **Invalid Domain**
   - Payload: `{"link": "https://malicious.com/page"}`
   - Expected: Stay at home, track `link_fail` with reason `domain_not_allowed`

4. **Invalid Deep Link Host**
   - Payload: `{"link": "tdpushsample://unknown/path"}`
   - Expected: Stay at home, track `link_fail` with reason `unknown_path`

5. **Missing Path Parameter**
   - Payload: `{"link": "tdpushsample://product/"}`
   - Expected: Stay at home, track `link_fail` with reason `invalid_link`

### Query Events in Treasure Data

```sql
SELECT
  time,
  type,
  campaign_id,
  message_id,
  platform,
  value,
  reason
FROM mobile.push_events
WHERE type IN ('link_open', 'deeplink_open', 'link_arrive', 'link_fail')
  AND time > td_time_add(now(), '-1h', 'JST')
ORDER BY time DESC
LIMIT 100
```

## Configuration

### Changing Deep Link Scheme

**Android**: Edit `app/build.gradle.kts`
```kotlin
buildConfigField("String", "DEEP_LINK_SCHEME", "\"yourscheme\"")
manifestPlaceholders["deepLinkScheme"] = "yourscheme"
```

**iOS**: Edit `TDPushSample/Info.plist`
```xml
<key>TDDeepLinkScheme</key>
<string>yourscheme</string>

<key>CFBundleURLSchemes</key>
<array>
    <string>yourscheme</string>
</array>
```

### Adding Allowed Domains

**Android**: Edit `app/build.gradle.kts`
```kotlin
buildConfigField("String", "ALLOWED_DOMAINS", "\"example.com,yourdomain.com\"")
```

**iOS**: Edit `TDPushSample/Info.plist`
```xml
<key>TDAllowedDomains</key>
<array>
    <string>example.com</string>
    <string>yourdomain.com</string>
</array>
```

### Adding Allowed Deep Link Hosts

**Android**: Edit `app/build.gradle.kts`
```kotlin
buildConfigField("String", "ALLOWED_DEEP_LINK_HOSTS", "\"product,category,home,profile\"")
```

**iOS**: Edit `TDPushSample/Info.plist`
```xml
<key>TDAllowedDeepLinkHosts</key>
<array>
    <string>product</string>
    <string>category</string>
    <string>home</string>
    <string>profile</string>
</array>
```

## Build Status

✅ **Android**: Build succeeded
- APK generated: `app/build/outputs/apk/debug/app-debug.apk` (10MB)
- Build time: 2025-12-27 23:34

⚠️ **iOS**: Syntax validated, Xcode build pending
- Swift compiler version: 6.2.3
- Full build requires Xcode installation

## Next Steps

1. Install dependencies:
   - Android: Dependencies already downloaded
   - iOS: Run `pod install` if using CocoaPods

2. Test on physical devices:
   - Android: Install APK and test with FCM test messages
   - iOS: Build in Xcode and test on simulator/device with APNs

3. Verify tracking events in Treasure Data console

## Security Notes

- ✅ All domains and hosts are validated against allowlists
- ✅ No user credentials or PII in tracking events
- ✅ Invalid links trigger fallback (stay at home screen)
- ✅ All failures are tracked with specific reasons for debugging
- ✅ HTTPS URLs only open in secure browser contexts

## References

- Implementation Guide: "Push通知 Link パラメータ実装ガイド（URL方式 / Scheme方式）"
- Project Instructions: `CLAUDE.md`
- Firebase Documentation: https://firebase.google.com/docs/cloud-messaging
- Treasure Data Documentation: https://docs.treasuredata.com/
