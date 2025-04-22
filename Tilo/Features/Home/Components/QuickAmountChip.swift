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
            .foregroundColor(Color("grey100"))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color("grey800").opacity(0.3))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: 0.5)
                    .stroke(Color("primary100").opacity(0.5), lineWidth: 1)
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