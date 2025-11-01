//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI
import Charts

struct HomeView: View {
    @State private var selectedTab = 0
    
    @State private var fromCurrencyName = UserDefaults.standard.string(forKey: "fromCurrencyName") ?? "US Dollar"
    @State private var fromFlagEmoji = UserDefaults.standard.string(forKey: "fromFlagEmoji") ?? "🇺🇸"
    @State private var fromCurrencyCode = UserDefaults.standard.string(forKey: "fromCurrencyCode") ?? "USD"
    @State private var fromAmount: Double = UserDefaults.standard.double(forKey: "fromAmount") != 0 ? UserDefaults.standard.double(forKey: "fromAmount") : 100.00
    
    @State private var toCurrencyName = UserDefaults.standard.string(forKey: "toCurrencyName") ?? "Euro"
    @State private var toFlagEmoji = UserDefaults.standard.string(forKey: "toFlagEmoji") ?? "🇪🇺"
    @State private var toCurrencyCode = UserDefaults.standard.string(forKey: "toCurrencyCode") ?? "EUR"
    @State private var toAmount: Double = UserDefaults.standard.double(forKey: "toAmount")
    
    @State private var exchangeRate: Double = 0.0
    @State private var isLoadingRate: Bool = false
    @State private var isEditingTopCard: Bool = false
    @State private var isEditingBottomCard: Bool = false
    @State private var activeEditingCard: String? = nil // Track which card is actively being edited
    
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    // Preview-only debug controls
    var tintOpacity: Double = 0.6
    var tintBlendMode: BlendMode = .normal
    var gradientColor1: Color = Color(red: 0.18, green: 0.09, blue: 0.38)
    var gradientColor2: Color = Color(red: 0.21, green: 0.10, blue: 0.42)
    var gradientColor3: Color = Color(red: 0.24, green: 0.11, blue: 0.48)
    var gradientColor4: Color = Color(red: 0.13, green: 0.05, blue: 0.26)
    var gradientColor5: Color = Color(red: 0.08, green: 0.03, blue: 0.15)
    
    // Save currency state to UserDefaults
    private func saveCurrencyState() {
        UserDefaults.standard.set(fromCurrencyName, forKey: "fromCurrencyName")
        UserDefaults.standard.set(fromFlagEmoji, forKey: "fromFlagEmoji")
        UserDefaults.standard.set(fromCurrencyCode, forKey: "fromCurrencyCode")
        UserDefaults.standard.set(fromAmount, forKey: "fromAmount")
        
        UserDefaults.standard.set(toCurrencyName, forKey: "toCurrencyName")
        UserDefaults.standard.set(toFlagEmoji, forKey: "toFlagEmoji")
        UserDefaults.standard.set(toCurrencyCode, forKey: "toCurrencyCode")
        UserDefaults.standard.set(toAmount, forKey: "toAmount")
    }
    
    private func swapCurrencies() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
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
        
        // Get exchange rate
        if let rate = await exchangeService.getRate(from: fromCurrencyCode, to: toCurrencyCode) {
            exchangeRate = rate
        }
        
        // Convert amount from top card to bottom card
        if let converted = await exchangeService.convert(amount: fromAmount, from: fromCurrencyCode, to: toCurrencyCode) {
            toAmount = converted
        }
        
        isLoadingRate = false
    }
    
    private func updateConversionReverse() async {
        // Don't update if top card is being edited
        guard !isEditingTopCard else { return }
        
        isLoadingRate = true
        
        // Get exchange rate
        if let rate = await exchangeService.getRate(from: fromCurrencyCode, to: toCurrencyCode) {
            exchangeRate = rate
        }
        
        // Convert amount from bottom card to top card (reverse)
        if let converted = await exchangeService.convert(amount: toAmount, from: toCurrencyCode, to: fromCurrencyCode) {
            fromAmount = converted
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
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CAD": return "$"
        case "AUD": return "$"
        case "SGD": return "$"
        case "CHF": return "CHF"
        case "CNY": return "¥"
        case "SEK": return "kr"
        case "NOK": return "kr"
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
                                    .onChange(of: toCurrencyCode) { oldValue, newValue in
                                        saveCurrencyState()
                                        Task {
                                            await updateConversion()
                                        }
                                    }
                                }
                                .padding(.top, min(40, geometry.size.height * 0.05))
                            
                            // SwapButton positioned exactly in the middle of the two cards
                            VStack {
                                Spacer()
                                SwapButton(action: swapCurrencies)
                                    .offset(y: 20) // Move down to center between cards
                                Spacer()
                            }
                            .zIndex(999)
                        }
                        
                        // Quick conversions section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Quick conversions")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            FlowLayout(horizontalSpacing: 12, verticalSpacing: 12) {
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
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 32)
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        
                        // Rate history section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Rate history")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            CurrencyChartView(fromCurrency: fromCurrencyCode, toCurrency: toCurrencyCode)
                                .id("\(fromCurrencyCode)-\(toCurrencyCode)")
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 32)
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        .padding(.bottom, min(40, geometry.size.height * 0.05))
                    }
                    .scrollDismissesKeyboard(.interactively)
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            .task {
                // Fetch rates when view appears
                await updateConversion()
            }
            
            // Activity Tab (placeholder)
            Text("Activity")
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Activity")
                }
                .tag(1)
            
            // Profile Tab (placeholder)
            Text("Profile")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .tint(Color("primary100"))
    }
}

#Preview("Default") {
    HomeView()
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("Home View")
}

#Preview("Debug Controls") {
    DebugHomeViewWrapper()
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("Home View - Debug")
}

#Preview("Design Backdrop") {
    DesignBackdropWrapper()
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("Home View - Calm Background")
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
