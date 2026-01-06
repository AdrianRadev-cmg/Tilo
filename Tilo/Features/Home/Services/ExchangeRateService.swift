import Foundation
import SwiftUI

// MARK: - API Response Models
struct CurrencyAPIResponse: Codable {
    let data: [String: CurrencyRate]
}

struct CurrencyRate: Codable {
    let code: String
    let value: Double
}

// MARK: - Cached Rates Model (Codable for persistence)
struct CachedRates: Codable {
    let rates: [String: Double]
    let timestamp: Date
    let baseCurrency: String
    
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
    
    var isExpired: Bool {
        age > CacheConfig.currentRatesExpiration
    }
    
    var isStale: Bool {
        age > CacheConfig.staleThreshold
    }
    
    var ageDescription: String {
        let minutes = Int(age / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            return "\(hours)h ago"
        }
    }
}

// MARK: - Historical Data Models (Codable for persistence)
struct HistoricalRate: Codable {
    let date: Date
    let rate: Double
}

struct CachedHistoricalData: Codable {
    let data: [HistoricalRate]
    let timestamp: Date
    let fromCurrency: String
    let toCurrency: String
    
    var isExpired: Bool {
        // Cache expires after 24 hours (historical data doesn't change)
        Date().timeIntervalSince(timestamp) > (24 * 60 * 60)
    }
}

// MARK: - Cache Configuration
struct CacheConfig {
    // Market hours: Mon-Fri, 8am-8pm UTC
    static var isMarketHours: Bool {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        let hour = calendar.component(.hour, from: now)
        
        // Weekend (Saturday = 7, Sunday = 1)
        if weekday == 1 || weekday == 7 {
            return false
        }
        
        // Check if within 8am-8pm UTC
        return hour >= 8 && hour < 20
    }
    
    // Cache expiration based on market hours
    static var currentRatesExpiration: TimeInterval {
        if isMarketHours {
            return 2 * 60 * 60 // 2 hours during market hours
        } else {
            return 4 * 60 * 60 // 4 hours off-market
        }
    }
    
    // Stale threshold for background refresh (triggers refresh but returns cached data)
    static let staleThreshold: TimeInterval = 1 * 60 * 60 // 1 hour
    
    // Background refresh cooldown (prevents multiple refreshes)
    static let backgroundRefreshCooldown: TimeInterval = 1 * 60 * 60 // 1 hour
    
    // Historical data expiration (doesn't change often)
    static let historicalExpiration: TimeInterval = 24 * 60 * 60 // 24 hours
}

// API Response for historical data
struct HistoricalAPIResponse: Codable {
    let data: [String: [String: CurrencyRate]]
}

// MARK: - Range API Models  
struct RangeAPIResponse: Codable {
    let meta: RangeMeta
    let data: [String: [String: CurrencyRate]] // Date -> Currency -> Rate
}

struct RangeMeta: Codable {
    let start_date: String
    let end_date: String
    let base_currency: String
}

// MARK: - Exchange Rate Service
@MainActor
class ExchangeRateService: ObservableObject {
    // Published properties for UI updates
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var cacheAge: String = ""
    @Published var isOffline: Bool = false
    
    // Private properties
    private var apiKey: String { APIKeyManager.apiKey }
    private let baseURL = "https://api.currencyapi.com/v3/latest"
    private let historicalURL = "https://api.currencyapi.com/v3/historical"
    private let rangeURL = "https://api.currencyapi.com/v3/range"
    private let baseCurrency = "USD"
    
    // Persistence keys
    private let cachedRatesKey = "cachedExchangeRates"
    private let cachedHistoricalKey = "cachedHistoricalRates"
    
    // Cache storage (in-memory + persisted)
    private var cachedRates: CachedRates? {
        didSet {
            if let rates = cachedRates {
                saveCachedRatesToDisk(rates)
                cacheAge = rates.ageDescription
            }
        }
    }
    private var cachedHistoricalData: [String: CachedHistoricalData] = [:] {
        didSet {
            saveCachedHistoricalToDisk(cachedHistoricalData)
        }
    }
    
    // Background refresh cooldown tracking
    private var lastBackgroundRefresh: Date?
    
    // Fallback rates used only when API fails and no cache exists
    private let fallbackRates: [String: Double] = [
        "USD": 1.0,
        "KWD": 0.31, "BHD": 0.38, "OMR": 0.38, "JOD": 0.71, "GBP": 0.79,
        "EUR": 0.92, "CHF": 0.91, "CAD": 1.36, "AUD": 1.52, "NZD": 1.65,
        "SGD": 1.35, "AED": 3.67, "SAR": 3.75, "QAR": 3.64, "ILS": 3.72,
        "BND": 1.35, "BSD": 1.0, "PAB": 1.0, "FJD": 2.27, "BWP": 13.5,
        "AZN": 1.70, "RON": 4.56, "BGN": 1.80, "GEL": 2.70, "PEN": 3.75,
        "BOB": 6.91, "GTQ": 7.75, "UAH": 41.2, "RSD": 107.5, "JMD": 154.5,
        "BBD": 2.0, "TTD": 6.78, "MUR": 45.8, "MVR": 15.4,
        "CNY": 7.23, "HKD": 7.82, "TWD": 31.5, "SEK": 10.35, "NOK": 10.62,
        "DKK": 6.87, "PLN": 4.02, "CZK": 23.1, "MXN": 17.2, "ZAR": 18.5,
        "BRL": 5.02, "INR": 83.2, "THB": 34.5, "MYR": 4.47, "PHP": 56.3,
        "TRY": 32.5, "EGP": 48.8, "RUB": 92.5, "MDL": 17.8, "MKD": 56.4,
        "DOP": 59.8, "HNL": 24.7, "NIO": 36.8, "MAD": 9.87, "TND": 3.11,
        "KES": 129.5, "UGX": 3685.0, "TZS": 2505.0, "GHS": 15.2, "NAD": 18.5,
        "JPY": 149.5, "KRW": 1325.0, "HUF": 360.5, "ISK": 137.2, "CLP": 920.0,
        "ARS": 850.0, "COP": 3925.0, "PKR": 278.5, "LKR": 305.0, "BDT": 110.5,
        "MMK": 2098.0, "NGN": 1580.0, "AMD": 386.0, "KZT": 452.0, "KGS": 87.5,
        "ALL": 92.3, "RWF": 1298.0, "BIF": 2865.0, "DJF": 178.0, "GNF": 8590.0,
        "KMF": 452.0, "MGA": 4520.0, "PYG": 7350.0, "KHR": 4095.0, "MNT": 3420.0,
        "VND": 24500.0, "IDR": 15780.0, "IRR": 42050.0, "LAK": 21850.0, "UZS": 12750.0,
        "SLL": 19750.0, "LBP": 89500.0, "SYP": 13000.0, "STN": 22.5, "VES": 36.5
    ]
    
    // Singleton instance
    static let shared = ExchangeRateService()
    
    private init() {
        loadCachedRatesFromDisk()
        loadCachedHistoricalFromDisk()
        
        if let rates = cachedRates {
            lastUpdated = rates.timestamp
            cacheAge = rates.ageDescription
        }
    }
    
    // MARK: - Persistence Methods
    
    private func saveCachedRatesToDisk(_ rates: CachedRates) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.shared.set(data, forKey: cachedRatesKey)
        }
    }
    
    private func loadCachedRatesFromDisk() {
        if let data = UserDefaults.shared.data(forKey: cachedRatesKey),
           let rates = try? JSONDecoder().decode(CachedRates.self, from: data) {
            cachedRates = rates
        }
    }
    
    private func saveCachedHistoricalToDisk(_ historical: [String: CachedHistoricalData]) {
        if let data = try? JSONEncoder().encode(historical) {
            UserDefaults.shared.set(data, forKey: cachedHistoricalKey)
        }
    }
    
    private func loadCachedHistoricalFromDisk() {
        if let data = UserDefaults.shared.data(forKey: cachedHistoricalKey),
           let historical = try? JSONDecoder().decode([String: CachedHistoricalData].self, from: data) {
            cachedHistoricalData = historical
        }
    }
    
    // MARK: - Debug Methods (only available in DEBUG builds)
    
    #if DEBUG
    /// Toggle mock mode for testing (DEBUG only)
    @Published var isMockMode: Bool = false
    
    func toggleMockMode() {
        isMockMode.toggle()
    }
    
    func setMockMode(_ enabled: Bool) {
        isMockMode = enabled
    }
    
    var modeDescription: String {
        return isMockMode ? "🧪 Mock Mode" : "🌐 Live Mode"
    }
    #endif
    
    /// Clear all cached data
    func clearCache() {
        cachedRates = nil
        cachedHistoricalData.removeAll()
        UserDefaults.shared.removeObject(forKey: cachedRatesKey)
        UserDefaults.shared.removeObject(forKey: cachedHistoricalKey)
        cacheAge = ""
    }
    
    // MARK: - Public Methods
    
    /// Fetch latest exchange rates from API or cache
    func fetchRates() async throws -> [String: Double] {
        #if DEBUG
        if isMockMode {
            lastUpdated = Date()
            errorMessage = nil
            isOffline = false
            return fallbackRates
        }
        #endif
        
        // If we have cached data
        if let cached = cachedRates {
            // Fresh cache - use immediately
            if !cached.isExpired {
                lastUpdated = cached.timestamp
                cacheAge = cached.ageDescription
                isOffline = false
                
                // If stale, trigger background refresh
                if cached.isStale && canBackgroundRefresh() {
                    Task {
                        await refreshRatesInBackground()
                    }
                }
                
                return cached.rates
            }
        }
        
        // No cache or expired - fetch fresh data
        return try await fetchFreshRates()
    }
    
    /// Force refresh rates (ignores cache)
    func forceRefresh() async throws -> [String: Double] {
        return try await fetchFreshRates()
    }
    
    /// Check if background refresh is allowed (cooldown check)
    private func canBackgroundRefresh() -> Bool {
        guard let lastRefresh = lastBackgroundRefresh else {
            return true
        }
        
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
        return timeSinceLastRefresh > CacheConfig.backgroundRefreshCooldown
    }
    
    /// Background refresh (doesn't throw, updates cache silently)
    private func refreshRatesInBackground() async {
        lastBackgroundRefresh = Date()
        
        do {
            let rates = try await fetchFromAPI()
            
            cachedRates = CachedRates(
                rates: rates,
                timestamp: Date(),
                baseCurrency: baseCurrency
            )
            
            lastUpdated = Date()
            isOffline = false
        } catch {
            // Silent failure - we still have cached data
        }
    }
    
    /// Fetch fresh rates from API
    private func fetchFreshRates() async throws -> [String: Double] {
        isLoading = true
        errorMessage = nil
        
        do {
            let rates = try await fetchFromAPI()
            
            cachedRates = CachedRates(
                rates: rates,
                timestamp: Date(),
                baseCurrency: baseCurrency
            )
            
            lastUpdated = Date()
            isLoading = false
            isOffline = false
            
            return rates
            
        } catch {
            isLoading = false
            isOffline = true
            errorMessage = error.localizedDescription
            
            // Fallback to cached data even if expired
            if let cached = cachedRates {
                return cached.rates
            }
            
            // No cache available - use fallback rates as last resort
            return fallbackRates
        }
    }
    
    /// Convert amount from one currency to another
    func convert(amount: Double, from: String, to: String) async -> Double? {
        do {
            let rates = try await fetchRates()
            
            if from == baseCurrency {
                return amount * (rates[to] ?? 1.0)
            }
            
            if to == baseCurrency {
                return amount / (rates[from] ?? 1.0)
            }
            
            guard let fromRate = rates[from], let toRate = rates[to] else {
                return nil
            }
            
            let amountInUSD = amount / fromRate
            return amountInUSD * toRate
            
        } catch {
            return nil
        }
    }
    
    /// Get exchange rate between two currencies
    func getRate(from: String, to: String) async -> Double? {
        do {
            let rates = try await fetchRates()
            
            if from == baseCurrency {
                return rates[to]
            }
            
            if to == baseCurrency {
                let fromRate = rates[from] ?? 1.0
                return 1.0 / fromRate
            }
            
            guard let fromRate = rates[from], let toRate = rates[to] else {
                return nil
            }
            
            return toRate / fromRate
            
        } catch {
            // Fallback to stored rates if API fails
            if from == "USD" {
                return fallbackRates[to]
            } else if to == "USD" {
                return 1.0 / (fallbackRates[from] ?? 1.0)
            } else {
                let fromRate = fallbackRates[from] ?? 1.0
                let toRate = fallbackRates[to] ?? 1.0
                return toRate / fromRate
            }
        }
    }
    
    /// Fetch historical rates for the past 30 days
    func fetchHistoricalRates(from: String, to: String, days: Int = 30) async -> [HistoricalRate]? {
        let cacheKey = "\(from)_\(to)"
        
        #if DEBUG
        if isMockMode {
            return generateFallbackHistoricalData(from: from, to: to, days: days)
        }
        #endif
        
        // Check cache first
        if let cached = cachedHistoricalData[cacheKey], !cached.isExpired {
            return cached.data
        }
        
        // Fetch from API
        do {
            let data = try await fetchHistoricalRangeFromAPI(from: from, to: to, days: days)
            
            cachedHistoricalData[cacheKey] = CachedHistoricalData(
                data: data,
                timestamp: Date(),
                fromCurrency: from,
                toCurrency: to
            )
            
            return data
            
        } catch {
            // Return cached data even if expired
            if let cached = cachedHistoricalData[cacheKey] {
                return cached.data
            }
            // Fallback to generated data if API fails
            return generateFallbackHistoricalData(from: from, to: to, days: days)
        }
    }
    
    /// Generate fallback historical data when API is unavailable
    private func generateFallbackHistoricalData(from: String, to: String, days: Int) -> [HistoricalRate] {
        let calendar = Calendar.current
        let endDate = Date()
        var data: [HistoricalRate] = []
        
        let todaysRate: Double
        if from == "USD" {
            todaysRate = fallbackRates[to] ?? 1.0
        } else if to == "USD" {
            todaysRate = 1.0 / (fallbackRates[from] ?? 1.0)
        } else {
            let fromRate = fallbackRates[from] ?? 1.0
            let toRate = fallbackRates[to] ?? 1.0
            todaysRate = toRate / fromRate
        }
        
        var currentRate = todaysRate
        for i in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            
            if i == 0 {
                currentRate = todaysRate
            } else {
                let variation = Double.random(in: -0.015...0.015)
                currentRate = currentRate * (1 + variation)
            }
            
            data.append(HistoricalRate(date: date, rate: currentRate))
        }
        
        return data
    }
    
    // MARK: - Private Methods
    
    private func fetchFromAPI() async throws -> [String: Double] {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw ExchangeRateError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "base_currency", value: baseCurrency)
        ]
        
        guard let url = urlComponents.url else {
            throw ExchangeRateError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(CurrencyAPIResponse.self, from: data)
        
        var rates: [String: Double] = [:]
        for (code, rate) in apiResponse.data {
            rates[code] = rate.value
        }
        
        return rates
    }
    
    /// Fetch historical data using efficient range API
    private func fetchHistoricalRangeFromAPI(from: String, to: String, days: Int) async throws -> [HistoricalRate] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days + 1, to: endDate) else {
            throw ExchangeRateError.invalidURL
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        guard var urlComponents = URLComponents(string: rangeURL) else {
            throw ExchangeRateError.invalidURL
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "start_date", value: startDateString),
            URLQueryItem(name: "end_date", value: endDateString),
            URLQueryItem(name: "base_currency", value: from),
            URLQueryItem(name: "currencies", value: to)
        ]
        
        guard let url = urlComponents.url else {
            throw ExchangeRateError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(RangeAPIResponse.self, from: data)
        
        var historicalData: [HistoricalRate] = []
        
        for (dateString, currencies) in apiResponse.data {
            if let rate = currencies[to]?.value,
               let date = dateFormatter.date(from: dateString) {
                historicalData.append(HistoricalRate(date: date, rate: rate))
            }
        }
        
        return historicalData.sorted { $0.date < $1.date }
    }
}

// MARK: - Error Types
enum ExchangeRateError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .decodingError:
            return "Failed to decode API response"
        }
    }
}
