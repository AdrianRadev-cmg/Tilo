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
    @Published var isMockMode: Bool = false // Set to true for development, false for production
    
    // Private properties
    private let apiKey = "cur_live_ekGkTC1IKGFiCe85LkBEwkjMNnZRA05iaVDqYq6G"
    private let baseURL = "https://api.currencyapi.com/v3/latest"
    private let baseCurrency = "USD" // Using USD as base for all conversions
    
    // Cache storage
    private var cachedRates: CachedRates?
    
    // Mock data for development
    private let mockRates: [String: Double] = [
        "EUR": 0.85,
        "GBP": 0.73,
        "JPY": 110.0,
        "CAD": 1.25,
        "AUD": 1.35,
        "CHF": 0.92,
        "CNY": 6.45,
        "SEK": 8.5,
        "NOK": 8.8,
        "USD": 1.0
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
