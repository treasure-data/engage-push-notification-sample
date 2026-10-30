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
Firebase initialized
APNs token registered
🔑 FCM token: dXkz8H...（long string）
```

Copy the FCM token (to be used for test notification sending).

### Android

```bash
# Install and launch the app
adb logcat -c  # Clear logs
adb logcat | grep "FCM"

# You should see logs like:
Firebase initialized
FCM token: dXkz8H...（long string）
```

## 2. Test Notification Sending Methods

### Android

#### Send an Engage Studio test

1. Run the app on an Android device or emulator with Google Play Services and allow notifications.
2. Get the app's current FCM registration token from Logcat.
3. In Engage Studio, open a Mobile Push campaign and select the **Campaign Content** tab.
4. Click **Create mobile push notification**, or **Edit** for existing content. The **Mobile Push Notification Editor** opens.
5. Under **Mobile push authentication**, select the authentication configured for the app's Firebase project.
6. Enter **Title** and **Message**. To test images or tap behavior, configure **Image** and **On click behavior**.
7. Click **Send test**.
8. Enter the token in **Test device token**.
9. Click **Send**.

Check Logcat for the received FCM data payload and confirm that the notification appears. Repeat the test with the app in the foreground and in the background. Verify the `delivery` event as described in [Section 5](#5-verifying-event-sending-to-treasure-data).

### iOS

#### Send an Engage Studio test on a physical device

1. Run the app on a physical iOS device, allow notifications, and copy its current FCM registration token from the Xcode console.
2. In Engage Studio, open a Mobile Push campaign and select the **Campaign Content** tab.
3. Click **Create mobile push notification**, or **Edit** for existing content. The **Mobile Push Notification Editor** opens.
4. Under **Mobile push authentication**, select the authentication configured for the app's Firebase project.
5. Enter **Title** and **Message**. To test images or tap behavior, configure **Image** and **On click behavior**.
6. Click **Send test**.
7. Enter the token in **Test device token**.
8. Click **Send**.
9. Verify notification display, tap behavior, and campaign events in the foreground and background.

**Note:** Background `delivery` events are recorded only when iOS invokes the background callback.

#### Send a test payload directly to the iOS Simulator

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
- `simctl push` injects the payload locally and bypasses FCM and APNs delivery.
- `xcrun simctl` commands require Xcode to be installed.

### Test Payload Files

Use `shared/test-payloads/test-notification.apns` with `simctl push` to test local notification handling on iOS Simulator. For campaign delivery, use Engage Studio **Send test** as described above.

#### iOS Simulator

- **Payload format:** Places `aps` and custom data at the root, with the simulator-only `Simulator Target Bundle`.
- **Message ID:** Does not include an FCM-generated message ID.
- **Notification options:** Omits `sound` and `badge`, matching the Engage Studio payload.

#### Payload Variations

| Test | Simulator fixture |
|------|-------------------|
| Open app | Remove `link` |
| Open a web URL | Set `link` to an allowed HTTPS URL |
| No image | Remove `image` and `aps.mutable-content` |

Use a publicly accessible image URL with a file extension, such as `.jpg` or `.png`.

### Campaign and Message IDs

| Platform | Campaign ID | FCM message ID |
|----------|-------------|----------------|
| Android | `RemoteMessage.data["tdCampaignId"]` | `RemoteMessage.messageId` |
| iOS | `userInfo["tdCampaignId"]` | `userInfo["gcm.message_id"]` |

The app records `tdCampaignId` as `campaign_id` and the FCM message ID as `message_id` in events. FCM supplies the message ID as metadata.

## 3. Confirming Notification Reception

### iOS

When notification arrives:
1. **App in Foreground**: Banner will be displayed
2. **App in Background/Closed**: Will appear in notification center

In the foreground, verify the following log. In the background, it appears only when iOS invokes the callback.

```
Delivery event added to Treasure Data SDK
```

### Android

```bash
adb logcat | grep -E "FCMService|PushEvent|Notification"

# Expected logs:
FCM message received from: ...
Campaign ID: <tdCampaignId from the payload>
Message ID: <FCM-generated message ID>
Delivery event added to Treasure Data SDK
Notification displayed (ID: ...)
```

## 4. Testing User Actions

### 4.1 Notification Tap (Open Event)

1. Tap the notification
2. App launches, deep link or web link opens
3. Verify in logs:

**iOS:**
```
Open event added to Treasure Data SDK
🔗 Deep link opened: tdpushsample://product/12345
📦 Navigating to product: 12345
```

**Android:**
```
Open event added to Treasure Data SDK
Deep link opened: tdpushsample://product/12345
Navigating to product: 12345
```

**iOS state checks:**

- Repeat the tap check with the app in the foreground, background, and terminated.
- Confirm that each tap records one `open` event and opens the configured screen or web link. **Open app** displays the app without navigating to a link.
- Background execution is not guaranteed, so do not require a `delivery` event for the terminated-state tap check.

### 4.2 Notification Dismiss (Dismiss Event)

1. Swipe notification to the left to dismiss
2. Verify in logs:

```
Dismiss event added to Treasure Data SDK
```

### 4.3 Deep Link (Deep Link Open Event)

**Payload:**

```json
{
  "link": "tdpushsample://product/12345"
}
```

**Platform Notes:**
- **Android:** In Engage Studio, set **On click behavior** to **Open a deep link** and enter the URL. It is sent as `data.link`.
- **iOS:** Use `link` at the root of the local APNs payload, matching the custom data key used by Engage Studio.

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

- In the Xcode console or Logcat, check for `Delivery/Open/Dismiss event added to Treasure Data SDK`. This confirms that the SDK accepted the event locally. Use the Treasure Data query below to verify upload.
- The iOS "Queued Events" counter and "Upload Events Now" button use the legacy EventQueue and do not show notification events. Notification events are added directly to the Treasure Data SDK.
- On Android, "Upload Events Now" manually uploads SDK events.

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

This example shows events from an Engage Studio **Send test** with campaign ID `12345` and **Open a deep link** selected. FCM generates a message ID for each notification. `simctl push` does not generate an FCM message ID.

| time | type | campaign_id | message_id | platform |
|------|------|-------------|------------|----------|
| 2025-01-15 10:30:00 | delivery | 12345 | `FCM-generated ID` | ios |
| 2025-01-15 10:30:05 | open | 12345 | `FCM-generated ID` | ios |
| 2025-01-15 10:30:06 | deeplink_open | 12345 | `FCM-generated ID` | ios |

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

1. Send a notification with the deep link in `data.link` (Android) or `link` in the iOS notification userInfo
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
