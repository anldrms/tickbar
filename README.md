# TickBar

**A native macOS Menu Bar (Status Bar) and floating desktop stock ticker widget with live quotes, official company logos, and intraday sparklines.**

TickBar pins live stock, ETF, and crypto prices directly to your macOS top status bar and includes a detachable non-activating obsidian desktop widget. Built natively in Swift, SwiftUI, and AppKit (`< 1 MB` Universal binary for Apple Silicon & Intel) with zero Electron overhead and zero API keys required.

## Features

- **Native macOS Status Bar Engine**: Pins your active ticker symbol, official company logo, live price, and color-coded daily percentage move directly in the macOS Menu Bar.
- **Floating Desktop Widget (PiP)**: Detachable, translucent dark-mode `NSPanel` that floats seamlessly across workspaces without stealing window focus.
- **Instant Add & Remove Watchlist**: Add any stock, ETF, or crypto symbol (`FLY`, `NVDA`, `QQQ`, `TSLA`, `AAPL`, `RKLB`, `PLTR`, `AMD`, `SPY`, `COIN`, `HOOD`, `ASTS`, `BTC-USD`, etc.) via the search bar or one-click quick-add chips, and remove any row anytime with `×`.
- **Up-to-Date Official Company Logos**: Resolves current official vector company emblems (including recent IPOs like Firefly Aerospace `$FLY`) with automatic multi-CDN fallback and local memory caching.
- **5-Minute Intraday Sparklines**: Renders smooth vector range curves and gradient fills from live intraday market data.
- **Auto-Cycle Mode**: Either pin a single ticker to your macOS Menu Bar or automatically cycle through your entire watchlist every 4.5 seconds.
- **Interactive Directory Landing Page**: Ships with a dark architectural showcase and live interactive web demo ready for instant Vercel deployment.

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

This compiles both `arm64` and `x86_64` binaries, merges them via `lipo` into a Universal `TickBar.app` bundle, signs the bundle, and packages `public/downloads/TickBar-macOS-Universal.dmg`.

## Managing Tickers

- **Add a Ticker**: Click the TickBar item in your macOS Menu Bar, type any symbol (e.g. `PLTR`, `AMD`, `SPY`, `BTC-USD`) into the input bar, and press `Return` or click `+ ADD`. You can also click any of the `+SYMBOL` quick-add chips below the search field.
- **Remove a Ticker**: Click the `×` button on the right side of any ticker row in the Menu Bar popover or floating desktop widget.
- **Pin to Menu Bar**: Click any ticker row (or its logo) to pin that symbol to your top macOS Status Bar, or enable **Cycle in Menu Bar** to rotate through all watched symbols automatically.

## Deploy to Vercel

1. Push or fork this repository to GitHub.
2. Import the repository on [Vercel](https://vercel.com/new).
3. Leave the **Framework Preset** as `Other` (static site served from `public/` via `vercel.json`).
4. Click **Deploy**. Your landing page and direct `.dmg` download will be live immediately.

## Project Structure

```text
tickbar/
├── macos-app/
│   ├── Sources/
│   │   └── TickBar.swift          # Native SwiftUI + AppKit Menu Bar & Floating Widget app
│   └── build_dmg.sh               # Universal (arm64 + x86_64) compiler, icon generator & DMG packager
├── public/
│   ├── index.html                 # Interactive landing page & live web demo
│   ├── downloads/
│   │   └── TickBar-macOS-Universal.dmg
│   ├── robots.txt
│   └── sitemap.xml
└── vercel.json                    # Vercel CDN & security headers for .dmg distribution
```

## License

MIT
