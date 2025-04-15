//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI

// PreferenceKey to store Y-coordinates of card edges
private struct SwapButtonPlacementPreferenceKey: PreferenceKey {
    // Store dictionary: [isTopCardBottomEdge: Anchor]
    typealias Value = [Bool: Anchor<CGRect>]
    
    static var defaultValue: Value = [:]
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        // Merge the dictionaries, storing anchors for both top and bottom cards
        value.merge(nextValue()) { $1 } 
    }
}

struct HomeView: View {
    
    // Coordinate Space Name
    private let coordinateSpaceName = "TopSectionSpace"
    
    // State to store calculated button Y position
    @State private var swapButtonY: CGFloat? = nil
    
    // Define gradient stops using named colors from Assets.xcassets
    // Based on Figma Dev Mode snippet
    let gradientStops = [
        // Using descriptive names matching updated Assets
        Gradient.Stop(color: Color("primary600"), location: 0.00),
        Gradient.Stop(color: Color("gradientPurpleMid"), location: 0.06), // #5636B5
        Gradient.Stop(color: Color("primary500"), location: 0.09),
        Gradient.Stop(color: Color("gradientPurpleDark"), location: 0.38), // #341B7D
        Gradient.Stop(color: Color("gradientPurpleDeep"), location: 1.00) // #1D0041
    ]

    var body: some View {
        VStack(spacing: 0) { 
            // === Top Gradient Section ===
            // Use GeometryReader for dynamic positioning
            GeometryReader { geometry in 
                ZStack(alignment: .top) { 
                    VStack(spacing: 8) { // Cards VStack
                        CurrencyCard(
                            currencyName: "British Pound",
                            amount: "50.00",
                            flagEmoji: "🇬🇧",
                            currencyCode: "GBP",
                            exchangeRateInfo: "1 GBP = 1.1700 EUR"
                        )
                        // Capture the bottom edge of the first card
                        .anchorPreference(key: SwapButtonPlacementPreferenceKey.self, value: .bounds) { anchor in
                            [true: anchor] 
                        }
                    
                        CurrencyCard(
                            currencyName: "Euro",
                            amount: "58.50",
                            flagEmoji: "🇪🇺",
                            currencyCode: "EUR",
                            exchangeRateInfo: "1 EUR = 0.8547 GBP"
                        )
                        // Capture the top edge of the second card
                        .anchorPreference(key: SwapButtonPlacementPreferenceKey.self, value: .bounds) { anchor in
                            [false: anchor] 
                        }
                    }
                    .padding(.horizontal, 16) 
                    .padding(.top, 40)       
                    .padding(.bottom, 40)    
                    .frame(maxWidth: .infinity)
                    
                    // --- Swap Button --- 
                    if let swapButtonY = swapButtonY { // Only show if position calculated
                        SwapButton()
                            // Position button at calculated Y, centered X
                            .position(x: geometry.size.width / 2, y: swapButtonY)
                            .zIndex(1) // Ensure button is drawn on top
                    }
                }
                .coordinateSpace(name: coordinateSpaceName)
                // Read the preference key values and calculate position
                .onPreferenceChange(SwapButtonPlacementPreferenceKey.self) { anchors in
                    guard let topCardBottomAnchor = anchors[true], 
                          let bottomCardTopAnchor = anchors[false] else { return }
                    
                    let topY = geometry[topCardBottomAnchor].maxY
                    let bottomY = geometry[bottomCardTopAnchor].minY
                    let midpointY = topY + (bottomY - topY) / 2
                    
                    DispatchQueue.main.async {
                        self.swapButtonY = midpointY
                    }
                }
            }
            .frame(maxWidth: .infinity) // Keep max width for GeoReader/ZStack area
            // Apply the gradient background to this structure
            .background(
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
            VStack { // Container for content on grey bg
                Spacer()
                Text("Actual Bottom Content Placeholder")
                Spacer()
            }
            .padding(.horizontal, 16) // Add L/R padding: 16
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill remaining space
            .background(Color("grey200")) // Apply correct grey background

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    HomeView()
}
