import Foundation

struct Currency: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let flag: String
    
    static let mockData = [
        Currency(code: "USD", name: "US Dollar", flag: "🇺🇸"),
        Currency(code: "EUR", name: "Euro", flag: "🇪🇺"),
        Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
        Currency(code: "JPY", name: "Japanese Yen", flag: "🇯🇵"),
        Currency(code: "CAD", name: "Canadian Dollar", flag: "🇨🇦"),
        Currency(code: "AUD", name: "Australian Dollar", flag: "🇦🇺"),
        Currency(code: "CHF", name: "Swiss Franc", flag: "🇨🇭"),
        Currency(code: "CNY", name: "Chinese Yuan", flag: "🇨🇳"),
        Currency(code: "SEK", name: "Swedish Krona", flag: "🇸🇪"),
        Currency(code: "NOK", name: "Norwegian Krone", flag: "🇳🇴")
    ]
    
    static let frequentlyUsed = [
        Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
        Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
    ]
} 