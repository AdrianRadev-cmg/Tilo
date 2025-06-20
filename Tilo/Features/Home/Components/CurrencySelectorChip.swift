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
                    .padding(.trailing, 4) // Add padding AFTER flag
                
                // Add faint vertical divider line
                Rectangle()
                    .frame(width: 1) // Thickness
                    // Removed fixed height - will stretch to HStack height
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7).opacity(0.05)) // Match stroke style

                Text(currencyCode)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.leading, 6) // Add a bit more space before code
                    .padding(.trailing, 2) // Add 2px after code
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.trailing, 2) // Add 2px after chevron
            }
            .padding(.horizontal, 10)
            // Removed vertical padding to allow divider to reach edges
            .background( // Apply manual frosted glass effect
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.15)) // Base color + opacity
                    .blur(radius: 30) // Apply background blur
            )
            .cornerRadius(8) // Clip the main content to the shape
            .overlay( // Re-add diagonal gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.05), Color.black.opacity(0.05)]),
                    startPoint: .topLeading, 
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            )
            .overlay( // Apply the subtle edge highlight stroke LAST
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.7, green: 0.7, blue: 0.7).opacity(0.05), lineWidth: 1)
            )
        }
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