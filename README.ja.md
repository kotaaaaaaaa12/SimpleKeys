<div align="center">

# ⌨️ SimpleKeys

### 軽量・プライバシー重視の iOS カスタムキーボード

**広告なし。追跡なし。余計な機能なし。ただ、タイピング。**

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/kotaaaaaaaa12/SimpleKeys/releases/tag/nightly)

<br>

日本語 · **[English](README.md)**

<br>

<img src="https://img.shields.io/badge/QWERTY-英語-4A90D9?style=flat-square" alt="QWERTY">
<img src="https://img.shields.io/badge/ローマ字-日本語-E84855?style=flat-square" alt="Romaji">
<img src="https://img.shields.io/badge/フリック-入力-34C759?style=flat-square" alt="Flick">

</div>

---

## ✨ なぜ SimpleKeys？

余計な権限を要求したり、広告だらけだったり、使わない機能ばかりのキーボードアプリにうんざりしていませんか？ **SimpleKeys** はゼロから作られたクリーンなオープンソースキーボードです。目的はただ一つ：**快適にタイピングすること。**

<table>
<tr>
<td width="50%">

### 🎯 SimpleKeys でできること
- ✅ 高速でレスポンシブなタイピング
- ✅ 複数の入力モード
- ✅ ダークモード対応
- ✅ ネットワークアクセスなし
- ✅ オープンソースで透明性が高い

</td>
<td width="50%">

### 🚫 SimpleKeys がやらないこと
- ❌ データ収集
- ❌ 広告表示
- ❌ インターネット接続要求
- ❌ デバイスの動作を重くする
- ❌ タイピング履歴の販売

</td>
</tr>
</table>

---

## 🎹 入力モード

組み込まれたモードボタンを使って、シームレスにモードを切り替えることができます。

| モード | ボタン | 説明 |
|:-------|:------:|:-----|
| **英語 QWERTY** | `🌐` | Shift対応の標準的な英語キーボード |
| **ローマ字 QWERTY** | `🌐` | ローマ字入力 → リアルタイムでひらがなに自動変換 |
| **フリック（かな）** | `🌐` / `あ` | 日本語のフリック入力 |
| **フリック（英字）** | `あいう` | サブラベル付きのアルファベットフリック入力 |
| **フリック（数字）** | `☆123` | 数字と記号のフリック入力 |

### 🔄 モード切替

- 地球儀アイコン（🌐）をタップして、有効な入力モード（例: QWERTY英語、QWERTYローマ字、フリック入力）を瞬時に切り替えます。
- アプリ本体の設定画面から、有効化/無効化したいモードを自由にカスタマイズできます！
- フリック入力モード中に `あいう` や `☆123` キーをタップすると、英字や数字のレイアウトに切り替わります。

---

## 🧩 機能一覧

<table>
<tr>
<td width="50%" valign="top">

#### ⌨️ QWERTY キーボード
- フルQWERTYレイアウト
- Shiftキー機能（大文字/小文字切替）
- 長押しによる特殊文字・アクセント記号の入力
- バックスペース & リターン機能
- 🌐 ネイティブな次キーボードへの切り替え
- モード切替ボタン（地球儀）
- キー押下時のアニメーションフィードバック

</td>
<td width="50%" valign="top">

#### 📱 フリック入力
- 方向スワイプ入力（かな、ABC、123）
- マルチタッチの高速連打対応
- クリーンでネイティブライクなヒントラベル
- 英字入力時の自動大文字化（大文字/小文字トグル）
- 濁点 / 半濁点 / 小文字の切り替え

</td>
</tr>
</table>

### 🌙 外観

**ライトモード** と **ダークモード** に自動適応します。角丸、微細なシャドウ、適切なスペーシングなど、iOS標準に忠実なキースタイルを採用しています。

---

## 📦 インストール方法

### オプション 1: ソースからビルド (Xcode)

```bash
git clone https://github.com/kotaaaaaaaa12/SimpleKeys.git
cd SimpleKeys
open SimpleKeys.xcodeproj
```

1. Xcode で **Signing Team** を設定します。
2. 実機に向けてビルド＆実行します。
3. キーボードを有効化します（下記参照）。

### オプション 2: SideStore / AltStore

GitHub Actions (`build-unsigned-ipa.yml`) により、Push ごとに自動でビルドが行われます！

1. GitHub の **Actions** タブを開きます。
2. 最新のワークフロー実行（緑のチェックマーク）をクリックします。
3. ページ下部の **Artifacts** からビルド済みの IPA をダウンロードします（または Releases からダウンロード）。
4. SideStore / AltStore 経由でインストールします。

### ⚙️ キーボードの有効化

```
設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加 → SimpleKeys
```

**重要**: **「フルアクセスを許可」** をオンにしてください！これはメインアプリで設定した内容（QWERTYかフリックかの好みなど）を App Group 経由でキーボードエクステンションと同期するためにのみ必要です。

---

## 🗺️ ロードマップ

| 状態 | 機能 |
|:----:|:-----|
| ✅ | 英語 QWERTY キーボード |
| ✅ | 日本語ローマ字 QWERTY (自動かな変換) |
| ✅ | フリック入力 (かな、ABC、123) |
| ✅ | マルチタッチ & 高速タイピング対応 |
| ✅ | キーボードモードの切替/カスタマイズ機能 |
| ✅ | QWERTY 長押しでの特殊文字入力 (スライド選択対応) |
| ✅ | 数字 & 記号キーボード |
| ✅ | iOSネイティブなUIとSF Symbolsアイコン |
| ✅ | ダークモード |
| ✅ | 自動 CI ビルド (GitHub Actions) |
| 🔲 | 漢字変換（予測変換） |
| 🔲 | カスタムテーマ |
| 🔲 | ユーザー辞書 |
| 🔲 | 絵文字パネル |
| 🔲 | 触覚フィードバック |

---

## 🔒 プライバシー

SimpleKeys は **「フルアクセスを許可」** (`RequestsOpenAccess = true`) を要求しますが、あなたのプライバシーは完全に守られます！

なぜフルアクセスが必要なのか：
- Apple はコンテナアプリからキーボードを厳格に分離しています。ユーザーがアプリ本体で設定した「デフォルトモード」等の設定を、共有 App Group を使ってキーボード側で読み込むためにシステム上フルアクセスが必要となります。

私たちが**絶対にしない**こと：
- 🚫 **ネットワークアクセスなし** — インターネットに接続するためのコードは一切含まれていません。
- 🚫 **データ収集なし** — 入力データがデバイスの外に出ることは絶対にありません。
- 🚫 **クリップボード監視なし** — コピーしたデータは安全です。
- ✅ **完全オフライン** — すべての処理はデバイス上でローカルに完結します。

---

## 🤝 コントリビュート

貢献大歓迎です！お気軽にどうぞ：
- 🐛 バグ報告は [Issues](https://github.com/kotaaaaaaaa12/SimpleKeys/issues) へ
- 💡 機能提案
- 🔧 プルリクエスト (PR) の作成

---

## 📄 ライセンス

このプロジェクトは **MIT License** のもとで公開されています。詳細は [LICENSE](LICENSE) ファイルをご覧ください。

---

<div align="center">

**ただタイピングしたい人のために、❤️ を込めて作りました。**

<sub>SimpleKeys は Apple Inc. とは関係ありません。</sub>

</div>
