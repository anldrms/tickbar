import Cocoa
import SwiftUI
import Combine

struct StockQuote: Identifiable, Codable, Equatable {
    var id: String { symbol }
    let symbol: String
    var name: String
    var price: Double
    var previousClose: Double
    var change: Double
    var changePercent: Double
    var dayHigh: Double
    var dayLow: Double
    var sparkline: [Double]
    var updatedAt: Date

    var isPositive: Bool {
        change >= 0
    }
}

final class LogoCache: ObservableObject {
    static let shared = LogoCache()
    @Published private(set) var images: [String: NSImage] = [:]
    private var inFlight: Set<String> = []

    private let directLogoMap: [String: String] = [
        "FLY": "https://s3-symbol-logo.tradingview.com/firefly-aerospace--big.svg",
        "NVDA": "https://s3-symbol-logo.tradingview.com/nvidia--big.svg",
        "QQQ": "https://s3-symbol-logo.tradingview.com/invesco--big.svg",
        "TSLA": "https://s3-symbol-logo.tradingview.com/tesla--big.svg",
        "AAPL": "https://s3-symbol-logo.tradingview.com/apple--big.svg",
        "RKLB": "https://s3-symbol-logo.tradingview.com/rocket-lab--big.svg",
        "PLTR": "https://s3-symbol-logo.tradingview.com/palantir--big.svg",
        "AMD": "https://s3-symbol-logo.tradingview.com/advanced-micro-devices--big.svg",
        "SPY": "https://s3-symbol-logo.tradingview.com/spdr-sandp500-etf-tr--big.svg",
        "COIN": "https://s3-symbol-logo.tradingview.com/coinbase--big.svg",
        "HOOD": "https://s3-symbol-logo.tradingview.com/robinhood--big.svg",
        "ASTS": "https://s3-symbol-logo.tradingview.com/ast-spacemobile--big.svg",
        "SOFI": "https://s3-symbol-logo.tradingview.com/sofi--big.svg",
        "MSFT": "https://s3-symbol-logo.tradingview.com/microsoft--big.svg",
        "AMZN": "https://s3-symbol-logo.tradingview.com/amazon--big.svg",
        "META": "https://s3-symbol-logo.tradingview.com/meta-platforms--big.svg",
        "GOOG": "https://s3-symbol-logo.tradingview.com/alphabet--big.svg",
        "GOOGL": "https://s3-symbol-logo.tradingview.com/alphabet--big.svg",
        "NFLX": "https://s3-symbol-logo.tradingview.com/netflix--big.svg",
        "IONQ": "https://s3-symbol-logo.tradingview.com/ionq--big.svg",
        "MSTR": "https://s3-symbol-logo.tradingview.com/microstrategy--big.svg",
        "BTC-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCBTC--big.svg",
        "ETH-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCETH--big.svg",
        "SOL-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCSOL--big.svg"
    ]

    private let domainMap: [String: String] = [
        "FLY": "fireflyspace.com",
        "NVDA": "nvidia.com",
        "AAPL": "apple.com",
        "TSLA": "tesla.com",
        "RKLB": "rocketlabusa.com",
        "QQQ": "invesco.com",
        "SPY": "ssga.com",
        "MSFT": "microsoft.com",
        "AMZN": "amazon.com",
        "META": "meta.com",
        "GOOG": "abc.xyz",
        "GOOGL": "abc.xyz",
        "AMD": "amd.com",
        "PLTR": "palantir.com",
        "NFLX": "netflix.com",
        "COIN": "coinbase.com",
        "HOOD": "robinhood.com",
        "ASTS": "ast-science.com",
        "IONQ": "ionq.com",
        "SOFI": "sofi.com",
        "MSTR": "strategy.com"
    ]

    func image(for symbol: String) -> NSImage? {
        let clean = symbol.uppercased()
        if let cached = images[clean] {
            return cached
        }
        fetchLogoIfNeeded(for: clean)
        return nil
    }

    func fetchLogoIfNeeded(for symbol: String) {
        let clean = symbol.uppercased()
        guard images[clean] == nil, !inFlight.contains(clean) else { return }
        inFlight.insert(clean)

        if let direct = directLogoMap[clean], let directURL = URL(string: direct) {
            tryNextURL(urls: [directURL] + fallbackURLs(for: clean), index: 0, symbol: clean)
            return
        }

        resolveTradingViewLogo(for: clean) { [weak self] resolvedURL in
            guard let self = self else { return }
            var candidates: [URL] = []
            if let resolvedURL = resolvedURL {
                candidates.append(resolvedURL)
            }
            candidates.append(contentsOf: self.fallbackURLs(for: clean))
            self.tryNextURL(urls: candidates, index: 0, symbol: clean)
        }
    }

    private func fallbackURLs(for clean: String) -> [URL] {
        let baseTicker = clean.components(separatedBy: "-").first ?? clean
        var urls: [URL] = []
        if let domain = domainMap[clean],
           let urlFav = URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=128") {
            urls.append(urlFav)
        }
        if clean != "FLY",
           let urlParqet = URL(string: "https://assets.parqet.com/logos/symbol/\(baseTicker)?format=png") {
            urls.append(urlParqet)
        }
        return urls
    }

    private func resolveTradingViewLogo(for symbol: String, completion: @escaping (URL?) -> Void) {
        let baseTicker = symbol.components(separatedBy: "-").first ?? symbol
        let encoded = baseTicker.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? baseTicker
        guard let searchURL = URL(string: "https://symbol-search.tradingview.com/symbol_search/v3/?text=\(encoded)&hl=0&lang=en") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: searchURL)
        request.timeoutInterval = 5
        request.setValue("https://www.tradingview.com", forHTTPHeaderField: "Origin")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let symbols = root["symbols"] as? [[String: Any]] else {
                completion(nil)
                return
            }

            let exactMatch = symbols.first { item in
                let sym = (item["symbol"] as? String)?.uppercased() ?? ""
                return sym == baseTicker && (item["logoid"] as? String)?.isEmpty == false
            } ?? symbols.first { item in
                (item["logoid"] as? String)?.isEmpty == false
            }

            if let logoid = exactMatch?["logoid"] as? String,
               let svgURL = URL(string: "https://s3-symbol-logo.tradingview.com/\(logoid)--big.svg") {
                completion(svgURL)
            } else {
                completion(nil)
            }
        }.resume()
    }

    private func tryNextURL(urls: [URL], index: Int, symbol: String) {
        guard index < urls.count else {
            DispatchQueue.main.async {
                self.inFlight.remove(symbol)
            }
            return
        }

        var request = URLRequest(url: urls[index])
        request.timeoutInterval = 6
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let self = self else { return }
            if let http = response as? HTTPURLResponse,
               http.statusCode == 200,
               let data = data,
               data.count > 80,
               let img = NSImage(data: data),
               img.size.width > 8 {
                DispatchQueue.main.async {
                    self.images[symbol] = img
                    self.inFlight.remove(symbol)
                }
            } else {
                self.tryNextURL(urls: urls, index: index + 1, symbol: symbol)
            }
        }.resume()
    }
}

final class TickerStore: ObservableObject {
    @Published var symbols: [String] {
        didSet {
            UserDefaults.standard.set(symbols, forKey: "tickbar.symbols")
        }
    }
    @Published var pinnedSymbol: String {
        didSet {
            UserDefaults.standard.set(pinnedSymbol, forKey: "tickbar.pinnedSymbol")
            onMenuBarUpdate?()
        }
    }
    @Published var autoCycleMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(autoCycleMenuBar, forKey: "tickbar.autoCycle")
            onMenuBarUpdate?()
        }
    }
    @Published var showFloatingWidget: Bool {
        didSet {
            UserDefaults.standard.set(showFloatingWidget, forKey: "tickbar.showFloatingWidget")
            onFloatingWidgetToggle?(showFloatingWidget)
        }
    }
    @Published var quotes: [String: StockQuote] = [:]
    @Published var isFetching: Bool = false
    @Published var lastUpdated: Date? = nil
    @Published var cycleIndex: Int = 0
    @Published var newTickerInput: String = ""
    @Published var hoveredSymbol: String? = nil

    let suggestedSymbols: [String] = [
        "FLY", "NVDA", "QQQ", "TSLA", "AAPL", "RKLB",
        "PLTR", "AMD", "SPY", "COIN", "HOOD", "ASTS", "BTC-USD"
    ]

    var onMenuBarUpdate: (() -> Void)?
    var onFloatingWidgetToggle: ((Bool) -> Void)?

    private var refreshTimer: Timer?
    private var cycleTimer: Timer?

    private let fallbackNames: [String: String] = [
        "FLY": "Firefly Aerospace",
        "NVDA": "NVIDIA Corp.",
        "QQQ": "Invesco QQQ Trust",
        "TSLA": "Tesla, Inc.",
        "AAPL": "Apple Inc.",
        "RKLB": "Rocket Lab USA",
        "AMD": "Advanced Micro Devices",
        "PLTR": "Palantir Technologies",
        "SPY": "SPDR S&P 500 ETF",
        "COIN": "Coinbase Global",
        "HOOD": "Robinhood Markets",
        "ASTS": "AST SpaceMobile",
        "MSFT": "Microsoft Corp.",
        "AMZN": "Amazon.com, Inc.",
        "META": "Meta Platforms",
        "BTC-USD": "Bitcoin USD"
    ]

    init() {
        let savedSymbols = UserDefaults.standard.stringArray(forKey: "tickbar.symbols")
        let defaultList = ["FLY", "NVDA", "QQQ", "TSLA", "AAPL", "RKLB"]
        self.symbols = (savedSymbols?.isEmpty == false) ? savedSymbols! : defaultList
        self.pinnedSymbol = UserDefaults.standard.string(forKey: "tickbar.pinnedSymbol") ?? "FLY"
        self.autoCycleMenuBar = UserDefaults.standard.bool(forKey: "tickbar.autoCycle")
        if UserDefaults.standard.object(forKey: "tickbar.showFloatingWidget") == nil {
            self.showFloatingWidget = true
        } else {
            self.showFloatingWidget = UserDefaults.standard.bool(forKey: "tickbar.showFloatingWidget")
        }

        seedInitialQuotes()
        startTimers()
        refreshAll()
    }

    private func seedInitialQuotes() {
        let seed: [StockQuote] = [
            StockQuote(symbol: "FLY", name: "Firefly Aerospace", price: 17.03, previousClose: 17.25, change: -0.22, changePercent: -1.28, dayHigh: 17.46, dayLow: 16.92, sparkline: [17.25, 17.38, 17.15, 17.02, 17.09, 17.01, 17.05, 17.03], updatedAt: Date()),
            StockQuote(symbol: "NVDA", name: "NVIDIA Corp.", price: 188.65, previousClose: 184.20, change: 4.45, changePercent: 2.42, dayHigh: 189.40, dayLow: 183.90, sparkline: [184.2, 185.1, 186.4, 185.9, 187.3, 188.1, 188.9, 188.65], updatedAt: Date()),
            StockQuote(symbol: "QQQ", name: "Invesco QQQ Trust", price: 512.40, previousClose: 508.90, change: 3.50, changePercent: 0.69, dayHigh: 513.80, dayLow: 508.10, sparkline: [508.9, 509.5, 510.2, 511.0, 510.8, 511.9, 512.6, 512.4], updatedAt: Date()),
            StockQuote(symbol: "TSLA", name: "Tesla, Inc.", price: 254.10, previousClose: 251.00, change: 3.10, changePercent: 1.24, dayHigh: 256.50, dayLow: 249.80, sparkline: [251.0, 250.4, 252.1, 253.8, 252.9, 254.6, 253.9, 254.1], updatedAt: Date()),
            StockQuote(symbol: "AAPL", name: "Apple Inc.", price: 233.85, previousClose: 231.50, change: 2.35, changePercent: 1.02, dayHigh: 234.60, dayLow: 231.10, sparkline: [231.5, 232.0, 232.8, 232.4, 233.1, 233.9, 234.2, 233.85], updatedAt: Date()),
            StockQuote(symbol: "RKLB", name: "Rocket Lab USA", price: 22.40, previousClose: 21.85, change: 0.55, changePercent: 2.52, dayHigh: 22.75, dayLow: 21.70, sparkline: [21.85, 21.95, 22.10, 22.05, 22.25, 22.48, 22.35, 22.40], updatedAt: Date())
        ]
        for q in seed {
            quotes[q.symbol] = q
            LogoCache.shared.fetchLogoIfNeeded(for: q.symbol)
        }
    }

    func startTimers() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.refreshAll()
        }

        cycleTimer?.invalidate()
        cycleTimer = Timer.scheduledTimer(withTimeInterval: 4.5, repeats: true) { [weak self] _ in
            guard let self = self, self.autoCycleMenuBar, !self.symbols.isEmpty else { return }
            self.cycleIndex = (self.cycleIndex + 1) % self.symbols.count
            self.onMenuBarUpdate?()
        }
    }

    var activeMenuBarQuote: StockQuote? {
        if autoCycleMenuBar, !symbols.isEmpty {
            let idx = cycleIndex % symbols.count
            let sym = symbols[idx]
            return quotes[sym]
        }
        if let q = quotes[pinnedSymbol] {
            return q
        }
        if let first = symbols.first {
            return quotes[first]
        }
        return nil
    }

    func addSymbol(_ raw: String) {
        let cleaned = raw
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        guard !cleaned.isEmpty else { return }
        if !symbols.contains(cleaned) {
            symbols.append(cleaned)
        }
        if symbols.count == 1 {
            pinnedSymbol = cleaned
        }
        LogoCache.shared.fetchLogoIfNeeded(for: cleaned)
        fetchQuote(for: cleaned)
    }

    func removeSymbol(_ symbol: String) {
        symbols.removeAll { $0 == symbol }
        if pinnedSymbol == symbol, let first = symbols.first {
            pinnedSymbol = first
        }
        onMenuBarUpdate?()
    }

    func refreshAll() {
        guard !symbols.isEmpty else { return }
        isFetching = true
        let group = DispatchGroup()
        for sym in symbols {
            LogoCache.shared.fetchLogoIfNeeded(for: sym)
            group.enter()
            fetchQuote(for: sym) {
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.isFetching = false
            self?.lastUpdated = Date()
            self?.onMenuBarUpdate?()
        }
    }

    func fetchQuote(for symbol: String, completion: (() -> Void)? = nil) {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=5m&range=1d") else {
            completion?()
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            defer { completion?() }
            guard let self = self,
                  let data = data,
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let chart = root["chart"] as? [String: Any],
                  let results = chart["result"] as? [[String: Any]],
                  let first = results.first,
                  let meta = first["meta"] as? [String: Any] else {
                return
            }

            let regularPrice = (meta["regularMarketPrice"] as? Double) ?? 0.0
            let prevClose = (meta["chartPreviousClose"] as? Double)
                ?? (meta["previousClose"] as? Double)
                ?? regularPrice
            let dayHigh = (meta["regularMarketDayHigh"] as? Double) ?? regularPrice
            let dayLow = (meta["regularMarketDayLow"] as? Double) ?? regularPrice
            let shortName = self.fallbackNames[symbol]
                ?? (meta["shortName"] as? String)
                ?? (meta["longName"] as? String)
                ?? symbol

            var closes: [Double] = []
            if let indicators = first["indicators"] as? [String: Any],
               let quoteArr = indicators["quote"] as? [[String: Any]],
               let quoteObj = quoteArr.first,
               let rawCloses = quoteObj["close"] as? [Any] {
                for item in rawCloses {
                    if let val = item as? Double {
                        closes.append(val)
                    }
                }
            }

            if closes.isEmpty {
                closes = [prevClose, regularPrice]
            } else if closes.count > 28 {
                let step = max(1, closes.count / 28)
                var sampled: [Double] = []
                var idx = 0
                while idx < closes.count {
                    sampled.append(closes[idx])
                    idx += step
                }
                if let last = closes.last, sampled.last != last {
                    sampled.append(last)
                }
                closes = sampled
            }

            let diff = regularPrice - prevClose
            let pct = prevClose > 0 ? (diff / prevClose) * 100.0 : 0.0

            let quote = StockQuote(
                symbol: symbol,
                name: shortName,
                price: regularPrice,
                previousClose: prevClose,
                change: diff,
                changePercent: pct,
                dayHigh: max(dayHigh, regularPrice),
                dayLow: min(dayLow, regularPrice),
                sparkline: closes,
                updatedAt: Date()
            )

            DispatchQueue.main.async {
                self.quotes[symbol] = quote
                self.onMenuBarUpdate?()
            }
        }.resume()
    }
}

struct TickerLogoView: View {
    let symbol: String
    let size: CGFloat
    @ObservedObject var cache = LogoCache.shared

    private var accentColor: Color {
        let colors: [Color] = [
            Color(red: 0.16, green: 0.82, blue: 0.48),
            Color(red: 0.25, green: 0.56, blue: 0.98),
            Color(red: 0.96, green: 0.62, blue: 0.18),
            Color(red: 0.68, green: 0.42, blue: 0.96),
            Color(red: 0.95, green: 0.33, blue: 0.42)
        ]
        let hash = abs(symbol.hashValue)
        return colors[hash % colors.count]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(Color(red: 0.11, green: 0.12, blue: 0.16))

            if let nsImg = cache.image(for: symbol) {
                Image(nsImage: nsImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
            } else {
                Text(String(symbol.prefix(3)))
                    .font(.system(size: size * 0.34, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

struct SparklineView: View {
    let points: [Double]
    let isPositive: Bool

    var strokeColor: Color {
        isPositive
            ? Color(red: 0.13, green: 0.84, blue: 0.48)
            : Color(red: 0.96, green: 0.32, blue: 0.38)
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minVal = points.min() ?? 0
            let maxVal = points.max() ?? 1
            let span = max(maxVal - minVal, 0.0001)

            ZStack {
                Path { path in
                    guard points.count > 1 else { return }
                    for (idx, val) in points.enumerated() {
                        let x = w * CGFloat(idx) / CGFloat(points.count - 1)
                        let y = h - (h * CGFloat((val - minVal) / span))
                        if idx == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    path.addLine(to: CGPoint(x: w, y: h))
                    path.addLine(to: CGPoint(x: 0, y: h))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [strokeColor.opacity(0.26), strokeColor.opacity(0.0)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Path { path in
                    guard points.count > 1 else { return }
                    for (idx, val) in points.enumerated() {
                        let x = w * CGFloat(idx) / CGFloat(points.count - 1)
                        let y = h - (h * CGFloat((val - minVal) / span))
                        if idx == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(strokeColor, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }
        }
    }
}

struct TickerRowView: View {
    let quote: StockQuote
    let isPinned: Bool
    let isHovered: Bool
    let onHoverChange: (Bool) -> Void
    let onPin: () -> Void
    let onDelete: () -> Void

    private var changeColor: Color {
        quote.isPositive
            ? Color(red: 0.13, green: 0.84, blue: 0.48)
            : Color(red: 0.96, green: 0.32, blue: 0.38)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onPin) {
                TickerLogoView(symbol: quote.symbol, size: 32)
                    .overlay(alignment: .topTrailing) {
                        if isPinned {
                            Circle()
                                .fill(Color(red: 0.13, green: 0.84, blue: 0.48))
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: -2)
                        }
                    }
            }
            .buttonStyle(.plain)
            .help("Click to pin \(quote.symbol) in macOS Menu Bar")

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(quote.symbol)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    if isPinned {
                        Text("BAR")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.13, green: 0.84, blue: 0.48))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color(red: 0.13, green: 0.84, blue: 0.48).opacity(0.14))
                            .cornerRadius(3)
                    }
                }
                Text(quote.name)
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.50))
                    .lineLimit(1)
            }
            .frame(width: 108, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onPin()
            }

            SparklineView(points: quote.sparkline, isPositive: quote.isPositive)
                .frame(width: 54, height: 22)

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Text(String(format: "$%.2f", quote.price))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)

                Text(String(format: "%@%.2f%%", quote.isPositive ? "+" : "", quote.changePercent))
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(changeColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(changeColor.opacity(0.14))
                    .cornerRadius(4)
            }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isHovered ? Color(red: 0.96, green: 0.32, blue: 0.38) : Color.white.opacity(0.42))
                    .frame(width: 20, height: 20)
                    .background(isHovered ? Color(red: 0.96, green: 0.32, blue: 0.38).opacity(0.16) : Color.white.opacity(0.06))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .help("Remove \(quote.symbol) from watchlist")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.05) : Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isPinned ? Color.white.opacity(0.16) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .onHover { hovering in
            onHoverChange(hovering)
        }
    }
}

struct PopoverContentView: View {
    @ObservedObject var store: TickerStore

    private var availableSuggestions: [String] {
        store.suggestedSymbols.filter { !store.symbols.contains($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.13, green: 0.84, blue: 0.48))
                        .frame(width: 7, height: 7)
                    Text("TICKBAR")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .tracking(1.2)
                        .foregroundColor(.white)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.13, green: 0.84, blue: 0.48))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color(red: 0.13, green: 0.84, blue: 0.48).opacity(0.14))
                        .cornerRadius(4)
                }

                Spacer()

                Button(action: { store.showFloatingWidget.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: store.showFloatingWidget ? "pip.fill" : "pip")
                            .font(.system(size: 10))
                        Text("Widget")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                    }
                    .foregroundColor(store.showFloatingWidget ? Color(red: 0.13, green: 0.84, blue: 0.48) : Color.white.opacity(0.65))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .help("Toggle Floating Desktop Widget")

                Button(action: { store.refreshAll() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.70))
                        .frame(width: 24, height: 22)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .help("Refresh Live Quotes")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.02))

            Divider().background(Color.white.opacity(0.08))

            // Add Ticker Input + Quick-Add Chips
            VStack(spacing: 7) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.13, green: 0.84, blue: 0.48))

                    TextField("Add symbol (e.g. PLTR, AMD, SPY, BTC-USD)...", text: $store.newTickerInput, onCommit: {
                        store.addSymbol(store.newTickerInput)
                        store.newTickerInput = ""
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(.white)

                    Button(action: {
                        store.addSymbol(store.newTickerInput)
                        store.newTickerInput = ""
                    }) {
                        Text("+ ADD")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.13, green: 0.84, blue: 0.48))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }

                if !availableSuggestions.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 5) {
                            ForEach(availableSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    store.addSymbol(suggestion)
                                }) {
                                    Text("+\(suggestion)")
                                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.72))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2.5)
                                        .background(Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(Color.white.opacity(0.10), lineWidth: 1)
                                        )
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.08, green: 0.09, blue: 0.12))

            Divider().background(Color.white.opacity(0.08))

            // Watchlist Rows
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(store.symbols, id: \.self) { sym in
                        if let quote = store.quotes[sym] {
                            TickerRowView(
                                quote: quote,
                                isPinned: !store.autoCycleMenuBar && store.pinnedSymbol == sym,
                                isHovered: store.hoveredSymbol == sym,
                                onHoverChange: { hovering in
                                    store.hoveredSymbol = hovering ? sym : nil
                                },
                                onPin: {
                                    store.autoCycleMenuBar = false
                                    store.pinnedSymbol = sym
                                },
                                onDelete: {
                                    store.removeSymbol(sym)
                                }
                            )
                        } else {
                            HStack(spacing: 10) {
                                TickerLogoView(symbol: sym, size: 30)
                                Text(sym)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("Fetching quote...")
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.45))
                                Button(action: { store.removeSymbol(sym) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.5))
                                        .frame(width: 20, height: 20)
                                        .background(Color.white.opacity(0.07))
                                        .cornerRadius(5)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color.white.opacity(0.02))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(10)
            }
            .frame(maxHeight: 310)

            Divider().background(Color.white.opacity(0.08))

            // Footer controls
            HStack(spacing: 10) {
                Toggle(isOn: $store.autoCycleMenuBar) {
                    Text("Cycle in Menu Bar")
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.65))
                }
                .toggleStyle(.checkbox)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.45))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.02))
        }
        .frame(width: 364)
        .background(Color(red: 0.05, green: 0.055, blue: 0.075))
    }
}

struct FloatingWidgetView: View {
    @ObservedObject var store: TickerStore

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.13, green: 0.84, blue: 0.48))
                        .frame(width: 6, height: 6)
                    Text("TICKBAR LIVE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .tracking(1.1)
                        .foregroundColor(Color.white.opacity(0.85))
                }
                Spacer()
                Button(action: { store.showFloatingWidget = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color.white.opacity(0.45))
                }
                .buttonStyle(.plain)
                .help("Hide Floating Widget")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.03))

            Divider().background(Color.white.opacity(0.08))

            VStack(spacing: 5) {
                ForEach(store.symbols.prefix(8), id: \.self) { sym in
                    if let q = store.quotes[sym] {
                        HStack(spacing: 8) {
                            TickerLogoView(symbol: q.symbol, size: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(q.symbol)
                                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text(q.name)
                                    .font(.system(size: 9, weight: .regular))
                                    .foregroundColor(Color.white.opacity(0.45))
                                    .lineLimit(1)
                            }
                            .frame(width: 86, alignment: .leading)

                            SparklineView(points: q.sparkline, isPositive: q.isPositive)
                                .frame(width: 44, height: 16)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 1) {
                                Text(String(format: "$%.2f", q.price))
                                    .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text(String(format: "%@%.2f%%", q.isPositive ? "+" : "", q.changePercent))
                                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                    .foregroundColor(
                                        q.isPositive
                                            ? Color(red: 0.13, green: 0.84, blue: 0.48)
                                            : Color(red: 0.96, green: 0.32, blue: 0.38)
                                    )
                            }

                            Button(action: { store.removeSymbol(q.symbol) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Color.white.opacity(0.38))
                                    .frame(width: 16, height: 16)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .help("Remove \(q.symbol)")
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.white.opacity(0.025))
                        )
                        .onTapGesture {
                            store.autoCycleMenuBar = false
                            store.pinnedSymbol = q.symbol
                        }
                    }
                }
            }
            .padding(8)
        }
        .frame(width: 294)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.05, green: 0.055, blue: 0.075).opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var floatingPanel: NSPanel?
    private let store = TickerStore()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 364, height: 455)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PopoverContentView(store: store))

        setupFloatingPanel()

        store.onMenuBarUpdate = { [weak self] in
            self?.updateStatusItemButton()
        }
        store.onFloatingWidgetToggle = { [weak self] visible in
            if visible {
                self?.floatingPanel?.orderFront(nil)
            } else {
                self?.floatingPanel?.orderOut(nil)
            }
        }

        LogoCache.shared.$images
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItemButton()
            }
            .store(in: &cancellables)

        updateStatusItemButton()
        if store.showFloatingWidget {
            floatingPanel?.orderFront(nil)
        }
    }

    private func setupFloatingPanel() {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let panelWidth: CGFloat = 294
        let panelHeight: CGFloat = 270
        let initialRect = NSRect(
            x: screenRect.maxX - panelWidth - 24,
            y: screenRect.maxY - panelHeight - 24,
            width: panelWidth,
            height: panelHeight
        )

        let panel = NSPanel(
            contentRect: initialRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: FloatingWidgetView(store: store))
        self.floatingPanel = panel
    }

    private func updateStatusItemButton() {
        guard let button = statusItem.button else { return }
        guard let quote = store.activeMenuBarQuote else {
            button.title = " TICKBAR"
            return
        }

        let arrow = quote.isPositive ? "▲" : "▼"
        let text = String(format: " %@ $%.2f %@%.2f%%", quote.symbol, quote.price, arrow, abs(quote.changePercent))

        let attr = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attr.length)
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        attr.addAttribute(.font, value: font, range: fullRange)
        attr.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        if let arrowRange = text.range(of: arrow) {
            let nsRange = NSRange(arrowRange.lowerBound..<text.endIndex, in: text)
            let changeColor = quote.isPositive
                ? NSColor(calibratedRed: 0.13, green: 0.84, blue: 0.48, alpha: 1.0)
                : NSColor(calibratedRed: 0.96, green: 0.32, blue: 0.38, alpha: 1.0)
            attr.addAttribute(.foregroundColor, value: changeColor, range: nsRange)
        }

        button.attributedTitle = attr

        if let rawImg = LogoCache.shared.image(for: quote.symbol) {
            let sized = NSImage(size: NSSize(width: 16, height: 16))
            sized.lockFocus()
            NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 16, height: 16), xRadius: 4, yRadius: 4).addClip()
            rawImg.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
            sized.unlockFocus()
            sized.isTemplate = false
            button.image = sized
            button.imagePosition = .imageLeft
        } else {
            button.image = nil
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}

let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.run()
