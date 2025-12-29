---
layout: default
title: Treasure Data Engage Push Notification Sample - Documentation
---

# Treasure Data Engage Push Notification Sample

Documentation for the iOS/Android push notification sample application.

## 📚 Documentation

### Getting Started

- [Setup Guide](SETUP.md) / [セットアップガイド](SETUP_ja.md)
  - Complete setup instructions for iOS and Android
  - Firebase and Treasure Data configuration

- [Testing Guide](TESTING.md) / [テストガイド](TESTING_ja.md)
  - How to test push notifications
  - Event tracking verification

### Implementation Guides

- [Link Implementation Summary](LINK_IMPLEMENTATION_SUMMARY.md) / [Link実装サマリー](LINK_IMPLEMENTATION_SUMMARY_ja.md)
  - Secure link handling (deep links and web links)
  - Domain/host allowlist configuration
  - Event tracking (link_arrive, link_fail)

### Reference

- [API Reference](API_REFERENCE.md) / [APIリファレンス](API_REFERENCE_ja.md)
  - Treasure Data Data Ingestion API
  - Request/response formats
  - Error handling

- [Security Guide](SECURITY.md) / [セキュリティガイド](SECURITY_ja.md)
  - API key management
  - Build-time injection
  - Best practices

### Troubleshooting

- [Troubleshooting Guide](TROUBLESHOOTING.md) / [トラブルシューティング](TROUBLESHOOTING_ja.md)
  - Common issues and solutions
  - Platform-specific problems
  - Debugging tips

## 🚀 Quick Links

- [Main README](../README.md) / [メインREADME](../README_ja.md)
- [GitHub Repository](https://github.com/treasure-data/engage-push-notification-sample)
- [Treasure Data Documentation](https://docs.treasuredata.com/)

## 📱 Platform Support

- **iOS**: 13.0+
- **Android**: 8.0+ (API 26)

## ✨ Features

- FCM token acquisition and registration
- Push notification reception and display
- Rich media notifications
- Deep link support
- Web link support with Chrome Custom Tabs/Safari
- Secure link handling (domain/host allowlist)
- Comprehensive event tracking
- Offline-ready event queue
- Automatic upload to Treasure Data

## 📄 License

This sample code is provided under the MIT License.

---

**Note**: This documentation is available in both English and Japanese. Click the links above to access the version you prefer.
