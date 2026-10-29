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
Firebase initialized
APNs token registered
🔑 FCM token: dXkz8H...（長い文字列）
```

FCMトークンをコピーしてください（テスト通知送信に使用します）。

### Android

```bash
# アプリをインストールして起動
adb logcat -c  # ログをクリア
adb logcat | grep "FCM"

# 以下のようなログが表示されます:
Firebase initialized
FCM token: dXkz8H...（長い文字列）
```

## 2. テスト通知の送信方法

### Android

#### Engage Studioのテストを送信

1. Google Play Servicesを搭載したAndroid端末またはエミュレーターでアプリを実行し、通知を許可します。
2. Logcatからアプリの現在のFCM registration tokenを取得します。
3. Engage StudioでMobile Push campaignを開き、**キャンペーンコンテンツ**タブを選択します。
4. **モバイルプッシュ通知を新規作成**をクリックします。既存のコンテンツがある場合は**編集**をクリックします。**モバイルプッシュ通知エディタ**が開きます。
5. **モバイルプッシュ認証**で、アプリのFirebaseプロジェクトに対応する認証を選択します。
6. **タイトル**と**メッセージ**を入力します。画像やタップ時の動作をテストする場合は、**画像**と**クリック時の動作**を設定します。
7. **テスト送信**をクリックします。
8. **テストデバイストークン**にtokenを入力します。
9. **送信**をクリックします。

Logcatで受信したFCM data payloadと通知表示を確認します。アプリをforegroundにした状態とbackgroundにした状態で、それぞれテストを繰り返します。[Section 5](#5-treasure-dataへのイベント送信確認)に従い、`delivery`イベントを確認します。

### iOS

#### iOS実機でEngage Studioのテストを送信

1. iOS実機でアプリを起動し、通知を許可します。Xcode consoleから現在のFCM registration tokenを取得します。
2. Engage StudioでMobile Push campaignを開き、**キャンペーンコンテンツ**タブを選択します。
3. **モバイルプッシュ通知を新規作成**をクリックします。既存のコンテンツがある場合は**編集**をクリックします。**モバイルプッシュ通知エディタ**が開きます。
4. **モバイルプッシュ認証**で、アプリのFirebaseプロジェクトに対応する認証を選択します。
5. **タイトル**と**メッセージ**を入力します。画像やタップ時の動作をテストする場合は、**画像**と**クリック時の動作**を設定します。
6. **テスト送信**をクリックします。
7. **テストデバイストークン**にtokenを入力します。
8. **送信**をクリックします。
9. foregroundとbackgroundで、通知表示、タップ時の動作、campaign eventを確認します。

**注意:** backgroundの`delivery`イベントは、iOSがbackground callbackを呼び出した場合にのみ記録されます。

#### iOS Simulatorでテストpayloadを直接送信

**前提条件:**
- **Xcode（完全版）がインストールされていること**
  - App Storeから[Xcode](https://apps.apple.com/jp/app/xcode/id497799835)をインストール
  - Command Line Toolsのみでは動作しません
  - インストール後、以下を実行してXcodeのパスを設定：
    ```bash
    sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
    ```

```bash
# 1. Xcodeの開発者ツールパスを確認
xcode-select -p
# 出力例: /Applications/Xcode.app/Contents/Developer
# もし /Library/Developer/CommandLineTools と表示される場合は上記のコマンドを実行

# 2. シミュレータを起動
open -a Simulator
# または利用可能なシミュレータを確認して起動:
xcrun simctl list devices available
xcrun simctl boot "iPhone 15"

# 3. アプリをビルド＆インストール（Xcodeから実行）
# Xcode > Product > Run (⌘R)

# 4. テストペイロードを送信
xcrun simctl push booted com.treasuredata.pushsample \
  shared/test-payloads/test-notification.apns
```

**注意:**
- `simctl push`はpayloadをローカルで注入し、FCMとAPNsの配信経路を通りません。
- `xcrun simctl`コマンドはXcodeがインストールされている必要があります。

### テストpayloadファイル

`shared/test-payloads/test-notification.apns`を`simctl push`で送り、iOS Simulator上の通知処理をローカルで確認します。campaign配信は、前述のEngage Studioの**Send test**で確認します。

#### iOS Simulator

- **Payload形式:** `aps`とcustom dataを直下に配置し、Simulator専用の`Simulator Target Bundle`を追加します。
- **Message ID:** FCMが生成するmessage IDは含みません。
- **通知オプション:** Engage Studioのpayloadと同様に、`sound`と`badge`は含みません。

#### Payloadの変更方法

| テスト内容 | Simulator fixture |
|------------|-------------------|
| Open app | `link`を削除 |
| Open a web URL | `link`を許可されたHTTPS URLに設定 |
| 画像なし | `image`と`aps.mutable-content`を削除 |

画像には`.jpg`や`.png`などの拡張子を持つ、外部からアクセス可能なURLを指定してください。

### Campaign IDとmessage ID

| Platform | Campaign ID | FCM message ID |
|----------|-------------|----------------|
| Android | `RemoteMessage.data["tdCampaignId"]` | `RemoteMessage.messageId` |
| iOS | `userInfo["tdCampaignId"]` | `userInfo["gcm.message_id"]` |

アプリは`tdCampaignId`をイベントの`campaign_id`に、FCM message IDを`message_id`に記録します。message IDはFCMがmetadataとして付加します。

## 3. 通知受信の確認

### iOS

通知が届いたら：
1. **アプリがフォアグラウンド**: バナーが表示される
2. **アプリがバックグラウンド/終了**: 通知センターに表示される

foregroundでは、次のログを確認します。backgroundでは、iOSがcallbackを呼び出した場合にだけ記録されます。

```
Delivery event added to Treasure Data SDK
```

### Android

```bash
adb logcat | grep -E "FCMService|PushEvent|Notification"

# 期待されるログ:
FCM message received from: ...
Campaign ID: <tdCampaignId from the payload>
Message ID: <FCM-generated message ID>
Delivery event added to Treasure Data SDK
Notification displayed (ID: ...)
```

## 4. ユーザーアクションのテスト

### 4.1 通知タップ（Open Event）

1. 通知をタップ
2. アプリが起動し、deep linkまたはweb linkが開く
3. ログで確認：

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

**iOSの状態別の確認:**

- foreground、background、アプリ終了状態からのタップをそれぞれ確認します。
- 1回のタップで`open`が1件記録され、設定した画面またはweb linkが開くことを確認します。**Open app**の場合はアプリの画面を表示します。
- background実行は保証されないため、終了状態からのタップの確認では`delivery`イベントを必須にしません。

### 4.2 通知削除（Dismiss Event）

1. 通知を左にスワイプして削除
2. ログで確認：

```
Dismiss event added to Treasure Data SDK
```

### 4.3 ディープリンク（Deep Link Open Event）

**Payload:**

```json
{
  "link": "tdpushsample://product/12345"
}
```

**Platform別の設定:**
- **Android:** Engage Studioの**クリック時の動作**で**ディープリンクを開く**を選択し、URLを入力します。`data.link`として送信されます。
- **iOS:** ローカルのAPNs payloadの直下に`link`を設定します。Engage Studioが使用するcustom data keyと同じ名前です。

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

- Xcode consoleまたはLogcatで`Delivery/Open/Dismiss event added to Treasure Data SDK`を確認します。これはSDKへの追加を示します。アップロードの確認には、次のTreasure Dataのqueryを使用します。
- iOSの「Queued Events」と「Upload Events Now」は旧EventQueue用のため、通知イベントの確認には使用しません。通知イベントはTreasure Data SDKに直接追加されます。
- Androidの「Upload Events Now」はSDKのイベントを手動アップロードします。

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

以下はcampaign ID `12345`で**Open a deep link**を選択し、Engage Studioの**Send test**で送信した場合のイベント例です。message IDはFCMが通知ごとに生成します。`simctl push`はFCM message IDを生成しません。

| time | type | campaign_id | message_id | platform |
|------|------|-------------|------------|----------|
| 2025-01-15 10:30:00 | delivery | 12345 | `FCM-generated ID` | ios |
| 2025-01-15 10:30:05 | open | 12345 | `FCM-generated ID` | ios |
| 2025-01-15 10:30:06 | deeplink_open | 12345 | `FCM-generated ID` | ios |

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

1. Androidでは`data.link`、iOSではnotification userInfoの`link`にdeep linkを指定して送信
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
