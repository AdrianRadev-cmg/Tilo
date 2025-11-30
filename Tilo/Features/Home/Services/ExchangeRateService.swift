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

// MARK: - Cached Rates Model
struct CachedRates {
    let rates: [String: Double]
    let timestamp: Date
    let baseCurrency: String
    
    var isExpired: Bool {
        // Cache expires after 5 hours
        Date().timeIntervalSince(timestamp) > (5 * 60 * 60)
    }
    
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}

// MARK: - Historical Data Models
struct HistoricalRate {
    let date: Date
    let rate: Double
}

struct CachedHistoricalData {
    let data: [HistoricalRate]
    let timestamp: Date
    let fromCurrency: String
    let toCurrency: String
    
    var isExpired: Bool {
        // Cache expires after 24 hours (historical data doesn't change)
        Date().timeIntervalSince(timestamp) > (24 * 60 * 60)
    }
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
    
    // Development mode toggle
    @Published var isMockMode: Bool = false // Set to true for development, false for production
    
    // Private properties
    private var apiKey: String { APIKeyManager.apiKey }
    private let baseURL = "https://api.currencyapi.com/v3/latest"
    private let historicalURL = "https://api.currencyapi.com/v3/historical"
    private let rangeURL = "https://api.currencyapi.com/v3/range"
    private let baseCurrency = "USD" // Using USD as base for all conversions
    
    // Cache storage
    private var cachedRates: CachedRates?
    private var cachedHistoricalData: [String: CachedHistoricalData] = [:] // Key: "FROM_TO" (e.g., "USD_EUR")
    
    // Mock data for development (all 100 currencies with realistic rates vs USD)
    private let mockRates: [String: Double] = [
        // USD is base (1.0)
        "USD": 1.0,
        
        // Very High-value
        "KWD": 0.31, "BHD": 0.38, "OMR": 0.38, "JOD": 0.71, "GBP": 0.79,
        
        // High-value
        "EUR": 0.92, "CHF": 0.91, "CAD": 1.36, "AUD": 1.52, "NZD": 1.65,
        "SGD": 1.35, "AED": 3.67, "SAR": 3.75, "QAR": 3.64, "ILS": 3.72,
        "BND": 1.35, "BSD": 1.0, "PAB": 1.0, "FJD": 2.27, "BWP": 13.5,
        "AZN": 1.70, "RON": 4.56, "BGN": 1.80, "GEL": 2.70, "PEN": 3.75,
        "BOB": 6.91, "GTQ": 7.75, "UAH": 41.2, "RSD": 107.5, "JMD": 154.5,
        "BBD": 2.0, "TTD": 6.78, "MUR": 45.8, "MVR": 15.4,
        
        // Medium-value
        "CNY": 7.23, "HKD": 7.82, "TWD": 31.5, "SEK": 10.35, "NOK": 10.62,
        "DKK": 6.87, "PLN": 4.02, "CZK": 23.1, "MXN": 17.2, "ZAR": 18.5,
        "BRL": 5.02, "INR": 83.2, "THB": 34.5, "MYR": 4.47, "PHP": 56.3,
        "TRY": 32.5, "EGP": 48.8, "RUB": 92.5, "MDL": 17.8, "MKD": 56.4,
        "DOP": 59.8, "HNL": 24.7, "NIO": 36.8, "MAD": 9.87, "TND": 3.11,
        "KES": 129.5, "UGX": 3685.0, "TZS": 2505.0, "GHS": 15.2, "NAD": 18.5,
        
        // Low-value
        "JPY": 149.5, "KRW": 1325.0, "HUF": 360.5, "ISK": 137.2, "CLP": 920.0,
        "ARS": 850.0, "COP": 3925.0, "PKR": 278.5, "LKR": 305.0, "BDT": 110.5,
        "MMK": 2098.0, "NGN": 1580.0, "AMD": 386.0, "KZT": 452.0, "KGS": 87.5,
        "ALL": 92.3, "RWF": 1298.0, "BIF": 2865.0, "DJF": 178.0, "GNF": 8590.0,
        "KMF": 452.0, "MGA": 4520.0, "PYG": 7350.0, "KHR": 4095.0, "MNT": 3420.0,
        
        // Very low-value
        "VND": 24500.0, "IDR": 15780.0, "IRR": 42050.0, "LAK": 21850.0, "UZS": 12750.0,
        "SLL": 19750.0, "LBP": 89500.0, "SYP": 13000.0, "STN": 22.5, "VES": 36.5
    ]
    
    // Singleton instance
    static let shared = ExchangeRateService()
    
    private init() {}
    
    // MARK: - Development Methods
    
    /// Toggle between mock mode and real API mode
    func toggleMockMode() {
        isMockMode.toggle()
        print("🔄 Mock mode: \(isMockMode ? "ON" : "OFF")")
    }
    
    /// Set mock mode explicitly
    func setMockMode(_ enabled: Bool) {
        isMockMode = enabled
        print("🔄 Mock mode: \(enabled ? "ON" : "OFF")")
    }
    
    /// Get current mode status
    var modeDescription: String {
        return isMockMode ? "🧪 Mock Mode (No API calls)" : "🌐 Live Mode (Real API)"
    }
    
    /// Clear all cached data (for testing)
    func clearCache() {
        cachedRates = nil
        cachedHistoricalData.removeAll()
        print("🗑️ All cache cleared - next requests will use API")
    }
    
    // MARK: - Public Methods
    
    /// Fetch latest exchange rates from API or cache
    func fetchRates() async throws -> [String: Double] {
        // Mock mode - return mock data immediately
        if isMockMode {
            print("🧪 Mock mode: Using mock exchange rates")
            lastUpdated = Date()
            errorMessage = nil
            return mockRates
        }
        
        // Check if we have valid cached data
        if let cached = cachedRates, !cached.isExpired {
            print("✅ Using cached rates (age: \(Int(cached.age / 60)) minutes)")
            lastUpdated = cached.timestamp
            return cached.rates
        }
        
        // Fetch fresh data from API
        print("🌐 Fetching fresh rates from API...")
        isLoading = true
        errorMessage = nil
        
        do {
            let rates = try await fetchFromAPI()
            
            // Cache the new rates
            cachedRates = CachedRates(
                rates: rates,
                timestamp: Date(),
                baseCurrency: baseCurrency
            )
            
            lastUpdated = Date()
            isLoading = false
            
            print("✅ Successfully fetched \(rates.count) currency rates")
            return rates
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            
            // Fallback to cached data even if expired
            if let cached = cachedRates {
                print("⚠️ API failed, using cached rates (age: \(Int(cached.age / 3600)) hours)")
                return cached.rates
            }
            
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
            // Fallback to mock rate if API fails
            print("⚠️ API failed, falling back to mock rate")
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
    
    /// Fetch historical rates for the past 30 days
    func fetchHistoricalRates(from: String, to: String, days: Int = 30) async -> [HistoricalRate]? {
        print("📊 fetchHistoricalRates called: \(from) → \(to), \(days) days, mockMode: \(isMockMode)")
        let cacheKey = "\(from)_\(to)"
        
        print("🔍 CACHE CHECK: Looking for cached data for key: \(cacheKey)")
        print("🔍 ALL CACHED KEYS: \(cachedHistoricalData.keys.sorted())")
        if let cached = cachedHistoricalData[cacheKey] {
            let ageHours = Int(Date().timeIntervalSince(cached.timestamp) / 3600)
            let ageMinutes = Int(Date().timeIntervalSince(cached.timestamp) / 60)
            print("🔍 CACHE FOUND: Age = \(ageHours)h \(ageMinutes % 60)m, Expired = \(cached.isExpired)")
            print("🔍 CACHE DATA: \(cached.data.count) data points from \(cached.fromCurrency) to \(cached.toCurrency)")
        } else {
            print("🔍 CACHE MISS: No cached data found for \(cacheKey)")
        }
        
        // Mock mode - return mock historical data
        if isMockMode {
            let data = generateMockHistoricalData(from: from, to: to, days: days)
            print("📊 Returning \(data.count) mock data points")
            return data
        }
        
        // Check cache first
        if let cached = cachedHistoricalData[cacheKey], !cached.isExpired {
            print("✅ Using cached historical data for \(cacheKey) (age: \(Int(Date().timeIntervalSince(cached.timestamp) / 3600)) hours)")
            return cached.data
        }
        
        // Fetch from API using efficient range endpoint
        print("🌐 MAKING RANGE API CALL: About to fetch \(days) days of data for \(from)→\(to) (THIS WILL USE 1 TOKEN)")
        do {
            let data = try await fetchHistoricalRangeFromAPI(from: from, to: to, days: days)
            
            // Cache the data
            cachedHistoricalData[cacheKey] = CachedHistoricalData(
                data: data,
                timestamp: Date(),
                fromCurrency: from,
                toCurrency: to
            )
            
            print("✅ Fetched historical data for \(cacheKey) (\(data.count) days)")
            return data
            
        } catch {
            print("❌ Historical fetch error: \(error.localizedDescription)")
            // Return cached data even if expired
            if let cached = cachedHistoricalData[cacheKey] {
                print("⚠️ Using expired cache for \(cacheKey)")
                return cached.data
            }
            // Fallback to mock data if API fails
            print("⚠️ API failed, falling back to mock historical data")
            return generateMockHistoricalData(from: from, to: to, days: days)
        }
    }
    
    /// Generate mock historical data for testing
    private func generateMockHistoricalData(from: String, to: String, days: Int) -> [HistoricalRate] {
        print("🧪 Generating mock historical data: \(from) → \(to) for \(days) days")
        
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
        
        print("🧪 Today's rate for \(from)→\(to): \(todaysRate)")
        
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
        
        print("🧪 Generated \(mockData.count) data points, last rate: \(mockData.last?.rate ?? 0)")
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
        let endDate = Date()
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
    
    /// OLD INEFFICIENT METHOD - Fetch historical data from API for a date range (30 separate calls)
    private func fetchHistoricalFromAPI_OLD(from: String, to: String, days: Int) async throws -> [HistoricalRate] {
        let calendar = Calendar.current
        let endDate = Date()
        guard calendar.date(byAdding: .day, value: -days, to: endDate) != nil else {
            throw ExchangeRateError.invalidURL
        }
        
        var historicalData: [HistoricalRate] = []
        
        // Fetch data for each day (CurrencyAPI requires individual date queries)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // To minimize API calls, we'll fetch data for every 1 day
        print("🔄 Starting loop for \(days) days...")
        for dayOffset in (0..<days) {
            print("🔄 Processing day \(dayOffset + 1)/\(days) (offset: \(dayOffset))")
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
                print("🌐 Making API call \(dayOffset + 1)/\(days) to: \(url)")
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
