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
        
        // Mark early adopters for future grandfathering (v1.0 users get premium free)
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "isEarlyAdopter")
            UserDefaults.standard.set(Date(), forKey: "firstLaunchDate")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            
            // Set locale-based default currencies for first-time users
            setLocaleBasedDefaults()
        }
    }
    
    private func setLocaleBasedDefaults() {
        let locale = Locale.current
        let regionCode = locale.region?.identifier ?? "US"
        
        // Map region to local currency and popular travel destination
        let (localCurrency, travelCurrency) = getDefaultCurrencies(for: regionCode)
        
        // Set "from" currency (user's local currency)
        UserDefaults.standard.set(localCurrency.name, forKey: "fromCurrencyName")
        UserDefaults.standard.set(localCurrency.flag, forKey: "fromFlagEmoji")
        UserDefaults.standard.set(localCurrency.code, forKey: "fromCurrencyCode")
        
        // Set "to" currency (popular travel destination)
        UserDefaults.standard.set(travelCurrency.name, forKey: "toCurrencyName")
        UserDefaults.standard.set(travelCurrency.flag, forKey: "toFlagEmoji")
        UserDefaults.standard.set(travelCurrency.code, forKey: "toCurrencyCode")
    }
    
    private func getDefaultCurrencies(for regionCode: String) -> (local: (code: String, name: String, flag: String), travel: (code: String, name: String, flag: String)) {
        // Define currency data
        let usd = (code: "USD", name: "US Dollar", flag: "🇺🇸")
        let eur = (code: "EUR", name: "Euro", flag: "🇪🇺")
        let gbp = (code: "GBP", name: "British Pound", flag: "🇬🇧")
        let jpy = (code: "JPY", name: "Japanese Yen", flag: "🇯🇵")
        let cny = (code: "CNY", name: "Chinese Yuan", flag: "🇨🇳")
        let aud = (code: "AUD", name: "Australian Dollar", flag: "🇦🇺")
        let cad = (code: "CAD", name: "Canadian Dollar", flag: "🇨🇦")
        let chf = (code: "CHF", name: "Swiss Franc", flag: "🇨🇭")
        let inr = (code: "INR", name: "Indian Rupee", flag: "🇮🇳")
        let mxn = (code: "MXN", name: "Mexican Peso", flag: "🇲🇽")
        let thb = (code: "THB", name: "Thai Baht", flag: "🇹🇭")
        let sgd = (code: "SGD", name: "Singapore Dollar", flag: "🇸🇬")
        
        switch regionCode {
        // North America
        case "US": return (usd, eur)
        case "CA": return (cad, usd)
        case "MX": return (mxn, usd)
            
        // Europe
        case "GB": return (gbp, eur)
        case "DE", "FR", "IT", "ES", "NL", "BE", "AT", "PT", "IE", "FI", "GR": return (eur, gbp)
        case "CH": return (chf, eur)
            
        // Asia Pacific
        case "JP": return (jpy, usd)
        case "CN", "HK": return (cny, jpy)
        case "AU": return (aud, usd)
        case "SG": return (sgd, mxn)
        case "IN": return (inr, thb)
        case "TH": return (thb, jpy)
            
        // Default: USD -> EUR (most common pair globally)
        default: return (usd, eur)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
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
