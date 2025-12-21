import SwiftUI

struct CurrencySelectorChip: View {
    // Properties
    let flagEmoji: String
    let currencyCode: String
    var action: () -> Void
    
    var body: some View {
        // Layout
        Button(action: action) {
            HStack(spacing: 4) { // Main horizontal arrangement
                Text(flagEmoji) // Use Text for emoji flag
                    .font(.system(size: 22))
                    .accessibilityHidden(true) // Hide flag from VoiceOver, code is sufficient

                Text(currencyCode)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.trailing, 2) // Add 2px after code
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.trailing, 2) // Add 2px after chevron
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(height: 42)
            .glassEffect()
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityLabel("\(currencyCode) currency selector")
        .accessibilityHint("Double tap to choose a different currency")
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
    
    CurrencySelectorChip(
        flagEmoji: "🇬🇧",
        currencyCode: "GBP",
        action: {}
    )
    .padding() // Keep padding to center the chip slightly in preview
    // Apply the actual gradient background for accurate preview
    .background(
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: gradientStops),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            Color.black.opacity(0.20)
        }
        .ignoresSafeArea() // Make preview background fill edges
    )
} 