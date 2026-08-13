<div align="center">

# ⌨️ SimpleKeys

**軽量でオープンソースな iOS キーボード — プライバシーを大切にする人のために。**

広告なし。追跡なし。通信なし。ただの、ちゃんと使えるキーボード。

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/kotaaaaaaaa12/SimpleKeys/releases/tag/nightly)

<br>

日本語 · **[English](README.md)**

</div>

---

## 🔥 ここがすごい

SimpleKeys が他のキーボードと一味違うポイント：

### 🧠 あらゆるローマ字入力に対応
`qa` → `くぁ`、`kya` → `きゃ`。内蔵のローマ字変換エンジンは、ヘボン式・訓令式・日本式など**主要なローマ字入力方式をすべてカバー**。クラウドへの問い合わせも遅延もなく、すべてデバイス上で瞬時に変換します。

### 👆 スライドで特殊文字をサッと入力
QWERTY キーボードのキーを長押しすると、アクセント付き文字や特殊文字が表示されます。そのまま**指をスライドするだけ**で、指を離さず選択できます。ポップアップなし、ストレスなし。

### 🔒 本当の意味でオフライン＆プライベート
売り文句じゃありません。SimpleKeys には**通信用のコードが一切入っていません**。あなたの入力がデバイスの外に出る手段は、物理的に存在しません。ソースコードはすべて公開しているので、自分の目で確かめてください。

### 🔄 SideStore / AltStore にも対応
サイドロードを前提に設計しています。SimpleKeys は**実行時に App Group ID を自動で取得する**ため、無料の Apple ID でも設定の同期が正しく動作します。有料の Apple Developer アカウントは不要です。

### 🛠️ アプリ内でアップデート通知
GitHub 上の軽量な JSON を読み取って新しいバージョンをチェック。更新があれば「お知らせ」タブにバッジが表示されます。App Store に依存しないアップデート通知です。

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

> **補足:** アプリ本体での設定をキーボード側に反映させるために、**「フルアクセスを許可」** をオンにしてください。

---

## 🔒 プライバシー

フルアクセスは、共有 App Group を通じてアプリの設定を読み込むためだけに使っています。具体的には：

- **通信コードなし** — このプロジェクトにはネットワーク通信のコードが存在しません。
- **データ収集なし** — 入力内容がデバイスの外に出ることは一切ありません。
- **クリップボード監視なし** — コピーしたデータには触れません。
- **完全オープンソース** — コードはすべて公開済み。自分の目で確認できます。

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
