import SwiftUI

struct SwapButton: View {
    // Properties/Actions might go here later
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.arrow.down.circle") 
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color("grey100"))
                .frame(width: 44, height: 44) // Larger hit area
                .background(
                    Circle()
                        .fill(Color("grey800").opacity(0.40))
                        .blur(radius: 20)
                )
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.12), Color.black.opacity(0.12)]),
                        startPoint: .topLeading, 
                        endPoint: .bottomTrailing
                    )
                    .clipShape(Circle())
                )
                .overlay(
                    Circle()
                        .stroke(Color("primary100").opacity(0.12), lineWidth: 1)
                )
                .clipShape(Circle())
                .contentShape(Circle()) // Explicitly define hit area
        }
        .buttonStyle(.plain) // Remove default button style
        .shadow(color: .black.opacity(0.20), radius: 10, x: 0, y: 3)
    }
}

#Preview {
    // Define gradient stops locally for preview purposes
    let gradientStops = [
        Gradient.Stop(color: Color("primary600"), location: 0.00),
        Gradient.Stop(color: Color("gradientPurpleMid"), location: 0.06),
        Gradient.Stop(color: Color("primary500"), location: 0.09),
        Gradient.Stop(color: Color("gradientPurpleDark"), location: 0.38),
        Gradient.Stop(color: Color("gradientPurpleDeep"), location: 1.00)
    ]

    SwapButton()
        .padding()
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: gradientStops),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                Color.black.opacity(0.20)
            }
            .ignoresSafeArea()
        )
} 