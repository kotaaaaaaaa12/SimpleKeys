<div align="center">

# ⌨️ SimpleKeys

**軽量でオープンソースな iOS キーボード — プライバシーを大切にする人のために。**

広告なし。追跡なし。ただの、ちゃんと使えるキーボード。

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/kotaaaaaaaa12/SimpleKeys/releases/tag/nightly)

<br>

日本語 · **[English](README.md)**

</div>

---

## ✨ 機能 (Features)

- **オフライン漢字変換:** オープンソースのSKK辞書（約13万語）を搭載し、完全オフラインで「ひらがな → 漢字」変換が可能です。ネットワーク通信は一切発生しません。
- **プライバシー最優先:** 入力した文字がデバイスの外部へ送信されることはありません。
- **QWERTY ＆ フリック入力:** ローマ字入力（QWERTY）とフリック入力の両方に対応しています。
- **高度な着せ替えテーマ機能:** 直感的なアプリ内エディタで、キーボードの見た目を完全にカスタマイズできます。
  - **スタイルと形状:** 標準、磨りガラス、フラット、クリアガラスなどのスタイルから選択可能。キーの形状（角丸、楕円、四角）も自由に設定できます。
  - **ライブプレビュー:** 編集画面で、実際のキーボード（QWERTY / フリック）と全く同じ比率・デザインのプレビューをリアルタイムで確認できます。
  - **自由なカラーカスタマイズ:** Apple純正のカラーピッカーを使用して、文字色、背景色、枠線の色（透明度含む）を自由に指定可能です。
- **App Group 同期:** サイドロード（AltStore/SideStore）環境でも動的にApp Group IDを解決し、作成したカスタムテーマや設定をキーボード本体へ完璧に同期します。

---

## 📦 インストール

### ソースからビルドする場合

```bash
git clone https://github.com/kotaaaaaaaa12/SimpleKeys.git
cd SimpleKeys
open SimpleKeys.xcodeproj
```

1. Xcode で **Signing Team** を設定
2. 実機に向けてビルド＆実行
3. キーボードを有効化（下記参照）

### SideStore / AltStore を使う場合

GitHub Actions が push のたびに未署名の IPA を自動ビルドします。

1. GitHub の **Actions** タブ → 最新のワークフローを開く
2. **Artifacts** から IPA をダウンロード（または [Releases](https://github.com/kotaaaaaaaa12/SimpleKeys/releases) から）
3. SideStore / AltStore でインストール

### キーボードの有効化

```
設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加 → SimpleKeys
```

> **補足:** アプリ側で作成したテーマや設定をキーボード側に反映させるために、**「フルアクセスを許可」** をオンにしてください。

---

## 🔒 プライバシー

フルアクセスは、共有 App Group を通じてアプリの設定を読み込むためだけに使っています。

- **データ収集なし** — 入力内容がデバイスの外に出ることはありません。
- **クリップボード監視なし** — コピーしたデータには触れません。
- **広告・解析なし** — 何も追跡しません。
- **完全オープンソース** — コードはすべて公開済み。自分の目で確認できます。

> 設定アプリはアップデート確認のために GitHub への HTTPS リクエストを1回だけ行います。キーボード本体は一切通信を行いません。

---

## 🤝 コントリビュート

- 🐛 バグを見つけたら → [Issue を作成](https://github.com/kotaaaaaaaa12/SimpleKeys/issues)
- 💡 アイデアがあれば → 機能提案を投稿
- 🔧 一緒に作りたければ → Pull Request を送ってください

---

## 📄 ライセンス

MIT License — 詳細は [LICENSE](LICENSE) をご覧ください。

---

<div align="center">

**ただタイピングしたい人のために、❤️ を込めて。**

<sub>SimpleKeys は Apple Inc. とは関係ありません。</sub>

</div>
