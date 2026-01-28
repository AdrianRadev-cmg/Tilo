import Foundation

// MARK: - App Group Identifier
// This must match the App Group configured in both the main app and widget entitlements
let appGroupIdentifier = "group.com.adriyanradev.tilo.shared"

// MARK: - Shared UserDefaults
extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}

// MARK: - Currency Pair Model (for sharing between app and widget)
struct CurrencyPair: Codable, Equatable {
    let fromCode: String
    let fromName: String
    let fromFlag: String
    let toCode: String
    let toName: String
    let toFlag: String
    let lastUpdated: Date
    
    // Cached exchange rate (optional, for offline display)
    var exchangeRate: Double?
    
    init(fromCode: String, fromName: String, fromFlag: String,
         toCode: String, toName: String, toFlag: String,
         exchangeRate: Double? = nil,
         lastUpdated: Date = Date()) {
        self.fromCode = fromCode
        self.fromName = fromName
        self.fromFlag = fromFlag
        self.toCode = toCode
        self.toName = toName
        self.toFlag = toFlag
        self.lastUpdated = lastUpdated
        self.exchangeRate = exchangeRate
    }
}

// MARK: - Widget Analytics Event (stored for later sending)
struct WidgetAnalyticsEvent: Codable {
    let eventName: String
    let timestamp: Date
    let properties: [String: String]
}

// MARK: - Shared Data Manager
class SharedCurrencyDataManager {
    static let shared = SharedCurrencyDataManager()
    
    private let currencyPairKey = "currentCurrencyPair"
    private let cachedConversionsKey = "cachedWidgetConversions"
    private let widgetEventsKey = "pendingWidgetEvents"
    
    private init() {}
    
    // MARK: - Widget Analytics
    
    /// Get and clear pending widget events (called by main app on launch)
    func flushWidgetEvents() -> [WidgetAnalyticsEvent] {
        let events = pendingWidgetEvents
        pendingWidgetEvents = []
        return events
    }
    
    private var pendingWidgetEvents: [WidgetAnalyticsEvent] {
        get {
            guard let data = UserDefaults.shared.data(forKey: widgetEventsKey),
                  let events = try? JSONDecoder().decode([WidgetAnalyticsEvent].self, from: data) else {
                return []
            }
            return events
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.shared.set(data, forKey: widgetEventsKey)
            }
        }
    }
    
    // MARK: - Currency Pair
    
    var currentCurrencyPair: CurrencyPair? {
        get {
            guard let data = UserDefaults.shared.data(forKey: currencyPairKey),
                  let pair = try? JSONDecoder().decode(CurrencyPair.self, from: data) else {
                return defaultCurrencyPair
            }
            return pair
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.shared.set(data, forKey: currencyPairKey)
            }
        }
    }
    
    // Default currency pair if none saved
    private var defaultCurrencyPair: CurrencyPair {
        CurrencyPair(
            fromCode: "GBP",
            fromName: "British Pound",
            fromFlag: "🇬🇧",
            toCode: "EUR",
            toName: "Euro",
            toFlag: "🇪🇺"
        )
    }
    
    // MARK: - Cached Conversions (for widget display)
    
    struct CachedConversion: Codable {
        let fromAmount: Double
        let toAmount: Double
    }
    
    var cachedConversions: [CachedConversion]? {
        get {
            guard let data = UserDefaults.shared.data(forKey: cachedConversionsKey),
                  let conversions = try? JSONDecoder().decode([CachedConversion].self, from: data) else {
                return nil
            }
            return conversions
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.shared.set(data, forKey: cachedConversionsKey)
            }
        }
    }
    
    // MARK: - Quick Amounts (based on currency strength)
    
    func getWidgetAmounts(for currencyCode: String, count: Int) -> [Double] {
        let allAmounts = getTableAmounts(for: currencyCode)
        return Array(allAmounts.prefix(count))
    }
    
    private func getTableAmounts(for currencyCode: String) -> [Double] {
        // Very high-value currencies
        let veryHighValue = ["KWD", "BHD", "OMR", "JOD", "GBP", "CHF", "KYD", "GIP", "FKP"]
        if veryHighValue.contains(currencyCode) {
            return [10, 20, 50, 100, 200, 500, 1000, 2000]
        }
        
        // High-value currencies
        let highValue = [
            "EUR", "USD", "CAD", "AUD", "NZD", "SGD", "AED", "SAR", "QAR",
            "ILS", "BND", "BSD", "PAB", "FJD", "BWP", "AZN", "RON", "GEL",
            "PEN", "BOB", "GTQ", "BBD", "TTD", "MUR", "MVR",
            "BMD", "BZD", "AWG", "XCD", "SHP", "GGP", "IMP", "JEP", "BAM", "BYN"
        ]
        if highValue.contains(currencyCode) {
            return [10, 20, 50, 100, 200, 500, 1000, 2000]
        }
        
        // Medium-value currencies
        let mediumValue = [
            "CNY", "HKD", "TWD", "SEK", "NOK", "DKK", "PLN", "CZK", "MXN", "ZAR",
            "BRL", "MYR", "TRY", "EGP", "RUB", "MDL", "MKD", "UAH", "RSD", "JMD",
            "DOP", "HNL", "NIO", "MAD", "TND", "GHS", "NAD",
            "DZD", "CRC", "MOP", "CVE", "GYD", "SRD", "LSL", "SZL", "ANG", "SCR",
            "GMD", "MWK", "MZN", "HTG", "LYD", "IQD", "SVC", "XAF", "XOF", "XPF",
            "AOA", "ERN", "ETB", "CDF", "SDG", "TOP", "WST"
        ]
        if mediumValue.contains(currencyCode) {
            return [50, 100, 200, 500, 1000, 2000, 5000, 10000]
        }
        
        // Lower-medium currencies
        let lowerMedium = ["THB", "INR", "PHP", "KES", "UGX", "TZS", "NPR", "BTN", "AFN", "MRU", "LRD"]
        if lowerMedium.contains(currencyCode) {
            return [100, 200, 500, 1000, 2000, 5000, 10000, 20000]
        }
        
        // Low-value currencies
        let lowValue = [
            "JPY", "KRW", "HUF", "ISK", "CLP", "ARS", "COP", "PKR", "LKR", "BDT",
            "MMK", "NGN", "AMD", "KZT", "KGS", "ALL", "RWF", "BIF", "DJF", "GNF",
            "KMF", "MGA", "PYG", "KHR", "MNT",
            "UYU", "CUP", "CUC", "SOS", "TJS", "TMT", "YER", "ZMW", "PGK", "SBD",
            "VUV", "KPW", "SLE", "CLF"
        ]
        if lowValue.contains(currencyCode) {
            return [500, 1000, 2000, 5000, 10000, 20000, 50000, 100000]
        }
        
        // Very low-value currencies
        let veryLowValue = [
            "VND", "IDR", "IRR", "LAK", "UZS", "SLL", "LBP", "SYP", "STN", "VES", "ZWG"
        ]
        if veryLowValue.contains(currencyCode) {
            return [10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000]
        }
        
        // Default
        return [10, 20, 50, 100, 200, 500, 1000, 2000]
    }
}

