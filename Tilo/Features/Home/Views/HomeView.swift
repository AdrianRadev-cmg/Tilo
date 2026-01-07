//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI
import Charts
import WidgetKit
import StoreKit

// Helper extension to dismiss keyboard
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Locale-based Currency Defaults
struct LocaleCurrencyDefaults {
    /// Returns the default "from" currency based on user's region
    static func getHomeCurrency() -> (code: String, name: String, flag: String) {
        let regionCode = Locale.current.region?.identifier ?? "US"
        
        switch regionCode {
        // Americas
        case "US": return ("USD", "US Dollar", "🇺🇸")
        case "CA": return ("CAD", "Canadian Dollar", "🇨🇦")
        case "MX": return ("MXN", "Mexican Peso", "🇲🇽")
        case "BR": return ("BRL", "Brazilian Real", "🇧🇷")
        case "AR": return ("ARS", "Argentine Peso", "🇦🇷")
        case "CO": return ("COP", "Colombian Peso", "🇨🇴")
        case "CL": return ("CLP", "Chilean Peso", "🇨🇱")
        case "PE": return ("PEN", "Peruvian Sol", "🇵🇪")
            
        // Europe
        case "GB": return ("GBP", "British Pound", "🇬🇧")
        case "DE", "FR", "IT", "ES", "NL", "BE", "AT", "IE", "PT", "FI", "GR": return ("EUR", "Euro", "🇪🇺")
        case "CH": return ("CHF", "Swiss Franc", "🇨🇭")
        case "SE": return ("SEK", "Swedish Krona", "🇸🇪")
        case "NO": return ("NOK", "Norwegian Krone", "🇳🇴")
        case "DK": return ("DKK", "Danish Krone", "🇩🇰")
        case "PL": return ("PLN", "Polish Zloty", "🇵🇱")
        case "CZ": return ("CZK", "Czech Koruna", "🇨🇿")
        case "HU": return ("HUF", "Hungarian Forint", "🇭🇺")
        case "RO": return ("RON", "Romanian Leu", "🇷🇴")
        case "RU": return ("RUB", "Russian Ruble", "🇷🇺")
        case "UA": return ("UAH", "Ukrainian Hryvnia", "🇺🇦")
        case "TR": return ("TRY", "Turkish Lira", "🇹🇷")
            
        // Asia Pacific
        case "AU": return ("AUD", "Australian Dollar", "🇦🇺")
        case "NZ": return ("NZD", "New Zealand Dollar", "🇳🇿")
        case "JP": return ("JPY", "Japanese Yen", "🇯🇵")
        case "KR": return ("KRW", "South Korean Won", "🇰🇷")
        case "CN": return ("CNY", "Chinese Yuan", "🇨🇳")
        case "HK": return ("HKD", "Hong Kong Dollar", "🇭🇰")
        case "TW": return ("TWD", "Taiwan Dollar", "🇹🇼")
        case "SG": return ("SGD", "Singapore Dollar", "🇸🇬")
        case "MY": return ("MYR", "Malaysian Ringgit", "🇲🇾")
        case "TH": return ("THB", "Thai Baht", "🇹🇭")
        case "ID": return ("IDR", "Indonesian Rupiah", "🇮🇩")
        case "PH": return ("PHP", "Philippine Peso", "🇵🇭")
        case "VN": return ("VND", "Vietnamese Dong", "🇻🇳")
        case "IN": return ("INR", "Indian Rupee", "🇮🇳")
        case "PK": return ("PKR", "Pakistani Rupee", "🇵🇰")
            
        // Middle East
        case "AE": return ("AED", "UAE Dirham", "🇦🇪")
        case "SA": return ("SAR", "Saudi Riyal", "🇸🇦")
        case "IL": return ("ILS", "Israeli Shekel", "🇮🇱")
        case "EG": return ("EGP", "Egyptian Pound", "🇪🇬")
            
        // Africa
        case "ZA": return ("ZAR", "South African Rand", "🇿🇦")
        case "NG": return ("NGN", "Nigerian Naira", "🇳🇬")
        case "KE": return ("KES", "Kenyan Shilling", "🇰🇪")
            
        default: return ("USD", "US Dollar", "🇺🇸")
        }
    }
    
    /// Returns popular travel destination currency based on user's region
    static func getTravelDestinationCurrency() -> (code: String, name: String, flag: String) {
        let regionCode = Locale.current.region?.identifier ?? "US"
        
        // Based on most popular international travel destinations for each country
        switch regionCode {
        // Americas
        case "US": return ("MXN", "Mexican Peso", "🇲🇽")           // Mexico is #1 destination for Americans
        case "CA": return ("USD", "US Dollar", "🇺🇸")              // US is #1 for Canadians
        case "MX": return ("USD", "US Dollar", "🇺🇸")              // US is #1 for Mexicans
        case "BR": return ("USD", "US Dollar", "🇺🇸")              // US popular for Brazilians
        case "AR": return ("BRL", "Brazilian Real", "🇧🇷")         // Brazil popular for Argentinians
        case "CO": return ("USD", "US Dollar", "🇺🇸")              // US popular for Colombians
            
        // UK & Europe
        case "GB": return ("EUR", "Euro", "🇪🇺")                   // Europe is #1 for Brits
        case "DE": return ("EUR", "Euro", "🇪🇺")                   // Spain/Italy for Germans (still EUR)
        case "FR": return ("EUR", "Euro", "🇪🇺")                   // Spain/Italy for French
        case "IT": return ("EUR", "Euro", "🇪🇺")                   // Spain/France for Italians
        case "ES": return ("EUR", "Euro", "🇪🇺")                   // France/Portugal for Spanish
        case "NL": return ("EUR", "Euro", "🇪🇺")                   // Germany/Spain for Dutch
        case "CH": return ("EUR", "Euro", "🇪🇺")                   // Europe for Swiss
        case "SE", "NO", "DK": return ("EUR", "Euro", "🇪🇺")       // Southern Europe for Nordics
        case "PL": return ("EUR", "Euro", "🇪🇺")                   // Western Europe for Poles
        case "RU": return ("TRY", "Turkish Lira", "🇹🇷")           // Turkey popular for Russians
        case "TR": return ("EUR", "Euro", "🇪🇺")                   // Europe for Turks
            
        // Asia Pacific
        case "AU": return ("IDR", "Indonesian Rupiah", "🇮🇩")      // Bali is #1 for Australians
        case "NZ": return ("AUD", "Australian Dollar", "🇦🇺")      // Australia is #1 for Kiwis
        case "JP": return ("USD", "US Dollar", "🇺🇸")              // Hawaii/US popular for Japanese
        case "KR": return ("JPY", "Japanese Yen", "🇯🇵")           // Japan is #1 for Koreans
        case "CN": return ("THB", "Thai Baht", "🇹🇭")              // Thailand popular for Chinese
        case "HK": return ("JPY", "Japanese Yen", "🇯🇵")           // Japan popular for Hong Kongers
        case "TW": return ("JPY", "Japanese Yen", "🇯🇵")           // Japan popular for Taiwanese
        case "SG": return ("MYR", "Malaysian Ringgit", "🇲🇾")      // Malaysia popular for Singaporeans
        case "MY": return ("THB", "Thai Baht", "🇹🇭")              // Thailand popular for Malaysians
        case "TH": return ("JPY", "Japanese Yen", "🇯🇵")           // Japan popular for Thais
        case "ID": return ("SGD", "Singapore Dollar", "🇸🇬")       // Singapore popular for Indonesians
        case "IN": return ("AED", "UAE Dirham", "🇦🇪")             // Dubai popular for Indians
            
        // Middle East
        case "AE", "SA": return ("GBP", "British Pound", "🇬🇧")    // UK popular for Gulf residents
        case "IL": return ("EUR", "Euro", "🇪🇺")                   // Europe popular for Israelis
            
        // Africa
        case "ZA": return ("EUR", "Euro", "🇪🇺")                   // Europe popular for South Africans
        case "NG": return ("GBP", "British Pound", "🇬🇧")          // UK popular for Nigerians
            
        default: return ("EUR", "Euro", "🇪🇺")
        }
    }
}

struct HomeView: View {
    @State private var selectedTab = 0
    
    // Use locale-based defaults for first-time users
    @State private var fromCurrencyName = UserDefaults.standard.string(forKey: "fromCurrencyName") ?? LocaleCurrencyDefaults.getHomeCurrency().name
    @State private var fromFlagEmoji = UserDefaults.standard.string(forKey: "fromFlagEmoji") ?? LocaleCurrencyDefaults.getHomeCurrency().flag
    @State private var fromCurrencyCode = UserDefaults.standard.string(forKey: "fromCurrencyCode") ?? LocaleCurrencyDefaults.getHomeCurrency().code
    @State private var fromAmount: Double = UserDefaults.standard.double(forKey: "fromAmount") != 0 ? UserDefaults.standard.double(forKey: "fromAmount") : 100.00
    
    @State private var toCurrencyName = UserDefaults.standard.string(forKey: "toCurrencyName") ?? LocaleCurrencyDefaults.getTravelDestinationCurrency().name
    @State private var toFlagEmoji = UserDefaults.standard.string(forKey: "toFlagEmoji") ?? LocaleCurrencyDefaults.getTravelDestinationCurrency().flag
    @State private var toCurrencyCode = UserDefaults.standard.string(forKey: "toCurrencyCode") ?? LocaleCurrencyDefaults.getTravelDestinationCurrency().code
    @State private var toAmount: Double = UserDefaults.standard.double(forKey: "toAmount") != 0 ? UserDefaults.standard.double(forKey: "toAmount") : 100.00
    
    @State private var exchangeRate: Double = 0.0
    @State private var rateLastFetched: Date = Date() // Track when rate was actually fetched from API
    @State private var isLoadingRate: Bool = false
    @State private var isEditingTopCard: Bool = false
    @State private var isEditingBottomCard: Bool = false
    @State private var activeEditingCard: String? = nil // Track which card is actively being edited
    @State private var swapOffset: CGFloat = 0 // For swap animation
    @State private var isSwapping: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @StateObject private var exchangeService = ExchangeRateService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Environment(\.requestReview) private var requestReview
    
    // Preview-only debug controls
    var tintOpacity: Double = 0.6
    var tintBlendMode: BlendMode = .normal
    var gradientColor1: Color = Color(red: 0.18, green: 0.09, blue: 0.38)
    var gradientColor2: Color = Color(red: 0.21, green: 0.10, blue: 0.42)
    var gradientColor3: Color = Color(red: 0.24, green: 0.11, blue: 0.48)
    var gradientColor4: Color = Color(red: 0.13, green: 0.05, blue: 0.26)
    var gradientColor5: Color = Color(red: 0.08, green: 0.03, blue: 0.15)
    
    // Save currency state to UserDefaults (both standard and shared for widget)
    private func saveCurrencyState() {
        // Save to standard UserDefaults (for app persistence)
        UserDefaults.standard.set(fromCurrencyName, forKey: "fromCurrencyName")
        UserDefaults.standard.set(fromFlagEmoji, forKey: "fromFlagEmoji")
        UserDefaults.standard.set(fromCurrencyCode, forKey: "fromCurrencyCode")
        UserDefaults.standard.set(fromAmount, forKey: "fromAmount")
        
        UserDefaults.standard.set(toCurrencyName, forKey: "toCurrencyName")
        UserDefaults.standard.set(toFlagEmoji, forKey: "toFlagEmoji")
        UserDefaults.standard.set(toCurrencyCode, forKey: "toCurrencyCode")
        UserDefaults.standard.set(toAmount, forKey: "toAmount")
        
        // Save to shared UserDefaults for widget
        updateWidgetData()
    }
    
    // Update widget with current currency pair and rate
    private func updateWidgetData() {
        let currencyPair = CurrencyPair(
            fromCode: fromCurrencyCode,
            fromName: fromCurrencyName,
            fromFlag: fromFlagEmoji,
            toCode: toCurrencyCode,
            toName: toCurrencyName,
            toFlag: toFlagEmoji,
            exchangeRate: exchangeRate > 0 ? exchangeRate : nil,
            lastUpdated: rateLastFetched // Use actual API fetch time, not current time
        )
        
        SharedCurrencyDataManager.shared.currentCurrencyPair = currencyPair
        
        // Reload widget timeline
        WidgetCenter.shared.reloadTimelines(ofKind: "TiloWidget")
    }
    
    // MARK: - App Store Review Prompt
    /// Triggers review prompt after first manual conversion (not from quick chips)
    private func triggerReviewIfFirstManualConversion() {
        let hasPromptedReview = UserDefaults.standard.bool(forKey: "hasPromptedForReview")
        
        // Only prompt once, after first manual conversion
        guard !hasPromptedReview else { return }
        
        // Mark that we've prompted
        UserDefaults.standard.set(true, forKey: "hasPromptedForReview")
        
        // Delay slightly so user sees their conversion result first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            requestReview()
        }
    }
    
    private func swapCurrencies() {
        // Prevent multiple swaps during animation
        guard !isSwapping else { return }
        isSwapping = true
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Animate cards moving towards each other
        withAnimation(.easeIn(duration: 0.15)) {
            swapOffset = 80 // Cards move towards center
        }
        
        // At midpoint, swap the data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
        // Swap the currency values
        let tempName = fromCurrencyName
        let tempFlag = fromFlagEmoji
        let tempCode = fromCurrencyCode
            let tempAmount = fromAmount
        
        fromCurrencyName = toCurrencyName
        fromFlagEmoji = toFlagEmoji
        fromCurrencyCode = toCurrencyCode
            fromAmount = toAmount
        
        toCurrencyName = tempName
        toFlagEmoji = tempFlag
        toCurrencyCode = tempCode
            toAmount = tempAmount
            
            // Animate cards moving back to original positions
            withAnimation(.easeOut(duration: 0.15)) {
                swapOffset = 0
            }
            
            // Reset swapping state after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isSwapping = false
            }
        }
        
        // Save state
        saveCurrencyState()
        
        // Update conversion after swap
        Task {
            await updateConversion()
        }
    }
    
    private func updateConversion() async {
        // Don't update if bottom card is being edited
        guard !isEditingBottomCard else { return }
        
        isLoadingRate = true
        showError = false
        
        // Get exchange rate
        if let rate = await exchangeService.getRate(from: fromCurrencyCode, to: toCurrencyCode) {
            exchangeRate = rate
            rateLastFetched = Date() // Track when rate was actually fetched
            
            // Convert amount from top card to bottom card
            if let converted = await exchangeService.convert(amount: fromAmount, from: fromCurrencyCode, to: toCurrencyCode) {
                toAmount = converted
            }
            
            // Update widget with new rate
            updateWidgetData()
        } else {
            // Show error if rate couldn't be fetched
            if let serviceError = exchangeService.errorMessage {
                errorMessage = serviceError
            } else {
                errorMessage = "Unable to fetch exchange rates. Please check your connection."
            }
            showError = true
        }
        
        isLoadingRate = false
    }
    
    private func updateConversionReverse() async {
        // Don't update if top card is being edited
        guard !isEditingTopCard else { return }
        
        isLoadingRate = true
        showError = false
        
        // Get exchange rate
        if let rate = await exchangeService.getRate(from: fromCurrencyCode, to: toCurrencyCode) {
            exchangeRate = rate
            rateLastFetched = Date() // Track when rate was actually fetched
            
            // Convert amount from bottom card to top card (reverse)
            if let converted = await exchangeService.convert(amount: toAmount, from: toCurrencyCode, to: fromCurrencyCode) {
                fromAmount = converted
            }
            
            // Update widget with new rate
            updateWidgetData()
        } else {
            // Show error if rate couldn't be fetched
            if let serviceError = exchangeService.errorMessage {
                errorMessage = serviceError
            } else {
                errorMessage = "Unable to fetch exchange rates. Please check your connection."
            }
            showError = true
        }
        
        isLoadingRate = false
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
    }
    
    private func getCurrencySymbol(for code: String) -> String {
        switch code {
        case "USD", "CAD", "AUD", "NZD", "SGD", "HKD", "MXN", "ARS", "CLP", "COP": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY", "CNY": return "¥"
        case "KRW": return "₩"
        case "INR": return "₹"
        case "RUB": return "₽"
        case "THB": return "฿"
        case "CHF": return "Fr"
        case "SEK", "NOK", "DKK", "ISK": return "kr"
        case "PLN": return "zł"
        case "CZK": return "Kč"
        case "HUF": return "Ft"
        case "TRY": return "₺"
        case "ZAR": return "R"
        case "BRL": return "R$"
        case "ILS": return "₪"
        case "AED", "SAR", "QAR": return "﷼"
        case "PHP": return "₱"
        case "MYR": return "RM"
        case "IDR": return "Rp"
        case "VND": return "₫"
        case "EGP": return "E£"
        case "NGN": return "₦"
        case "KES", "UGX", "TZS": return "Sh"
        case "PKR", "LKR", "NPR": return "Rs"
        default: return code
        }
    }
    
    private func formatExchangeRate(_ rate: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: rate)) ?? String(format: "%.4f", rate)
    }
    
    // Get appropriate chip amounts based on currency value category
    private func getChipAmounts(for currencyCode: String) -> [Double] {
        // Very high-value currencies - [10, 50, 100, 200, 500, 1000]
        let veryHighValue: Set<String> = ["KWD", "BHD", "OMR", "JOD", "GBP"]
        if veryHighValue.contains(currencyCode) {
            return [10, 50, 100, 200, 500, 1000]
        }
        
        // High-value currencies - [10, 50, 100, 200, 500, 1000]
        let highValue: Set<String> = [
            "EUR", "USD", "CHF", "CAD", "AUD", "NZD", "SGD", "AED", "SAR", "QAR",
            "ILS", "BND", "BSD", "PAB", "FJD", "BWP", "AZN", "RON", "BGN", "GEL",
            "PEN", "BOB", "GTQ", "UAH", "RSD", "JMD", "BBD", "TTD", "MUR", "MVR"
        ]
        if highValue.contains(currencyCode) {
            return [10, 50, 100, 200, 500, 1000]
        }
        
        // Medium-value currencies - [100, 500, 1000, 2000, 5000, 10000]
        let mediumValue: Set<String> = [
            "CNY", "HKD", "TWD", "SEK", "NOK", "DKK", "PLN", "CZK", "MXN", "ZAR",
            "BRL", "INR", "THB", "MYR", "PHP", "TRY", "EGP", "RUB", "MDL", "MKD",
            "DOP", "HNL", "NIO", "MAD", "TND", "KES", "UGX", "TZS", "GHS", "NAD"
        ]
        if mediumValue.contains(currencyCode) {
            return [100, 500, 1000, 2000, 5000, 10000]
        }
        
        // Low-value currencies - [1000, 5000, 10000, 20000, 50000, 100000]
        let lowValue: Set<String> = [
            "JPY", "KRW", "HUF", "ISK", "CLP", "ARS", "COP", "PKR", "LKR", "BDT",
            "MMK", "NGN", "AMD", "KZT", "KGS", "ALL", "RWF", "BIF", "DJF", "GNF",
            "KMF", "MGA", "PYG", "KHR", "MNT"
        ]
        if lowValue.contains(currencyCode) {
            return [1000, 5000, 10000, 20000, 50000, 100000]
        }
        
        // Very low-value currencies - [10000, 50000, 100000, 200000, 500000, 1000000]
        let veryLowValue: Set<String> = [
            "VND", "IDR", "IRR", "LAK", "UZS", "SLL", "LBP", "SYP", "STN", "VES"
        ]
        if veryLowValue.contains(currencyCode) {
            return [10000, 50000, 100000, 200000, 500000, 1000000]
        }
        
        // Default to high-value for any unlisted currencies
        return [10, 50, 100, 200, 500, 1000]
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            ZStack(alignment: .top) {
                // Base purple gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        Gradient.Stop(color: Color(red: 0.18, green: 0.09, blue: 0.38), location: 0.00),
                        Gradient.Stop(color: Color(red: 0.21, green: 0.10, blue: 0.42), location: 0.06),
                        Gradient.Stop(color: Color(red: 0.24, green: 0.11, blue: 0.48), location: 0.09),
                        Gradient.Stop(color: Color(red: 0.13, green: 0.05, blue: 0.26), location: 0.38),
                        Gradient.Stop(color: Color(red: 0.08, green: 0.03, blue: 0.15), location: 1.00)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .overlay(Color.black.opacity(0.30))
                .ignoresSafeArea()
                
                GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Offline indicator - only shown when disconnected
                        if !networkMonitor.isConnected {
                            HStack {
                                OfflineIndicatorChip(lastUpdated: exchangeService.lastUpdated)
                                Spacer()
                            }
                            .padding(.horizontal, max(16, geometry.size.width * 0.04))
                            .padding(.top, min(40, geometry.size.height * 0.05))
                            .padding(.bottom, 12)
                        }
                        
                        // Purple section with currency cards
                        ZStack {
                            VStack(alignment: .leading, spacing: 12) {
                                CurrencyCard(
                                    currencyName: $fromCurrencyName,
                                    flagEmoji: $fromFlagEmoji,
                                    currencyCode: $fromCurrencyCode,
                                        amount: formatAmount(fromAmount),
                                        exchangeRateInfo: exchangeRate > 0 ? "1 \(fromCurrencyCode) = \(formatExchangeRate(exchangeRate)) \(toCurrencyCode)" : "Loading rate...",
                                        currencySymbol: getCurrencySymbol(for: fromCurrencyCode),
                                        onAmountChange: { newAmount in
                                            fromAmount = newAmount
                                            saveCurrencyState()
                                            Task {
                                                await updateConversion()
                                            }
                                        },
                                        onEditingChanged: { isEditing in
                                            isEditingTopCard = isEditing
                                            if isEditing {
                                                activeEditingCard = "top"
                                                isEditingBottomCard = false
                                            } else {
                                                activeEditingCard = nil
                                                // Trigger review prompt after first manual conversion
                                                triggerReviewIfFirstManualConversion()
                                            }
                                        },
                                        isEditable: true,
                                        isCurrentlyActive: activeEditingCard == "top" || activeEditingCard == nil,
                                        tintOpacity: tintOpacity,
                                        tintBlendMode: tintBlendMode,
                                        gradientColor1: gradientColor1,
                                        gradientColor2: gradientColor2,
                                        gradientColor3: gradientColor3,
                                        gradientColor4: gradientColor4,
                                        gradientColor5: gradientColor5
                                    )
                                    .padding(.horizontal, max(16, geometry.size.width * 0.04))
                                    .offset(y: swapOffset) // Animate down during swap
                                    .onChange(of: fromCurrencyCode) { oldValue, newValue in
                                        saveCurrencyState()
                                        Task {
                                            await updateConversion()
                                        }
                                    }
                                
                                CurrencyCard(
                                    currencyName: $toCurrencyName,
                                    flagEmoji: $toFlagEmoji,
                                    currencyCode: $toCurrencyCode,
                                        amount: formatAmount(toAmount),
                                        exchangeRateInfo: exchangeRate > 0 ? "1 \(toCurrencyCode) = \(formatExchangeRate(1.0 / exchangeRate)) \(fromCurrencyCode)" : "Loading rate...",
                                        currencySymbol: getCurrencySymbol(for: toCurrencyCode),
                                        onAmountChange: { newAmount in
                                            toAmount = newAmount
                                            saveCurrencyState()
                                            Task {
                                                await updateConversionReverse()
                                            }
                                        },
                                        onEditingChanged: { isEditing in
                                            isEditingBottomCard = isEditing
                                            if isEditing {
                                                activeEditingCard = "bottom"
                                                isEditingTopCard = false
                                            } else {
                                                activeEditingCard = nil
                                                // Trigger review prompt after first manual conversion
                                                triggerReviewIfFirstManualConversion()
                                            }
                                        },
                                        isEditable: true,
                                        isCurrentlyActive: activeEditingCard == "bottom" || activeEditingCard == nil,
                                        tintOpacity: tintOpacity,
                                        tintBlendMode: tintBlendMode,
                                        gradientColor1: gradientColor1,
                                        gradientColor2: gradientColor2,
                                        gradientColor3: gradientColor3,
                                        gradientColor4: gradientColor4,
                                        gradientColor5: gradientColor5
                                    )
                                    .padding(.horizontal, max(16, geometry.size.width * 0.04))
                                    .offset(y: -swapOffset) // Animate up during swap
                                    .onChange(of: toCurrencyCode) { oldValue, newValue in
                                        saveCurrencyState()
                                        Task {
                                            await updateConversion()
                                        }
                                    }
                            }
                            
                            // SwapButton centered and always on top
                                SwapButton(action: swapCurrencies)
                        }
                        .padding(.top, networkMonitor.isConnected ? min(40, geometry.size.height * 0.05) : 0)
                        
                        // Error banner (if any)
                        if showError {
                            ErrorBanner(
                                message: errorMessage,
                                onDismiss: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showError = false
                                    }
                                }
                            )
                            .padding(.horizontal, max(16, geometry.size.width * 0.04))
                            .padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Quick conversions section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Quick conversions")
                                .font(.title2)
                                .foregroundColor(.white)
                                .dynamicTypeSize(.large) // Fixed size for layout stability
                                .padding(.horizontal, max(16, geometry.size.width * 0.04))
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(getChipAmounts(for: fromCurrencyCode), id: \.self) { amount in
                                    QuickAmountChip(
                                            symbol: getCurrencySymbol(for: fromCurrencyCode),
                                        amount: amount,
                                        selectedAmount: .constant(0),
                                            onSelect: { selectedAmount in
                                                // Fill top card with selected amount
                                                fromAmount = selectedAmount
                                                saveCurrencyState()
                                                // Trigger conversion
                                                Task {
                                                    await updateConversion()
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, max(16, geometry.size.width * 0.04))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 32)
                        
                        // Rate history section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Rate history")
                                .font(.title2)
                                .foregroundColor(.white)
                                .dynamicTypeSize(.large) // Fixed size for layout stability
                            
                        CurrencyChartView(fromCurrency: fromCurrencyCode, toCurrency: toCurrencyCode)
                                .id("\(fromCurrencyCode)-\(toCurrencyCode)")
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 32)
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        .padding(.bottom, min(40, geometry.size.height * 0.05))
                    }
                    }
                    .simultaneousGesture(
                        DragGesture().onChanged { _ in
                            hideKeyboard()
                        }
                    )
                    .scrollDismissesKeyboard(.interactively)
                }
                .ignoresSafeArea(.keyboard) // Prevent layout jump when keyboard opens/closes
            }
            .tabItem {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                Text("Convert")
            }
            .tag(0)
            .task {
                // Fetch rates when view appears
                await updateConversion()
            }
            
            // Price guide Tab
            TravelView(
                fromCurrencyCode: $fromCurrencyCode,
                fromCurrencyName: $fromCurrencyName,
                fromFlagEmoji: $fromFlagEmoji,
                toCurrencyCode: $toCurrencyCode,
                toCurrencyName: $toCurrencyName,
                toFlagEmoji: $toFlagEmoji
            )
                .tabItem {
                Image(systemName: "tablecells.fill")
                Text("Price guide")
                }
                .tag(1)
        }
        .tint(Color("primary100"))
    }
}

#Preview("Default") {
    HomeView()
        .preferredColorScheme(.dark)
}

#Preview("Debug Controls") {
    DebugHomeViewWrapper()
        .preferredColorScheme(.dark)
}

#Preview("Design Backdrop") {
    DesignBackdropWrapper()
        .preferredColorScheme(.dark)
}

// MARK: - Preview Debug Helpers

struct DebugHomeViewWrapper: View {
    @State private var tintOpacity: Double = 0.6
    @State private var blendMode: BlendMode = .normal
    @State private var showControls: Bool = true
    @State private var showColorPickers: Bool = false
    
    // Gradient colors
    @State private var gradientColor1: Color = Color(red: 0.18, green: 0.09, blue: 0.38)
    @State private var gradientColor2: Color = Color(red: 0.21, green: 0.10, blue: 0.42)
    @State private var gradientColor3: Color = Color(red: 0.24, green: 0.11, blue: 0.48)
    @State private var gradientColor4: Color = Color(red: 0.13, green: 0.05, blue: 0.26)
    @State private var gradientColor5: Color = Color(red: 0.08, green: 0.03, blue: 0.15)
    
    // API mode control
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    var body: some View {
        ZStack {
            HomeView(
                tintOpacity: tintOpacity,
                tintBlendMode: blendMode,
                gradientColor1: gradientColor1,
                gradientColor2: gradientColor2,
                gradientColor3: gradientColor3,
                gradientColor4: gradientColor4,
                gradientColor5: gradientColor5
            )
            
            if showControls {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Debug Controls")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { showControls.toggle() }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        // API Mode Toggle
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("API Mode:")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                                Button(action: {
                                    exchangeService.toggleMockMode()
                                }) {
                                    Text(exchangeService.isMockMode ? "🧪 Mock" : "🌐 Live")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(exchangeService.isMockMode ? Color.orange.opacity(0.8) : Color.green.opacity(0.8))
                                        .cornerRadius(6)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tint Opacity: \(String(format: "%.2f", tintOpacity))")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Slider(value: $tintOpacity, in: 0...1, step: 0.05)
                                .tint(.purple)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Blend Mode")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            HStack(spacing: 12) {
                                Button("Normal") {
                                    blendMode = .normal
                                }
                                .buttonStyle(DebugButtonStyle(isSelected: blendMode == .normal))
                                
                                Button("Multiply") {
                                    blendMode = .multiply
                                }
                                .buttonStyle(DebugButtonStyle(isSelected: blendMode == .multiply))
                                
                                Button("Overlay") {
                                    blendMode = .overlay
                                }
                                .buttonStyle(DebugButtonStyle(isSelected: blendMode == .overlay))
                            }
                        }
                        
                        Button(action: { showColorPickers.toggle() }) {
                            HStack {
                                Text(showColorPickers ? "Hide Gradient Colors" : "Show Gradient Colors")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: showColorPickers ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        if showColorPickers {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    ColorPickerRow(title: "Color 1 (Top)", color: $gradientColor1)
                                    ColorPickerRow(title: "Color 2", color: $gradientColor2)
                                    ColorPickerRow(title: "Color 3", color: $gradientColor3)
                                    ColorPickerRow(title: "Color 4", color: $gradientColor4)
                                    ColorPickerRow(title: "Color 5 (Bottom)", color: $gradientColor5)
                                    
                                    Button("Reset to Default") {
                                        gradientColor1 = Color(red: 0.18, green: 0.09, blue: 0.38)
                                        gradientColor2 = Color(red: 0.21, green: 0.10, blue: 0.42)
                                        gradientColor3 = Color(red: 0.24, green: 0.11, blue: 0.48)
                                        gradientColor4 = Color(red: 0.13, green: 0.05, blue: 0.26)
                                        gradientColor5 = Color(red: 0.08, green: 0.03, blue: 0.15)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.red.opacity(0.6))
                                    )
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .padding()
                }
            } else {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showControls.toggle() }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

struct DesignBackdropWrapper: View {
    var body: some View {
        ZStack {
            // Calmer background for judging contrast
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            HomeView(tintOpacity: 0.6, tintBlendMode: .normal)
        }
    }
}

struct DebugButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.purple : Color.white.opacity(0.1))
            )
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()
                .frame(height: 30)
        }
    }
}
