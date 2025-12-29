# トラブルシューティングガイド

このドキュメントでは、よくある問題とその解決方法を説明します。

## 目次

1. [FCMトークン取得の問題](#fcmトークン取得の問題)
2. [通知受信の問題](#通知受信の問題)
3. [イベント送信の問題](#イベント送信の問題)
4. [ディープリンクの問題](#ディープリンクの問題)
5. [ビルドエラー](#ビルドエラー)

## FCMトークン取得の問題

### iOS: FCMトークンが取得できない

**症状:**
```
❌ Error fetching FCM token: ...
```

**原因と解決策:**

1. **APNsトークンが取得できていない**
   - 実機でテストしているか確認（シミュレータではAPNs非対応）
   - Push Notifications capabilityが有効か確認
   - Provisioning Profileが正しいか確認

2. **Firebase設定が不正**
   ```bash
   # GoogleService-Info.plistを確認
   ls -la ios/TDPushSample/GoogleService-Info.plist

   # ファイルが存在しない場合
   cp ios/TDPushSample/GoogleService-Info.plist.example \
      ios/TDPushSample/GoogleService-Info.plist
   # 実際のFirebase設定を入力
   ```

3. **Firebase初期化エラー**
   ```swift
   // AppDelegate.swift で確認
   FirebaseApp.configure() // この行が実行されているか確認
   ```

### Android: FCMトークンが取得できない

**症状:**
```
❌ Error fetching FCM token: ...
```

**原因と解決策:**

1. **google-services.jsonが配置されていない**
   ```bash
   ls -la android/app/google-services.json

   # ファイルが存在しない場合
   cp android/app/google-services.json.example \
      android/app/google-services.json
   # 実際のFirebase設定を入力
   ```

2. **Package nameが一致しない**
   ```bash
   # google-services.jsonのpackage_nameを確認
   cat android/app/google-services.json | grep package_name

   # build.gradle.ktsのapplicationIdと一致するか確認
   cat android/app/build.gradle.kts | grep applicationId
   ```

3. **Google Play Servicesが古い**
   ```bash
   # エミュレータ/デバイスのGoogle Play Servicesを更新
   # Settings > Apps > Google Play Services > Update
   ```

## 通知受信の問題

### iOS: 通知が届かない

**症状:**
- テスト通知を送信しても何も表示されない

**診断手順:**

```bash
# 1. Xcodeコンソールでログを確認
# 以下のログが表示されるか:
✅ Notification permission granted: true
📱 APNs token registered
🔑 FCM token: ...
```

**原因と解決策:**

1. **実機を使用していない**
   - **解決策**: 実機でテストしてください（シミュレータではAPNs経由の通知は受信不可）
   - シミュレータテスト用: `xcrun simctl push`コマンドを使用

2. **APNs認証キーが設定されていない**
   ```bash
   # Firebase Console > プロジェクト設定 > Cloud Messaging > iOS
   # APNs認証キーが登録されているか確認
   ```

3. **通知権限が許可されていない**
   ```bash
   # デバイスで確認:
   # Settings > Notifications > TDPushSample > Allow Notifications
   ```

4. **Background Modesが有効になっていない**
   ```
   Xcode > Target: TDPushSample > Signing & Capabilities
   > Background Modes > Remote notifications にチェック
   ```

5. **Bundle IDが一致しない**
   ```bash
   # Xcode: Bundle Identifier
   # Firebase Console: iOSアプリのBundle ID
   # 両方が一致しているか確認
   ```

### Android: 通知が届かない

**症状:**
- テスト通知を送信しても何も表示されない

**診断手順:**

```bash
adb logcat -c  # ログをクリア
# テスト通知を送信
adb logcat | grep -E "FCM|Notification"
```

**原因と解決策:**

1. **通知権限が許可されていない（Android 13+）**
   ```bash
   # デバイスで確認:
   # Settings > Apps > TD Push Sample > Notifications > Allow

   # プログラムで確認:
   # MainActivity.kt で通知権限リクエストを追加
   ```

2. **Package nameが一致しない**
   ```bash
   # AndroidManifest.xml
   grep package android/app/src/main/AndroidManifest.xml

   # build.gradle.kts
   grep applicationId android/app/build.gradle.kts

   # google-services.json
   grep package_name android/app/google-services.json
   ```

3. **FirebaseMessagingServiceが登録されていない**
   ```xml
   <!-- AndroidManifest.xml で確認 -->
   <service
       android:name=".fcm.MyFirebaseMessagingService"
       android:exported="false">
       <intent-filter>
           <action android:name="com.google.firebase.MESSAGING_EVENT" />
       </intent-filter>
   </service>
   ```

4. **アプリがバッテリー最適化の対象になっている**
   ```bash
   # Settings > Battery > Battery optimization
   # TD Push Sampleを「最適化しない」に設定
   ```

## イベント送信の問題

### Treasure Dataにイベントが送信されない

**症状:**
```
❌ Upload failed with status code: 401
または
❌ Upload failed with status code: 404
```

**診断手順:**

```bash
# iOS: Xcodeコンソール
# Android: adb logcat

# 以下のログを確認:
📡 Sending X events to Treasure Data
URL: https://in.treasuredata.com/postback/v3/event/mobile/push_events
📊 HTTP Status Code: ???
```

**HTTPステータスコード別の解決策:**

| コード | 意味 | 解決策 |
|--------|------|--------|
| 200 | 成功 | 問題なし |
| 401 | 認証エラー | API Keyが間違っている |
| 403 | 権限エラー | API Keyの権限が不足 |
| 404 | Not Found | データベース/テーブル名が間違っている |
| 500 | サーバーエラー | Treasure Dataサポートに連絡 |

**解決策:**

1. **API Keyの確認**

   **iOS:**
   ```swift
   // FCMTokenService.swift
   private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← 正しいか確認

   // PushEventUploader.swift
   private let tdWriteKey = "YOUR_TD_WRITE_KEY" // ← 正しいか確認
   ```

   **Android:**
   ```kotlin
   // PushEventUploader.kt
   private const val TD_WRITE_KEY = "YOUR_TD_WRITE_KEY" // ← 正しいか確認
   ```

2. **データベース/テーブル名の確認**

   ```swift
   // iOS
   private let tdDatabase = "mobile"  // ← Treasure Dataと一致するか
   private let tdTable = "push_events"
   ```

   ```kotlin
   // Android
   private const val TD_DATABASE = "mobile"  // ← Treasure Dataと一致するか
   private const val TD_TABLE = "push_events"
   ```

3. **ネットワーク接続の確認**
   ```bash
   # デバイスがインターネットに接続されているか確認
   ping -c 3 in.treasuredata.com
   ```

4. **エンドポイントの確認**

   リージョンによってエンドポイントが異なります：
   - US: `https://in.treasuredata.com`
   - Tokyo: `https://in.treasure-data.com`
   - EU: `https://in.eu01.treasuredata.com`

### イベントがキューに溜まり続ける

**症状:**
- アプリで「Queued Events: 1000」が減らない

**診断手順:**

```bash
# ログでアップロード処理を確認
📤 Starting upload of 1000 events
📡 Sending 500 events to Treasure Data
❌ Upload failed with status code: 401
❌ Upload failed, re-enqueuing events
```

**解決策:**

1. 上記「Treasure Dataにイベントが送信されない」を参照
2. API Keyや設定を修正後、アプリを再起動
3. 「Upload Events Now」ボタンで手動アップロード

## ディープリンクの問題

### iOS: ディープリンクが動作しない

**症状:**
- 通知をタップしてもディープリンクが開かない

**解決策:**

1. **URL Schemeの確認**
   ```xml
   <!-- Info.plist -->
   <key>CFBundleURLSchemes</key>
   <array>
       <string>tdpushsample</string>
   </array>
   ```

2. **SceneDelegateの実装確認**
   ```swift
   func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
       // この関数が実装されているか確認
   }
   ```

3. **通知ペイロードの確認**
   ```json
   {
     "deeplink": "tdpushsample://product/12345"  // スキームが正しいか
   }
   ```

### Android: ディープリンクが動作しない

**症状:**
- 通知をタップしてもディープリンクが開かない

**解決策:**

1. **Intent Filterの確認**
   ```xml
   <!-- AndroidManifest.xml -->
   <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="tdpushsample" />
   </intent-filter>
   ```

2. **MainActivity.launchModeの確認**
   ```xml
   <activity
       android:name=".MainActivity"
       android:launchMode="singleTop">  <!-- 重要 -->
   ```

3. **onNewIntentの実装確認**
   ```kotlin
   override fun onNewIntent(intent: Intent) {
       super.onNewIntent(intent)
       handleIntent(intent)  // この関数が実装されているか
   }
   ```

## ビルドエラー

### iOS: CocoaPods関連エラー

**症状:**
```
[!] Unable to find a specification for `Firebase/Messaging`
```

**解決策:**

```bash
cd ios

# 1. CocoaPodsキャッシュをクリア
pod cache clean --all

# 2. リポジトリを更新
pod repo update

# 3. 再インストール
pod deintegrate
pod install

cd ..
```

### iOS: Signing エラー

**症状:**
```
Signing for "TDPushSample" requires a development team.
```

**解決策:**

1. Xcode > Targets > TDPushSample > Signing & Capabilities
2. Team: 開発チームを選択
3. NotificationServiceターゲットも同様に設定

### Android: Gradle エラー

**症状:**
```
Could not resolve com.google.firebase:firebase-bom:34.7.0
```

**解決策:**

```bash
cd android

# 1. Gradleキャッシュをクリア
./gradlew clean
./gradlew --stop
rm -rf ~/.gradle/caches/

# 2. 再ビルド
./gradlew assembleDebug

cd ..
```

### Android: google-services.jsonエラー

**症状:**
```
File google-services.json is missing.
```

**解決策:**

```bash
# テンプレートをコピー
cp android/app/google-services.json.example \
   android/app/google-services.json

# Firebase Consoleからダウンロードした実際のファイルに置き換え
```

## リッチメディア（画像）の問題

### iOS: 画像が表示されない

**解決策:**

1. **Notification Service Extensionの確認**
   ```bash
   # Xcodeで確認:
   # Targets に "NotificationService" が存在するか
   ```

2. **画像URLの確認**
   ```bash
   # HTTPSか確認（HTTPは不可）
   curl -I https://picsum.photos/400/300
   ```

3. **ペイロードの確認**
   ```json
   {
     "aps": {
       "mutable-content": 1  // 必須
     },
     "image": "https://..."
   }
   ```

### Android: 画像が表示されない

**解決策:**

1. **インターネット権限の確認**
   ```xml
   <!-- AndroidManifest.xml -->
   <uses-permission android:name="android.permission.INTERNET" />
   ```

2. **画像URLの確認**
   ```bash
   curl -I https://picsum.photos/400/300
   # HTTP 200 が返ってくるか確認
   ```

## ログ収集

### iOS

```bash
# Xcodeコンソールのログをファイルに保存
# デバイスを接続してアプリを実行
# Xcode > Window > Devices and Simulators > View Device Logs
```

### Android

```bash
# logcatをファイルに保存
adb logcat -d > logcat.txt

# フィルタリング
adb logcat -d | grep -E "FCM|PushEvent|Treasure" > filtered_log.txt
```

## サポート

上記の方法で解決しない場合は、以下の情報を含めてTreasure Dataサポートにお問い合わせください：

- プラットフォーム（iOS/Android）とバージョン
- エラーメッセージ全文
- 関連するログ
- 実行した手順
- 期待される動作と実際の動作

---

**参考資料:**
- [Firebase Cloud Messaging Troubleshooting](https://firebase.google.com/docs/cloud-messaging/troubleshooting)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [Treasure Data API Documentation](https://api-docs.treasuredata.com/)
