import SwiftUI

struct QuickAmountChip: View {
    let symbol: String
    let amount: Double
    // Add action later if needed

    // Formatter for the amount
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true // Add grouping separators
        formatter.maximumFractionDigits = 0 // Show whole numbers for these chips
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }

    var body: some View {
        // Display symbol + formatted amount
        Text(symbol + formattedAmount)
            .font(.custom("SF Pro", size: 17))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            // Use a solid background for testing
            .background(Color.gray.opacity(0.3))
            // .background(.ultraThinMaterial) // Apply material background first
            // .blur(radius: 20) // Apply blur AFTER background - COMMENTED OUT FOR TESTING
            .cornerRadius(8) // Apply corner radius AFTER background/blur
            .overlay( // Apply overlay/stroke AFTER cornerRadius
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: 0.5) // Inset slightly for stroke alignment
                    // Using raw RGB for now - replace with named color (e.g., grey100 opacity 0.5) if available
                    .stroke(Color(red: 0.95, green: 0.94, blue: 0.97).opacity(0.5), lineWidth: 1)
            )
    }
}

#Preview {
    // Define gradient stops locally, matching HomeView
    let gradientStops = [
        Gradient.Stop(color: Color("primary600"), location: 0.00),
        Gradient.Stop(color: Color("gradientPurpleMid"), location: 0.06),
        Gradient.Stop(color: Color("primary500"), location: 0.09),
        Gradient.Stop(color: Color("gradientPurpleDark"), location: 0.38),
        Gradient.Stop(color: Color("gradientPurpleDeep"), location: 1.00)
    ]
    
    // Use the same ZStack background as HomeView
    ZStack {
        LinearGradient(
            gradient: Gradient(stops: gradientStops),
            startPoint: .topTrailing, 
            endPoint: .bottomLeading
        )
        Color.black.opacity(0.20)
    }
    .ignoresSafeArea() // Apply ignoresSafeArea to the ZStack
    .overlay { // Place the chip inside an overlay on the background
        QuickAmountChip(symbol: "€", amount: 117.00)
    }
} 