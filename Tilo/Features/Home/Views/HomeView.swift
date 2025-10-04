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
    
    @State private var toCurrencyName = "Euro"
    @State private var toFlagEmoji = "🇪🇺"
    @State private var toCurrencyCode = "EUR"
    
    private func swapCurrencies() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Swap the currency values
        let tempName = fromCurrencyName
        let tempFlag = fromFlagEmoji
        let tempCode = fromCurrencyCode
        
        fromCurrencyName = toCurrencyName
        fromFlagEmoji = toFlagEmoji
        fromCurrencyCode = toCurrencyCode
        
        toCurrencyName = tempName
        toFlagEmoji = tempFlag
        toCurrencyCode = tempCode
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
                                    amount: "50.00",
                                    exchangeRateInfo: "1 \(fromCurrencyCode) = 1.1700 \(toCurrencyCode)"
                                )
                                .padding(.horizontal, 16)
                                
                                CurrencyCard(
                                    currencyName: $toCurrencyName,
                                    flagEmoji: $toFlagEmoji,
                                    currencyCode: $toCurrencyCode,
                                    amount: "58.50",
                                    exchangeRateInfo: "1 \(toCurrencyCode) = 0.8547 \(fromCurrencyCode)"
                                )
                                .padding(.horizontal, 16)
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

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("Home View")
        .previewLayout(.sizeThatFits)
        .previewInterfaceOrientation(.portrait)
}
