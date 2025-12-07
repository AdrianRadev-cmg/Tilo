//
//  SplashScreenView.swift
//  Tilo
//
//  Created by Adrian Radev on 07/12/2025.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoOpacity: Double = 1.0
    
    var onFinished: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient matching main app
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.18, green: 0.09, blue: 0.38),
                    Color(red: 0.21, green: 0.10, blue: 0.42),
                    Color(red: 0.24, green: 0.11, blue: 0.48),
                    Color(red: 0.13, green: 0.05, blue: 0.26),
                    Color(red: 0.08, green: 0.03, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Logo
            Image("SplashLogoText")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 44)
                .opacity(logoOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Hold for a moment, then fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                logoOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashScreenView(onFinished: {})
}

