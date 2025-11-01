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

// MARK: - Exchange Rate Service
@MainActor
class ExchangeRateService: ObservableObject {
    // Published properties for UI updates
    @Published var isLoading: Bool = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    
    // Development mode toggle
    @Published var isMockMode: Bool = true // Set to true for development, false for production
    
    // Private properties
    private let apiKey = "cur_live_ekGkTC1IKGFiCe85LkBEwkjMNnZRA05iaVDqYq6G"
    private let baseURL = "https://api.currencyapi.com/v3/latest"
    private let baseCurrency = "USD" // Using USD as base for all conversions
    
    // Cache storage
    private var cachedRates: CachedRates?
    
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
        do {
            let rates = try await fetchRates()
            
            // If getting rate from base currency (USD)
            if from == baseCurrency {
                return rates[to]
            }
            
            // If getting rate to base currency (USD)
            if to == baseCurrency {
                return 1.0 / (rates[from] ?? 1.0)
            }
            
            // Cross-rate: EUR → GBP = (USD → GBP) ÷ (USD → EUR)
            guard let fromRate = rates[from], let toRate = rates[to] else {
                return nil
            }
            
            return toRate / fromRate
            
        } catch {
            print("❌ Get rate error: \(error.localizedDescription)")
            return nil
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
