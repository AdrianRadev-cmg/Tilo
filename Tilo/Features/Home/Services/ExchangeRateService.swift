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
            return 30 * 60 // 30 minutes during market hours
        } else {
            return 1 * 60 * 60 // 1 hour off-market
        }
    }
    
    // Stale threshold for background refresh (triggers refresh but returns cached data)
    static let staleThreshold: TimeInterval = 15 * 60 // 15 minutes
    
    // Background refresh cooldown (prevents multiple refreshes)
    static let backgroundRefreshCooldown: TimeInterval = 15 * 60 // 15 minutes
    
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
    
    /// Clear all cached data (for testing)
    func clearCache() {
        cachedRates = nil
        cachedHistoricalData.removeAll()
        UserDefaults.shared.removeObject(forKey: cachedRatesKey)
        UserDefaults.shared.removeObject(forKey: cachedHistoricalKey)
        cacheAge = ""
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
                lastUpdated = cached.timestamp
                cacheAge = cached.ageDescription
                isOffline = false
                
                // If stale (>1h), trigger background refresh with cooldown check
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
            return true // Never refreshed before
        }
        
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefresh)
        return timeSinceLastRefresh > CacheConfig.backgroundRefreshCooldown
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
            
        } catch {
            // Don't update error state - we still have cached data
        }
    }
    
    /// Fetch fresh rates from API
    private func fetchFreshRates() async throws -> [String: Double] {
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
            
            return rates
            
        } catch {
            isLoading = false
            isOffline = true
            errorMessage = error.localizedDescription
            
            // Fallback to cached data even if expired (offline support)
            if let cached = cachedRates {
                return cached.rates
            }
            
            // No cache available - throw error
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
            return nil
        }
    }
    
    /// Get exchange rate between two currencies
    func getRate(from: String, to: String) async -> Double? {
        do {
            let rates = try await fetchRates()
            
            // If getting rate from base currency (USD)
            if from == baseCurrency {
                return rates[to]
            }
            
            // If getting rate to base currency (USD)
            if to == baseCurrency {
                let fromRate = rates[from] ?? 1.0
                return 1.0 / fromRate
            }
            
            // Cross-rate: EUR → GBP = (USD → GBP) ÷ (USD → EUR)
            guard let fromRate = rates[from], let toRate = rates[to] else {
                return nil
            }
            
            return toRate / fromRate
            
        } catch {
            return nil
        }
    }
    
    /// Fetch historical rates for the past N days (default: 14 days)
    func fetchHistoricalRates(from: String, to: String, days: Int = 14) async -> [HistoricalRate]? {
        let cacheKey = "\(from)_\(to)"
        
        // Check cache first - ensures data stability when switching tabs
        if let cached = cachedHistoricalData[cacheKey], !cached.isExpired {
            return cached.data
        }
        do {
            let data = try await fetchHistoricalRangeFromAPI(from: from, to: to, days: days)
            
            // Cache the data
            cachedHistoricalData[cacheKey] = CachedHistoricalData(
                data: data,
                timestamp: Date(),
                fromCurrency: from,
                toCurrency: to
            )
            
            return data
            
        } catch {
            // Fallback to Historical endpoint (free - 1 call per day)
            do {
                let data = try await fetchHistoricalFromAPI(from: from, to: to, days: days)
                
                // Only cache if we have at least 70% of expected data points
                let minimumDataPoints = Int(Double(days) * 0.7)
                if data.count >= minimumDataPoints {
                    cachedHistoricalData[cacheKey] = CachedHistoricalData(
                        data: data,
                        timestamp: Date(),
                        fromCurrency: from,
                        toCurrency: to
                    )
                }
                
                return data
                
            } catch {
                // Return cached data even if expired (offline support)
                if let cached = cachedHistoricalData[cacheKey] {
                    return cached.data
                }
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
    
    /// Fetch historical data using free Historical endpoint (parallel calls for speed)
    private func fetchHistoricalFromAPI(from: String, to: String, days: Int) async throws -> [HistoricalRate] {
        let calendar = Calendar.current
        let endDate = Date()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Create all date/URL pairs upfront
        var requests: [(date: Date, dateString: String, url: URL)] = []
        for dayOffset in (1...days) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate) else { continue }
            let dateString = dateFormatter.string(from: date)
            
            guard var urlComponents = URLComponents(string: historicalURL) else { continue }
            urlComponents.queryItems = [
                URLQueryItem(name: "apikey", value: apiKey),
                URLQueryItem(name: "date", value: dateString),
                URLQueryItem(name: "base_currency", value: from),
                URLQueryItem(name: "currencies", value: to)
            ]
            guard let url = urlComponents.url else { continue }
            requests.append((date: date, dateString: dateString, url: url))
        }
        
        // Fetch all days in parallel using TaskGroup (much faster!)
        let historicalData = await withTaskGroup(of: HistoricalRate?.self) { group in
            var results: [HistoricalRate] = []
            
            for request in requests {
                group.addTask {
                    await self.fetchSingleDay(date: request.date, dateString: request.dateString, url: request.url, targetCurrency: to)
                }
            }
            
            // Collect results
            for await result in group {
                if let rate = result {
                    results.append(rate)
                }
            }
            
            return results
        }
        
        return historicalData.sorted { $0.date < $1.date }
    }
    
    /// Fetch a single day's rate (helper for parallel fetching)
    private func fetchSingleDay(date: Date, dateString: String, url: URL, targetCurrency: String) async -> HistoricalRate? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(CurrencyAPIResponse.self, from: data)
            
            if let rate = apiResponse.data[targetCurrency]?.value {
                return HistoricalRate(date: date, rate: rate)
            }
        } catch {
            // Silent failure - handled by caller
        }
        return nil
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
