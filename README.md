# 🎹 SimpleKeys

**シンプルで使いやすい、日本語対応カスタムキーボードアプリ**

Simejiのような余計な機能がない、軽量でプライバシーを重視したiOS用キーボードです。

## ✨ 機能

### キーボードモード
| モード | 説明 |
|--------|------|
| 🔤 English QWERTY | 標準的な英語キーボード（Shift対応） |
| 🇯🇵 日本語ローマ字 | ローマ字入力 → ひらがな自動変換 |
| 📱 フリック入力 | iOS標準風フリック入力 |

### 対応機能
- ⬆️ Shiftキー（大文字/小文字切替）
- ⌫ バックスペース
- 🌐 キーボード切替（他のキーボードへ）
- 🔄 入力モード切替（EN → あ → flick）
- 🌙 ダークモード自動対応
- ✨ キー押下アニメーション
- 📝 ローマ字 → ひらがなリアルタイム変換
- 👆 フリックジェスチャー（上下左右）
- ゛ 濁点・半濁点・小文字変換サイクル

## 📱 対応環境

- iOS 15.0+
- iPhone / iPad

## 🚀 インストール方法

### Xcode から
1. `SimpleKeys.xcodeproj` を Xcode で開く
2. Signing & Capabilities で Team を設定
3. 実機にビルド & インストール

### SideStore / AltStore から
1. GitHub Actions の `Build SimpleKeys for SideStore` を実行
2. Artifacts から IPA をダウンロード
3. SideStore / AltStore でインストール

### キーボードの有効化
1. **設定** > **一般** > **キーボード**
2. **キーボード** > **新しいキーボードを追加**
3. **SimpleKeys** を選択

## 🏗️ プロジェクト構成

```
SimpleKeys/
├── SimpleKeys/                    # メインアプリ（設定画面）
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── ViewController.swift
│   └── Info.plist
├── KeyboardExtension/             # キーボード本体
│   ├── KeyboardViewController.swift   # メインコントローラ
│   ├── RomajiConverter.swift          # ローマ字→かな変換エンジン
│   ├── FlickKeyboardView.swift        # フリック入力UI
│   └── Info.plist
└── .github/workflows/
    └── build-ipa.yml              # unsigned IPA 自動ビルド
```

## 🗺️ ロードマップ

- [x] 英語QWERTYキーボード
- [x] 日本語ローマ字入力（ひらがな変換）
- [x] フリック入力
- [x] ダークモード対応
- [x] GitHub Actions CI
- [ ] 漢字変換（予測変換）
- [ ] テーマ・着せ替え機能
- [ ] 学習辞書
- [ ] 絵文字パネル
- [ ] カスタムフォント
- [ ] 触覚フィードバック

## 🔒 プライバシー

SimpleKeysは **RequestsOpenAccess = false** で動作します。
ネットワークアクセスやデータ収集は一切行いません。

## 📄 License

MIT License
