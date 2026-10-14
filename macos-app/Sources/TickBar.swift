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
    var extendedPrice: Double?
    var extendedChange: Double?
    var extendedChangePercent: Double?
    var extendedLabel: String?
    var sparkline: [Double]
    var updatedAt: Date

    var isPositive: Bool {
        change >= 0
    }

    var isExtendedPositive: Bool {
        (extendedChange ?? 0) >= 0
    }
}

struct VisualEffectGlassView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = .active
    }
}

final class LogoCache: ObservableObject {
    static let shared = LogoCache()
    @Published private(set) var images: [String: NSImage] = [:]
    private var inFlight: Set<String> = []

    private let directLogoMap: [String: String] = [
        "NVDA": "https://s3-symbol-logo.tradingview.com/nvidia--big.svg",
        "AAPL": "https://s3-symbol-logo.tradingview.com/apple--big.svg",
        "TSLA": "https://s3-symbol-logo.tradingview.com/tesla--big.svg",
        "MSFT": "https://s3-symbol-logo.tradingview.com/microsoft--big.svg",
        "AMZN": "https://s3-symbol-logo.tradingview.com/amazon--big.svg",
        "META": "https://s3-symbol-logo.tradingview.com/meta-platforms--big.svg",
        "GOOG": "https://s3-symbol-logo.tradingview.com/alphabet--big.svg",
        "GOOGL": "https://s3-symbol-logo.tradingview.com/alphabet--big.svg",
        "PLTR": "https://s3-symbol-logo.tradingview.com/palantir--big.svg",
        "AMD": "https://s3-symbol-logo.tradingview.com/advanced-micro-devices--big.svg",
        "NFLX": "https://s3-symbol-logo.tradingview.com/netflix--big.svg",
        "COIN": "https://s3-symbol-logo.tradingview.com/coinbase--big.svg",
        "MSTR": "https://s3-symbol-logo.tradingview.com/strategy-cad-hedged-cibc-cdr--big.svg",
        "SPY": "https://s3-symbol-logo.tradingview.com/spdr-sandp500-etf-tr--big.svg",
        "QQQ": "https://s3-symbol-logo.tradingview.com/invesco--big.svg",
        "HOOD": "https://s3-symbol-logo.tradingview.com/robinhood--big.svg",
        "RKLB": "https://s3-symbol-logo.tradingview.com/rocket-lab--big.svg",
        "FLY": "https://s3-symbol-logo.tradingview.com/firefly-aerospace--big.svg",
        "SOFI": "https://s3-symbol-logo.tradingview.com/sofi--big.svg",
        "ASTS": "https://s3-symbol-logo.tradingview.com/ast-spacemobile--big.svg",
        "IONQ": "https://s3-symbol-logo.tradingview.com/ionq--big.svg",
        "AVGO": "https://s3-symbol-logo.tradingview.com/broadcom--big.svg",
        "ARM": "https://s3-symbol-logo.tradingview.com/arm--big.svg",
        "ORCL": "https://s3-symbol-logo.tradingview.com/oracle--big.svg",
        "CRWD": "https://s3-symbol-logo.tradingview.com/crowdstrike--big.svg",
        "UBER": "https://s3-symbol-logo.tradingview.com/uber--big.svg",
        "SHOP": "https://s3-symbol-logo.tradingview.com/shopify--big.svg",
        "MU": "https://s3-symbol-logo.tradingview.com/micron-technology--big.svg",
        "TSM": "https://s3-symbol-logo.tradingview.com/taiwan-semiconductor--big.svg",
        "ASML": "https://s3-symbol-logo.tradingview.com/asml--big.svg",
        "BTC-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCBTC--big.svg",
        "ETH-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCETH--big.svg",
        "SOL-USD": "https://s3-symbol-logo.tradingview.com/crypto/XTVCSOL--big.svg"
    ]

    private let domainMap: [String: String] = [
        "NVDA": "nvidia.com",
        "AAPL": "apple.com",
        "TSLA": "tesla.com",
        "MSFT": "microsoft.com",
        "AMZN": "amazon.com",
        "META": "meta.com",
        "GOOG": "abc.xyz",
        "GOOGL": "abc.xyz",
        "PLTR": "palantir.com",
        "AMD": "amd.com",
        "NFLX": "netflix.com",
        "COIN": "coinbase.com",
        "MSTR": "strategy.com",
        "SPY": "ssga.com",
        "QQQ": "invesco.com",
        "HOOD": "robinhood.com",
        "RKLB": "rocketlabusa.com",
        "FLY": "fireflyspace.com",
        "SOFI": "sofi.com",
        "ASTS": "ast-science.com",
        "IONQ": "ionq.com",
        "AVGO": "broadcom.com",
        "ARM": "arm.com",
        "ORCL": "oracle.com",
        "CRWD": "crowdstrike.com",
        "UBER": "uber.com",
        "SHOP": "shopify.com",
        "MU": "micron.com",
        "TSM": "tsmc.com",
        "ASML": "asml.com"
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
        if clean != "FLY" && clean != "MSTR",
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
            UserDefaults.standard.set(symbols, forKey: "tickbar.symbols.v2")
        }
    }
    @Published var pinnedSymbol: String {
        didSet {
            UserDefaults.standard.set(pinnedSymbol, forKey: "tickbar.pinnedSymbol.v2")
            onMenuBarUpdate?()
        }
    }
    @Published var autoCycleMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(autoCycleMenuBar, forKey: "tickbar.autoCycle")
            onMenuBarUpdate?()
        }
    }
    @Published var showExtendedInMenuBar: Bool {
        didSet {
            UserDefaults.standard.set(showExtendedInMenuBar, forKey: "tickbar.showExtendedInMenuBar")
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

    let popularPool: [String] = [
        "NVDA", "AAPL", "TSLA", "MSFT", "AMZN", "META", "GOOGL", "PLTR",
        "AMD", "NFLX", "COIN", "MSTR", "SPY", "QQQ", "HOOD", "RKLB",
        "FLY", "SOFI", "ASTS", "AVGO", "ARM", "TSM", "BTC-USD"
    ]

    var suggestedSymbols: [String] {
        popularPool
    }

    var onMenuBarUpdate: (() -> Void)?
    var onFloatingWidgetToggle: ((Bool) -> Void)?

    private var refreshTimer: Timer?
    private var cycleTimer: Timer?

    private let fallbackNames: [String: String] = [
        "NVDA": "NVIDIA Corp.",
        "AAPL": "Apple Inc.",
        "TSLA": "Tesla, Inc.",
        "MSFT": "Microsoft Corp.",
        "AMZN": "Amazon.com, Inc.",
        "META": "Meta Platforms",
        "GOOGL": "Alphabet Inc.",
        "GOOG": "Alphabet Inc.",
        "PLTR": "Palantir Technologies",
        "AMD": "Advanced Micro Devices",
        "NFLX": "Netflix, Inc.",
        "COIN": "Coinbase Global",
        "MSTR": "Strategy Inc.",
        "SPY": "SPDR S&P 500 ETF",
        "QQQ": "Invesco QQQ Trust",
        "HOOD": "Robinhood Markets",
        "RKLB": "Rocket Lab USA",
        "FLY": "Firefly Aerospace",
        "SOFI": "SoFi Technologies",
        "ASTS": "AST SpaceMobile",
        "AVGO": "Broadcom Inc.",
        "ARM": "Arm Holdings",
        "TSM": "Taiwan Semiconductor",
        "BTC-USD": "Bitcoin USD",
        "ETH-USD": "Ethereum USD",
        "SOL-USD": "Solana USD"
    ]

    init() {
        let savedSymbols = UserDefaults.standard.stringArray(forKey: "tickbar.symbols.v2")
        let defaultList = ["NVDA", "AAPL", "TSLA", "MSFT", "META", "PLTR", "AMD", "AMZN"]
        self.symbols = (savedSymbols?.isEmpty == false) ? savedSymbols! : defaultList
        self.pinnedSymbol = UserDefaults.standard.string(forKey: "tickbar.pinnedSymbol.v2") ?? "NVDA"
        self.autoCycleMenuBar = UserDefaults.standard.bool(forKey: "tickbar.autoCycle")
        if UserDefaults.standard.object(forKey: "tickbar.showExtendedInMenuBar") == nil {
            self.showExtendedInMenuBar = true
        } else {
            self.showExtendedInMenuBar = UserDefaults.standard.bool(forKey: "tickbar.showExtendedInMenuBar")
        }
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
            StockQuote(symbol: "NVDA", name: "NVIDIA Corp.", price: 221.30, previousClose: 228.52, change: -7.22, changePercent: -3.16, dayHigh: 226.40, dayLow: 219.80, extendedPrice: 221.36, extendedChange: 0.06, extendedChangePercent: 0.03, extendedLabel: "AH", sparkline: [228.5, 226.1, 224.8, 223.2, 222.0, 220.9, 221.6, 221.30], updatedAt: Date()),
            StockQuote(symbol: "AAPL", name: "Apple Inc.", price: 342.96, previousClose: 341.25, change: 1.71, changePercent: 0.50, dayHigh: 344.20, dayLow: 340.80, extendedPrice: 342.99, extendedChange: 0.03, extendedChangePercent: 0.01, extendedLabel: "AH", sparkline: [341.2, 341.8, 342.1, 341.9, 342.6, 343.1, 342.8, 342.96], updatedAt: Date()),
            StockQuote(symbol: "TSLA", name: "Tesla, Inc.", price: 367.16, previousClose: 375.22, change: -8.06, changePercent: -2.15, dayHigh: 374.50, dayLow: 365.40, extendedPrice: 366.80, extendedChange: -0.36, extendedChangePercent: -0.10, extendedLabel: "AH", sparkline: [375.2, 373.4, 371.0, 369.8, 368.5, 367.9, 366.9, 367.16], updatedAt: Date()),
            StockQuote(symbol: "MSFT", name: "Microsoft Corp.", price: 533.69, previousClose: 543.47, change: -9.78, changePercent: -1.80, dayHigh: 541.20, dayLow: 532.10, extendedPrice: 533.05, extendedChange: -0.64, extendedChangePercent: -0.12, extendedLabel: "AH", sparkline: [543.4, 540.8, 538.9, 536.5, 535.1, 534.0, 533.2, 533.69], updatedAt: Date()),
            StockQuote(symbol: "META", name: "Meta Platforms", price: 737.54, previousClose: 762.47, change: -24.93, changePercent: -3.27, dayHigh: 758.00, dayLow: 735.10, extendedPrice: 737.75, extendedChange: 0.21, extendedChangePercent: 0.03, extendedLabel: "AH", sparkline: [762.4, 756.0, 750.2, 746.8, 742.1, 739.5, 738.0, 737.54], updatedAt: Date()),
            StockQuote(symbol: "PLTR", name: "Palantir Technologies", price: 200.97, previousClose: 208.67, change: -7.70, changePercent: -3.69, dayHigh: 206.80, dayLow: 199.50, extendedPrice: 199.82, extendedChange: -1.15, extendedChangePercent: -0.57, extendedLabel: "AH", sparkline: [208.6, 206.2, 204.5, 203.1, 202.0, 201.4, 200.6, 200.97], updatedAt: Date()),
            StockQuote(symbol: "AMD", name: "Advanced Micro Devices", price: 570.82, previousClose: 605.51, change: -34.69, changePercent: -5.73, dayHigh: 598.40, dayLow: 568.10, extendedPrice: 568.56, extendedChange: -2.26, extendedChangePercent: -0.40, extendedLabel: "AH", sparkline: [605.5, 597.2, 589.4, 582.0, 577.5, 573.8, 571.2, 570.82], updatedAt: Date()),
            StockQuote(symbol: "AMZN", name: "Amazon.com, Inc.", price: 254.08, previousClose: 258.58, change: -4.50, changePercent: -1.74, dayHigh: 257.90, dayLow: 253.20, extendedPrice: 253.50, extendedChange: -0.58, extendedChangePercent: -0.23, extendedLabel: "AH", sparkline: [258.5, 257.4, 256.2, 255.8, 254.9, 254.3, 253.9, 254.08], updatedAt: Date())
        ]
        for q in seed {
            quotes[q.symbol] = q
            LogoCache.shared.fetchLogoIfNeeded(for: q.symbol)
        }
    }

    func shuffleWatchlist() {
        let shuffled = Array(popularPool.shuffled().prefix(7))
        symbols = shuffled
        if let first = shuffled.first {
            pinnedSymbol = first
        }
        refreshAll()
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
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=5m&range=1d&includePrePost=true") else {
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

            let timestamps = (first["timestamp"] as? [Int]) ?? []
            var closes: [Double] = []
            var lastValidTs: Int = 0
            var lastValidClose: Double = regularPrice

            if let indicators = first["indicators"] as? [String: Any],
               let quoteArr = indicators["quote"] as? [[String: Any]],
               let quoteObj = quoteArr.first,
               let rawCloses = quoteObj["close"] as? [Any] {
                for (i, item) in rawCloses.enumerated() {
                    if let val = item as? Double {
                        closes.append(val)
                        if i < timestamps.count {
                            lastValidTs = timestamps[i]
                            lastValidClose = val
                        }
                    }
                }
            }

            var extPrice: Double? = nil
            var extChange: Double? = nil
            var extPct: Double? = nil
            var extLabel: String? = nil

            let hasPrePost = (meta["hasPrePostMarketData"] as? Bool) ?? false
            if hasPrePost,
               let period = meta["currentTradingPeriod"] as? [String: Any] {
                let regDict = period["regular"] as? [String: Any]
                let preDict = period["pre"] as? [String: Any]
                let regEnd = (regDict?["end"] as? Int) ?? 0
                let regStart = (regDict?["start"] as? Int) ?? 0
                let preStart = (preDict?["start"] as? Int) ?? 0

                if regEnd > 0 && lastValidTs > regEnd && regularPrice > 0 {
                    extLabel = "AH"
                    extPrice = lastValidClose
                    let d = lastValidClose - regularPrice
                    extChange = d
                    extPct = (d / regularPrice) * 100.0
                } else if preStart > 0 && regStart > 0 && lastValidTs >= preStart && lastValidTs < regStart && prevClose > 0 {
                    extLabel = "PM"
                    extPrice = lastValidClose
                    let d = lastValidClose - prevClose
                    extChange = d
                    extPct = (d / prevClose) * 100.0
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
                extendedPrice: extPrice,
                extendedChange: extChange,
                extendedChangePercent: extPct,
                extendedLabel: extLabel,
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
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let nsImg = cache.image(for: symbol) {
                Image(nsImage: nsImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            } else {
                Text(String(symbol.prefix(3)))
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.32), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 1.5)
    }
}

struct SparklineView: View {
    let points: [Double]
    let isPositive: Bool

    var strokeColor: Color {
        isPositive
            ? Color(red: 0.19, green: 0.86, blue: 0.49)
            : Color(red: 1.00, green: 0.36, blue: 0.40)
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
                        gradient: Gradient(colors: [strokeColor.opacity(0.28), strokeColor.opacity(0.0)]),
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
            ? Color(red: 0.19, green: 0.86, blue: 0.49)
            : Color(red: 1.00, green: 0.36, blue: 0.40)
    }

    private var extendedColor: Color {
        quote.isExtendedPositive
            ? Color(red: 0.25, green: 0.88, blue: 0.56)
            : Color(red: 1.00, green: 0.45, blue: 0.48)
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onPin) {
                TickerLogoView(symbol: quote.symbol, size: 34)
                    .overlay(alignment: .topTrailing) {
                        if isPinned {
                            Circle()
                                .fill(Color(red: 0.19, green: 0.86, blue: 0.49))
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 1))
                                .offset(x: 2, y: -2)
                        }
                    }
            }
            .buttonStyle(.plain)
            .help("Pin \(quote.symbol) in macOS Menu Bar")

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(quote.symbol)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    if isPinned {
                        Text("BAR")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.19, green: 0.86, blue: 0.49))
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color(red: 0.19, green: 0.86, blue: 0.49).opacity(0.16)))
                    }
                }
                Text(quote.name)
                    .font(.system(size: 10.5, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.54))
                    .lineLimit(1)
            }
            .frame(width: 104, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                onPin()
            }

            SparklineView(points: quote.sparkline, isPositive: quote.isPositive)
                .frame(width: 50, height: 22)

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2.5) {
                HStack(spacing: 5) {
                    Text(String(format: "$%.2f", quote.price))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(String(format: "%@%.2f%%", quote.isPositive ? "+" : "", quote.changePercent))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(changeColor)
                        .padding(.horizontal, 5.5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(changeColor.opacity(0.15)))
                }

                if let extLabel = quote.extendedLabel,
                   let extPrice = quote.extendedPrice,
                   let extPct = quote.extendedChangePercent {
                    HStack(spacing: 3.5) {
                        Text(extLabel)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.62, green: 0.76, blue: 1.0))
                            .padding(.horizontal, 3.5)
                            .padding(.vertical, 0.5)
                            .background(Capsule().fill(Color(red: 0.42, green: 0.62, blue: 1.0).opacity(0.18)))

                        Text(String(format: "$%.2f", extPrice))
                            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.75))

                        Text(String(format: "%@%.2f%%", quote.isExtendedPositive ? "+" : "", extPct))
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(extendedColor)
                    }
                }
            }

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(isHovered ? Color(red: 1.0, green: 0.36, blue: 0.40) : Color.white.opacity(0.42))
                    .frame(width: 20, height: 20)
                    .background(
                        Circle()
                            .fill(isHovered ? Color(red: 1.0, green: 0.36, blue: 0.40).opacity(0.18) : Color.white.opacity(0.07))
                    )
            }
            .buttonStyle(.plain)
            .help("Remove \(quote.symbol)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7.5)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? 0.12 : 0.065),
                            Color.white.opacity(isHovered ? 0.06 : 0.025)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    isPinned ? Color(red: 0.19, green: 0.86, blue: 0.49).opacity(0.45) : Color.white.opacity(0.22),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.9
                        )
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
        ZStack {
            VisualEffectGlassView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.68),
                    Color(red: 0.04, green: 0.05, blue: 0.09).opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // macOS 27 Liquid Glass Header
                HStack(spacing: 7) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.19, green: 0.86, blue: 0.49))
                            .frame(width: 7, height: 7)
                            .shadow(color: Color(red: 0.19, green: 0.86, blue: 0.49).opacity(0.8), radius: 4)
                        Text("TickBar")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("24/5 + AH")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.65, green: 0.80, blue: 1.0))
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color(red: 0.35, green: 0.60, blue: 1.0).opacity(0.18)))
                    }

                    Spacer()

                    Button(action: { store.shuffleWatchlist() }) {
                        HStack(spacing: 3.5) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 9.5, weight: .semibold))
                            Text("Shuffle")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(Color.white.opacity(0.82))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.09)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Randomize Popular Watchlist")

                    Button(action: { store.showFloatingWidget.toggle() }) {
                        HStack(spacing: 3.5) {
                            Image(systemName: store.showFloatingWidget ? "pip.fill" : "pip")
                                .font(.system(size: 9.5))
                            Text("Widget")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(store.showFloatingWidget ? Color(red: 0.19, green: 0.86, blue: 0.49) : Color.white.opacity(0.72))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.09)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Floating Liquid Glass Widget")

                    Button(action: { store.refreshAll() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.white.opacity(0.82))
                            .frame(width: 24, height: 22)
                            .background(Capsule().fill(Color.white.opacity(0.09)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Refresh Yahoo Finance Quotes")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)

                Divider().background(Color.white.opacity(0.10))

                // Add Ticker Pill Bar + Quick-Add Chips
                VStack(spacing: 7) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.50))

                        TextField("Add ticker (NVDA, TSLA, FLY, MSTR, BTC-USD)...", text: $store.newTickerInput, onCommit: {
                            store.addSymbol(store.newTickerInput)
                            store.newTickerInput = ""
                        })
                        .textFieldStyle(.plain)
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundColor(.white)

                        Button(action: {
                            store.addSymbol(store.newTickerInput)
                            store.newTickerInput = ""
                        }) {
                            Text("+ Add")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(red: 0.19, green: 0.86, blue: 0.49)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.26))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                            )
                    )

                    if !availableSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(availableSuggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        store.addSymbol(suggestion)
                                    }) {
                                        Text("+\(suggestion)")
                                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                            .foregroundColor(Color.white.opacity(0.78))
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(Color.white.opacity(0.07)))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.14), lineWidth: 0.7)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 9)

                Divider().background(Color.white.opacity(0.10))

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
                                    TickerLogoView(symbol: sym, size: 32)
                                    Text(sym)
                                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("Syncing Yahoo...")
                                        .font(.system(size: 10.5, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.48))
                                    Button(action: { store.removeSymbol(sym) }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8.5, weight: .bold))
                                            .foregroundColor(Color.white.opacity(0.5))
                                            .frame(width: 20, height: 20)
                                            .background(Circle().fill(Color.white.opacity(0.08)))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.04))
                                )
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(maxHeight: 330)

                Divider().background(Color.white.opacity(0.10))

                // Footer controls
                HStack(spacing: 12) {
                    Toggle(isOn: $store.autoCycleMenuBar) {
                        Text("Cycle Bar")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.72))
                    }
                    .toggleStyle(.checkbox)

                    Toggle(isOn: $store.showExtendedInMenuBar) {
                        Text("Show AH/PM in Bar")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.72))
                    }
                    .toggleStyle(.checkbox)

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.50))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
            }
        }
        .frame(width: 392)
    }
}

struct FloatingWidgetView: View {
    @ObservedObject var store: TickerStore

    var body: some View {
        ZStack {
            VisualEffectGlassView(material: .hudWindow, blendingMode: .behindWindow)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.11, blue: 0.17).opacity(0.62),
                    Color(red: 0.04, green: 0.05, blue: 0.09).opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(spacing: 0) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(red: 0.19, green: 0.86, blue: 0.49))
                        .frame(width: 6, height: 6)
                    Text("TickBar Glass")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.92))
                    Text("YAHOO LIVE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(red: 0.19, green: 0.86, blue: 0.49))
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color(red: 0.19, green: 0.86, blue: 0.49).opacity(0.15)))

                    Spacer()

                    Button(action: { store.shuffleWatchlist() }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.65))
                    }
                    .buttonStyle(.plain)
                    .help("Shuffle Watchlist")

                    Button(action: { store.showFloatingWidget = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color.white.opacity(0.50))
                    }
                    .buttonStyle(.plain)
                    .help("Hide Floating Widget")
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 9)

                Divider().background(Color.white.opacity(0.10))

                VStack(spacing: 5) {
                    ForEach(store.symbols.prefix(8), id: \.self) { sym in
                        if let q = store.quotes[sym] {
                            HStack(spacing: 8) {
                                TickerLogoView(symbol: q.symbol, size: 26)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(q.symbol)
                                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(q.name)
                                        .font(.system(size: 9, weight: .regular))
                                        .foregroundColor(Color.white.opacity(0.50))
                                        .lineLimit(1)
                                }
                                .frame(width: 82, alignment: .leading)

                                SparklineView(points: q.sparkline, isPositive: q.isPositive)
                                    .frame(width: 40, height: 16)

                                Spacer()

                                VStack(alignment: .trailing, spacing: 1.5) {
                                    HStack(spacing: 4) {
                                        Text(String(format: "$%.2f", q.price))
                                            .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Text(String(format: "%@%.2f%%", q.isPositive ? "+" : "", q.changePercent))
                                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                            .foregroundColor(
                                                q.isPositive
                                                    ? Color(red: 0.19, green: 0.86, blue: 0.49)
                                                    : Color(red: 1.00, green: 0.36, blue: 0.40)
                                            )
                                    }

                                    if let extLabel = q.extendedLabel,
                                       let extPrice = q.extendedPrice,
                                       let extPct = q.extendedChangePercent {
                                        Text(String(format: "%@ $%.2f (%@%.2f%%)", extLabel, extPrice, q.isExtendedPositive ? "+" : "", extPct))
                                            .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                                            .foregroundColor(Color(red: 0.65, green: 0.80, blue: 1.0))
                                    }
                                }

                                Button(action: { store.removeSymbol(q.symbol) }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 7.5, weight: .bold))
                                        .foregroundColor(Color.white.opacity(0.42))
                                        .frame(width: 16, height: 16)
                                        .background(Circle().fill(Color.white.opacity(0.07)))
                                }
                                .buttonStyle(.plain)
                                .help("Remove \(q.symbol)")
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5.5)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.045))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(Color.white.opacity(0.10), lineWidth: 0.6)
                                    )
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
        }
        .frame(width: 318)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
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
        popover.contentSize = NSSize(width: 392, height: 485)
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
        let panelWidth: CGFloat = 318
        let panelHeight: CGFloat = 310
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
            button.title = " TickBar"
            return
        }

        let arrow = quote.isPositive ? "▲" : "▼"
        var text = String(format: " %@ $%.2f %@%.2f%%", quote.symbol, quote.price, arrow, abs(quote.changePercent))

        var extSuffixRange: Range<String.Index>? = nil
        if store.showExtendedInMenuBar,
           let extLabel = quote.extendedLabel,
           let extPrice = quote.extendedPrice,
           let extPct = quote.extendedChangePercent {
            let extArrow = quote.isExtendedPositive ? "▲" : "▼"
            let suffix = String(format: " · %@ $%.2f %@%.2f%%", extLabel, extPrice, extArrow, abs(extPct))
            let startIdx = text.endIndex
            text += suffix
            extSuffixRange = startIdx..<text.endIndex
        }

        let attr = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: attr.length)
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        attr.addAttribute(.font, value: font, range: fullRange)
        attr.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        if let arrowRange = text.range(of: arrow) {
            let endBound = extSuffixRange?.lowerBound ?? text.endIndex
            let nsRange = NSRange(arrowRange.lowerBound..<endBound, in: text)
            let changeColor = quote.isPositive
                ? NSColor(calibratedRed: 0.19, green: 0.86, blue: 0.49, alpha: 1.0)
                : NSColor(calibratedRed: 1.00, green: 0.36, blue: 0.40, alpha: 1.0)
            attr.addAttribute(.foregroundColor, value: changeColor, range: nsRange)
        }

        if let extRange = extSuffixRange {
            let nsExtRange = NSRange(extRange, in: text)
            let extFont = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
            let extColor = NSColor(calibratedRed: 0.56, green: 0.76, blue: 1.0, alpha: 0.95)
            attr.addAttribute(.font, value: extFont, range: nsExtRange)
            attr.addAttribute(.foregroundColor, value: extColor, range: nsExtRange)
        }

        button.attributedTitle = attr

        if let rawImg = LogoCache.shared.image(for: quote.symbol) {
            let sized = NSImage(size: NSSize(width: 16, height: 16))
            sized.lockFocus()
            NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 16, height: 16), xRadius: 4.5, yRadius: 4.5).addClip()
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
