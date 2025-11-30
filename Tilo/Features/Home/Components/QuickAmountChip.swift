import SwiftUI

struct QuickAmountChip: View {
    let symbol: String
    let amount: Double
    @Binding var selectedAmount: Double?
    let onSelect: (Double) -> Void
    
    // Formatter for the amount
    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
    
    private var isSelected: Bool {
        selectedAmount == amount
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            onSelect(amount)
            generator.impactOccurred()
        }) {
            Text(symbol + formattedAmount)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Convert \(symbol)\(formattedAmount)")
        .accessibilityHint("Double tap to convert this amount")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
    .ignoresSafeArea()
    .overlay {
        QuickAmountChip(
            symbol: "€",
            amount: 117.00,
            selectedAmount: .constant(117.00),
            onSelect: { _ in }
        )
    }
} 