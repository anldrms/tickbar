<div align="center">

<img src="docs/assets/app-icon.png" width="116" height="116" alt="TickBar macOS App Icon" />

# TickBar

**Native macOS 27 Liquid Glass Menu Bar Stock Ticker & Floating Desktop Widget**

Stream real-time **Yahoo Finance** regular session, **Pre-Market (PM)**, and **After-Hours (AH)** quotes with **2026 official vector company logos**, intraday sparklines, and a fully customizable watchlist right in your macOS status bar.

[![macOS Universal](https://img.shields.io/badge/macOS-Universal%20Binary-000000?style=for-the-badge&logo=apple&logoColor=white)](https://tickbar.vercel.app/downloads/TickBar-macOS-Universal.dmg)
[![Design Language](https://img.shields.io/badge/UI-macOS%2027%20Liquid%20Glass-1d4ed8?style=for-the-badge)](https://tickbar.vercel.app)
[![Market Data](https://img.shields.io/badge/Yahoo%20Finance-24%2F5%20%2B%20After--Hours-22c55e?style=for-the-badge)](https://tickbar.vercel.app)
[![License: MIT](https://img.shields.io/badge/License-MIT-f59e0b?style=for-the-badge)](LICENSE)

<br />

<a href="https://tickbar.vercel.app/downloads/TickBar-macOS-Universal.dmg">
  <img src="docs/assets/btn-download-dmg.svg" height="48" alt="Download TickBar for macOS (.DMG)" />
</a>
&nbsp;&nbsp;
<a href="https://tickbar.vercel.app">
  <img src="docs/assets/btn-live-demo.svg" height="48" alt="Open Interactive Web Stage" />
</a>

<br /><br />

<img src="docs/assets/hero-macos27.png" width="100%" alt="TickBar macOS 27 Liquid Glass Menu Bar & Floating Desktop Widget Preview" />

</div>

---

## Designed Like a Native Apple Utility

TickBar is built from the ground up with **SwiftUI + AppKit** (`NSStatusItem`, `NSPopover`, `NSPanel`, and `NSVisualEffectView`) following the **macOS 27 Liquid Glass** design system. Every surface features translucent specular highlights, SF Pro & SF Mono tabular numerals, and sub-millisecond responsiveness in a binary under **1 MB**.

<p align="center">
  <img src="docs/assets/bento-features.png" width="100%" alt="TickBar Custom Watchlist, After-Hours Quotes, and 2026 Official Vector Logos" />
</p>

---

## Add, Remove & Customize Any Stock, ETF, or Crypto

You have complete control over your watchlist. TickBar is never locked to a static list of tickers:

| Action | How It Works in TickBar |
| :--- | :--- |
| **➕ Add Any Ticker** | Type **any valid Yahoo Finance symbol** (`NVDA`, `AAPL`, `TSLA`, `AMD`, `PLTR`, `FLY`, `RKLB`, `MSTR`, `SPY`, `QQQ`, `BTC-USD`, `ETH-USD`, or international equities) into the search bar and press **Return** or click **`+ Add`**. |
| **⚡ Quick-Add Chips** | One-click popular ticker pills (`+AMD`, `+SPY`, `+QQQ`, `+COIN`, `+RKLB`, `+HOOD`, `+BTC-USD`) appear below the search bar so you can populate your watchlist in a single tap. |
| **✖ Remove Any Ticker** | Click the inline **`×`** button on the right side of any row in the menu bar popover to immediately remove that symbol from your watchlist. |
| **📌 Pin to Menu Bar** | Click any stock row in the popover to pin that symbol and its live **After-Hours (`AH`) / Pre-Market (`PM`)** price directly to your top macOS status bar. |
| **⇄ Shuffle Popular Stocks** | Click **`⇄ Shuffle`** in the header to load a fresh random sample of 7 high-volume market movers from the 2026 flagship catalog. |

Your custom watchlist and preferences are automatically persisted in `UserDefaults` across restarts.

---

## 2026 Official Vector Company Logos

TickBar resolves high-contrast vector company emblems for your watchlist, including updated **2026 corporate identities** (such as Strategy `MSTR`, Firefly Aerospace `FLY`, Rocket Lab `RKLB`, Palantir `PLTR`, and Coinbase `COIN`):

<div align="center">

| | Ticker | Company | | Ticker | Company | | Ticker | Company | | Ticker | Company |
| :---: | :--- | :--- | :---: | :--- | :--- | :---: | :--- | :--- | :---: | :--- | :--- |
| <img src="docs/assets/logos/nvda.svg" width="28" height="28" /> | **`NVDA`** | NVIDIA Corp. | <img src="docs/assets/logos/aapl.svg" width="28" height="28" /> | **`AAPL`** | Apple Inc. | <img src="docs/assets/logos/tsla.svg" width="28" height="28" /> | **`TSLA`** | Tesla, Inc. | <img src="docs/assets/logos/msft.svg" width="28" height="28" /> | **`MSFT`** | Microsoft Corp. |
| <img src="docs/assets/logos/amzn.svg" width="28" height="28" /> | **`AMZN`** | Amazon.com | <img src="docs/assets/logos/meta.svg" width="28" height="28" /> | **`META`** | Meta Platforms | <img src="docs/assets/logos/googl.svg" width="28" height="28" /> | **`GOOGL`** | Alphabet Inc. | <img src="docs/assets/logos/pltr.svg" width="28" height="28" /> | **`PLTR`** | Palantir Tech |
| <img src="docs/assets/logos/amd.svg" width="28" height="28" /> | **`AMD`** | Adv. Micro Devices | <img src="docs/assets/logos/nflx.svg" width="28" height="28" /> | **`NFLX`** | Netflix, Inc. | <img src="docs/assets/logos/mstr.svg" width="28" height="28" /> | **`MSTR`** | Strategy Inc. | <img src="docs/assets/logos/coin.svg" width="28" height="28" /> | **`COIN`** | Coinbase Global |
| <img src="docs/assets/logos/spy.svg" width="28" height="28" /> | **`SPY`** | SPDR S&P 500 ETF | <img src="docs/assets/logos/qqq.svg" width="28" height="28" /> | **`QQQ`** | Invesco QQQ | <img src="docs/assets/logos/hood.svg" width="28" height="28" /> | **`HOOD`** | Robinhood Markets | <img src="docs/assets/logos/sofi.svg" width="28" height="28" /> | **`SOFI`** | SoFi Technologies |
| <img src="docs/assets/logos/rklb.svg" width="28" height="28" /> | **`RKLB`** | Rocket Lab USA | <img src="docs/assets/logos/fly.svg" width="28" height="28" /> | **`FLY`** | Firefly Aerospace | <img src="docs/assets/logos/asts.svg" width="28" height="28" /> | **`ASTS`** | AST SpaceMobile | <img src="docs/assets/logos/btc.svg" width="28" height="28" /> | **`BTC-USD`** | Bitcoin USD |

</div>

Any custom ticker added via the search bar automatically resolves its official icon or generates a colour-matched monogram badge.

---

## Extended Hours: Pre-Market (`PM`) & After-Hours (`AH`)

Markets move outside the 9:30 AM to 4:00 PM ET bell. TickBar queries Yahoo Finance with `includePrePost=true` to stream:
- **Regular Session Price & Percent Change** with a 30-point intraday vector sparkline.
- **After-Hours (`AH`) & Pre-Market (`PM`) Live Price & Delta** displayed both in the popover list and directly inside the top macOS Menu Bar pill (`NVDA $221.30 ▼3.16% · AH $221.36 ▲0.03%`).
- **24/7 Crypto Spot Streaming** (`BTC-USD`, `ETH-USD`, `SOL-USD`) alongside US & global equities.

---

## Installation

### Option 1: Direct Universal `.DMG` Installer (Recommended)

1. Download **[`TickBar-macOS-Universal.dmg`](https://tickbar.vercel.app/downloads/TickBar-macOS-Universal.dmg)**.
2. Open the `.dmg` image and drag **`TickBar.app`** into your **`/Applications`** folder.
3. Launch **TickBar** from Applications or Spotlight. It appears immediately in your top-right macOS Menu Bar.

### Option 2: Build from Source

Requires macOS 13.0+ and Xcode Command Line Tools (`swiftc`):

```bash
git clone https://github.com/anldrms/tickbar.git
cd tickbar
bash macos-app/build_dmg.sh
open public/downloads/TickBar-macOS-Universal.dmg
```

---

## Architecture

| Component | Path | Description |
| :--- | :--- | :--- |
| **macOS Native App** | [`macos-app/Sources/TickBar.swift`](macos-app/Sources/TickBar.swift) | Native SwiftUI + AppKit (`NSStatusItem`, `NSPopover`, `NSPanel`, `VisualEffectGlassView`) with Yahoo Finance `v8/finance/chart` (`includePrePost=true`) & `v7/finance/quote` live engine |
| **Universal DMG Builder** | [`macos-app/build_dmg.sh`](macos-app/build_dmg.sh) | Compiles `arm64` + `x86_64` universal binary (`lipo`), generates `.icns`, signs bundle, and packages `TickBar-macOS-Universal.dmg` |
| **Live Yahoo Finance API** | [`api/quotes.js`](api/quotes.js) | Vercel Serverless edge proxy returning real-time regular, Pre-Market (`PM`), and After-Hours (`AH`) quotes + intraday sparklines |
| **Interactive Web Stage** | [`public/index.html`](public/index.html) | Interactive macOS 27 Liquid Glass web showcase with live add/remove watchlist, shuffle, and extended-hours preview |

---

## License

Released under the [MIT License](LICENSE). Crafted by [@anldrms](https://github.com/anldrms).
