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
    
    @State private var fromCurrencyName = "US Dollar"
    @State private var fromFlagEmoji = "🇺🇸"
    @State private var fromCurrencyCode = "USD"
    @State private var fromAmount: Double = 100.00
    
    @State private var toCurrencyName = "Euro"
    @State private var toFlagEmoji = "🇪🇺"
    @State private var toCurrencyCode = "EUR"
    @State private var toAmount: Double = 0.00
    
    @State private var exchangeRate: Double = 0.0
    @State private var isLoadingRate: Bool = false
    @State private var isEditingTopCard: Bool = false
    @State private var isEditingBottomCard: Bool = false
    @State private var activeEditingCard: String? = nil // Track which card is actively being edited
    
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    // Preview-only debug controls
    var tintOpacity: Double = 0.6
    var tintBlendMode: BlendMode = .normal
    
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
                                    tintBlendMode: tintBlendMode
                                )
                                .padding(.horizontal, 16)
                                .onChange(of: fromCurrencyCode) { oldValue, newValue in
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
                                    tintBlendMode: tintBlendMode
                                )
                                .padding(.horizontal, 16)
                                .onChange(of: toCurrencyCode) { oldValue, newValue in
                                    Task {
                                        await updateConversion()
                                    }
                                }
                            }
                            .padding(.top, 40)
                            
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
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick conversions")
                                .font(.title3)
                                .foregroundColor(.white)
                            
                            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                                ForEach([1000, 2000, 5000, 10000, 20000], id: \.self) { amount in
                                    QuickAmountChip(
                                        symbol: fromCurrencyCode == "GBP" ? "£" : fromCurrencyCode == "EUR" ? "€" : "$",
                                        amount: amount,
                                        selectedAmount: .constant(0),
                                        onSelect: { _ in }
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.top, 40)
                        .padding(.horizontal, 16)
                        
                        // Currency Chart Section
                        CurrencyChartView(fromCurrency: fromCurrencyCode, toCurrency: toCurrencyCode)
                            .padding(.top, 40)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40)
                    }
                }
            }
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
    
    var body: some View {
        ZStack {
            HomeView(tintOpacity: tintOpacity, tintBlendMode: blendMode)
            
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
