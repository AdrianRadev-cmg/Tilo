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
        if minutes < 1 {
            return "" // Will show "Updated just now" in UI
        } else if minutes < 60 {
            return "Last updated \(minutes) min ago"
        } else {
            let hours = minutes / 60
            return "Last updated \(hours) hr ago"
        }
    }
}

// MARK: - Historical Data Models (Codable for persistence)
struct HistoricalRate: Codable {
    let date: Date
    let rate: Double
}

struct CachedHistoricalData: Codable {
    var data: [HistoricalRate]
    var timestamp: Date
    let fromCurrency: String
    let toCurrency: String
    
    /// Returns the most recent date in the cached data
    var mostRecentDate: Date? {
        data.max(by: { $0.date < $1.date })?.date
    }
    
    /// Returns how many days of new data we need to fetch (0 if up to date)
    /// Note: Historical API only has data through YESTERDAY, not today
    var daysMissing: Int {
        guard let mostRecent = mostRecentDate else { return 14 }
        let calendar = Calendar.current
        // Compare to yesterday since historical data isn't available for today
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return 0 }
        let yesterdayStart = calendar.startOfDay(for: yesterday)
        let cachedDay = calendar.startOfDay(for: mostRecent)
        let daysDiff = calendar.dateComponents([.day], from: cachedDay, to: yesterdayStart).day ?? 0
        return max(0, daysDiff)
    }
    
    /// Check if cache needs updating (missing recent days)
    var needsUpdate: Bool {
        daysMissing > 0
    }
    
    // Legacy - kept for compatibility but not used for rolling cache
    var isExpired: Bool {
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
        // Note: This uses local time; for production, convert to UTC
        return hour >= 8 && hour < 20
    }
    
    // Cache expiration based on market hours
    static var currentRatesExpiration: TimeInterval {
        if isMarketHours {
            return 1 * 60 * 60 // 1 hour during market hours
        } else {
            return 2 * 60 * 60 // 2 hours off-market
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
    @Published var cacheAge: String = "" // For UI display
    @Published var isOffline: Bool = false
    
    // Development mode toggle
    @Published var isMockMode: Bool = false // Set to true for development, false for production
    
    // Private properties
    private var apiKey: String { APIKeyManager.apiKey }
    private let baseURL = "https://api.currencyapi.com/v3/latest"
    private let historicalURL = "https://api.currencyapi.com/v3/historical"
    private let rangeURL = "https://api.currencyapi.com/v3/range"
    private let baseCurrency = "USD" // Using USD as base for all conversions
    
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
    
    // Mock data for development (all 160 currencies with realistic rates vs USD)
    private let mockRates: [String: Double] = [
        // USD is base (1.0)
        "USD": 1.0,
        
        // Very High-value
        "KWD": 0.31, "BHD": 0.38, "OMR": 0.38, "JOD": 0.71, "GBP": 0.79,
        "KYD": 0.83, "GIP": 0.79, "FKP": 0.79,
        
        // High-value
        "EUR": 0.92, "CHF": 0.91, "CAD": 1.36, "AUD": 1.52, "NZD": 1.65,
        "SGD": 1.35, "AED": 3.67, "SAR": 3.75, "QAR": 3.64, "ILS": 3.72,
        "BND": 1.35, "BSD": 1.0, "PAB": 1.0, "FJD": 2.27, "BWP": 13.5,
        "AZN": 1.70, "RON": 4.56, "GEL": 2.70, "PEN": 3.75,
        "BOB": 6.91, "GTQ": 7.75, "UAH": 41.2, "RSD": 107.5, "JMD": 154.5,
        "BBD": 2.0, "TTD": 6.78, "MUR": 45.8, "MVR": 15.4,
        "BMD": 1.0, "BZD": 2.0, "AWG": 1.79, "XCD": 2.70, "SHP": 0.79,
        "GGP": 0.79, "IMP": 0.79, "JEP": 0.79, "BAM": 1.80, "BYN": 3.25,
        
        // Medium-value
        "CNY": 7.23, "HKD": 7.82, "TWD": 31.5, "SEK": 10.35, "NOK": 10.62,
        "DKK": 6.87, "PLN": 4.02, "CZK": 23.1, "MXN": 17.2, "ZAR": 18.5,
        "BRL": 5.02, "INR": 83.2, "THB": 34.5, "MYR": 4.47, "PHP": 56.3,
        "TRY": 32.5, "EGP": 48.8, "RUB": 92.5, "MDL": 17.8, "MKD": 56.4,
        "DOP": 59.8, "HNL": 24.7, "NIO": 36.8, "MAD": 9.87, "TND": 3.11,
        "KES": 129.5, "UGX": 3685.0, "TZS": 2505.0, "GHS": 15.2, "NAD": 18.5,
        "DZD": 135.0, "CRC": 520.0, "MOP": 8.05, "CVE": 101.5, "GYD": 209.0,
        "SRD": 35.5, "LSL": 18.5, "SZL": 18.5, "ANG": 1.79, "SCR": 13.2,
        "GMD": 67.5, "MWK": 1735.0, "MZN": 63.8, "HTG": 131.5, "LYD": 4.85,
        "IQD": 1310.0, "SVC": 8.75, "XAF": 605.0, "XOF": 605.0, "XPF": 110.0,
        "AOA": 920.0, "ERN": 15.0, "ETB": 125.0, "CDF": 2820.0, "SDG": 601.0,
        "TOP": 2.35, "WST": 2.72,
        
        // Low-value
        "JPY": 149.5, "KRW": 1325.0, "HUF": 360.5, "ISK": 137.2, "CLP": 920.0,
        "ARS": 850.0, "COP": 3925.0, "PKR": 278.5, "LKR": 305.0, "BDT": 110.5,
        "MMK": 2098.0, "NGN": 1580.0, "AMD": 386.0, "KZT": 452.0, "KGS": 87.5,
        "ALL": 92.3, "RWF": 1298.0, "BIF": 2865.0, "DJF": 178.0, "GNF": 8590.0,
        "KMF": 452.0, "MGA": 4520.0, "PYG": 7350.0, "KHR": 4095.0, "MNT": 3420.0,
        "NPR": 133.0, "BTN": 83.5, "AFN": 70.5, "MRU": 39.8, "LRD": 193.0,
        "UYU": 39.2, "CUP": 24.0, "CUC": 1.0, "SOS": 571.0, "TJS": 10.9,
        "TMT": 3.5, "YER": 250.0, "ZMW": 27.2, "PGK": 3.95, "SBD": 8.45,
        "VUV": 118.5, "KPW": 900.0, "SLE": 22750.0, "CLF": 0.034,
        
        // Very low-value
        "VND": 24500.0, "IDR": 15780.0, "IRR": 42050.0, "LAK": 21850.0, "UZS": 12750.0,
        "SLL": 19750.0, "LBP": 89500.0, "SYP": 13000.0, "STN": 22.5, "VES": 36.5,
        "ZWG": 13.8, "XCG": 1.79
    ]
    
    // Singleton instance
    static let shared = ExchangeRateService()
    
    private init() {
        // Load cached data from disk on init
        loadCachedRatesFromDisk()
        loadCachedHistoricalFromDisk()
        
        if let rates = cachedRates {
            lastUpdated = rates.timestamp
            cacheAge = rates.ageDescription
            debugLog("📦 Loaded cached rates from disk (age: \(rates.ageDescription))")
        }
    }
    
    // MARK: - Persistence Methods
    
    private func saveCachedRatesToDisk(_ rates: CachedRates) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.shared.set(data, forKey: cachedRatesKey)
            debugLog("💾 Saved rates to disk")
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
            debugLog("💾 Saved historical data to disk")
        }
    }
    
    private func loadCachedHistoricalFromDisk() {
        if let data = UserDefaults.shared.data(forKey: cachedHistoricalKey),
           let historical = try? JSONDecoder().decode([String: CachedHistoricalData].self, from: data) {
            cachedHistoricalData = historical
            debugLog("📦 Loaded \(historical.count) historical cache entries from disk")
        }
    }
    
    // MARK: - Development Methods
    
    /// Toggle between mock mode and real API mode
    func toggleMockMode() {
        isMockMode.toggle()
        debugLog("🔄 Mock mode: \(isMockMode ? "ON" : "OFF")")
    }
    
    /// Set mock mode explicitly
    func setMockMode(_ enabled: Bool) {
        isMockMode = enabled
        debugLog("🔄 Mock mode: \(enabled ? "ON" : "OFF")")
    }
    
    /// Get current mode status
    var modeDescription: String {
        return isMockMode ? "🧪 Mock Mode (No API calls)" : "🌐 Live Mode (Real API)"
    }
    
    /// Clear all cached data (for testing)
    func clearCache() {
        cachedRates = nil
        cachedHistoricalData.removeAll()
        UserDefaults.shared.removeObject(forKey: cachedRatesKey)
        UserDefaults.shared.removeObject(forKey: cachedHistoricalKey)
        cacheAge = ""
        debugLog("🗑️ All cache cleared (memory + disk) - next requests will use API")
    }
    
    // MARK: - Public Methods
    
    /// Fetch latest exchange rates from API or cache
    /// Uses stale-while-revalidate: returns cached data immediately, refreshes in background if stale
    func fetchRates() async throws -> [String: Double] {
        // Mock mode - return mock data immediately
        if isMockMode {
            debugLog("🧪 Mock mode: Using mock exchange rates")
            lastUpdated = Date()
            errorMessage = nil
            isOffline = false
            return mockRates
        }
        
        // If we have cached data
        if let cached = cachedRates {
            let ageMinutes = Int(cached.age / 60)
            
            // Fresh cache - use immediately
            if !cached.isExpired {
                debugLog("✅ Using cached rates (age: \(ageMinutes) minutes, market hours: \(CacheConfig.isMarketHours))")
                lastUpdated = cached.timestamp
                cacheAge = cached.ageDescription
                isOffline = false
                
                // If stale (>1h), trigger background refresh with cooldown check
                if cached.isStale && canBackgroundRefresh() {
                    debugLog("🔄 Cache is stale, triggering background refresh...")
                    Task {
                        await refreshRatesInBackground()
                    }
                }
                
                return cached.rates
            }
            
            // Expired cache - try to refresh, but return cached if offline
            debugLog("⏰ Cache expired (age: \(ageMinutes) minutes), fetching fresh data...")
        }
        
        // No cache or expired - fetch fresh data
        return try await fetchFreshRates()
    }
    
    /// Force refresh rates (ignores cache)
    func forceRefresh() async throws -> [String: Double] {
        debugLog("🔄 Force refresh requested")
        return try await fetchFreshRates()
    }
    
    /// Check if background refresh is allowed (cooldown check)
    private func canBackgroundRefresh() -> Bool {
        guard let lastRefresh = lastBackgroundRefresh else {
            return true // Never refreshed before
        }
        
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
        let canRefresh = timeSinceLastRefresh > CacheConfig.backgroundRefreshCooldown
        
        if !canRefresh {
            let minutesRemaining = Int((CacheConfig.backgroundRefreshCooldown - timeSinceLastRefresh) / 60)
            debugLog("⏳ Background refresh on cooldown (\(minutesRemaining) min remaining)")
        }
        
        return canRefresh
    }
    
    /// Background refresh (doesn't throw, updates cache silently)
    private func refreshRatesInBackground() async {
        // Mark refresh time immediately to prevent duplicate calls
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
            debugLog("✅ Background refresh completed")
            
        } catch {
            debugLog("⚠️ Background refresh failed: \(error.localizedDescription)")
            // Don't update error state - we still have cached data
        }
    }
    
    /// Fetch fresh rates from API
    private func fetchFreshRates() async throws -> [String: Double] {
        debugLog("🌐 Fetching fresh rates from API...")
        isLoading = true
        errorMessage = nil
        
        do {
            let rates = try await fetchFromAPI()
            
            // Cache the new rates (triggers persistence via didSet)
            cachedRates = CachedRates(
                rates: rates,
                timestamp: Date(),
                baseCurrency: baseCurrency
            )
            
            lastUpdated = Date()
            isLoading = false
            isOffline = false
            
            debugLog("✅ Successfully fetched \(rates.count) currency rates")
            return rates
            
        } catch {
            isLoading = false
            isOffline = true
            errorMessage = error.localizedDescription
            
            // Fallback to cached data even if expired (offline support)
            if let cached = cachedRates {
                debugLog("⚠️ API failed, using cached rates (age: \(cached.ageDescription)) - OFFLINE MODE")
                return cached.rates
            }
            
            // No cache available - use mock rates as last resort
            debugLog("⚠️ No cache available, using mock rates as fallback")
            return mockRates
        }
    }
    
    /// Convert amount from one currency to another
    func convert(amount: Double, from: String, to: String) async -> Double? {
        do {
            let rates = try await fetchRates()
            
            // If converting from base currency (USD)
            if from == baseCurrency {
                return amount * (rates[to] ?? 1.0)
            }
            
            // If converting to base currency (USD)
            if to == baseCurrency {
                return amount / (rates[from] ?? 1.0)
            }
            
            // Cross-rate conversion: EUR → GBP = (USD → GBP) ÷ (USD → EUR)
            guard let fromRate = rates[from], let toRate = rates[to] else {
                return nil
            }
            
            let amountInUSD = amount / fromRate
            let convertedAmount = amountInUSD * toRate
            
            return convertedAmount
            
        } catch {
            debugLog("❌ Conversion error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get exchange rate between two currencies
    func getRate(from: String, to: String) async -> Double? {
        debugLog("🔍 Getting rate: \(from) → \(to)")
        do {
            let rates = try await fetchRates()
            debugLog("🔍 Available rates: \(rates.keys.sorted())")
            
            // If getting rate from base currency (USD)
            if from == baseCurrency {
                let rate = rates[to]
                debugLog("🔍 USD → \(to): \(rate ?? 0)")
                return rate
            }
            
            // If getting rate to base currency (USD)
            if to == baseCurrency {
                let fromRate = rates[from] ?? 1.0
                let rate = 1.0 / fromRate
                debugLog("🔍 \(from) → USD: \(rate) (from rate: \(fromRate))")
                return rate
            }
            
            // Cross-rate: EUR → GBP = (USD → GBP) ÷ (USD → EUR)
            guard let fromRate = rates[from], let toRate = rates[to] else {
                debugLog("❌ Missing rates - \(from): \(rates[from] ?? 0), \(to): \(rates[to] ?? 0)")
                return nil
            }
            
            let rate = toRate / fromRate
            debugLog("🔍 \(from) → \(to): \(rate) (fromRate: \(fromRate), toRate: \(toRate))")
            return rate
            
        } catch {
            debugLog("❌ Get rate error: \(error.localizedDescription)")
            // Fallback to mock rate if API fails
            debugLog("⚠️ API failed, falling back to mock rate")
            if from == "USD" {
                return mockRates[to]
            } else if to == "USD" {
                return 1.0 / (mockRates[from] ?? 1.0)
            } else {
                let fromRate = mockRates[from] ?? 1.0
                let toRate = mockRates[to] ?? 1.0
                return toRate / fromRate
            }
        }
    }
    
    /// Fetch historical rates for the past 14 days (matches API plan limit)
    /// Uses ROLLING CACHE: Only fetches missing days, not all 14 every time
    func fetchHistoricalRates(from: String, to: String, days: Int = 14) async -> [HistoricalRate]? {
        debugLog("📊 fetchHistoricalRates called: \(from) → \(to), \(days) days, mockMode: \(isMockMode)")
        let cacheKey = "\(from)_\(to)"
        
        // Mock mode - return mock historical data
        if isMockMode {
            let data = generateMockHistoricalData(from: from, to: to, days: days)
            debugLog("📊 Returning \(data.count) mock data points")
            return data
        }
        
        // Check if we have cached data
        if let cached = cachedHistoricalData[cacheKey] {
            let daysMissing = cached.daysMissing
            debugLog("🔍 CACHE FOUND: \(cached.data.count) points, missing \(daysMissing) day(s)")
            
            // Cache is up to date - return it
            if daysMissing == 0 {
                debugLog("✅ Cache is current, returning \(cached.data.count) cached points (0 tokens used)")
                return cached.data.suffix(days).map { $0 } // Return last N days
            }
            
            // Need to fetch only the missing days (rolling update)
            debugLog("🌐 ROLLING UPDATE: Fetching \(daysMissing) missing day(s) for \(from)→\(to) (USES \(daysMissing) TOKEN(S))")
            do {
                let newData = try await fetchHistoricalIndividualFromAPI(from: from, to: to, days: daysMissing)
                
                // Merge new data with existing cache
                var mergedData = cached.data
                for newRate in newData {
                    // Only add if not already in cache (avoid duplicates)
                    if !mergedData.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: newRate.date) }) {
                        mergedData.append(newRate)
                    }
                }
                
                // Sort by date and keep only the last 'days' worth
                mergedData.sort { $0.date < $1.date }
                let trimmedData = Array(mergedData.suffix(days))
                
                // Update cache
                cachedHistoricalData[cacheKey] = CachedHistoricalData(
                    data: trimmedData,
                    timestamp: Date(),
                    fromCurrency: from,
                    toCurrency: to
                )
                
                debugLog("✅ Rolling update complete: \(trimmedData.count) total points (fetched \(daysMissing) new)")
                return trimmedData
                
            } catch {
                debugLog("⚠️ Rolling update failed, returning existing cache: \(error.localizedDescription)")
                return cached.data.suffix(days).map { $0 }
            }
        }
        
        // No cache exists - fetch all days (initial load)
        debugLog("🌐 INITIAL LOAD: Fetching all \(days) days for \(from)→\(to) (USES \(days) TOKENS)")
        do {
            let data = try await fetchHistoricalIndividualFromAPI(from: from, to: to, days: days)
            
            // Cache the data
            cachedHistoricalData[cacheKey] = CachedHistoricalData(
                data: data,
                timestamp: Date(),
                fromCurrency: from,
                toCurrency: to
            )
            
            debugLog("✅ Initial load complete: \(data.count) days cached")
            return data
            
        } catch {
            debugLog("❌ Historical fetch error: \(error.localizedDescription)")
            // Fallback to mock data if API fails
            debugLog("⚠️ API failed, falling back to mock historical data")
            return generateMockHistoricalData(from: from, to: to, days: days)
        }
    }
    
    /// Generate mock historical data for testing
    private func generateMockHistoricalData(from: String, to: String, days: Int) -> [HistoricalRate] {
        debugLog("🧪 Generating mock historical data: \(from) → \(to) for \(days) days")
        
        let calendar = Calendar.current
        let endDate = Date()
        var mockData: [HistoricalRate] = []
        
        // Get base rate from mock rates (this is today's actual rate)
        let todaysRate: Double
        if from == "USD" {
            todaysRate = mockRates[to] ?? 1.0
        } else if to == "USD" {
            todaysRate = 1.0 / (mockRates[from] ?? 1.0)
        } else {
            let fromRate = mockRates[from] ?? 1.0
            let toRate = mockRates[to] ?? 1.0
            todaysRate = toRate / fromRate
        }
        
        debugLog("🧪 Today's rate for \(from)→\(to): \(todaysRate)")
        
        // Generate historical data working backwards from today
        var currentRate = todaysRate
        for i in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: endDate) else { continue }
            
            if i == 0 {
                // Today - use exact rate
                currentRate = todaysRate
            } else {
                // Past days - add realistic fluctuation (±1.5% daily variation)
                let variation = Double.random(in: -0.015...0.015)
                currentRate = currentRate * (1 + variation)
            }
            
            mockData.append(HistoricalRate(date: date, rate: currentRate))
        }
        
        debugLog("🧪 Generated \(mockData.count) data points, last rate: \(mockData.last?.rate ?? 0)")
        return mockData
    }
    
    // MARK: - Private Methods
    
    private func fetchFromAPI() async throws -> [String: Double] {
        // Construct URL with API key and base currency
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
        
        // Make API request
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Check response status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Decode JSON response
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(CurrencyAPIResponse.self, from: data)
        
        // Convert to simple dictionary
        var rates: [String: Double] = [:]
        for (code, rate) in apiResponse.data {
            rates[code] = rate.value
        }
        
        // Log all available currencies (for development)
        debugLog("🌍 Available currencies from API (\(rates.count) total):")
        let sortedCodes = rates.keys.sorted()
        for code in sortedCodes {
            debugLog("  - \(code): \(rates[code] ?? 0)")
        }
        
        return rates
        
    }
    
    /// Fetch historical data using efficient range API (1 token instead of 30)
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
        
        debugLog("📅 Fetching range: \(startDateString) to \(endDateString)")
        
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
        
        debugLog("🌐 Making SINGLE range API call to: \(url)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }
        
        debugLog("📡 HTTP Status: \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(RangeAPIResponse.self, from: data)
        
        debugLog("🔍 Range API Response: \(apiResponse.data.keys.count) dates received")
        
        var historicalData: [HistoricalRate] = []
        
        for (dateString, currencies) in apiResponse.data {
            if let rate = currencies[to]?.value,
               let date = dateFormatter.date(from: dateString) {
                historicalData.append(HistoricalRate(date: date, rate: rate))
                debugLog("✅ Added rate for \(dateString): \(rate)")
            }
        }
        
        debugLog("🏁 Range API completed. Total data points: \(historicalData.count)")
        return historicalData.sorted { $0.date < $1.date }
    }
    
    /// Fetch historical data from API using individual date calls (for plans without range endpoint)
    /// Note: Starts from YESTERDAY since historical data isn't available for today
    private func fetchHistoricalIndividualFromAPI(from: String, to: String, days: Int) async throws -> [HistoricalRate] {
        let calendar = Calendar.current
        // Start from yesterday since today's historical data isn't available yet
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            throw ExchangeRateError.invalidURL
        }
        
        var historicalData: [HistoricalRate] = []
        
        // Fetch data for each day (CurrencyAPI requires individual date queries)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Start from yesterday (offset 0 = yesterday, offset 1 = day before, etc.)
        debugLog("🔄 Starting loop for \(days) days (from yesterday backwards)...")
        for dayOffset in (0..<days) {
            debugLog("🔄 Processing day \(dayOffset + 1)/\(days) (offset: \(dayOffset))")
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: yesterday) else { 
                debugLog("❌ Failed to create date for offset \(dayOffset)")
                continue 
            }
            let dateString = dateFormatter.string(from: date)
            debugLog("📅 Fetching data for date: \(dateString)")
            
            guard var urlComponents = URLComponents(string: historicalURL) else {
                throw ExchangeRateError.invalidURL
            }
            
            urlComponents.queryItems = [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "date", value: dateString),
                URLQueryItem(name: "base_currency", value: from),
                URLQueryItem(name: "currencies", value: to)
            ]
            
            guard let url = urlComponents.url else {
                throw ExchangeRateError.invalidURL
            }
            
            do {
                debugLog("🌐 Making API call \(dayOffset + 1)/\(days) to: \(url)")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    debugLog("❌ Invalid response for \(dateString), skipping...")
                    continue
                }
                
                debugLog("📡 HTTP Status for \(dateString): \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    debugLog("❌ HTTP Error \(httpResponse.statusCode) for \(dateString), skipping...")
                    continue
                }
                
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(CurrencyAPIResponse.self, from: data)
                
                debugLog("🔍 API Response for \(dateString): \(apiResponse)")
                
                if let rate = apiResponse.data[to]?.value {
                    debugLog("✅ Found rate for \(to): \(rate)")
                    historicalData.append(HistoricalRate(date: date, rate: rate))
                } else {
                    debugLog("❌ No rate found for \(to) in response: \(apiResponse.data.keys)")
                }
                
                // Add small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                
            } catch {
                debugLog("❌ Error fetching data for \(dateString): \(error.localizedDescription), skipping...")
                continue
            }
        }
        
        debugLog("🏁 Loop completed. Total data points collected: \(historicalData.count)")
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
 