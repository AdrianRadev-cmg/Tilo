import Foundation

struct Currency: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let name: String
    let flag: String
    
    static let mockData = [
        Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
        Currency(code: "EUR", name: "Euro", flag: "🇪🇺"),
        Currency(code: "USD", name: "US Dollar", flag: "🇺🇸"),
        Currency(code: "JPY", name: "Japanese Yen", flag: "🇯🇵"),
        Currency(code: "AUD", name: "Australian Dollar", flag: "🇦🇺"),
        Currency(code: "CAD", name: "Canadian Dollar", flag: "🇨🇦")
    ]
    
    static let frequentlyUsed = [
        Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
        Currency(code: "EUR", name: "Euro", flag: "🇪🇺")
    ]
} 