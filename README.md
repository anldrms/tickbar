# TickBar

**A native macOS 27 Liquid Glass Menu Bar and floating desktop stock & crypto ticker with live Yahoo Finance regular + After-Hours (`AH`) & Pre-Market (`PM`) quotes, 2026 official vector logos, and intraday sparklines.**

TickBar pins live stock, ETF, and crypto prices directly to your macOS top Menu Bar and includes a detachable non-activating Liquid Glass desktop widget. Built natively in Swift, SwiftUI, and AppKit (`< 1 MB` macOS Universal binary) with zero Electron overhead and zero API keys required.

## Features

- **Regular + Extended-Hours (`AH` / `PM`) Live Feed**: Streams real-time regular session quotes alongside Pre-Market (`PM`) and After-Hours (`AH`) prices and percentage changes directly from Yahoo Finance (`includePrePost=true`).
- **macOS 27 Liquid Glass Design Language**: Crafted with native `NSVisualEffectView` translucent materials, specular inner rim highlights, concentric continuous squircles, and SF Pro / SF Mono typography.
- **2026 Official Vector Logos**: Resolves crisp 2026 official TradingView SVG vector company logos (`NVDA`, `AAPL`, `TSLA`, `MSFT`, `AMZN`, `META`, `GOOGL`, `PLTR`, `AMD`, `MSTR` Strategy Inc., `FLY` Firefly Aerospace, `RKLB`, `BTC-USD`, and any custom ticker).
- **Instant Add, Remove & Shuffle**: Add any stock, ETF, or crypto symbol via the search bar or quick-add chips, remove any ticker with `×`, or hit **Shuffle** to randomize from top market movers.
- **5-Minute Intraday Sparklines**: Renders smooth vector intraday curves and gradient fills.
- **Interactive Web Stage + Live Yahoo API**: Ships with an interactive `mkdir.directory`-inspired showcase and a Vercel serverless Yahoo Finance proxy (`/api/quotes`) that continuously streams live market and after-hours data.

## Quick Start

### Option 1: Install the Universal `.DMG`

1. Download [`TickBar-macOS-Universal.dmg`](https://tickbar.vercel.app/downloads/TickBar-macOS-Universal.dmg).
2. Open the disk image and drag **TickBar.app** into your **Applications** folder.
3. If macOS Gatekeeper prompts on first launch, clear the quarantine attribute and open:

```bash
xattr -cr /Applications/TickBar.app && open /Applications/TickBar.app
```

### Option 2: Build from Source

Requires macOS 13.0+ and Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/anldrms/tickbar.git
cd tickbar
bash macos-app/build_dmg.sh
```

This compiles both `arm64` and `x86_64` binaries, merges them via `lipo` into a macOS Universal `TickBar.app` bundle, signs the bundle, and packages `public/downloads/TickBar-macOS-Universal.dmg`.

## Managing Tickers

- **Add a Ticker**: Click TickBar in your macOS Menu Bar, type any Yahoo Finance symbol (e.g. `NVDA`, `PLTR`, `AMD`, `MSTR`, `FLY`, `BTC-USD`), and press `Return` or click `+ Add`.
- **Remove a Ticker**: Click the `×` button on the right side of any ticker row in the Menu Bar popover or floating desktop widget.
- **Shuffle Watchlist**: Click **Shuffle** in the header to sample a fresh set of popular market movers.
- **After-Hours in Menu Bar**: Toggle **Show AH/PM in Bar** in the footer to display extended-hours price and delta right next to the regular close in your macOS Menu Bar.

## Project Structure

```text
tickbar/
├── api/
│   └── quotes.js                  # Vercel serverless live Yahoo Finance (Regular + AH/PM) endpoint
├── macos-app/
│   ├── Sources/
│   │   └── TickBar.swift          # Native SwiftUI + AppKit macOS 27 Liquid Glass app
│   └── build_dmg.sh               # Universal compiler, icon generator & DMG packager
├── public/
│   ├── index.html                 # Interactive mkdir.directory + macOS 27 Liquid Glass web stage
│   ├── downloads/
│   │   └── TickBar-macOS-Universal.dmg
│   ├── robots.txt
│   └── sitemap.xml
└── vercel.json                    # Vercel routing & DMG headers
```

## License

MIT
