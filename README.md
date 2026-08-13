<div align="center">

# ⌨️ SimpleKeys

**A lightweight, open-source keyboard for iOS — built for people who value privacy.**

No ads. No tracking. No network access. Just a keyboard that works.

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/kotaaaaaaaa12/SimpleKeys/releases/tag/nightly)

<br>

🌐 **[日本語](README.ja.md)** · English

</div>

---

## 🔥 Featured

What makes SimpleKeys stand out from other keyboards:

### 🧠 Full Romaji Engine
Type `qa` and get `くぁ`. Type `kya` and get `きゃ`. Our built-in Romaji-to-Hiragana engine covers **every major input style** — Hepburn, Kunrei-shiki, Nihon-shiki, and more. No cloud lookups, no lag. Everything converts instantly, right on your device.

### 👆 Slide-to-Select Special Characters
Long-press any key on the QWERTY keyboard to reveal accented and special characters — then **slide your finger** to pick the one you want without lifting. Fast, fluid, no popups.

### 🔒 Truly Offline & Private
This isn't marketing talk. SimpleKeys contains **zero networking code**. There is literally no way for your keystrokes to leave your device. The source code is right here — verify it yourself.

### 🔄 SideStore / AltStore Ready
Designed with sideloading in mind. SimpleKeys **dynamically resolves App Group IDs** at runtime, so your settings sync correctly even on free developer accounts. No paid Apple Developer membership required.

### 🛠️ In-App Update Notifications
The app fetches a lightweight JSON from GitHub to check for new versions. If an update is available, you'll see a badge on the Updates tab — no App Store needed.

---

## 📦 Installation

### Build from Source

```bash
git clone https://github.com/kotaaaaaaaa12/SimpleKeys.git
cd SimpleKeys
open SimpleKeys.xcodeproj
```

1. Set your **Signing Team** in Xcode
2. Build & run on your device
3. Enable the keyboard (see below)

### SideStore / AltStore

GitHub Actions automatically builds an unsigned IPA on every push.

1. Go to the **Actions** tab → latest workflow run
2. Download the IPA from **Artifacts** (or from [Releases](https://github.com/kotaaaaaaaa12/SimpleKeys/releases))
3. Install via SideStore / AltStore

### Enable the Keyboard

```
Settings → General → Keyboard → Keyboards → Add New Keyboard → SimpleKeys
```

> **Note:** Turn on **"Allow Full Access"** to sync your preferences between the app and the keyboard extension via App Groups.

---

## 🔒 Privacy

SimpleKeys requests Full Access solely to read your preferences via a shared App Group. Here's what that means in practice:

- **No network access** — there is no networking code in this project.
- **No data collection** — nothing leaves your device. Ever.
- **No clipboard monitoring** — your copied data stays yours.
- **Fully open source** — audit the code yourself.

---

## 🤝 Contributing

- 🐛 Found a bug? [Open an issue](https://github.com/kotaaaaaaaa12/SimpleKeys/issues)
- 💡 Have an idea? Suggest a feature
- 🔧 Want to help? Pull requests are welcome

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Built with ❤️ for people who just want to type.**

<sub>SimpleKeys is not affiliated with Apple Inc.</sub>

</div>
