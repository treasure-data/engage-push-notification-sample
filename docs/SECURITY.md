# Security Guide

This document explains how to securely manage sensitive information such as API keys.

## Android: Build-Time API Key Injection

### Overview

The Android app does not embed API keys directly in source code. Instead, it stores them in a `local.properties` file and injects them at build time.

### Benefits

1. ✅ **Prevents Git commits**: `local.properties` is included in `.gitignore`
2. ✅ **Suitable for team development**: Each developer can use their own keys
3. ✅ **Easy CI/CD integration**: Generate local.properties from environment variables
4. ✅ **Multi-environment support**: Use different keys for dev/staging/production

### Implementation

#### 1. Secrets Gradle Plugin

The project uses the [Secrets Gradle Plugin](https://github.com/google/secrets-gradle-plugin). This is an official Google plugin that automatically generates `BuildConfig` fields from `local.properties` values.

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

#### 2. local.properties Configuration

**android/local.properties:**
```properties
TD_WRITE_KEY=your_actual_api_key_here
TD_DATABASE=mobile
TD_TABLE=push_events
TD_ENDPOINT=https://us01.records.in.treasuredata.com
```

#### 3. Usage in Code

**android/app/src/main/java/com/treasuredata/pushsample/fcm/PushEventUploader.kt:**
```kotlin
import com.treasuredata.pushsample.BuildConfig

object PushEventUploader {
    // Retrieved from auto-generated BuildConfig fields at build time
    private val TD_WRITE_KEY = BuildConfig.TD_WRITE_KEY
    private val TD_DATABASE = BuildConfig.TD_DATABASE
    private val TD_TABLE = BuildConfig.TD_TABLE
    private val TD_ENDPOINT = BuildConfig.TD_ENDPOINT
}
```

### Build Process

```
local.properties
    ↓
Secrets Gradle Plugin
    ↓
BuildConfig.java/kt (auto-generated)
    ↓
Embedded in app binary
```

### CI/CD Environment Configuration

#### GitHub Actions Example

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

#### GitLab CI Example

```yaml
build:
  script:
    - echo "TD_WRITE_KEY=${TD_WRITE_KEY}" > android/local.properties
    - echo "TD_DATABASE=mobile" >> android/local.properties
    - echo "TD_TABLE=push_events" >> android/local.properties
    - echo "TD_ENDPOINT=${TD_ENDPOINT}" >> android/local.properties
    - cd android && ./gradlew assembleRelease
```

### Debugging and Troubleshooting

#### If BuildConfig is Not Generated

```bash
# 1. Clean build
cd android
./gradlew clean

# 2. Force BuildConfig generation
./gradlew assembleDebug

# 3. Check generated file
ls -la app/build/generated/source/buildConfig/debug/com/treasuredata/pushsample/BuildConfig.kt
```

#### If local.properties is Not Loaded

1. Verify file name is correct (`local.properties`)
2. Verify file location is correct (`android/local.properties`)
3. Verify key names are correct (including case)

#### Build Errors

**Error:** `Unresolved reference: TD_WRITE_KEY`

**Cause:** `local.properties` does not exist or values are not set

**Solution:**
```bash
cd android
cp local.properties.example local.properties
# Edit local.properties and set actual values
```

### Production Environment Recommendations

1. **Environment-Specific Configuration**
   ```properties
   # local.properties (development)
   TD_WRITE_KEY=dev_key_xxxxx
   TD_ENDPOINT=https://us01.records.in.treasuredata.com

   # Inject from environment variables for release builds
   # export TD_WRITE_KEY=prod_key_xxxxx
   # export TD_ENDPOINT=https://us01.records.in.treasuredata.com
   ```

2. **ProGuard Configuration**

   For production builds, use ProGuard to prevent easy extraction of API keys from the APK:

   **android/app/proguard-rules.pro:**
   ```proguard
   # BuildConfig obfuscation
   -keepclassmembers class com.treasuredata.pushsample.BuildConfig {
       *;
   }
   ```

3. **Server-Side Proxy Usage**

   The most secure approach is to store API keys in a server-side proxy API instead of in the app:

   ```
   [Mobile App] → [Your API Server] → [Treasure Data]
                       ↑
                  API Key managed here
   ```

## iOS: Secure Configuration (Reference)

A similar approach is possible for iOS:

### Method 1: xcconfig files

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

### Method 2: Info.plist and Environment Variables

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

## Best Practices

1. ✅ **Never commit API keys to Git**
2. ✅ **Use Write-only keys** (Do not grant Read permission)
3. ✅ **Use different keys for dev/production**
4. ✅ **Rotate keys regularly**
5. ✅ **Use encryption tools for team key sharing** (1Password, Vault, etc.)
6. ✅ **Use Secrets features in CI/CD**
7. ✅ **Consider server-side proxy for production**

## Security Checklist

- [ ] `local.properties` is included in `.gitignore`
- [ ] No API keys are hardcoded in source code
- [ ] Using Write-only API key
- [ ] ProGuard is enabled for production builds
- [ ] Using Secrets in CI/CD
- [ ] Established encrypted key sharing method within team

## References

- [Secrets Gradle Plugin](https://github.com/google/secrets-gradle-plugin)
- [Android Security Best Practices](https://developer.android.com/topic/security/best-practices)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
