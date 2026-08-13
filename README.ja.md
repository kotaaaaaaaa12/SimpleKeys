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

余計な機能や広告だらけのキーボードアプリにうんざりしていませんか？ **SimpleKeys** はゼロから作られたクリーンなオープンソースキーボードです。目的はただ一つ：**快適にタイピングすること。**

<table>
<tr>
<td width="50%">

### 🎯 SimpleKeys でできること
- ✅ 高速でレスポンシブなタイピング
- ✅ 複数の入力モード
- ✅ ダークモード対応
- ✅ ネットワークアクセスなし
- ✅ オープンソース

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

モードボタンをタップするだけで切り替え可能。

| モード | ボタン | 説明 |
|:-------|:------:|:-----|
| **英語 QWERTY** | `🌐` | Shift対応の標準英語キーボード |
| **ローマ字 QWERTY** | `🌐` | ローマ字入力 → リアルタイムでひらがなに自動変換 |
| **フリック入力** | `🌐` | スワイプで文字を選択する日本語入力 |

### 🔄 モード切替

- 地球儀アイコン（🌐）をタップして、有効な入力モード（フリック、QWERTY英語、QWERTYローマ字）を素早く切り替えます。
- アプリ本体の設定画面から、使いたいモードだけをON/OFFカスタマイズできます！

---

## 🧩 機能一覧

<table>
<tr>
<td>

#### ⌨️ QWERTY キーボード
- フルQWERTYレイアウト
- Shiftキー（大文字/小文字切替）
- アルファベットの長押しによる特殊文字（アクセント記号等）入力
- バックスペース & リターン
- 🌐 キーボード切替
- キー押下アニメーション

</td>
<td>

#### 🇯🇵 日本語入力
- ローマ字→ひらがな変換
- 拗音（きゃ、しゅ 等）
- 促音（っ）自動検出
- 子音前のn → ん 変換
- 濁点サイクル（か→が→か）

</td>
<td>

#### 📱 フリック入力
- 方向スワイプ入力
- ポップアッププレビュー
- 濁点 / 半濁点 / 小文字
- 句読点行
- iOS ネイティブな操作感

</td>
</tr>
</table>

### 🌙 外観

**ライトモード** と **ダークモード** に自動対応。角丸、微細なシャドウ、適切なスペーシングでiOS標準に近いキースタイルを実現。

---

## 📦 インストール方法

### 方法 1: ソースからビルド（Xcode）

```bash
git clone https://github.com/kotaaaaaaaa12/SimpleKeys.git
cd SimpleKeys
open SimpleKeys.xcodeproj
```

1. Xcode で **Signing Team** を設定
2. 実機にビルド & 実行
3. キーボードを有効化（下記参照）

### 方法 2: SideStore / AltStore

1. **Actions** タブを開く
2. 最新のワークフロー（緑色のチェックマーク）をクリック
3. ページ下部の **Artifacts** から IPA をダウンロード
4. SideStore / AltStore でインストール

### ⚙️ キーボードの有効化

```
設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加 → SimpleKeys
```

**重要**: **「フルアクセスを許可」** をオンにしてください！これはメインアプリで設定した内容（使いたい入力モードなど）をキーボードと同期するためにのみ使用されます。

---

## 🏗️ プロジェクト構成

```
SimpleKeys/
│
├── SimpleKeys/                        # コンテナアプリ
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── ViewController.swift           # セットアップ手順画面
│   └── Info.plist
│
├── KeyboardExtension/                 # キーボードエクステンション
│   ├── KeyboardViewController.swift   # メインコントローラ & モード切替
│   ├── RomajiConverter.swift          # ローマ字→かな変換エンジン
│   ├── FlickKeyboardView.swift        # フリック入力 UI & ジェスチャー
│   └── Info.plist
│
└── .github/workflows/
    └── build-ipa.yml                  # CI: ビルド + nightly pre-release
```

---

## 🗺️ ロードマップ

| 状態 | 機能 |
|:----:|:-----|
| ✅ | 英語 QWERTY キーボード |
| ✅ | 日本語ローマ字 QWERTY (自動かな変換) |
| ✅ | フリック入力 (マルチタッチ高速連打対応) |
| ✅ | 使いたいモードのカスタマイズ機能 |
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

SimpleKeys は設定の同期のために **「フルアクセスを許可」**（`RequestsOpenAccess = true`）を要求しますが、プライバシーは完全に守られます！

なぜフルアクセスが必要なのか：
- Appleはキーボードを本体アプリから厳格に分離しています。ユーザーがアプリ本体で設定した「有効にする入力モード」等の設定をキーボード側で読み込む（App Groupを通じた共有）ために、システム上フルアクセスが必要となります。

私たちが**絶対にしない**こと：
- 🚫 **ネットワークアクセスなし** — インターネットに接続するためのコードは一切含まれていません。
- 🚫 **データ収集なし** — 入力データがデバイスの外に出ることは絶対にありません。
- 🚫 **クリップボード監視なし** — コピーしたデータは安全です。
- ✅ **完全オフライン** — すべての処理はデバイス上で完結します。

---

## 🤝 コントリビュート

貢献大歓迎です！

- 🐛 バグ報告は [Issues](https://github.com/kotaaaaaaaa12/SimpleKeys/issues) へ
- 💡 機能提案も歓迎
- 🔧 プルリクエストもお気軽に

---

## 📄 ライセンス

このプロジェクトは **MIT License** のもとで公開されています。

---

<div align="center">

**ただタイピングしたい人のために、❤️ を込めて作りました。**

<sub>SimpleKeys は Apple Inc. とは関係ありません。</sub>

</div>
