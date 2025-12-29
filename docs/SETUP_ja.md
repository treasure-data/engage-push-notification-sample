# セットアップガイド

このドキュメントでは、サンプルアプリの詳細なセットアップ手順を説明します。

## 前提条件

### 開発環境

**iOS:**
- macOS 12.0以上
- Xcode 14.0以上
- CocoaPods 1.11以上
- 実機（APNsテストに必要）

**Android:**
- Android Studio Flamingo以上
- JDK 17
- Android SDK (API 26+)

### アカウント

- [Firebase Console](https://console.firebase.google.com/)アクセス権
- [Apple Developer Program](https://developer.apple.com/)メンバーシップ（iOS実機テスト用）
- [Treasure Data Console](https://console.treasuredata.com/)アクセス権

## 1. Firebase プロジェクトの作成

### 1.1 プロジェクト作成

1. [Firebase Console](https://console.firebase.google.com/)を開く
2. 「プロジェクトを追加」をクリック
3. プロジェクト名を入力（例: `td-push-sample`）
4. Google Analyticsを有効化（推奨）
5. 「プロジェクトを作成」をクリック

### 1.2 iOSアプリの登録

1. Firebase Console > プロジェクト設定 > 「アプリを追加」 > iOS
2. 以下の情報を入力：
   - **Apple バンドル ID**: `com.treasuredata.pushsample`（または任意のBundle ID）
   - **アプリのニックネーム**: `TD Push Sample iOS`
   - **App Store ID**: （オプション）
3. 「アプリを登録」をクリック
4. `GoogleService-Info.plist`をダウンロード
5. ファイルを`ios/TDPushSample/`にコピー

### 1.3 Androidアプリの登録

1. Firebase Console > プロジェクト設定 > 「アプリを追加」 > Android
2. 以下の情報を入力：
   - **Android パッケージ名**: `com.treasuredata.pushsample`
   - **アプリのニックネーム**: `TD Push Sample Android`
   - **デバッグ署名証明書 SHA-1**: （オプション）
3. 「アプリを登録」をクリック
4. `google-services.json`をダウンロード
5. ファイルを`android/app/`にコピー

### 1.4 APNs認証キーの設定（iOS）

#### Step 1: Apple Developer Portalで認証キーを作成

1. [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)にログイン
2. 「Keys」セクションで「+」ボタンをクリック
3. Key Name: `TD Push Sample APNs Key`
4. 「Apple Push Notifications service (APNs)」を選択
5. 「Continue」→「Register」→「Download」
6. `.p8`ファイルをダウンロード（Key IDをメモ）
7. Team IDを確認（Account > Membership）

#### Step 2: Firebase Consoleにアップロード

1. Firebase Console > プロジェクト設定 > Cloud Messaging > iOS
2. 「APNs認証キー」セクションで「アップロード」をクリック
3. `.p8`ファイルを選択
4. Key IDとTeam IDを入力
5. 「アップロード」をクリック

## 2. Treasure Data の設定

### 2.1 データベースとテーブルの作成

Treasure Data Consoleで以下のSQLを実行：

```sql
-- データベースを作成（存在しない場合）
CREATE DATABASE IF NOT EXISTS mobile;

-- テーブルは自動作成されます（Ingest API使用時）
-- スキーマ確認用:
SELECT * FROM mobile.push_events LIMIT 1;
```

### 2.2 API Keyの取得

1. Treasure Data Console > Settings > API Keys
2. 「Generate New Key」をクリック
3. Key Type: **Write-only**（推奨）
4. Permissions: `mobile`データベースへの書き込み権限
5. Keyをコピー（後で使用）

**⚠️ セキュリティ注意:**
- Write-only Keyを使用してデータ漏洩リスクを最小化
- Keyをコードにハードコードしない（環境変数や設定ファイルを使用）
- 本番環境では、サーバー側でKeyを管理してください

## 3. iOSアプリのセットアップ

### 3.1 依存関係のインストール

```bash
cd ios
pod install
cd ..
```

### 3.2 Xcodeプロジェクトの設定

```bash
open ios/TDPushSample.xcworkspace
```

#### Signing & Capabilities

1. プロジェクトナビゲータで`TDPushSample`を選択
2. Signing & Capabilities タブ
3. Team: 開発チームを選択
4. Bundle Identifier: `com.treasuredata.pushsample`（または任意）
5. 「+ Capability」をクリック
   - **Push Notifications**を追加
   - **Background Modes**を追加 → Remote notificationsにチェック

#### Notification Service Extension

1. 同様に`NotificationService`ターゲットも設定
2. Team: 同じ開発チームを選択
3. Bundle Identifier: `com.treasuredata.pushsample.NotificationService`

### 3.3 Treasure Data API Keyの設定

以下のファイルを編集し、`YOUR_TD_WRITE_KEY`を実際のAPI Keyに置き換え：

**ios/TDPushSample/Models/FCMTokenService.swift:**
```swift
private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← ここを変更
```

**ios/TDPushSample/Models/PushEventUploader.swift:**
```swift
private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← ここを変更
```

### 3.4 Bundle IDとURL Schemeの変更（オプション）

Bundle IDを変更した場合、以下も更新：

**ios/TDPushSample/Info.plist:**
```xml
<key>CFBundleURLSchemes</key>
<array>
    <string>tdpushsample</string> <!-- 任意のスキームに変更可能 -->
</array>
```

**iOS/TDPushSample/AppDelegate.swift と SceneDelegate.swift:**
```swift
if url.scheme == "tdpushsample" { // ← 変更したスキームに合わせる
```

## 4. Androidアプリのセットアップ

### 4.1 Treasure Data API Keyの設定（推奨: ビルド時注入）

**セキュアな方法:** API KeyをGitにコミットせず、ビルド時に注入します。

#### Step 1: local.propertiesファイルを作成

```bash
cd android

# テンプレートをコピー
cp local.properties.example local.properties

# エディタで編集
nano local.properties  # または vi, code など
```

#### Step 2: 実際の値を設定

**android/local.properties:**
```properties
# Treasure Data Configuration
TD_WRITE_KEY=あなたのTreasure Data Write-only API Key
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

**重要:**
- `local.properties`は`.gitignore`に含まれており、Gitにコミットされません
- チーム内で共有する場合は、暗号化された設定管理ツール（1Password、AWS Secrets Manager等）を使用してください

#### 仕組み

`local.properties`の値は、Secrets Gradle Pluginによって自動的に`BuildConfig`フィールドとして生成されます：

```kotlin
// 自動生成される（コード内で使用可能）
BuildConfig.TD_WRITE_KEY
BuildConfig.TD_DATABASE
BuildConfig.TD_TABLE
BuildConfig.TD_ENDPOINT
```

コード内では以下のように使用されます：

**android/app/src/main/java/com/treasuredata/pushsample/fcm/PushEventUploader.kt:**
```kotlin
private val TD_WRITE_KEY = BuildConfig.TD_WRITE_KEY  // ビルド時に注入
private val TD_DATABASE = BuildConfig.TD_DATABASE
private val TD_TABLE = BuildConfig.TD_TABLE
private val TD_ENDPOINT = BuildConfig.TD_ENDPOINT
```

### 4.2 Package Nameの変更（オプション）

Package nameを変更する場合、以下を更新：

**android/app/build.gradle.kts:**
```kotlin
android {
    namespace = "com.treasuredata.pushsample" // ← 変更
    defaultConfig {
        applicationId = "com.treasuredata.pushsample" // ← 変更
    }
}
```

**android/app/src/main/AndroidManifest.xml:**
```xml
<data android:scheme="tdpushsample" /> <!-- 任意のスキームに変更可能 -->
```

**すべてのKotlinファイル:**
```kotlin
package com.treasuredata.pushsample // ← 変更したpackage nameに合わせる
```

### 4.3 ビルド

```bash
cd android
./gradlew clean assembleDebug
```

エラーがなければ成功です。

## 5. 動作確認

### 5.1 iOS

```bash
# 1. 実機を接続
# 2. Xcodeでビルド＆実行（Cmd + R）
# 3. コンソールでFCMトークンを確認
# "🔑 FCM token: xxxxx" が表示されればOK
```

### 5.2 Android

```bash
cd android
./gradlew installDebug
adb shell am start -n com.treasuredata.pushsample/.MainActivity
adb logcat | grep "FCM token"
# "🔑 FCM token: xxxxx" が表示されればOK
```

## 6. テスト通知の送信

[TESTING.md](TESTING.md)を参照してください。

## 次のステップ

- [TESTING.md](TESTING.md): テスト方法
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md): トラブルシューティング
- [Treasure Data Documentation](https://docs.treasuredata.com/)

## よくある質問

### Q: Bundle IDやPackage Nameを変更する必要がありますか？

A: 本番環境では独自のIDを使用してください。サンプルとして実行する場合は変更不要です。

### Q: Write-only API Keyではなく、Full access Keyを使用できますか？

A: 技術的には可能ですが、セキュリティリスクが高いため推奨しません。

### Q: シミュレータ/エミュレータでテストできますか？

A:
- **iOS**: シミュレータでもFCMトークンは取得できますが、APNs経由の実際の通知受信は実機が必要です。
- **Android**: エミュレータでも完全に動作します。

### Q: Treasure Dataへのデータ送信が失敗します。

A:
1. API Keyが正しいか確認
2. ネットワーク接続を確認
3. データベース/テーブル名が正しいか確認
4. アプリのログでHTTPレスポンスを確認
