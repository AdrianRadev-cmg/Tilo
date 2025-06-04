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
                .font(.custom("SF Pro", size: 17))
                .foregroundColor(Color("grey100"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color("primary600").opacity(0.3) : Color("grey800").opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .inset(by: 0.5)
                        .stroke(isSelected ? Color("primary100") : Color("primary100").opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(QuickAmountChipButtonStyle())
    }
}

struct QuickAmountChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
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