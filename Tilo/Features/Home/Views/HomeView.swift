//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI

// PreferenceKey Removed

@available(iOS 16.0, *) // Mark View as requiring iOS 16+
struct HomeView: View {
    
    // State for top card amount
    @State private var topCardAmountString: String = "50.00"
    // Remove base/target currency state
    
    // State & Coordinate Space Name Removed
    
    // Helper to format amounts (adapted from CurrencyCard)
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

    let gradientStops = [
        Gradient.Stop(color: Color("primary600"), location: 0.00),
        Gradient.Stop(color: Color("gradientPurpleMid"), location: 0.06),
        Gradient.Stop(color: Color("primary500"), location: 0.09),
        Gradient.Stop(color: Color("gradientPurpleDark"), location: 0.38),
        Gradient.Stop(color: Color("gradientPurpleDeep"), location: 1.00)
    ]

    var body: some View {
        // Remove columns definition
        
        VStack(spacing: 0) { 
            // === Top Gradient Section ===
            VStack(alignment: .leading, spacing: 8) {
                CurrencyCard(
                    currencyName: "British Pound", // Hardcoded
                    amount: topCardAmountString,
                    flagEmoji: "🇬🇧", // Hardcoded
                    currencyCode: "GBP", // Hardcoded
                    exchangeRateInfo: "1 GBP = 1.1700 EUR" // Hardcoded example
                )
                // Apply padding individually to card
                .padding(.horizontal, 16)
                .overlay(alignment: .bottom) {
                    SwapButton()
                        .zIndex(1) // Ensure button is on top
                        .offset(y: 22) // Nudge down 2 more points again
                }
                
                CurrencyCard(
                    currencyName: "Euro", // Hardcoded
                    amount: "58.50", // Hardcoded example amount
                    flagEmoji: "🇪🇺", // Hardcoded
                    currencyCode: "EUR", // Hardcoded
                    exchangeRateInfo: "1 EUR = 0.8547 GBP" // Hardcoded example
                )
                // Apply padding individually to card
                .padding(.horizontal, 16)
                
                // Quick Conversions section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick conversions")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    // Define amounts for the chips (Hardcoded JPY)
                    let chipAmounts: [Double] = [1000, 2000, 5000, 10000, 20000] // JPY amounts
                    
                    // Use custom FlowLayout
                    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) { 
                        // Use hardcoded symbol and amounts
                        ForEach(chipAmounts, id: \.self) { amount in
                             QuickAmountChip(symbol: "¥", amount: amount) // JPY symbol
                        }
                    }
                    // NO .frame() modifier directly on FlowLayout here

                }
                .frame(maxWidth: .infinity, alignment: .topLeading) // Frame on parent VStack is correct
                .padding(.top, 40) // Apply 40pt spacing above the VStack
                .padding(.horizontal, 16) // Apply horizontal alignment padding to the VStack

            }
            // Padding removed from outer VStack
            .padding(.top, 40) // Keep top padding
            .padding(.bottom, 40) // Keep bottom padding
            .frame(maxWidth: .infinity) // Allow VStack content to determine height
            .background( // Apply background to VStack
                ZStack {
                    LinearGradient(
                        gradient: Gradient(stops: gradientStops),
                        startPoint: .topTrailing, 
                        endPoint: .bottomLeading
                    )
                    Color.black.opacity(0.20)
                }
                .ignoresSafeArea(edges: .top)
            )
            
            // === Bottom Grey Section ===
            VStack { 
                Spacer()
                Text("Actual Bottom Content Placeholder")
                Spacer()
            }
            .padding(.horizontal, 16) 
            // Restore maxHeight constraint
            .frame(maxWidth: .infinity, maxHeight: .infinity) 
            .background(Color("grey200")) 

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
}
