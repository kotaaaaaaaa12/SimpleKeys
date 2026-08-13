<div align="center">

# ⌨️ SimpleKeys

### A lightweight, privacy-first custom keyboard for iOS

**No ads. No tracking. No bloat. Just typing.**

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/kotaaaaaaaa12/SimpleKeys/releases/tag/nightly)

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

Switch between modes seamlessly using the built-in mode buttons.

| Mode | Button | Description |
|:-----|:------:|:------------|
| **English QWERTY** | `🌐` | Standard English keyboard with Shift support |
| **Romaji QWERTY** | `🌐` | Romaji input → Real-time auto-conversion to Hiragana |
| **Flick Kana** | `🌐` / `あ` | Japanese flick-style input |
| **Flick Alphabet** | `あいう` | Alphabet flick-style input with sub-labels |
| **Flick Numbers** | `☆123` | Numbers and symbols flick-style input |

### 🔄 Mode Cycling

- Tap the Globe icon (🌐) to instantly toggle between your active modes (e.g. QWERTY English, QWERTY Romaji, Flick Kana).
- You can fully customize which input modes are enabled/disabled via the main SimpleKeys app settings!
- Tap the `あいう` or `☆123` keys within Flick mode to switch to Alphabet or Number layouts.

---

## 🧩 Features

<table>
<tr>
<td width="50%" valign="top">

#### ⌨️ QWERTY Keyboard
- Full QWERTY layout
- English & Japanese Romaji support
- Real-time Hiragana conversion
- Shift key (uppercase toggle)
- Backspace & Return
- Mode toggle button (Globe)
- Press animation feedback

</td>
<td width="50%" valign="top">

#### 📱 Flick Keyboard
- Directional swipe input (Kana, ABC, 123)
- Multi-touch support for fast typing
- Clean and native-like hint labels
- Auto-capitalization for Alphabet
- Dakuten / Handakuten / Small character toggles

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

The GitHub Action (`build-unsigned-ipa.yml`) runs automatically on every push!

1. Go to the **Actions** tab on GitHub.
2. Click the latest workflow run.
3. Download the compiled IPA from the **Artifacts** section at the bottom (or from Releases if published).
4. Install via SideStore / AltStore.

### ⚙️ Enable the Keyboard

```
Settings → General → Keyboard → Keyboards → Add New Keyboard → SimpleKeys
```

**Important**: Turn on **"Allow Full Access"**! This is required to sync your settings (like QWERTY vs Flick preference) between the main app and the keyboard extension via App Groups.

---

## 🗺️ Roadmap

| Status | Feature |
|:------:|:--------|
| ✅ | English QWERTY keyboard |
| ✅ | Japanese Romaji QWERTY (auto-conversion) |
| ✅ | Flick input (Kana, ABC, 123) |
| ✅ | Multi-touch & fast typing |
| ✅ | Customizable active input modes |
| ✅ | Dark mode |
| ✅ | Automatic CI builds (GitHub Actions) |
| 🔲 | Kanji conversion (predictive) |
| 🔲 | Custom themes |
| 🔲 | User dictionary |
| 🔲 | Emoji panel |
| 🔲 | Haptic feedback |

---

## 🔒 Privacy

SimpleKeys requires **"Allow Full Access"** (`RequestsOpenAccess = true`), but we respect your privacy!

Why we need Full Access:
- Apple strictly isolates keyboards from their container apps. Full Access allows the keyboard to read your settings (e.g., Default Mode) using a shared App Group.

What we **DON'T** do:
- 🚫 **No network access** — the keyboard has zero code to connect to the internet.
- 🚫 **No data collection** — nothing leaves your device.
- 🚫 **No clipboard tracking** — your copied data stays private.
- ✅ **Fully offline** — everything runs locally on your device.

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
