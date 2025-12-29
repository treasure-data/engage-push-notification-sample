# セキュリティガイド

このドキュメントでは、APIキーなどの機密情報を安全に管理する方法を説明します。

## Android: ビルド時のAPIキー注入

### 概要

AndroidアプリではAPI Keyをソースコードに直接埋め込まず、`local.properties`ファイルに保存し、ビルド時に注入する方法を採用しています。

### メリット

1. ✅ **Gitへのコミットを防止**: `local.properties`は`.gitignore`に含まれる
2. ✅ **チーム開発に適している**: 各開発者が独自のキーを使用可能
3. ✅ **CI/CD統合が容易**: 環境変数からlocal.propertiesを生成できる
4. ✅ **複数環境対応**: 開発/ステージング/本番で異なるキーを使用可能

### 実装方法

#### 1. Secrets Gradle Plugin

プロジェクトは[Secrets Gradle Plugin](https://github.com/google/secrets-gradle-plugin)を使用しています。これはGoogle公式のプラグインで、`local.properties`の値を自動的に`BuildConfig`フィールドとして生成します。

**android/build.gradle.kts:**
```kotlin
plugins {
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin") version "2.0.1" apply false
}
```

**android/app/build.gradle.kts:**
```kotlin
plugins {
    id("com.google.android.libraries.mapsplatform.secrets-gradle-plugin")
}

android {
    buildFeatures {
        buildConfig = true
    }
}
```

#### 2. local.properties設定

**android/local.properties:**
```properties
TD_WRITE_KEY=your_actual_api_key_here
TD_DATABASE=mobile
TD_TABLE=push_events
TD_ENDPOINT=https://us01.records.in.treasuredata.com
```

#### 3. コード内での使用

**android/app/src/main/java/com/treasuredata/pushsample/fcm/PushEventUploader.kt:**
```kotlin
import com.treasuredata.pushsample.BuildConfig

object PushEventUploader {
    // ビルド時に自動生成されるBuildConfigフィールドから取得
    private val TD_WRITE_KEY = BuildConfig.TD_WRITE_KEY
    private val TD_DATABASE = BuildConfig.TD_DATABASE
    private val TD_TABLE = BuildConfig.TD_TABLE
    private val TD_ENDPOINT = BuildConfig.TD_ENDPOINT
}
```

### ビルドプロセス

```
local.properties
    ↓
Secrets Gradle Plugin
    ↓
BuildConfig.java/kt (自動生成)
    ↓
アプリバイナリに埋め込み
```

### CI/CD環境での設定

#### GitHub Actions例

```yaml
- name: Create local.properties
  run: |
    echo "TD_WRITE_KEY=${{ secrets.TD_WRITE_KEY }}" > android/local.properties
    echo "TD_DATABASE=mobile" >> android/local.properties
    echo "TD_TABLE=push_events" >> android/local.properties
    echo "TD_ENDPOINT=https://us01.records.in.treasuredata.com" >> android/local.properties

- name: Build APK
  run: |
    cd android
    ./gradlew assembleRelease
```

#### GitLab CI例

```yaml
build:
  script:
    - echo "TD_WRITE_KEY=${TD_WRITE_KEY}" > android/local.properties
    - echo "TD_DATABASE=mobile" >> android/local.properties
    - echo "TD_TABLE=push_events" >> android/local.properties
    - echo "TD_ENDPOINT=${TD_ENDPOINT}" >> android/local.properties
    - cd android && ./gradlew assembleRelease
```

### デバッグとトラブルシューティング

#### BuildConfigが生成されない場合

```bash
# 1. クリーンビルド
cd android
./gradlew clean

# 2. BuildConfig生成を強制
./gradlew assembleDebug

# 3. 生成されたファイルを確認
ls -la app/build/generated/source/buildConfig/debug/com/treasuredata/pushsample/BuildConfig.kt
```

#### local.propertiesが読み込まれない場合

1. ファイル名が正しいか確認（`local.properties`）
2. ファイルの場所が正しいか確認（`android/local.properties`）
3. キー名が正しいか確認（大文字小文字を含む）

#### ビルド時のエラー

**エラー:** `Unresolved reference: TD_WRITE_KEY`

**原因:** `local.properties`が存在しないか、値が設定されていない

**解決策:**
```bash
cd android
cp local.properties.example local.properties
# local.propertiesを編集して実際の値を設定
```

### 本番環境での推奨事項

1. **環境別の設定**
   ```properties
   # local.properties (開発環境)
   TD_WRITE_KEY=dev_key_xxxxx
   TD_ENDPOINT=https://us01.records.in.treasuredata.com

   # リリースビルド時は環境変数から注入
   # export TD_WRITE_KEY=prod_key_xxxxx
   # export TD_ENDPOINT=https://us01.records.in.treasuredata.com
   ```

2. **ProGuard設定**

   本番ビルドでは、API KeyがAPKから簡単に抽出されないようにProGuardを使用してください：

   **android/app/proguard-rules.pro:**
   ```proguard
   # BuildConfig難読化
   -keepclassmembers class com.treasuredata.pushsample.BuildConfig {
       *;
   }
   ```

3. **サーバーサイドプロキシの使用**

   最もセキュアな方法は、API KeyをアプリではなくサーバーサイドのプロキシAPIに保管することです：

   ```
   [Mobile App] → [Your API Server] → [Treasure Data]
                       ↑
                  API Keyはここで管理
   ```

## iOS: セキュアな設定方法（参考）

iOSでも同様のアプローチが可能です：

### 方法1: xcconfig files

**Config/Debug.xcconfig:**
```
TD_WRITE_KEY = your_dev_key
TD_DATABASE = mobile
```

**Config/Release.xcconfig:**
```
TD_WRITE_KEY = your_prod_key
TD_DATABASE = mobile
```

### 方法2: Info.plistと環境変数

**Info.plist:**
```xml
<key>TDWriteKey</key>
<string>$(TD_WRITE_KEY)</string>
```

**Build Settings > User-Defined:**
```
TD_WRITE_KEY = ${TD_WRITE_KEY_ENV}
```

**Swift code:**
```swift
let tdWriteKey = Bundle.main.object(forInfoDictionaryKey: "TDWriteKey") as? String ?? ""
```

## ベストプラクティス

1. ✅ **API Keyは絶対にGitにコミットしない**
2. ✅ **Write-only Keyを使用する**（Read権限を与えない）
3. ✅ **開発/本番で異なるKeyを使用**
4. ✅ **定期的にKeyをローテーション**
5. ✅ **チーム内でKeyを共有する場合は暗号化ツールを使用**（1Password、Vault等）
6. ✅ **CI/CDではSecrets機能を使用**
7. ✅ **本番環境ではサーバーサイドプロキシの使用を検討**

## セキュリティチェックリスト

- [ ] `local.properties`が`.gitignore`に含まれている
- [ ] ソースコードにAPIキーがハードコードされていない
- [ ] Write-only API Keyを使用している
- [ ] 本番ビルドでProGuardを有効にしている
- [ ] CI/CDでSecretsを使用している
- [ ] チーム内で暗号化されたKey共有方法を確立している

## 参考資料

- [Secrets Gradle Plugin](https://github.com/google/secrets-gradle-plugin)
- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
