# テストガイド

このドキュメントでは、プッシュ通知とイベントトラッキングのテスト方法を説明します。

## テストの流れ

1. FCMトークンの取得確認
2. テスト通知の送信
3. 通知の受信確認
4. ユーザーアクション（タップ、削除、リンククリック）
5. Treasure Dataへのイベント送信確認

## 1. FCMトークンの取得確認

### iOS

```bash
# Xcodeでアプリを実行し、コンソールを確認
# 以下のようなログが表示されます:
✅ Firebase initialized
📱 APNs token registered
🔑 FCM token: dXkz8H...（長い文字列）
```

FCMトークンをコピーしてください（テスト通知送信に使用します）。

### Android

```bash
# アプリをインストールして起動
adb logcat -c  # ログをクリア
adb logcat | grep "FCM"

# 以下のようなログが表示されます:
✅ Firebase initialized
🔑 FCM token: dXkz8H...（長い文字列）
```

## 2. テスト通知の送信方法

### 方法A: Firebase Consoleから送信（最も簡単）

1. [Firebase Console](https://console.firebase.google.com/)を開く
2. プロジェクト > Cloud Messaging > 「新しいキャンペーン」 > 「Notifications」
3. 通知の内容を入力：
   - **通知のタイトル**: Test Notification
   - **通知テキスト**: This is a test push notification
4. 「次へ」をクリック
5. 「テストメッセージを送信」をクリック
6. FCMトークンを入力してテスト送信

**カスタムデータを追加するには:**
1. 「追加オプション」を展開
2. 「カスタムデータ」セクションで以下を追加：

| キー | 値 |
|------|-----|
| campaign_id | test_campaign_001 |
| message_id | test_message_001 |
| image | https://picsum.photos/400/300 |
| deeplink | tdpushsample://product/12345 |
| link | https://www.treasuredata.com |

### 方法B: iOS Simulatorで直接送信

```bash
# 1. シミュレータを起動
open -a Simulator
xcrun simctl boot "iPhone 15"

# 2. アプリをビルド＆インストール（Xcodeから実行）

# 3. テストペイロードを送信
xcrun simctl push booted com.treasuredata.pushsample \
  shared/test-payloads/test-notification.apns
```

**注意:** シミュレータではAPNs経由の通知は受信できません。上記コマンドはシミュレータ専用機能です。

## 3. 通知受信の確認

### iOS

通知が届いたら：
1. **アプリがフォアグラウンド**: バナーが表示される
2. **アプリがバックグラウンド/終了**: 通知センターに表示される

ログで確認：
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

# 期待されるログ:
📬 FCM message received from: ...
Campaign ID: test_campaign_001
Message ID: test_message_001
✅ Event enqueued. Total events: 1
✅ Notification displayed (ID: ...)
```

## 4. ユーザーアクションのテスト

### 4.1 通知タップ（Open Event）

1. 通知をタップ
2. アプリが起動し、deep linkまたはweb linkが開く
3. ログで確認：

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

### 4.2 通知削除（Dismiss Event）

1. 通知を左にスワイプして削除
2. ログで確認：

```
🗑️ Notification dismissed - campaign: test_campaign_001
✅ Event enqueued. Total events: 1
```

### 4.3 ディープリンク（Deep Link Open Event）

通知ペイロードに`deeplink`フィールドが含まれている場合：

```json
{
  "deeplink": "tdpushsample://product/12345"
}
```

通知タップ時に：
1. アプリ内で該当画面に遷移
2. `deeplink_open`イベントが記録される

### 4.4 Webリンク（Link Open Event）

通知ペイロードに`link`フィールドが含まれている場合：

```json
{
  "link": "https://www.treasuredata.com"
}
```

通知タップ時に：
1. Safari（iOS）またはChrome Custom Tabs（Android）でURLを開く
2. `link_open`イベントが記録される

## 5. Treasure Dataへのイベント送信確認

### 5.1 アプリ内での確認

**iOS/Android:**
- アプリのメイン画面で「Queued Events」カウンターを確認
- 「Upload Events Now」ボタンをタップして手動アップロード
- ログでHTTPステータスコード200を確認

### 5.2 Treasure Data Consoleでの確認

1. [Treasure Data Console](https://console.treasuredata.com/)にログイン
2. Queries > New Query
3. 以下のSQLを実行：

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

**期待される結果:**

| time | type | campaign_id | message_id | platform |
|------|------|-------------|------------|----------|
| 2025-01-15 10:30:00 | delivery | test_campaign_001 | test_message_001 | ios |
| 2025-01-15 10:30:05 | open | test_campaign_001 | test_message_001 | ios |
| 2025-01-15 10:30:06 | deeplink_open | test_campaign_001 | test_message_001 | ios |

### 5.3 イベント集計例

**配信率の計算:**
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

## 6. 自動テストシナリオ

### シナリオ1: 基本的な通知配信

1. アプリを起動
2. FCMトークンを取得
3. テスト通知を送信
4. 通知受信を確認（delivery イベント）
5. 通知をタップ（open イベント）
6. Treasure Dataでイベント確認

### シナリオ2: リッチメディア通知

1. 画像URLを含む通知を送信
2. 通知に画像が表示されることを確認
3. タップして動作確認

### シナリオ3: ディープリンク

1. `deeplink`フィールドを含む通知を送信
2. 通知をタップ
3. アプリ内で正しい画面に遷移することを確認
4. `deeplink_open`イベントがTreasure Dataに送信されることを確認

### シナリオ4: Webリンク

1. `link`フィールドを含む通知を送信
2. 通知をタップ
3. Safari/Chrome Custom Tabsでリンクが開くことを確認
4. `link_open`イベントがTreasure Dataに送信されることを確認

### シナリオ5: オフライン動作

1. デバイスを機内モードにする
2. 通知を受信
3. 通知をタップ
4. イベントがキューに保存されることを確認（ログで確認）
5. 機内モードを解除
6. アプリを再起動
7. イベントが自動的にアップロードされることを確認

## 6. トラブルシューティング

詳細は[TROUBLESHOOTING.md](TROUBLESHOOTING.md)を参照してください。

### よくある問題

**通知が届かない:**
- FCMトークンが正しく取得されているか確認
- Firebase Consoleでプロジェクト設定を確認
- iOS: APNs認証キーが設定されているか確認
- Android: google-services.jsonが正しいか確認

**イベントがアップロードされない:**
- ネットワーク接続を確認
- TD API Keyが正しいか確認
- HTTPレスポンスコードを確認（200 = 成功）

**画像が表示されない:**
- iOS: Notification Service Extensionが正しく設定されているか確認
- 画像URLがHTTPSか確認
- 画像サイズが大きすぎないか確認（推奨: 1MB以下）
