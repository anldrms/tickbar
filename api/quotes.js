const DIRECT_LOGOS = {
  NVDA: "https://s3-symbol-logo.tradingview.com/nvidia--big.svg",
  AAPL: "https://s3-symbol-logo.tradingview.com/apple--big.svg",
  TSLA: "https://s3-symbol-logo.tradingview.com/tesla--big.svg",
  MSFT: "https://s3-symbol-logo.tradingview.com/microsoft--big.svg",
  AMZN: "https://s3-symbol-logo.tradingview.com/amazon--big.svg",
  META: "https://s3-symbol-logo.tradingview.com/meta-platforms--big.svg",
  GOOG: "https://s3-symbol-logo.tradingview.com/alphabet--big.svg",
  GOOGL: "https://s3-symbol-logo.tradingview.com/alphabet--big.svg",
  PLTR: "https://s3-symbol-logo.tradingview.com/palantir--big.svg",
  AMD: "https://s3-symbol-logo.tradingview.com/advanced-micro-devices--big.svg",
  NFLX: "https://s3-symbol-logo.tradingview.com/netflix--big.svg",
  COIN: "https://s3-symbol-logo.tradingview.com/coinbase--big.svg",
  MSTR: "https://s3-symbol-logo.tradingview.com/strategy-cad-hedged-cibc-cdr--big.svg",
  SPY: "https://s3-symbol-logo.tradingview.com/spdr-sandp500-etf-tr--big.svg",
  QQQ: "https://s3-symbol-logo.tradingview.com/invesco--big.svg",
  HOOD: "https://s3-symbol-logo.tradingview.com/robinhood--big.svg",
  RKLB: "https://s3-symbol-logo.tradingview.com/rocket-lab--big.svg",
  FLY: "https://s3-symbol-logo.tradingview.com/firefly-aerospace--big.svg",
  SOFI: "https://s3-symbol-logo.tradingview.com/sofi--big.svg",
  ASTS: "https://s3-symbol-logo.tradingview.com/ast-spacemobile--big.svg",
  IONQ: "https://s3-symbol-logo.tradingview.com/ionq--big.svg",
  AVGO: "https://s3-symbol-logo.tradingview.com/broadcom--big.svg",
  ARM: "https://s3-symbol-logo.tradingview.com/arm--big.svg",
  ORCL: "https://s3-symbol-logo.tradingview.com/oracle--big.svg",
  CRWD: "https://s3-symbol-logo.tradingview.com/crowdstrike--big.svg",
  UBER: "https://s3-symbol-logo.tradingview.com/uber--big.svg",
  SHOP: "https://s3-symbol-logo.tradingview.com/shopify--big.svg",
  MU: "https://s3-symbol-logo.tradingview.com/micron-technology--big.svg",
  TSM: "https://s3-symbol-logo.tradingview.com/taiwan-semiconductor--big.svg",
  ASML: "https://s3-symbol-logo.tradingview.com/asml--big.svg",
  "BTC-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCBTC--big.svg",
  "ETH-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCETH--big.svg",
  "SOL-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCSOL--big.svg"
};

const FALLBACK_NAMES = {
  NVDA: "NVIDIA Corp.",
  AAPL: "Apple Inc.",
  TSLA: "Tesla, Inc.",
  MSFT: "Microsoft Corp.",
  AMZN: "Amazon.com, Inc.",
  META: "Meta Platforms",
  GOOGL: "Alphabet Inc.",
  GOOG: "Alphabet Inc.",
  PLTR: "Palantir Technologies",
  AMD: "Advanced Micro Devices",
  NFLX: "Netflix, Inc.",
  COIN: "Coinbase Global",
  MSTR: "Strategy Inc.",
  SPY: "SPDR S&P 500 ETF",
  QQQ: "Invesco QQQ Trust",
  HOOD: "Robinhood Markets",
  RKLB: "Rocket Lab USA",
  FLY: "Firefly Aerospace",
  SOFI: "SoFi Technologies",
  ASTS: "AST SpaceMobile",
  IONQ: "IonQ, Inc.",
  AVGO: "Broadcom Inc.",
  ARM: "Arm Holdings",
  ORCL: "Oracle Corp.",
  CRWD: "CrowdStrike Holdings",
  UBER: "Uber Technologies",
  SHOP: "Shopify Inc.",
  MU: "Micron Technology",
  TSM: "Taiwan Semiconductor",
  ASML: "ASML Holding",
  "BTC-USD": "Bitcoin USD",
  "ETH-USD": "Ethereum USD",
  "SOL-USD": "Solana USD"
};

async function resolveLogoUrl(symbol) {
  const clean = symbol.toUpperCase();
  if (DIRECT_LOGOS[clean]) {
    return DIRECT_LOGOS[clean];
  }
  const baseTicker = clean.split("-")[0];
  try {
    const res = await fetch(
      `https://symbol-search.tradingview.com/symbol_search/v3/?text=${encodeURIComponent(baseTicker)}&hl=0&lang=en`,
      {
        headers: {
          Origin: "https://www.tradingview.com",
          "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15"
        }
      }
    );
    if (res.ok) {
      const data = await res.json();
      const symbols = Array.isArray(data.symbols) ? data.symbols : [];
      const match =
        symbols.find((s) => (s.symbol || "").toUpperCase() === baseTicker && s.logoid) ||
        symbols.find((s) => s.logoid);
      if (match && match.logoid) {
        return `https://s3-symbol-logo.tradingview.com/${match.logoid}--big.svg`;
      }
    }
  } catch (_) {}
  return `https://assets.parqet.com/logos/symbol/${encodeURIComponent(baseTicker)}?format=png`;
}

async function fetchSingleYahooQuote(symbol) {
  const clean = symbol.trim().toUpperCase();
  const url = `https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(clean)}?interval=5m&range=1d&includePrePost=true`;

  const [yahooRes, logoUrl] = await Promise.all([
    fetch(url, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15"
      }
    }),
    resolveLogoUrl(clean)
  ]);

  if (!yahooRes.ok) {
    throw new Error(`Yahoo status ${yahooRes.status} for ${clean}`);
  }

  const json = await yahooRes.json();
  const result = json?.chart?.result?.[0];
  if (!result || !result.meta) {
    throw new Error(`Invalid Yahoo payload for ${clean}`);
  }

  const meta = result.meta;
  const regularPrice = Number(meta.regularMarketPrice || 0);
  const prevClose = Number(meta.chartPreviousClose ?? meta.previousClose ?? regularPrice);
  const change = regularPrice - prevClose;
  const changePercent = prevClose > 0 ? (change / prevClose) * 100 : 0;

  const timestamps = Array.isArray(result.timestamp) ? result.timestamp : [];
  const rawCloses = result?.indicators?.quote?.[0]?.close || [];

  const closes = [];
  let lastValidTs = 0;
  let lastValidClose = regularPrice;

  for (let i = 0; i < rawCloses.length; i++) {
    const val = rawCloses[i];
    if (typeof val === "number" && !Number.isNaN(val)) {
      closes.push(Number(val.toFixed(2)));
      if (i < timestamps.length) {
        lastValidTs = timestamps[i];
        lastValidClose = val;
      }
    }
  }

  let extendedLabel = null;
  let extendedPrice = null;
  let extendedChange = null;
  let extendedChangePercent = null;

  const period = meta.currentTradingPeriod || {};
  const regEnd = period?.regular?.end || 0;
  const regStart = period?.regular?.start || 0;
  const preStart = period?.pre?.start || 0;

  if (meta.hasPrePostMarketData) {
    if (regEnd > 0 && lastValidTs > regEnd && regularPrice > 0) {
      extendedLabel = "AH";
      extendedPrice = Number(lastValidClose.toFixed(2));
      extendedChange = Number((lastValidClose - regularPrice).toFixed(2));
      extendedChangePercent = Number((((lastValidClose - regularPrice) / regularPrice) * 100).toFixed(2));
    } else if (preStart > 0 && regStart > 0 && lastValidTs >= preStart && lastValidTs < regStart && prevClose > 0) {
      extendedLabel = "PM";
      extendedPrice = Number(lastValidClose.toFixed(2));
      extendedChange = Number((lastValidClose - prevClose).toFixed(2));
      extendedChangePercent = Number((((lastValidClose - prevClose) / prevClose) * 100).toFixed(2));
    }
  }

  let sparkline = closes;
  if (sparkline.length > 24) {
    const step = Math.max(1, Math.floor(sparkline.length / 24));
    const sampled = [];
    for (let i = 0; i < sparkline.length; i += step) {
      sampled.push(sparkline[i]);
    }
    if (sampled[sampled.length - 1] !== sparkline[sparkline.length - 1]) {
      sampled.push(sparkline[sparkline.length - 1]);
    }
    sparkline = sampled;
  } else if (sparkline.length < 2) {
    sparkline = [prevClose, regularPrice];
  }

  return {
    symbol: clean,
    name: FALLBACK_NAMES[clean] || meta.shortName || meta.longName || clean,
    price: Number(regularPrice.toFixed(2)),
    previousClose: Number(prevClose.toFixed(2)),
    change: Number(change.toFixed(2)),
    changePercent: Number(changePercent.toFixed(2)),
    extendedLabel,
    extendedPrice,
    extendedChange,
    extendedChangePercent,
    sparkline,
    logo: logoUrl,
    updatedAt: new Date().toISOString()
  };
}

module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  res.setHeader("Cache-Control", "s-maxage=10, stale-while-revalidate=20");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  const rawSymbols = req.query.symbols || "NVDA,AAPL,TSLA,MSFT,AMZN,META,GOOGL,PLTR,AMD,NFLX,COIN,MSTR,SPY,QQQ,HOOD,RKLB,FLY,SOFI,ASTS,BTC-USD";
  const symbols = rawSymbols
    .split(",")
    .map((s) => s.trim().toUpperCase())
    .filter(Boolean)
    .slice(0, 28);

  const settled = await Promise.allSettled(symbols.map((sym) => fetchSingleYahooQuote(sym)));
  const quotes = {};

  for (const item of settled) {
    if (item.status === "fulfilled" && item.value) {
      quotes[item.value.symbol] = item.value;
    }
  }

  return res.status(200).json({
    source: "Yahoo Finance v8 (Regular + Extended Hours)",
    timestamp: new Date().toISOString(),
    count: Object.keys(quotes).length,
    quotes
  });
};
