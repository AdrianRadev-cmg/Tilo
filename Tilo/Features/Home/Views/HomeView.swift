//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI

// PreferenceKey Removed

struct StatusBarGradient: View {
    let gradientStops: [Gradient.Stop]
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(stops: gradientStops),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .overlay(Color.black.opacity(0.20))
            .frame(height: geometry.safeAreaInsets.top)
            .edgesIgnoringSafeArea(.top)
        }
    }
}

@available(iOS 16.0, *) // Mark View as requiring iOS 16+
struct HomeView: View {
    @State private var topCardAmountString: String = "50.00"
    
    private let gradientStops = [
        Gradient.Stop(color: Color("primary600"), location: 0.00),
        Gradient.Stop(color: Color("gradientPurpleMid"), location: 0.06),
        Gradient.Stop(color: Color("primary500"), location: 0.09),
        Gradient.Stop(color: Color("gradientPurpleDark"), location: 0.38),
        Gradient.Stop(color: Color("gradientPurpleDeep"), location: 1.00)
    ]
    
    private func formatAmount(_ string: String) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        if let number = Decimal(string: string.replacingOccurrences(of: formatter.groupingSeparator, with: "")) {
            return formatter.string(from: number as NSDecimalNumber)
        }
        return nil
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Status bar gradient
            StatusBarGradient(gradientStops: gradientStops)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Purple content section
                    VStack(alignment: .leading, spacing: 8) {
                        currencyCards
                        quickConversions
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(stops: gradientStops),
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        )
                        .overlay(Color.black.opacity(0.20))
                    )
                    
                    // Grey section
                    greySection
                        .background(Color("grey200"))
                }
            }
            .background(Color("grey200"))
        }
    }
    
    private var currencyCards: some View {
        VStack(spacing: 8) {
            CurrencyCard(
                currencyName: "British Pound",
                amount: topCardAmountString,
                flagEmoji: "🇬🇧",
                currencyCode: "GBP",
                exchangeRateInfo: "1 GBP = 1.1700 EUR"
            )
            .overlay(alignment: .bottom) {
                SwapButton()
                    .zIndex(1)
                    .offset(y: 22)
            }
            
            CurrencyCard(
                currencyName: "Euro",
                amount: "58.50",
                flagEmoji: "🇪🇺",
                currencyCode: "EUR",
                exchangeRateInfo: "1 EUR = 0.8547 GBP"
            )
        }
        .padding(.horizontal, 16)
    }
    
    private var quickConversions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick conversions")
                .font(.title3)
                .foregroundColor(.white)
            
            FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach([1000, 2000, 5000, 10000, 20000], id: \.self) { amount in
                    QuickAmountChip(symbol: "¥", amount: amount)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.top, 40)
        .padding(.horizontal, 16)
    }
    
    private var greySection: some View {
        VStack(spacing: 16) {
            Text("Actual Bottom Content Placeholder")
            Text("More content can go here")
            Text("And even more content")
            Text("Keep adding content")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
    }
}

#Preview {
    HomeView()
}

// Add preference key for height measurement
private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
