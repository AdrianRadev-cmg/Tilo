import Foundation

struct Currency: Identifiable, Hashable, Codable {
    var id: String { code } // Use code as stable identifier for Codable
    let code: String
    let name: String
    let flag: String
    
    // MARK: - Recently Used Management
    private static let recentlyUsedKey = "recentlyUsedCurrencies"
    private static let maxRecentlyUsed = 5
    
    static var recentlyUsed: [Currency] {
        guard let data = UserDefaults.standard.data(forKey: recentlyUsedKey),
              let codes = try? JSONDecoder().decode([String].self, from: data) else {
            // Default to common currencies if no history
            return [
                Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
                Currency(code: "EUR", name: "Euro", flag: "🇪🇺"),
                Currency(code: "USD", name: "US Dollar", flag: "🇺🇸"),
                Currency(code: "JPY", name: "Japanese Yen", flag: "🇯🇵"),
                Currency(code: "THB", name: "Thai Baht", flag: "🇹🇭")
            ]
        }
        
        // Convert codes back to Currency objects
        return codes.compactMap { code in
            mockData.first { $0.code == code }
        }
    }
    
    static func addToRecentlyUsed(_ currency: Currency) {
        var codes = (try? JSONDecoder().decode([String].self, from: UserDefaults.standard.data(forKey: recentlyUsedKey) ?? Data())) ?? []
        
        // Remove if already exists (to move to front)
        codes.removeAll { $0 == currency.code }
        
        // Add to front
        codes.insert(currency.code, at: 0)
        
        // Keep only last 5
        if codes.count > maxRecentlyUsed {
            codes = Array(codes.prefix(maxRecentlyUsed))
        }
        
        // Save
        if let data = try? JSONEncoder().encode(codes) {
            UserDefaults.standard.set(data, forKey: recentlyUsedKey)
        }
    }
    
    // MARK: - All Currencies (sorted alphabetically by name)
    static var allCurrenciesSorted: [Currency] {
        mockData.sorted { $0.name < $1.name }
    }
    
    static let mockData = [
        // Very High-value (5 currencies) - Chips: [1, 5, 10, 20]
        Currency(code: "KWD", name: "Kuwaiti Dinar", flag: "🇰🇼"),
        Currency(code: "BHD", name: "Bahraini Dinar", flag: "🇧🇭"),
        Currency(code: "OMR", name: "Omani Rial", flag: "🇴🇲"),
        Currency(code: "JOD", name: "Jordanian Dinar", flag: "🇯🇴"),
        Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
        
        // High-value (30 currencies) - Chips: [10, 50, 100, 200]
        Currency(code: "EUR", name: "Euro", flag: "🇪🇺"),
        Currency(code: "USD", name: "US Dollar", flag: "🇺🇸"),
        Currency(code: "CHF", name: "Swiss Franc", flag: "🇨🇭"),
        Currency(code: "CAD", name: "Canadian Dollar", flag: "🇨🇦"),
        Currency(code: "AUD", name: "Australian Dollar", flag: "🇦🇺"),
        Currency(code: "NZD", name: "New Zealand Dollar", flag: "🇳🇿"),
        Currency(code: "SGD", name: "Singapore Dollar", flag: "🇸🇬"),
        Currency(code: "AED", name: "UAE Dirham", flag: "🇦🇪"),
        Currency(code: "SAR", name: "Saudi Riyal", flag: "🇸🇦"),
        Currency(code: "QAR", name: "Qatari Riyal", flag: "🇶🇦"),
        Currency(code: "ILS", name: "Israeli Shekel", flag: "🇮🇱"),
        Currency(code: "BND", name: "Brunei Dollar", flag: "🇧🇳"),
        Currency(code: "BSD", name: "Bahamian Dollar", flag: "🇧🇸"),
        Currency(code: "PAB", name: "Panamanian Balboa", flag: "🇵🇦"),
        Currency(code: "FJD", name: "Fijian Dollar", flag: "🇫🇯"),
        Currency(code: "BWP", name: "Botswana Pula", flag: "🇧🇼"),
        Currency(code: "AZN", name: "Azerbaijani Manat", flag: "🇦🇿"),
        Currency(code: "RON", name: "Romanian Leu", flag: "🇷🇴"),
        Currency(code: "GEL", name: "Georgian Lari", flag: "🇬🇪"),
        Currency(code: "PEN", name: "Peruvian Sol", flag: "🇵🇪"),
        Currency(code: "BOB", name: "Bolivian Boliviano", flag: "🇧🇴"),
        Currency(code: "GTQ", name: "Guatemalan Quetzal", flag: "🇬🇹"),
        Currency(code: "UAH", name: "Ukrainian Hryvnia", flag: "🇺🇦"),
        Currency(code: "RSD", name: "Serbian Dinar", flag: "🇷🇸"),
        Currency(code: "JMD", name: "Jamaican Dollar", flag: "🇯🇲"),
        Currency(code: "BBD", name: "Barbadian Dollar", flag: "🇧🇧"),
        Currency(code: "TTD", name: "Trinidad & Tobago Dollar", flag: "🇹🇹"),
        Currency(code: "MUR", name: "Mauritian Rupee", flag: "🇲🇺"),
        Currency(code: "MVR", name: "Maldivian Rufiyaa", flag: "🇲🇻"),
        
        // Medium-value (30 currencies) - Chips: [100, 500, 1000, 2000]
        Currency(code: "CNY", name: "Chinese Yuan", flag: "🇨🇳"),
        Currency(code: "HKD", name: "Hong Kong Dollar", flag: "🇭🇰"),
        Currency(code: "TWD", name: "Taiwan Dollar", flag: "🇹🇼"),
        Currency(code: "SEK", name: "Swedish Krona", flag: "🇸🇪"),
        Currency(code: "NOK", name: "Norwegian Krone", flag: "🇳🇴"),
        Currency(code: "DKK", name: "Danish Krone", flag: "🇩🇰"),
        Currency(code: "PLN", name: "Polish Zloty", flag: "🇵🇱"),
        Currency(code: "CZK", name: "Czech Koruna", flag: "🇨🇿"),
        Currency(code: "MXN", name: "Mexican Peso", flag: "🇲🇽"),
        Currency(code: "ZAR", name: "South African Rand", flag: "🇿🇦"),
        Currency(code: "BRL", name: "Brazilian Real", flag: "🇧🇷"),
        Currency(code: "INR", name: "Indian Rupee", flag: "🇮🇳"),
        Currency(code: "THB", name: "Thai Baht", flag: "🇹🇭"),
        Currency(code: "MYR", name: "Malaysian Ringgit", flag: "🇲🇾"),
        Currency(code: "PHP", name: "Philippine Peso", flag: "🇵🇭"),
        Currency(code: "TRY", name: "Turkish Lira", flag: "🇹🇷"),
        Currency(code: "EGP", name: "Egyptian Pound", flag: "🇪🇬"),
        Currency(code: "RUB", name: "Russian Ruble", flag: "🇷🇺"),
        Currency(code: "MDL", name: "Moldovan Leu", flag: "🇲🇩"),
        Currency(code: "MKD", name: "Macedonian Denar", flag: "🇲🇰"),
        Currency(code: "DOP", name: "Dominican Peso", flag: "🇩🇴"),
        Currency(code: "HNL", name: "Honduran Lempira", flag: "🇭🇳"),
        Currency(code: "NIO", name: "Nicaraguan Córdoba", flag: "🇳🇮"),
        Currency(code: "MAD", name: "Moroccan Dirham", flag: "🇲🇦"),
        Currency(code: "TND", name: "Tunisian Dinar", flag: "🇹🇳"),
        Currency(code: "KES", name: "Kenyan Shilling", flag: "🇰🇪"),
        Currency(code: "UGX", name: "Ugandan Shilling", flag: "🇺🇬"),
        Currency(code: "TZS", name: "Tanzanian Shilling", flag: "🇹🇿"),
        Currency(code: "GHS", name: "Ghanaian Cedi", flag: "🇬🇭"),
        Currency(code: "NAD", name: "Namibian Dollar", flag: "🇳🇦"),
        
        // Low-value (25 currencies) - Chips: [1000, 5000, 10000, 20000]
        Currency(code: "JPY", name: "Japanese Yen", flag: "🇯🇵"),
        Currency(code: "KRW", name: "South Korean Won", flag: "🇰🇷"),
        Currency(code: "HUF", name: "Hungarian Forint", flag: "🇭🇺"),
        Currency(code: "ISK", name: "Icelandic Króna", flag: "🇮🇸"),
        Currency(code: "CLP", name: "Chilean Peso", flag: "🇨🇱"),
        Currency(code: "ARS", name: "Argentine Peso", flag: "🇦🇷"),
        Currency(code: "COP", name: "Colombian Peso", flag: "🇨🇴"),
        Currency(code: "PKR", name: "Pakistani Rupee", flag: "🇵🇰"),
        Currency(code: "LKR", name: "Sri Lankan Rupee", flag: "🇱🇰"),
        Currency(code: "BDT", name: "Bangladeshi Taka", flag: "🇧🇩"),
        Currency(code: "MMK", name: "Myanmar Kyat", flag: "🇲🇲"),
        Currency(code: "NGN", name: "Nigerian Naira", flag: "🇳🇬"),
        Currency(code: "AMD", name: "Armenian Dram", flag: "🇦🇲"),
        Currency(code: "KZT", name: "Kazakhstani Tenge", flag: "🇰🇿"),
        Currency(code: "KGS", name: "Kyrgyzstani Som", flag: "🇰🇬"),
        Currency(code: "ALL", name: "Albanian Lek", flag: "🇦🇱"),
        Currency(code: "RWF", name: "Rwandan Franc", flag: "🇷🇼"),
        Currency(code: "BIF", name: "Burundian Franc", flag: "🇧🇮"),
        Currency(code: "DJF", name: "Djiboutian Franc", flag: "🇩🇯"),
        Currency(code: "GNF", name: "Guinean Franc", flag: "🇬🇳"),
        Currency(code: "KMF", name: "Comorian Franc", flag: "🇰🇲"),
        Currency(code: "MGA", name: "Malagasy Ariary", flag: "🇲🇬"),
        Currency(code: "PYG", name: "Paraguayan Guarani", flag: "🇵🇾"),
        Currency(code: "KHR", name: "Cambodian Riel", flag: "🇰🇭"),
        Currency(code: "MNT", name: "Mongolian Tugrik", flag: "🇲🇳"),
        
        // Very low-value (10 currencies) - Chips: [10000, 50000, 100000, 200000]
        Currency(code: "VND", name: "Vietnamese Dong", flag: "🇻🇳"),
        Currency(code: "IDR", name: "Indonesian Rupiah", flag: "🇮🇩"),
        Currency(code: "IRR", name: "Iranian Rial", flag: "🇮🇷"),
        Currency(code: "LAK", name: "Lao Kip", flag: "🇱🇦"),
        Currency(code: "UZS", name: "Uzbekistani Som", flag: "🇺🇿"),
        Currency(code: "SLL", name: "Sierra Leonean Leone", flag: "🇸🇱"),
        Currency(code: "LBP", name: "Lebanese Pound", flag: "🇱🇧"),
        Currency(code: "SYP", name: "Syrian Pound", flag: "🇸🇾"),
        Currency(code: "STN", name: "São Tomé & Príncipe Dobra", flag: "🇸🇹"),
        Currency(code: "VES", name: "Venezuelan Bolívar", flag: "🇻🇪"),
        
        // Additional currencies (61 new) - Expanded coverage
        Currency(code: "AFN", name: "Afghan Afghani", flag: "🇦🇫"),
        Currency(code: "ANG", name: "NL Antillean Guilder", flag: "🌍"),
        Currency(code: "AOA", name: "Angolan Kwanza", flag: "🇦🇴"),
        Currency(code: "AWG", name: "Aruban Florin", flag: "🇦🇼"),
        Currency(code: "BAM", name: "Bosnia-Herzegovina Convertible Mark", flag: "🇧🇦"),
        Currency(code: "BMD", name: "Bermudan Dollar", flag: "🇧🇲"),
        Currency(code: "BTN", name: "Bhutanese Ngultrum", flag: "🇧🇹"),
        Currency(code: "BYN", name: "Belarusian ruble", flag: "🇧🇾"),
        Currency(code: "BZD", name: "Belize Dollar", flag: "🇧🇿"),
        Currency(code: "CDF", name: "Congolese Franc", flag: "🇨🇩"),
        Currency(code: "CLF", name: "Unidad de Fomento", flag: "🇨🇱"),
        Currency(code: "CRC", name: "Costa Rican Colón", flag: "🇨🇷"),
        Currency(code: "CUC", name: "Cuban Convertible Peso", flag: "🌍"),
        Currency(code: "CUP", name: "Cuban Peso", flag: "🇨🇺"),
        Currency(code: "CVE", name: "Cape Verdean Escudo", flag: "🇨🇻"),
        Currency(code: "DZD", name: "Algerian Dinar", flag: "🇩🇿"),
        Currency(code: "ERN", name: "Eritrean Nakfa", flag: "🇪🇷"),
        Currency(code: "ETB", name: "Ethiopian Birr", flag: "🇪🇹"),
        Currency(code: "FKP", name: "Falkland Islands Pound", flag: "🇫🇰"),
        Currency(code: "GGP", name: "Guernsey pound", flag: "🌍"),
        Currency(code: "GIP", name: "Gibraltar Pound", flag: "🇬🇮"),
        Currency(code: "GMD", name: "Gambian Dalasi", flag: "🇬🇲"),
        Currency(code: "GYD", name: "Guyanaese Dollar", flag: "🇬🇾"),
        Currency(code: "HTG", name: "Haitian Gourde", flag: "🇭🇹"),
        Currency(code: "IMP", name: "Manx pound", flag: "🌍"),
        Currency(code: "IQD", name: "Iraqi Dinar", flag: "🇮🇶"),
        Currency(code: "JEP", name: "Jersey pound", flag: "🌍"),
        Currency(code: "KPW", name: "North Korean Won", flag: "🇰🇵"),
        Currency(code: "KYD", name: "Cayman Islands Dollar", flag: "🇰🇾"),
        Currency(code: "LRD", name: "Liberian Dollar", flag: "🇱🇷"),
        Currency(code: "LSL", name: "Lesotho Loti", flag: "🇱🇸"),
        Currency(code: "LYD", name: "Libyan Dinar", flag: "🇱🇾"),
        Currency(code: "MOP", name: "Macanese Pataca", flag: "🇲🇴"),
        Currency(code: "MRU", name: "Mauritanian ouguiya", flag: "🇲🇷"),
        Currency(code: "MWK", name: "Malawian Kwacha", flag: "🇲🇼"),
        Currency(code: "MZN", name: "Mozambican Metical", flag: "🇲🇿"),
        Currency(code: "NPR", name: "Nepalese Rupee", flag: "🇳🇵"),
        Currency(code: "PGK", name: "Papua New Guinean Kina", flag: "🇵🇬"),
        Currency(code: "SBD", name: "Solomon Islands Dollar", flag: "🇸🇧"),
        Currency(code: "SCR", name: "Seychellois Rupee", flag: "🇸🇨"),
        Currency(code: "SDG", name: "Sudanese Pound", flag: "🇸🇩"),
        Currency(code: "SHP", name: "Saint Helena Pound", flag: "🇸🇭"),
        Currency(code: "SLE", name: "Sierra Leonean leone", flag: "🇸🇱"),
        Currency(code: "SOS", name: "Somali Shilling", flag: "🇸🇴"),
        Currency(code: "SRD", name: "Surinamese Dollar", flag: "🇸🇷"),
        Currency(code: "SVC", name: "Salvadoran Colón", flag: "🌍"),
        Currency(code: "SZL", name: "Swazi Lilangeni", flag: "🇸🇿"),
        Currency(code: "TJS", name: "Tajikistani Somoni", flag: "🇹🇯"),
        Currency(code: "TMT", name: "Turkmenistani Manat", flag: "🇹🇲"),
        Currency(code: "TOP", name: "Tongan Paʻanga", flag: "🇹🇴"),
        Currency(code: "UYU", name: "Uruguayan Peso", flag: "🇺🇾"),
        Currency(code: "VUV", name: "Vanuatu Vatu", flag: "🇻🇺"),
        Currency(code: "WST", name: "Samoan Tala", flag: "🇼🇸"),
        Currency(code: "XAF", name: "CFA Franc BEAC", flag: "🇨🇫"),
        Currency(code: "XCD", name: "East Caribbean Dollar", flag: "🇦🇬"),
        Currency(code: "XCG", name: "Caribbean guilder", flag: "🇨🇼"),
        Currency(code: "XOF", name: "CFA Franc BCEAO", flag: "🇧🇫"),
        Currency(code: "XPF", name: "CFP Franc", flag: "🇳🇨"),
        Currency(code: "YER", name: "Yemeni Rial", flag: "🇾🇪"),
        Currency(code: "ZMW", name: "Zambian Kwacha", flag: "🇿🇲"),
        Currency(code: "ZWG", name: "Zimbabwe Gold", flag: "🇿🇼")
    ]
}
