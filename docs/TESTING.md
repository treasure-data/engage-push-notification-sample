# Testing Guide

This document explains how to test push notifications and event tracking.

## Test Workflow

1. Verify FCM Token Retrieval
2. Send Test Notification
3. Confirm Notification Reception
4. User Actions (Tap, Dismiss, Link Click)
5. Verify Event Sending to Treasure Data

## 1. Verifying FCM Token Retrieval

### iOS

```bash
# Run the app in Xcode and check the console
# You should see logs like:
✅ Firebase initialized
📱 APNs token registered
🔑 FCM token: dXkz8H...（long string）
```

Copy the FCM token (to be used for test notification sending).

### Android

```bash
# Install and launch the app
adb logcat -c  # Clear logs
adb logcat | grep "FCM"

# You should see logs like:
✅ Firebase initialized
🔑 FCM token: dXkz8H...（long string）
```

## 2. Test Notification Sending Methods

### Method A: Sending from Firebase Console (Easiest)

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Project > Cloud Messaging > "New Campaign" > "Notifications"
3. Enter notification details:
   - **Notification Title**: Test Notification
   - **Notification Text**: This is a test push notification
4. Click "Next"
5. Click "Send Test Message"
6. Enter FCM token to send test message

**To add custom data:**
1. Expand "Additional Options"
2. In the "Custom Data" section, add:

| Key | Value |
|------|-----|
| campaign_id | test_campaign_001 |
| message_id | test_message_001 |
| image | https://picsum.photos/400/300 |
| deeplink | tdpushsample://product/12345 |
| link | https://www.treasuredata.com |

### Method B: Direct Sending in iOS Simulator

**Prerequisites:**
- **Xcode (full version) must be installed**
  - Install [Xcode](https://apps.apple.com/us/app/xcode/id497799835) from the App Store
  - Command Line Tools alone are not sufficient
  - After installation, set Xcode path:
    ```bash
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    ```

```bash
# 1. Verify Xcode developer tools path
xcode-select -p
# Expected output: /Applications/Xcode.app/Contents/Developer
# If it shows /Library/Developer/CommandLineTools, run the command above

# 2. Launch simulator
open -a Simulator
# Or check available simulators and boot:
xcrun simctl list devices available
xcrun simctl boot "iPhone 15"

# 3. Build & install app (run from Xcode)
# Xcode > Product > Run (⌘R)

# 4. Send test payload
xcrun simctl push booted com.treasuredata.pushsample \
  shared/test-payloads/test-notification.apns
```

**Note:**
- Simulators cannot receive APNs notifications. The above command is a simulator-specific feature.
- `xcrun simctl` commands require Xcode to be installed.

## 3. Confirming Notification Reception

### iOS

When notification arrives:
1. **App in Foreground**: Banner will be displayed
2. **App in Background/Closed**: Will appear in notification center

Verify in logs:
```
📬 Notification received in foreground: {...}
✅ Event enqueued. Total events: 1
📡 Sending 1 events to Treasure Data
📊 HTTP Status Code: 200
✅ Successfully uploaded 1 events
```

### Android

```bash
adb logcat | grep -E "FCMService|PushEvent|Notification"

# Expected logs:
📬 FCM message received from: ...
Campaign ID: test_campaign_001
Message ID: test_message_001
✅ Event enqueued. Total events: 1
✅ Notification displayed (ID: ...)
```

## 4. Testing User Actions

### 4.1 Notification Tap (Open Event)

1. Tap the notification
2. App launches, deep link or web link opens
3. Verify in logs:

**iOS:**
```
👆 Notification tapped: {...}
🔗 Deep link opened: tdpushsample://product/12345
📦 Navigating to product: 12345
```

**Android:**
```
👆 Notification tapped - campaign: test_campaign_001
🔗 Deep link opened: tdpushsample://product/12345
📦 Navigating to product: 12345
```

### 4.2 Notification Dismiss (Dismiss Event)

1. Swipe notification to the left to dismiss
2. Verify in logs:

```
🗑️ Notification dismissed - campaign: test_campaign_001
✅ Event enqueued. Total events: 1
```

### 4.3 Deep Link (Deep Link Open Event)

When notification payload includes `deeplink` field:

```json
{
  "deeplink": "tdpushsample://product/12345"
}
```

When tapping notification:
1. Navigate to corresponding screen in the app
2. `deeplink_open` event is recorded

### 4.4 Web Link (Link Open Event)

When notification payload includes `link` field:

```json
{
  "link": "https://www.treasuredata.com"
}
```

When tapping notification:
1. Open URL in Safari (iOS) or Chrome Custom Tabs (Android)
2. `link_open` event is recorded

## 5. Verifying Event Sending to Treasure Data

### 5.1 In-App Verification

**iOS/Android:**
- Check "Queued Events" counter on main screen
- Tap "Upload Events Now" button for manual upload
- Verify HTTP status code 200 in logs

### 5.2 Verification in Treasure Data Console

1. Log in to [Treasure Data Console](https://console.treasuredata.com/)
2. Queries > New Query
3. Execute the following SQL:

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
  app_version,
  os_version,
  device_model
FROM mobile.push_events
WHERE time > td_time_add(now(), '-1h', 'JST')
ORDER BY time DESC
LIMIT 100
```

**Expected Results:**

| time | type | campaign_id | message_id | platform |
|------|------|-------------|------------|----------|
| 2025-01-15 10:30:00 | delivery | test_campaign_001 | test_message_001 | ios |
| 2025-01-15 10:30:05 | open | test_campaign_001 | test_message_001 | ios |
| 2025-01-15 10:30:06 | deeplink_open | test_campaign_001 | test_message_001 | ios |

### 5.3 Event Aggregation Example

**Calculating Delivery Rate:**
```sql
SELECT
  campaign_id,
  COUNT(*) as total_sent,
  COUNT(CASE WHEN type = 'delivery' THEN 1 END) as delivered,
  COUNT(CASE WHEN type = 'open' THEN 1 END) as opened,
  ROUND(100.0 * COUNT(CASE WHEN type = 'open' THEN 1 END) / COUNT(CASE WHEN type = 'delivery' THEN 1 END), 2) as open_rate
FROM mobile.push_events
WHERE time > td_time_add(now(), '-24h', 'JST')
GROUP BY campaign_id
ORDER BY total_sent DESC
```

## 6. Automatic Test Scenarios

### Scenario 1: Basic Notification Delivery

1. Launch the app
2. Retrieve FCM token
3. Send test notification
4. Confirm notification reception (delivery event)
5. Tap notification (open event)
6. Verify events in Treasure Data

### Scenario 2: Rich Media Notification

1. Send notification with image URL
2. Confirm image displays in notification
3. Tap to verify functionality

### Scenario 3: Deep Link

1. Send notification with `deeplink` field
2. Tap notification
3. Confirm correct screen transition in app
4. Verify `deeplink_open` event sent to Treasure Data

### Scenario 4: Web Link

1. Send notification with `link` field
2. Tap notification
3. Confirm link opens in Safari/Chrome Custom Tabs
4. Verify `link_open` event sent to Treasure Data

### Scenario 5: Offline Behavior

1. Enable airplane mode
2. Receive notification
3. Tap notification
4. Confirm event queued (verify in logs)
5. Disable airplane mode
6. Restart app
7. Confirm events automatically uploaded

## 7. Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for details.

### Common Issues

**No Notifications Received:**
- Confirm FCM token is correctly retrieved
- Check project settings in Firebase Console
- iOS: Verify APNs authentication key is set
- Android: Verify google-services.json is correct

**No Events Uploaded:**
- Check network connection
- Verify TD API Key is correct
- Check HTTP response code (200 = success)

**No Images Displayed:**
- iOS: Confirm Notification Service Extension is correctly configured
- Verify image URL uses HTTPS
- Check image size (recommended: under 1MB)