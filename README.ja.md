<div align="center">

# ⌨️ SimpleKeys

### 軽量・プライバシー重視の iOS カスタムキーボード

**広告なし。追跡なし。余計な機能なし。ただ、タイピング。**

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](.github/workflows/build-unsigned-ipa.yml)

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
| **英語 QWERTY** | `EN` | Shift対応の標準英語キーボード |
| **日本語ローマ字** | `あ` | ローマ字入力 → リアルタイムでひらがなに自動変換 |
| **フリック入力** | `flick` | スワイプで文字を選択する日本語入力 |

### 🔄 モード切替

```
EN  →  あ  →  flick  →  EN  → ...
```

---

## 🧩 機能一覧

<table>
<tr>
<td>

#### ⌨️ キーボード
- フルQWERTYレイアウト
- Shiftキー（大文字/小文字切替）
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

1. **Actions** タブ → **Build SimpleKeys for SideStore** を開く
2. **Run workflow** をクリック
3. 自動生成された **Release**（pre-release）から IPA をダウンロード
4. SideStore / AltStore でインストール

### ⚙️ キーボードの有効化

```
設定 → 一般 → キーボード → キーボード → 新しいキーボードを追加 → SimpleKeys
```

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
| ✅ | 日本語ローマ字 → ひらがな変換 |
| ✅ | フリック入力 |
| ✅ | ダークモード |
| ✅ | Nightly CI ビルド |
| 🔲 | 漢字変換（予測変換） |
| 🔲 | カスタムテーマ |
| 🔲 | ユーザー辞書 |
| 🔲 | 絵文字パネル |
| 🔲 | 触覚フィードバック |
| 🔲 | 数字 & 記号キーボード |

---

## 🔒 プライバシー

SimpleKeys は **`RequestsOpenAccess = false`** で動作します。

- 🚫 **ネットワークアクセスなし** — インターネットに接続しません
- 🚫 **データ収集なし** — 情報がデバイスの外に出ることはありません
- 🚫 **クリップボードアクセスなし** — コピーしたデータは安全です
- ✅ **完全オフライン** — すべてがデバイス上でローカルに動作します

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
