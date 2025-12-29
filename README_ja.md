# Treasure Data Mobile Push Sample App

完全機能のiOS/Androidプッシュ通知サンプルアプリケーションです。Treasure Data Engage Studioとの連携テストが可能です。

## 概要

このサンプルアプリは以下の機能を実装しています：

- ✅ FCMトークンの取得と登録
- ✅ プッシュ通知の受信と表示
- ✅ リッチメディア通知（画像表示）
- ✅ ディープリンク対応
- ✅ Webリンク対応（Safari/Chrome Custom Tabs）
- ✅ イベントトラッキング（delivery, open, dismiss, link_open, deeplink_open, link_arrive, link_fail, token_register）
- ✅ Treasure Data Ingest APIへの自動アップロード
- ✅ オフライン対応のイベントキュー
- ✅ セキュアなリンク処理（ドメイン/ホストallowlist）

## 対応プラットフォーム

- **iOS**: 13.0以上
- **Android**: 8.0以上（API 26）

## 必要な準備

### 1. Firebase プロジェクト

1. [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成
2. iOSアプリを登録（Bundle ID: `com.treasuredata.pushsample`）
3. Androidアプリを登録（Package name: `com.treasuredata.pushsample`）
4. `GoogleService-Info.plist` (iOS)と`google-services.json` (Android)をダウンロード

**iOS APNs設定:**
- Apple Developer PortalでAPNs認証キー（.p8ファイル）を作成
- Firebase Console > プロジェクト設定 > Cloud Messaging > APNs認証キーをアップロード

### 2. Treasure Data

1. [Treasure Data Console](https://console.treasuredata.com/) にログイン
2. データベースとテーブルを作成（例: `mobile.push_events`）
3. Write-only API keyを取得（Settings > API Keys）

## セットアップ手順

### iOS

```bash
# 1. Firebase設定ファイルを配置
cp ios/TDPushSample/GoogleService-Info.plist.example ios/TDPushSample/GoogleService-Info.plist
# GoogleService-Info.plist を編集して実際のFirebase設定を入力

# 2. Info.plistを編集してTreasure Data設定を入力
# - TDWriteKey: YOUR_TD_WRITE_KEY
# - TDDatabase: mobile
# - TDTable: push_events
# - TDEndpoint: https://us01.records.in.treasuredata.com

# 3. 依存関係をインストール
cd ios
pod install
cd ..

# 4. Xcodeでプロジェクトを開く
open ios/TDPushSample.xcworkspace
```

**Xcode設定:**
1. Signing & Capabilities > Team を選択
2. Bundle Identifierを変更する場合は、Info.plistのURL Schemeも更新
3. Capabilities > Push Notifications を有効化
4. Capabilities > Background Modes > Remote notifications を有効化

### Android

```bash
# 1. Firebase設定ファイルを配置
cp android/app/google-services.json.example android/app/google-services.json
# google-services.json を編集して実際のFirebase設定を入力

# 2. Treasure Data API Keyを設定（ビルド時注入方式）
cd android
cp local.properties.example local.properties
# local.properties を編集してTD_WRITE_KEYなどの値を設定
# 例:
# TD_WRITE_KEY=あなたのAPIキー
# TD_DATABASE=mobile
# TD_TABLE=push_events
# TD_ENDPOINT=https://us01.records.in.treasuredata.com

# 3. ビルドとインストール
./gradlew assembleDebug
./gradlew installDebug
```

**注意:** `local.properties`はGitにコミットされません（セキュリティのため）

## 動作確認

### 1. FCMトークンの確認

**iOS:**
```bash
# Xcodeのコンソールで確認
# "🔑 FCM token: xxxxx" が表示されます
```

**Android:**
```bash
adb logcat | grep "FCM token"
# "🔑 FCM token: xxxxx" が表示されます
```

### 2. テスト通知の送信

#### Firebase Consoleから送信（簡単）

1. Firebase Console > Cloud Messaging > 新しいキャンペーン > Notifications
2. 通知テキストを入力
3. テストメッセージ > FCMトークンを入力 > テスト

#### コマンドラインから送信（推奨）

**iOS Simulator:**
```bash
# シミュレータを起動
open -a Simulator
xcrun simctl boot "iPhone 15"

# テスト通知を送信
xcrun simctl push booted com.treasuredata.pushsample shared/test-payloads/test-notification.apns
```

**Android:**
```bash
# Firebase Admin SDK またはcurlを使用（Server Keyが必要）
# 詳細はdocs/TESTING.mdを参照
```

### 3. イベントデータの確認

Treasure Data Consoleでクエリを実行：

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

## イベントスキーマ

すべてのイベントは以下のフィールドを含みます：

| フィールド | 型 | 説明 |
|-----------|------|------|
| `type` | string | イベントタイプ（delivery, open, dismiss, link_open, deeplink_open, link_arrive, link_fail, token_register） |
| `campaign_id` | string | キャンペーンID |
| `message_id` | string | メッセージID |
| `platform` | string | プラットフォーム（ios/android） |
| `fcm_token` | string | FCMトークン |
| `user_id` | string | ユーザーID（オプション） |
| `value` | string | リンクまたはディープリンクURL（link_open/deeplink_open/link_arrive/link_fail時のみ） |
| `reason` | string | 失敗理由（link_fail時のみ: invalid_link, domain_not_allowed, unknown_path, browser_open_failed） |
| `time` | string | ISO8601タイムスタンプ（UTC） |

## ディープリンクとWebリンク

### カスタムURLスキーム（ディープリンク）

デフォルトスキーム: `tdpushsample://`

**サポートされているルート:**
- `tdpushsample://product/{id}` - 商品詳細
- `tdpushsample://category/{id}` - カテゴリ
- `tdpushsample://home` - ホーム

**設定方法:**
- **Android**: `app/build.gradle.kts` の `DEEP_LINK_SCHEME` を変更
- **iOS**: `Info.plist` の `TDDeepLinkScheme` と `CFBundleURLSchemes` を変更

### Webリンク（URL方式）

HTTPS URLはブラウザで開かれます:
- **Android**: Chrome Custom Tabs
- **iOS**: Safari

**セキュリティ:**
- ドメインallowlistで検証（`ALLOWED_DOMAINS` / `TDAllowedDomains`）
- 許可されていないドメインは `link_fail` イベントがトラッキングされます

詳細は [docs/LINK_IMPLEMENTATION_SUMMARY_ja.md](docs/LINK_IMPLEMENTATION_SUMMARY_ja.md) を参照してください。

## トラブルシューティング

詳細は[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)を参照してください。

### よくある問題

**iOS: 通知が届かない**
- APNs認証キーがFirebase Consoleに登録されているか確認
- デバイスが実機であることを確認（シミュレータはAPNs非対応）
- Background Modes > Remote notificationsが有効か確認

**Android: 通知が届かない**
- google-services.jsonが正しく配置されているか確認
- Package nameがcom.treasuredata.pushsampleと一致しているか確認
- インターネット権限が許可されているか確認

**イベントがTreasure Dataに送信されない**
- TD_WRITE_KEYが正しく設定されているか確認
- ネットワーク接続を確認
- アプリのログでHTTPステータスコードを確認（200 = 成功）

**リンクが動作しない**
- ドメイン/ホストがallowlistに含まれているか確認
- `link_fail` イベントの `reason` フィールドで原因を特定
- 詳細は [docs/LINK_IMPLEMENTATION_SUMMARY_ja.md](docs/LINK_IMPLEMENTATION_SUMMARY_ja.md) のトラブルシューティングセクションを参照

## プロジェクト構成

```
.
├── android/                    # Androidアプリ
│   ├── app/src/main/
│   │   ├── java/.../fcm/      # FCM関連サービス
│   │   └── res/               # リソース
│   └── build.gradle.kts
├── ios/                        # iOSアプリ
│   ├── TDPushSample/
│   │   ├── Models/            # サービスクラス
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   └── TrackingService.swift
│   ├── NotificationService/   # 通知拡張
│   └── Podfile
├── shared/
│   └── test-payloads/         # テスト用ペイロード
├── docs/                       # ドキュメント
│   ├── LINK_IMPLEMENTATION_SUMMARY.md
│   ├── LINK_IMPLEMENTATION_SUMMARY_ja.md
│   ├── SETUP.md
│   ├── TESTING.md
│   └── TROUBLESHOOTING.md
├── README.md                   # 英語版README
└── README_ja.md               # 日本語版README（このファイル）
```

## 参考資料

- [Treasure Data Mobile Push Documentation](https://docs.treasuredata.com/products/marketing-cloud/engage-studio/channels/mobile-push/)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Treasure Data Ingest API](https://api-docs.treasuredata.com/)

## ライセンス

このサンプルコードはMITライセンスの下で提供されます。

## サポート

問題が発生した場合は、Treasure Dataサポートにお問い合わせください。
