//
//  SatisfactionPromptView.swift
//  Tilo
//
//  A pre-review satisfaction check to filter unhappy users before showing the native review prompt
//

import SwiftUI

struct SatisfactionPromptView: View {
    let onYes: () -> Void
    let onNo: () -> Void
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onNo()
                }
            
            // Liquid glass popup
            VStack(spacing: 20) {
                // Title
                Text("Enjoying Tilo?")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Subtitle
                Text("Your feedback helps us improve the app for travelers like you.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                
                // Buttons - side by side
                HStack(spacing: 12) {
                    // No button - secondary action (left)
                    Button(action: onNo) {
                        Text("Not really")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Yes button - primary action (right)
                    Button(action: onYes) {
                        Text("Yes 💜")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.50, green: 0.24, blue: 0.88),
                                                Color(red: 0.38, green: 0.16, blue: 0.72)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .background(
                ZStack {
                    // Base frosted glass
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    
                    // Purple tint to match app theme
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.28, green: 0.14, blue: 0.50).opacity(0.6),
                                    Color(red: 0.18, green: 0.08, blue: 0.35).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle border glow
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 40)
        }
    }
}

#Preview {
    ZStack {
        // Background to simulate the app
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.18, green: 0.09, blue: 0.38),
                Color(red: 0.08, green: 0.03, blue: 0.15)
            ]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
        
        SatisfactionPromptView(
            onYes: { print("User is happy!") },
            onNo: { print("User is not happy") }
        )
    }
}
