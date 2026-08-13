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

SimpleKeys requests Full Access solely to read your preferences via a shared App Group.

- **No data collection** — your keystrokes never leave your device.
- **No clipboard monitoring** — your copied data stays yours.
- **No ads, no analytics** — nothing is tracked.
- **Fully open source** — audit the code yourself.

> The companion app makes a single HTTPS request to GitHub to check for updates. The keyboard extension itself performs no network access.

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
