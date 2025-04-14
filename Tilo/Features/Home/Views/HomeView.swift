//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI

struct HomeView: View {
    
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
            VStack { // Container for content on gradient
                Spacer() // Push content down slightly for now
                Text("Actual Top Content Placeholder")
                    .foregroundStyle(.white) // Make text visible on dark bg
                Spacer()
            }
            .frame(maxWidth: .infinity)
            // Apply the gradient background to this VStack
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
                // Don't ignore safe area for the VStack itself
            )
            
            // === Bottom Grey Section ===
            VStack { // Container for content on grey bg
                Spacer()
                Text("Actual Bottom Content Placeholder")
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill remaining space

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Background on outer VStack removed
        // Important: Apply ignoresSafeArea to the *entire* VStack 
        // if we want the backgrounds (but not necessarily content) 
        // to go edge-to-edge later. For now, we keep it off.
    }
}

#Preview {
    HomeView()
}
