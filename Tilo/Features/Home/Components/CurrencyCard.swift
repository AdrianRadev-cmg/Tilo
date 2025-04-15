import SwiftUI

struct CurrencyCard: View {
    // Properties
    let currencyName: String
    let amount: String
    let flagEmoji: String
    let currencyCode: String
    let exchangeRateInfo: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(currencyName)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color("grey100"))
            
            HStack {
                Text(amount)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(Color("grey100"))
                
                Spacer() // Pushes chip to the right
                
                // Use the actual chip component
                CurrencySelectorChip(flagEmoji: flagEmoji, currencyCode: currencyCode)
            }
            
            Text(exchangeRateInfo)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color("grey400"))
        }
        // Apply Styling based on Figma specs
        .frame(maxWidth: .infinity) // Make card take full width
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background( // Apply manual frosted glass effect
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("grey800").opacity(0.25)) // Increased opacity from 0.15
                .blur(radius: 15) // Use blur radius 15 from Figma
        )
        .cornerRadius(16) // Clip the main content to the shape
        .overlay( // Apply the subtle edge highlight stroke
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("primary100").opacity(0.05), lineWidth: 1)
        )
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
    
    CurrencyCard(
        currencyName: "British Pound",
        amount: "50.00",
        flagEmoji: "🇬🇧",
        currencyCode: "GBP",
        exchangeRateInfo: "1 GBP = 1.1700 EUR"
    )
    // Removed VStack wrapper and duplicate card
    // Use .previewLayout to prevent vertical stretching in preview
    .previewLayout(.sizeThatFits)
    .padding() // Keep padding for visual spacing in preview
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