# TickBar by @anldrms

A 100% free, native macOS Menu Bar & Floating Desktop Widget for real-time stock tickers, company logos, and intraday sparklines.

- **Created by:** [@anldrms](https://github.com/anldrms)
- **Platform:** macOS 13.0+ (Universal Binary: Apple Silicon `arm64` & Intel `x86_64`)
- **Download:** [`TickBar-macOS-Universal.dmg`](./public/downloads/TickBar-macOS-Universal.dmg)

## Features

- **Native macOS Status Bar Ticker:** Pin your primary stock (`$FLY`, `$NVDA`, `$QQQ`, `$TSLA`, `$AAPL`, `$RKLB`, or any custom symbol) directly to the top macOS Menu Bar with live company logo, price, and percentage delta, or enable Auto-Cycle mode.
- **Floating Obsidian Desktop Widget:** Detach a sleek non-activating floating desktop widget (`NSPanel`) that stays visible across spaces.
- **Automatic Company Logos & Sparklines:** Resolves high-DPI company logos and renders intraday 5-minute sparklines with zero API keys required.

## Building from Source

```bash
bash macos-app/build_dmg.sh
```
