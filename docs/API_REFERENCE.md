# Treasure Data API Reference

This document explains the details of the Treasure Data Data Ingestion API used by the sample app.

## Data Ingestion API

### Endpoints

Base URLs by region:

| Region | Base URL |
|--------|----------|
| US01 | `https://us01.records.in.treasuredata.com` |
| Tokyo (AP01) | `https://ap01.records.in.treasuredata.com` |
| EU01 | `https://eu01.records.in.treasuredata.com` |
| Korea (AP02) | `https://ap02.records.in.treasuredata.com` |
| AP03 | `https://ap03.records.in.treasuredata.com` |

### Request URL

```
POST https://{endpoint}/{database_name}/{table_name}
```

Example: `https://us01.records.in.treasuredata.com/mobile/push_events`

### HTTP Headers

#### Required Headers

1. **Authorization** (Authentication)
   ```
   Authorization: TD1 {your_api_key}
   ```

   Example:
   ```
   Authorization: TD1 1/123456789abcdef0123456789abcdef012345678
   ```

2. **Content-Type** (Content Type)

   - **For single record:**
     ```
     Content-Type: application/vnd.treasuredata.v1.single+json
     ```

   - **For multiple records:**
     ```
     Content-Type: application/vnd.treasuredata.v1+json
     ```

### Request Body

#### Single Record

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

#### Multiple Records (Used in Sample App)

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

### Response

#### Success (200 OK)

```json
{
  "status": "ok"
}
```

#### Errors

**401 Unauthorized:**
```json
{
  "code": 401,
  "message": "Credentials are required to access this resource."
}
```

Causes:
- Invalid API key
- Incorrect Authorization header format (`TD1` prefix required)
- Insufficient API key permissions

**404 Not Found:**
```json
{
  "code": 404,
  "message": "Database or table not found."
}
```

Causes:
- Database or table does not exist
- Typo in database/table name

**400 Bad Request:**
```json
{
  "code": 400,
  "message": "Invalid request body."
}
```

Causes:
- Invalid JSON format
- Incorrect Content-Type header
- Missing `records` array (for multiple records)

## Implementation Examples

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

## Differences from Legacy Postback API

| Item | Postback API (Legacy) | Data Ingestion API (Current) |
|------|----------------------|------------------------------|
| Endpoint | `https://in.treasuredata.com` | `https://us01.records.in.treasuredata.com` |
| Path | `/postback/v3/event/{db}/{table}` | `/{db}/{table}` |
| Auth Header | `X-TD-Write-Key: {key}` | `Authorization: TD1 {key}` |
| Content-Type | `application/json` | `application/vnd.treasuredata.v1+json` |
| Body Format | Newline-delimited JSON | `{"records": [...]}` |

## Troubleshooting

### Getting 401 Errors

1. **Check API Key**
   ```bash
   # Android
   cat android/local.properties | grep TD_WRITE_KEY

   # iOS
   grep tdWriteKey ios/TDPushSample/Models/PushEventUploader.swift
   ```

2. **Check Authorization Header Format**

   ✅ Correct:
   ```
   Authorization: TD1 1/abcdef...
   ```

   ❌ Incorrect:
   ```
   X-TD-Write-Key: 1/abcdef...
   Authorization: abcdef...
   ```

3. **Check API Key Permissions**
   - Treasure Data Console > Settings > API Keys
   - Verify Write permission is enabled

### Check Request in Logs

**Android:**
```bash
adb logcat | grep "Treasure Data"
```

**iOS:**
```
# Check in Xcode console
📡 Sending 5 events to Treasure Data
URL: https://us01.records.in.treasuredata.com/mobile/push_events
📊 HTTP Status Code: 200
```

## References

- [Importing Table Records Using the Data Ingestion API](https://docs.treasuredata.com/display/public/PD/Importing+Table+Records+Using+the+Data+Ingestion+API)
- [Treasure Data API Documentation](https://api-docs.treasuredata.com/)

## Frequently Asked Questions

### Q: Which API key should I use?

A: Use a **Write-only API Key**. Do not use the Master API Key.

### Q: How do I determine my region?

A: Check the Treasure Data Console URL:
- `https://console.treasuredata.com` → US01
- `https://console.ap01.treasuredata.com` → Tokyo (AP01)
- `https://console.eu01.treasuredata.com` → EU01

### Q: What is the maximum number of records I can send at once?

A: The sample app uses a batch size of 500 records, but please check Treasure Data documentation for official API limits.
