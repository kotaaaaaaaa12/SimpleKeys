<div align="center">

# ⌨️ SimpleKeys

### A lightweight, privacy-first custom keyboard for iOS

**No ads. No tracking. No bloat. Just typing.**

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](.github/workflows/build-ipa.yml)

<br>

🌐 **[日本語](README.ja.md)** · English

<br>

<img src="https://img.shields.io/badge/QWERTY-English-4A90D9?style=flat-square" alt="QWERTY">
<img src="https://img.shields.io/badge/ローマ字-Japanese-E84855?style=flat-square" alt="Romaji">
<img src="https://img.shields.io/badge/フリック-Flick-34C759?style=flat-square" alt="Flick">

</div>

---

## ✨ Why SimpleKeys?

Tired of bloated keyboard apps with invasive permissions, annoying ads, and features you never asked for? **SimpleKeys** is a clean, open-source keyboard built from scratch — designed to do one thing well: **let you type.**

<table>
<tr>
<td width="50%">

### 🎯 What SimpleKeys does
- ✅ Fast, responsive typing
- ✅ Multiple input modes
- ✅ Dark mode support
- ✅ Zero network access
- ✅ Open source & transparent

</td>
<td width="50%">

### 🚫 What SimpleKeys doesn't do
- ❌ Collect your data
- ❌ Show ads
- ❌ Require internet access
- ❌ Slow down your phone
- ❌ Sell your typing habits

</td>
</tr>
</table>

---

## 🎹 Input Modes

Switch between modes with a single tap on the mode button.

| Mode | Button | Description |
|:-----|:------:|:------------|
| **English QWERTY** | `EN` | Standard English keyboard with Shift support |
| **Japanese Romaji** | `あ` | Type romaji → auto-converts to hiragana in real-time |
| **Flick Input** | `flick` | Japanese flick-style input — swipe to select characters |

### 🔄 Mode Cycling

```
EN  →  あ  →  flick  →  EN  → ...
```

---

## 🧩 Features

<table>
<tr>
<td>

#### ⌨️ Keyboard
- Full QWERTY layout
- Shift key (uppercase toggle)
- Backspace & Return
- 🌐 Keyboard switcher
- Press animation feedback

</td>
<td>

#### 🇯🇵 Japanese
- Romaji → Hiragana engine
- Yōon (きゃ, しゅ, etc.)
- Sokuon (っ) auto-detection
- N-before-consonant → ん
- Dakuten cycle (か→が→か)

</td>
<td>

#### 📱 Flick
- Directional swipe input
- Popup character preview
- Dakuten / Handakuten / Small
- Punctuation row
- iOS-native feel

</td>
</tr>
</table>

### 🌙 Appearance

Automatically adapts to **Light** and **Dark** mode with iOS-accurate key styling — rounded corners, subtle shadows, and proper spacing.

---

## 📦 Installation

### Option 1: Build from Source (Xcode)

```bash
git clone https://github.com/kotaaaaaaaa12/SimpleKeys.git
cd SimpleKeys
open SimpleKeys.xcodeproj
```

1. Set your **Signing Team** in Xcode
2. Build & run on your device
3. Enable the keyboard (see below)

### Option 2: SideStore / AltStore

1. Go to **Actions** tab → **Build SimpleKeys for SideStore**
2. Click **Run workflow**
3. Download the IPA from the auto-generated **Release** (pre-release)
4. Install via SideStore / AltStore

### ⚙️ Enable the Keyboard

```
Settings → General → Keyboard → Keyboards → Add New Keyboard → SimpleKeys
```

---

## 🏗️ Architecture

```
SimpleKeys/
│
├── SimpleKeys/                        # Container App
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── ViewController.swift           # Setup instructions UI
│   └── Info.plist
│
├── KeyboardExtension/                 # Keyboard Extension
│   ├── KeyboardViewController.swift   # Main controller & mode switching
│   ├── RomajiConverter.swift          # Romaji → Kana conversion engine
│   ├── FlickKeyboardView.swift        # Flick input UI & gestures
│   └── Info.plist
│
└── .github/workflows/
    └── build-ipa.yml                  # CI: Build + nightly pre-release
```

---

## 🗺️ Roadmap

| Status | Feature |
|:------:|:--------|
| ✅ | English QWERTY keyboard |
| ✅ | Japanese Romaji → Hiragana |
| ✅ | Flick input |
| ✅ | Dark mode |
| ✅ | Nightly CI builds |
| 🔲 | Kanji conversion (predictive) |
| 🔲 | Custom themes |
| 🔲 | User dictionary |
| 🔲 | Emoji panel |
| 🔲 | Haptic feedback |
| 🔲 | Number & symbol keyboard |

---

## 🔒 Privacy

SimpleKeys operates with **`RequestsOpenAccess = false`**.

This means:
- 🚫 **No network access** — the keyboard cannot connect to the internet
- 🚫 **No data collection** — nothing leaves your device
- 🚫 **No clipboard access** — your copied data stays private
- ✅ **Fully offline** — everything runs locally on your device

---

## 🤝 Contributing

Contributions are welcome! Feel free to:
- 🐛 Report bugs via [Issues](https://github.com/kotaaaaaaaa12/SimpleKeys/issues)
- 💡 Suggest features
- 🔧 Submit pull requests

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ for people who just want to type.**

<sub>SimpleKeys is not affiliated with Apple Inc.</sub>

</div>
