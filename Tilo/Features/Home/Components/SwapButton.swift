import SwiftUI

struct SwapButton: View {
    // Properties/Actions might go here later
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up.arrow.down.circle") 
                .font(.system(size: 18, weight: .regular)) // Reduced icon size to 18
                .foregroundStyle(Color("grey100")) // Apply correct color
        }
        .frame(width: 36, height: 36) // Reduced frame size from 40x40
        // Restore effects, use grey800 @ 10% for fill
        .background( 
            Circle()
                .fill(Color("grey800").opacity(0.20)) // Increased opacity to 20%
                .blur(radius: 20) // Re-enable blur
        )
        .overlay( // Re-enable diagonal gradient (5% -> 5%)
            LinearGradient(
                gradient: Gradient(colors: [Color.white.opacity(0.05), Color.black.opacity(0.05)]),
                startPoint: .topLeading, 
                endPoint: .bottomTrailing
            )
            .clipShape(Circle())
        )
        .overlay( // Re-enable edge stroke
            Circle()
                .stroke(Color("primary100").opacity(0.05), lineWidth: 1)
        )
        .clipShape(Circle()) // Ensure content stays within circle
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 3) // Keep adjusted shadow
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
        // Use app gradient for preview background
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