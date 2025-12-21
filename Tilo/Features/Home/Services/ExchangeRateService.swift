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
        // Note: This uses local time; for production, convert to UTC
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
    @Published var cacheAge: String = "" // For UI display
    @Published var isOffline: Bool = false
    
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
    
    // Singleton instance
    static let shared = ExchangeRateService()
    
    private init() {
        // Load cached data from disk on init
        loadCachedRatesFromDisk()
        loadCachedHistoricalFromDisk()
        
        if let rates = cachedRates {
            lastUpdated = rates.timestamp
            cacheAge = rates.ageDescription
            print("📦 Loaded cached rates from disk (age: \(rates.ageDescription))")
        }
    }
    
    // MARK: - Persistence Methods
    
    private func saveCachedRatesToDisk(_ rates: CachedRates) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.shared.set(data, forKey: cachedRatesKey)
            print("💾 Saved rates to disk")
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
            print("💾 Saved historical data to disk")
        }
    }
    
    private func loadCachedHistoricalFromDisk() {
        if let data = UserDefaults.shared.data(forKey: cachedHistoricalKey),
           let historical = try? JSONDecoder().decode([String: CachedHistoricalData].self, from: data) {
            cachedHistoricalData = historical
            print("📦 Loaded \(historical.count) historical cache entries from disk")
        }
    }
    
    /// Clear all cached data (for testing)
    func clearCache() {
        cachedRates = nil
        cachedHistoricalData.removeAll()
        UserDefaults.shared.removeObject(forKey: cachedRatesKey)
        UserDefaults.shared.removeObject(forKey: cachedHistoricalKey)
        cacheAge = ""
        print("🗑️ All cache cleared (memory + disk) - next requests will use API")
    }
    
    // MARK: - Public Methods
    
    /// Fetch latest exchange rates from API or cache
    /// Uses stale-while-revalidate: returns cached data immediately, refreshes in background if stale
    func fetchRates() async throws -> [String: Double] {
        // If we have cached data
        if let cached = cachedRates {
            let ageMinutes = Int(cached.age / 60)
            
            // Fresh cache - use immediately
            if !cached.isExpired {
                print("✅ Using cached rates (age: \(ageMinutes) minutes, market hours: \(CacheConfig.isMarketHours))")
                lastUpdated = cached.timestamp
                cacheAge = cached.ageDescription
                isOffline = false
                
                // If stale (>1h), trigger background refresh with cooldown check
                if cached.isStale && canBackgroundRefresh() {
                    print("🔄 Cache is stale, triggering background refresh...")
                    Task {
                        await refreshRatesInBackground()
                    }
                }
                
                return cached.rates
            }
            
            // Expired cache - try to refresh, but return cached if offline
            print("⏰ Cache expired (age: \(ageMinutes) minutes), fetching fresh data...")
        }
        
        // No cache or expired - fetch fresh data
        return try await fetchFreshRates()
    }
    
    /// Force refresh rates (ignores cache)
    func forceRefresh() async throws -> [String: Double] {
        print("🔄 Force refresh requested")
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
            print("⏳ Background refresh on cooldown (\(minutesRemaining) min remaining)")
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
            print("✅ Background refresh completed")
            
        } catch {
            print("⚠️ Background refresh failed: \(error.localizedDescription)")
            // Don't update error state - we still have cached data
        }
    }
    
    /// Fetch fresh rates from API
    private func fetchFreshRates() async throws -> [String: Double] {
        print("🌐 Fetching fresh rates from API...")
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
            
            print("✅ Successfully fetched \(rates.count) currency rates")
            return rates
            
        } catch {
            isLoading = false
            isOffline = true
            errorMessage = error.localizedDescription
            
            // Fallback to cached data even if expired (offline support)
            if let cached = cachedRates {
                print("⚠️ API failed, using cached rates (age: \(cached.ageDescription)) - OFFLINE MODE")
                return cached.rates
            }
            
            // No cache available - throw error (no mock fallback)
            print("❌ No cache available and API failed - cannot provide rates")
            throw error
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
            print("❌ Conversion error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Get exchange rate between two currencies
    func getRate(from: String, to: String) async -> Double? {
        print("🔍 Getting rate: \(from) → \(to)")
        do {
            let rates = try await fetchRates()
            print("🔍 Available rates: \(rates.keys.sorted())")
            
            // If getting rate from base currency (USD)
            if from == baseCurrency {
                let rate = rates[to]
                print("🔍 USD → \(to): \(rate ?? 0)")
                return rate
            }
            
            // If getting rate to base currency (USD)
            if to == baseCurrency {
                let fromRate = rates[from] ?? 1.0
                let rate = 1.0 / fromRate
                print("🔍 \(from) → USD: \(rate) (from rate: \(fromRate))")
                return rate
            }
            
            // Cross-rate: EUR → GBP = (USD → GBP) ÷ (USD → EUR)
            guard let fromRate = rates[from], let toRate = rates[to] else {
                print("❌ Missing rates - \(from): \(rates[from] ?? 0), \(to): \(rates[to] ?? 0)")
                return nil
            }
            
            let rate = toRate / fromRate
            print("🔍 \(from) → \(to): \(rate) (fromRate: \(fromRate), toRate: \(toRate))")
            return rate
            
        } catch {
            print("❌ Get rate error: \(error.localizedDescription)")
            // No mock fallback - return nil if API fails and no cache
            return nil
        }
    }
    
    /// Fetch historical rates for the past N days (default: 14 days)
    func fetchHistoricalRates(from: String, to: String, days: Int = 14) async -> [HistoricalRate]? {
        print("📊 fetchHistoricalRates called: \(from) → \(to), \(days) days")
        let cacheKey = "\(from)_\(to)"
        
        print("🔍 CACHE CHECK: Looking for cached data for key: \(cacheKey)")
        if let cached = cachedHistoricalData[cacheKey] {
            let ageHours = Int(Date().timeIntervalSince(cached.timestamp) / 3600)
            let ageMinutes = Int(Date().timeIntervalSince(cached.timestamp) / 60)
            print("🔍 CACHE FOUND: Age = \(ageHours)h \(ageMinutes % 60)m, Expired = \(cached.isExpired)")
            print("🔍 CACHE DATA: \(cached.data.count) data points from \(cached.fromCurrency) to \(cached.toCurrency)")
        } else {
            print("🔍 CACHE MISS: No cached data found for \(cacheKey)")
        }
        
        // Check cache first - ensures data stability when switching tabs
        if let cached = cachedHistoricalData[cacheKey], !cached.isExpired {
            print("✅ Using cached historical data for \(cacheKey) (age: \(Int(Date().timeIntervalSince(cached.timestamp) / 3600)) hours)")
            return cached.data
        }
        
        // Try Range endpoint first (premium - 1 call for all days)
        print("🌐 Attempting RANGE API call (premium): About to fetch \(days) days of data for \(from)→\(to)")
        do {
            let data = try await fetchHistoricalRangeFromAPI(from: from, to: to, days: days)
            
            // Cache the data
            cachedHistoricalData[cacheKey] = CachedHistoricalData(
                data: data,
                timestamp: Date(),
                fromCurrency: from,
                toCurrency: to
            )
            
            print("✅ Fetched historical data via Range endpoint for \(cacheKey) (\(data.count) days) - 1 API call")
            return data
            
        } catch {
            print("⚠️ Range endpoint failed (likely premium feature): \(error.localizedDescription)")
            print("🔄 Falling back to Historical endpoint (free): Will make \(days) individual API calls")
            
            // Fallback to Historical endpoint (free - 1 call per day)
            do {
                let data = try await fetchHistoricalFromAPI(from: from, to: to, days: days)
                
                // Cache the data
                cachedHistoricalData[cacheKey] = CachedHistoricalData(
                    data: data,
                    timestamp: Date(),
                    fromCurrency: from,
                    toCurrency: to
                )
                
                print("✅ Fetched historical data via Historical endpoint for \(cacheKey) (\(data.count) days) - \(days) API calls")
                return data
                
            } catch {
                print("❌ Historical endpoint also failed: \(error.localizedDescription)")
                // Return cached data even if expired (offline support)
                if let cached = cachedHistoricalData[cacheKey] {
                    print("⚠️ Using expired cache for \(cacheKey) - OFFLINE MODE")
                    return cached.data
                }
                // No cache available - return nil
                print("❌ No cache available and both API endpoints failed - cannot provide historical data")
                return nil
            }
        }
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
        print("🌍 Available currencies from API (\(rates.count) total):")
        let sortedCodes = rates.keys.sorted()
        for code in sortedCodes {
            print("  - \(code): \(rates[code] ?? 0)")
        }
        
        return rates
        
    }
    
    /// Fetch historical data using efficient range API (1 token instead of 30)
    private func fetchHistoricalRangeFromAPI(from: String, to: String, days: Int) async throws -> [HistoricalRate] {
        let calendar = Calendar.current
        // End date is yesterday (today's data may be incomplete)
        guard let endDate = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            throw ExchangeRateError.invalidURL
        }
        guard let startDate = calendar.date(byAdding: .day, value: -days + 1, to: endDate) else {
            throw ExchangeRateError.invalidURL
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        print("📅 Fetching range: \(startDateString) to \(endDateString)")
        
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
        
        print("🌐 Making SINGLE range API call to: \(url)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeRateError.invalidResponse
        }
        
        print("📡 HTTP Status: \(httpResponse.statusCode)")
        guard httpResponse.statusCode == 200 else {
            throw ExchangeRateError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(RangeAPIResponse.self, from: data)
        
        print("🔍 Range API Response: \(apiResponse.data.keys.count) dates received")
        
        var historicalData: [HistoricalRate] = []
        
        for (dateString, currencies) in apiResponse.data {
            if let rate = currencies[to]?.value,
               let date = dateFormatter.date(from: dateString) {
                historicalData.append(HistoricalRate(date: date, rate: rate))
                print("✅ Added rate for \(dateString): \(rate)")
            }
        }
        
        print("🏁 Range API completed. Total data points: \(historicalData.count)")
        return historicalData.sorted { $0.date < $1.date }
    }
    
    /// Fetch historical data using free Historical endpoint (1 call per day)
    private func fetchHistoricalFromAPI(from: String, to: String, days: Int) async throws -> [HistoricalRate] {
        let calendar = Calendar.current
        let endDate = Date()
        guard calendar.date(byAdding: .day, value: -days, to: endDate) != nil else {
            throw ExchangeRateError.invalidURL
        }
        
        var historicalData: [HistoricalRate] = []
        
        // Fetch data for each day (CurrencyAPI requires individual date queries)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Fetch data for each day, starting from yesterday (today's data may be incomplete)
        // This ensures we always show complete daily data
        print("🔄 Starting loop for \(days) days (excluding today)...")
        for dayOffset in (1...days) {
            print("🔄 Processing day \(dayOffset)/\(days) (offset: \(dayOffset))")
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { 
                print("❌ Failed to create date for offset \(dayOffset)")
                continue 
            }
            let dateString = dateFormatter.string(from: date)
            print("📅 Fetching data for date: \(dateString)")
            
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
                print("🌐 Making API call \(dayOffset)/\(days) to: \(url)")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Invalid response for \(dateString), skipping...")
                    continue
                }
                
                print("📡 HTTP Status for \(dateString): \(httpResponse.statusCode)")
                guard httpResponse.statusCode == 200 else {
                    print("❌ HTTP Error \(httpResponse.statusCode) for \(dateString), skipping...")
                    continue
                }
                
                let decoder = JSONDecoder()
                let apiResponse = try decoder.decode(CurrencyAPIResponse.self, from: data)
                
                print("🔍 API Response for \(dateString): \(apiResponse)")
                
                if let rate = apiResponse.data[to]?.value {
                    print("✅ Found rate for \(to): \(rate)")
                    historicalData.append(HistoricalRate(date: date, rate: rate))
                } else {
                    print("❌ No rate found for \(to) in response: \(apiResponse.data.keys)")
                }
                
                // Add small delay to avoid rate limiting
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                
            } catch {
                print("❌ Error fetching data for \(dateString): \(error.localizedDescription), skipping...")
                continue
            }
        }
        
        print("🏁 Loop completed. Total data points collected: \(historicalData.count)")
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
