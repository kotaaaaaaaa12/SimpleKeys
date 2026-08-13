<div align="center">

# ⌨️ SimpleKeys

**A lightweight, open-source keyboard for iOS — built for people who value privacy.**

No ads. No tracking. Just a keyboard that works.

[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0%2B-007AFF?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5](https://img.shields.io/badge/Swift-5-F05138?style=for-the-badge&logo=swift&logoColor=white)](https://swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Build](https://img.shields.io/badge/Build-Nightly-blueviolet?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/kotaaaaaaaa12/SimpleKeys/releases/tag/nightly)

<br>

🌐 **[日本語](README.ja.md)** · English

</div>

---

## ✨ Features

- **Offline Kanji Conversion:** Powered by the open-source SKK dictionary (~130,000 entries), SimpleKeys converts Hiragana to Kanji completely offline. No network requests are made.
- **Gemini AI Conversion:** Connect your own Gemini API key to leverage advanced AI for context-aware Japanese input conversion (e.g., fixing typos, or converting casual text into polite business emails).
- **Privacy First:** Your keystrokes never leave your device (unless using the Gemini AI feature, which connects directly to Google).
- **QWERTY & Flick Input:** Supports both classic QWERTY Romaji input and Japanese Flick input.
- **Advanced Theme Engine:** Fully customize your keyboard's look and feel with an intuitive in-app editor.
  - **Styles & Shapes:** Choose between Standard, Frosted Glass, Flat, or Clear Glass key styles. Customize key shapes (Rounded, Oval, Rectangle).
  - **Flick Popup Customization:** Customize the background, text, highlight color, and shape (Rounded, Oval, Rectangle) of the flick hint popups.
  - **Custom Fonts:** Import and manage TrueType (`.ttf`)/OpenType (`.otf`) custom fonts directly from the app's font manager and apply them to your keyboard.
  - **Background Images:** Add custom images as your keyboard background. Includes an interactive editor to zoom, pan, and crop your images perfectly.
  - **Live Preview:** See exactly how your keyboard will look with an interactive, pixel-perfect layout preview (switchable between QWERTY and Flick).
  - **Deep Color Customization:** Use the native Apple Color Picker to select exact Hex/RGB colors for key backgrounds, text, and borders with full opacity control.
- **App Group Syncing:** Dynamically resolves App Group IDs to fully support sideloading (AltStore/SideStore) and syncs custom themes perfectly to the keyboard extension.

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

> **Note:** Turn on **"Allow Full Access"** to sync your preferences and custom themes between the app and the keyboard extension via App Groups.

---

## 🔒 Privacy

SimpleKeys requests Full Access solely to read your preferences via a shared App Group.

- **No data collection** — your keystrokes never leave your device.
- **No clipboard monitoring** — your copied data stays yours.
- **No ads, no analytics** — nothing is tracked.
- **Fully open source** — audit the code yourself.

> **About Gemini AI Conversion:** If you enable the Gemini API feature, your typing data is sent directly to Google's Gemini API for conversion processing. **We (the developers) do not collect, intercept, or extract any of your typing data or API keys.** Your API key is stored securely and locally on your device.

> The companion app makes a single HTTPS request to GitHub to check for updates. The keyboard extension itself performs no network access (unless Gemini AI is explicitly enabled by the user).

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

