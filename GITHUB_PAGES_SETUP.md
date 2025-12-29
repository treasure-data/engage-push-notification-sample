# GitHub Pages セットアップガイド

このドキュメントでは、docsディレクトリをGitHub Pagesとして公開する方法を説明します。

## 📋 手順

### 1. ファイルをコミット・プッシュ

```bash
# 新しく作成したファイルを追加
git add docs/index.md docs/_config.yml GITHUB_PAGES_SETUP.md

# コミット
git commit -m "Add GitHub Pages configuration for documentation"

# プッシュ
git push origin main
```

### 2. GitHub Pages を有効化

1. GitHubリポジトリページを開く: https://github.com/treasure-data/engage-push-notification-sample

2. **Settings** タブをクリック

3. 左サイドバーの **Pages** をクリック

4. **Build and deployment** セクションで:
   - **Source**: `Deploy from a branch` を選択
   - **Branch**: `main` を選択
   - **Folder**: `/docs` を選択
   - **Save** ボタンをクリック

5. 数分待つとデプロイが完了します

### 3. 公開URLの確認

デプロイが完了すると、以下のURLでアクセス可能になります：

```
https://treasure-data.github.io/engage-push-notification-sample/
```

ページ上部に「Your site is live at ...」というメッセージが表示されます。

## 🎨 テーマのカスタマイズ

`docs/_config.yml` でテーマを変更できます：

```yaml
# 利用可能なテーマ
theme: jekyll-theme-cayman      # デフォルト（推奨）
# theme: jekyll-theme-minimal
# theme: jekyll-theme-slate
# theme: jekyll-theme-architect
# theme: jekyll-theme-tactile
# theme: jekyll-theme-dinky
# theme: jekyll-theme-merlot
```

テーマを変更したら、再度コミット・プッシュしてください。

## 📁 ドキュメント構成

公開されるページ：

- **トップページ**: `docs/index.md`
  - すべてのドキュメントへのリンク
  - 英語版と日本語版の両方

- **セットアップ**: `docs/SETUP.md` / `docs/SETUP_ja.md`
- **テスト**: `docs/TESTING.md` / `docs/TESTING_ja.md`
- **トラブルシューティング**: `docs/TROUBLESHOOTING.md` / `docs/TROUBLESHOOTING_ja.md`
- **セキュリティ**: `docs/SECURITY.md` / `docs/SECURITY_ja.md`
- **APIリファレンス**: `docs/API_REFERENCE.md` / `docs/API_REFERENCE_ja.md`
- **Link実装**: `docs/LINK_IMPLEMENTATION_SUMMARY.md` / `docs/LINK_IMPLEMENTATION_SUMMARY_ja.md`

## 🔧 ローカルでプレビュー（オプション）

GitHub Pagesをローカルで確認したい場合：

```bash
# Jekyllをインストール
gem install bundler jekyll

# Gemfileを作成
cd docs
cat > Gemfile <<EOF
source 'https://rubygems.org'
gem 'github-pages', group: :jekyll_plugins
EOF

# 依存関係をインストール
bundle install

# ローカルサーバーを起動
bundle exec jekyll serve

# ブラウザで開く
open http://localhost:4000/engage-push-notification-sample/
```

## ✅ 確認事項

- [ ] `docs/index.md` が作成されている
- [ ] `docs/_config.yml` が作成されている
- [ ] ファイルがmainブランチにプッシュされている
- [ ] GitHub Settings > Pages で設定が完了している
- [ ] デプロイが成功している（緑のチェックマーク）
- [ ] URLでアクセスできる

## 🐛 トラブルシューティング

### ページが404エラーになる

**原因**: デプロイに時間がかかっている、または設定が間違っている

**解決策**:
1. Settings > Pages で設定を確認
2. Actions タブでビルドステータスを確認
3. 5-10分待ってから再度アクセス

### スタイルが適用されない

**原因**: `_config.yml` の `baseurl` が間違っている

**解決策**:
```yaml
baseurl: "/engage-push-notification-sample"  # リポジトリ名と一致させる
```

### リンクが壊れている

**原因**: 相対パスが間違っている

**解決策**:
- Markdownファイル内のリンクは相対パスで記述（例: `[Link](SETUP.md)`）
- `_config.yml` で `jekyll-relative-links` プラグインを有効化

## 📚 参考資料

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Jekyll Documentation](https://jekyllrb.com/docs/)
- [GitHub Pages Themes](https://pages.github.com/themes/)

## 🎉 完了後

GitHub Pagesが公開されたら、メインREADMEに公開URLを追加することをおすすめします：

```markdown
## 📖 Documentation

Full documentation is available at: https://treasure-data.github.io/engage-push-notification-sample/
```
