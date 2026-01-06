import SwiftUI
import UIKit

@main
struct TiloApp: App {
    init() {
        // Set solid tab bar background color
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "grey700")
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // Set up default currencies based on locale (only on first launch)
        setupDefaultCurrenciesIfNeeded()
        
        // Early adopter flag for future grandfathering
        if !UserDefaults.standard.bool(forKey: "isEarlyAdopter") {
            UserDefaults.standard.set(true, forKey: "isEarlyAdopter")
            UserDefaults.standard.set(Date(), forKey: "earlyAdopterInstallDate")
            UserDefaults.standard.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", forKey: "earlyAdopterVersion")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
    }
    
    /// Sets up default currencies based on user's locale and popular travel destinations
    private func setupDefaultCurrenciesIfNeeded() {
        // Only set defaults if this is the first launch (no saved currency)
        guard UserDefaults.standard.string(forKey: "fromCurrencyCode") == nil else { return }
        
        let localeCurrency = getLocaleCurrency()
        let travelDestination = getPopularTravelDestination(for: localeCurrency.code)
        
        // Set "from" currency (user's local currency)
        UserDefaults.standard.set(localeCurrency.name, forKey: "fromCurrencyName")
        UserDefaults.standard.set(localeCurrency.flag, forKey: "fromFlagEmoji")
        UserDefaults.standard.set(localeCurrency.code, forKey: "fromCurrencyCode")
        
        // Set "to" currency (popular travel destination)
        UserDefaults.standard.set(travelDestination.name, forKey: "toCurrencyName")
        UserDefaults.standard.set(travelDestination.flag, forKey: "toFlagEmoji")
        UserDefaults.standard.set(travelDestination.code, forKey: "toCurrencyCode")
    }
    
    /// Detects the user's local currency from device locale
    private func getLocaleCurrency() -> (code: String, name: String, flag: String) {
        let locale = Locale.current
        let currencyCode = locale.currency?.identifier ?? "USD"
        
        // Map currency codes to names and flags
        let currencyInfo: [String: (name: String, flag: String)] = [
            "USD": ("US Dollar", "🇺🇸"),
            "GBP": ("British Pound", "🇬🇧"),
            "EUR": ("Euro", "🇪🇺"),
            "CAD": ("Canadian Dollar", "🇨🇦"),
            "AUD": ("Australian Dollar", "🇦🇺"),
            "JPY": ("Japanese Yen", "🇯🇵"),
            "CNY": ("Chinese Yuan", "🇨🇳"),
            "INR": ("Indian Rupee", "🇮🇳"),
            "KRW": ("South Korean Won", "🇰🇷"),
            "MXN": ("Mexican Peso", "🇲🇽"),
            "BRL": ("Brazilian Real", "🇧🇷"),
            "CHF": ("Swiss Franc", "🇨🇭"),
            "SEK": ("Swedish Krona", "🇸🇪"),
            "NOK": ("Norwegian Krone", "🇳🇴"),
            "DKK": ("Danish Krone", "🇩🇰"),
            "NZD": ("New Zealand Dollar", "🇳🇿"),
            "SGD": ("Singapore Dollar", "🇸🇬"),
            "HKD": ("Hong Kong Dollar", "🇭🇰"),
            "ZAR": ("South African Rand", "🇿🇦"),
            "AED": ("UAE Dirham", "🇦🇪"),
            "SAR": ("Saudi Riyal", "🇸🇦"),
            "PLN": ("Polish Zloty", "🇵🇱"),
            "THB": ("Thai Baht", "🇹🇭"),
            "IDR": ("Indonesian Rupiah", "🇮🇩"),
            "MYR": ("Malaysian Ringgit", "🇲🇾"),
            "PHP": ("Philippine Peso", "🇵🇭"),
            "TRY": ("Turkish Lira", "🇹🇷"),
            "RUB": ("Russian Ruble", "🇷🇺"),
            "ILS": ("Israeli Shekel", "🇮🇱"),
            "CZK": ("Czech Koruna", "🇨🇿"),
            "HUF": ("Hungarian Forint", "🇭🇺")
        ]
        
        if let info = currencyInfo[currencyCode] {
            return (currencyCode, info.name, info.flag)
        }
        
        // Default to USD if currency not found
        return ("USD", "US Dollar", "🇺🇸")
    }
    
    /// Returns the most popular travel destination currency for a given home currency
    private func getPopularTravelDestination(for homeCurrency: String) -> (code: String, name: String, flag: String) {
        // Based on most popular international travel destinations by country
        let popularDestinations: [String: (code: String, name: String, flag: String)] = [
            // North America
            "USD": ("MXN", "Mexican Peso", "🇲🇽"),        // US → Mexico (#1 destination)
            "CAD": ("USD", "US Dollar", "🇺🇸"),          // Canada → USA
            "MXN": ("USD", "US Dollar", "🇺🇸"),          // Mexico → USA
            
            // Europe
            "GBP": ("EUR", "Euro", "🇪🇺"),               // UK → Spain/France/Italy
            "EUR": ("GBP", "British Pound", "🇬🇧"),      // Eurozone → UK
            "CHF": ("EUR", "Euro", "🇪🇺"),               // Switzerland → EU countries
            "SEK": ("EUR", "Euro", "🇪🇺"),               // Sweden → Spain/Greece
            "NOK": ("EUR", "Euro", "🇪🇺"),               // Norway → Spain/Greece
            "DKK": ("EUR", "Euro", "🇪🇺"),               // Denmark → Spain
            "PLN": ("EUR", "Euro", "🇪🇺"),               // Poland → Spain/Italy
            "CZK": ("EUR", "Euro", "🇪🇺"),               // Czech → Croatia/Spain
            "HUF": ("EUR", "Euro", "🇪🇺"),               // Hungary → Croatia/Italy
            "RUB": ("TRY", "Turkish Lira", "🇹🇷"),       // Russia → Turkey
            
            // Asia Pacific
            "JPY": ("USD", "US Dollar", "🇺🇸"),          // Japan → USA/Hawaii
            "CNY": ("THB", "Thai Baht", "🇹🇭"),          // China → Thailand
            "KRW": ("JPY", "Japanese Yen", "🇯🇵"),       // Korea → Japan
            "AUD": ("IDR", "Indonesian Rupiah", "🇮🇩"),  // Australia → Bali
            "NZD": ("AUD", "Australian Dollar", "🇦🇺"),  // NZ → Australia
            "SGD": ("MYR", "Malaysian Ringgit", "🇲🇾"),  // Singapore → Malaysia
            "HKD": ("JPY", "Japanese Yen", "🇯🇵"),       // Hong Kong → Japan
            "INR": ("THB", "Thai Baht", "🇹🇭"),          // India → Thailand
            "THB": ("JPY", "Japanese Yen", "🇯🇵"),       // Thailand → Japan
            "IDR": ("SGD", "Singapore Dollar", "🇸🇬"),   // Indonesia → Singapore
            "MYR": ("THB", "Thai Baht", "🇹🇭"),          // Malaysia → Thailand
            "PHP": ("JPY", "Japanese Yen", "🇯🇵"),       // Philippines → Japan
            
            // Middle East
            "AED": ("GBP", "British Pound", "🇬🇧"),      // UAE → UK
            "SAR": ("EUR", "Euro", "🇪🇺"),               // Saudi → Europe
            "ILS": ("EUR", "Euro", "🇪🇺"),               // Israel → Europe
            "TRY": ("EUR", "Euro", "🇪🇺"),               // Turkey → Europe
            
            // Africa & South America
            "ZAR": ("EUR", "Euro", "🇪🇺"),               // South Africa → Europe
            "BRL": ("USD", "US Dollar", "🇺🇸")           // Brazil → USA
        ]
        
        if let destination = popularDestinations[homeCurrency] {
            return destination
        }
        
        // Default: EUR as it's widely used for travel
        return ("EUR", "Euro", "🇪🇺")
    }
}

struct AppContentView: View {
    @State private var showSplash = false
    
    var body: some View {
        ZStack {
            HomeView()
                .preferredColorScheme(.dark)
            
            if showSplash {
                SplashScreenView(onFinished: {
                    // Mark that user has seen splash screen today
                    let today = Calendar.current.startOfDay(for: Date())
                    UserDefaults.standard.set(today, forKey: "lastSplashDate")
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear {
            checkShouldShowSplash()
        }
    }
    
    private func checkShouldShowSplash() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get last date splash was shown
        if let lastSplashDate = UserDefaults.standard.object(forKey: "lastSplashDate") as? Date {
            let lastSplashDay = Calendar.current.startOfDay(for: lastSplashDate)
            
            // Show splash if it's a different day
            if today != lastSplashDay {
                showSplash = true
            }
        } else {
            // First time ever - show splash
            showSplash = true
        }
    }
}
