# Treasure Data API リファレンス

このドキュメントでは、サンプルアプリが使用するTreasure Data Data Ingestion APIの詳細を説明します。

## Data Ingestion API

### エンドポイント

リージョン別のベースURL:

| リージョン | ベースURL |
|-----------|----------|
| US01 | `https://us01.records.in.treasuredata.com` |
| Tokyo (AP01) | `https://ap01.records.in.treasuredata.com` |
| EU01 | `https://eu01.records.in.treasuredata.com` |
| Korea (AP02) | `https://ap02.records.in.treasuredata.com` |
| AP03 | `https://ap03.records.in.treasuredata.com` |

### リクエストURL

```
POST https://{endpoint}/{database_name}/{table_name}
```

例: `https://us01.records.in.treasuredata.com/mobile/push_events`

### HTTPヘッダー

#### 必須ヘッダー

1. **Authorization** (認証)
   ```
   Authorization: TD1 {your_api_key}
   ```

   例:
   ```
   Authorization: TD1 1/123456789abcdef0123456789abcdef012345678
   ```

2. **Content-Type** (コンテンツタイプ)

   - **単一レコード送信の場合:**
     ```
     Content-Type: application/vnd.treasuredata.v1.single+json
     ```

   - **複数レコード送信の場合:**
     ```
     Content-Type: application/vnd.treasuredata.v1+json
     ```

### リクエストボディ

#### 単一レコードの場合

```json
{
  "type": "delivery",
  "campaign_id": "test_campaign_001",
  "message_id": "test_message_001",
  "platform": "android",
  "fcm_token": "abc123...",
  "time": "2025-12-26T06:23:39Z"
}
```

#### 複数レコードの場合（サンプルアプリで使用）

```json
{
  "records": [
    {
      "type": "delivery",
      "campaign_id": "test_campaign_001",
      "message_id": "test_message_001",
      "platform": "android",
      "fcm_token": "abc123...",
      "time": "2025-12-26T06:23:39Z"
    },
    {
      "type": "open",
      "campaign_id": "test_campaign_001",
      "message_id": "test_message_001",
      "platform": "android",
      "fcm_token": "abc123...",
      "time": "2025-12-26T06:23:45Z"
    }
  ]
}
```

### レスポンス

#### 成功時 (200 OK)

```json
{
  "status": "ok"
}
```

#### エラー時

**401 Unauthorized:**
```json
{
  "code": 401,
  "message": "Credentials are required to access this resource."
}
```

原因:
- APIキーが間違っている
- Authorizationヘッダーの形式が間違っている（`TD1`プレフィックスが必要）
- APIキーの権限が不足している

**404 Not Found:**
```json
{
  "code": 404,
  "message": "Database or table not found."
}
```

原因:
- データベースまたはテーブルが存在しない
- データベース/テーブル名のスペルミス

**400 Bad Request:**
```json
{
  "code": 400,
  "message": "Invalid request body."
}
```

原因:
- JSONフォーマットが無効
- Content-Typeヘッダーが間違っている
- `records`配列が欠落している（複数レコード送信時）

## 実装例

### Android (Kotlin)

```kotlin
val url = "$TD_ENDPOINT/$TD_DATABASE/$TD_TABLE"

val payload = JSONObject().apply {
    put("records", org.json.JSONArray(events))
}

val requestBody = payload.toString()
    .toRequestBody("application/vnd.treasuredata.v1+json".toMediaType())

val request = Request.Builder()
    .url(url)
    .post(requestBody)
    .addHeader("Authorization", "TD1 $TD_WRITE_KEY")
    .build()
```

### iOS (Swift)

```swift
let urlString = "\(tdEndpoint)/\(tdDatabase)/\(tdTable)"
guard let url = URL(string: urlString) else { return }

var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/vnd.treasuredata.v1+json",
                 forHTTPHeaderField: "Content-Type")
request.setValue("TD1 \(tdWriteKey)",
                 forHTTPHeaderField: "Authorization")

let payload: [String: Any] = ["records": events]
request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
```

## 旧PostbackAPIとの違い

| 項目 | Postback API (旧) | Data Ingestion API (新) |
|------|------------------|------------------------|
| エンドポイント | `https://in.treasuredata.com` | `https://us01.records.in.treasuredata.com` |
| パス | `/postback/v3/event/{db}/{table}` | `/{db}/{table}` |
| 認証ヘッダー | `X-TD-Write-Key: {key}` | `Authorization: TD1 {key}` |
| Content-Type | `application/json` | `application/vnd.treasuredata.v1+json` |
| ボディ形式 | Newline-delimited JSON | `{"records": [...]}` |

## トラブルシューティング

### 401エラーが発生する

1. **APIキーを確認**
   ```bash
   # Android
   cat android/local.properties | grep TD_WRITE_KEY

   # iOS
   grep tdWriteKey ios/TDPushSample/Models/PushEventUploader.swift
   ```

2. **Authorizationヘッダーの形式を確認**

   ✅ 正しい:
   ```
   Authorization: TD1 1/abcdef...
   ```

   ❌ 間違い:
   ```
   X-TD-Write-Key: 1/abcdef...
   Authorization: abcdef...
   ```

3. **APIキーの権限を確認**
   - Treasure Data Console > Settings > API Keys
   - Write権限があるか確認

### ログでリクエスト内容を確認

**Android:**
```bash
adb logcat | grep "Treasure Data"
```

**iOS:**
```
# Xcodeコンソールで確認
📡 Sending 5 events to Treasure Data
URL: https://us01.records.in.treasuredata.com/mobile/push_events
📊 HTTP Status Code: 200
```

## 参考資料

- [Importing Table Records Using the Data Ingestion API](https://docs.treasuredata.com/display/public/PD/Importing+Table+Records+Using+the+Data+Ingestion+API)
- [Treasure Data API Documentation](https://api-docs.treasuredata.com/)

## よくある質問

### Q: どのAPIキーを使用すべきですか？

A: **Write-only API Key**を使用してください。Master API Keyは使用しないでください。

### Q: リージョンはどうやって確認しますか？

A: Treasure Data ConsoleのURLで確認できます：
- `https://console.treasuredata.com` → US01
- `https://console.ap01.treasuredata.com` → Tokyo (AP01)
- `https://console.eu01.treasuredata.com` → EU01

### Q: 最大何件のレコードを一度に送信できますか？

A: サンプルアプリでは500件をバッチサイズとしていますが、APIの公式な制限についてはTreasure Dataのドキュメントを確認してください。
