import SwiftUI

struct CurrencySelectorChip: View {
    // Properties
    let flagEmoji: String
    let currencyCode: String
    
    var body: some View {
        // Layout
        HStack(spacing: 4) { // Main horizontal arrangement
            Text(flagEmoji) // Use Text for emoji flag
                .font(.system(size: 22))
                .padding(.trailing, 4) // Add padding AFTER flag
            
            // Add faint vertical divider line
            Rectangle()
                .frame(width: 1) // Thickness
                // Removed fixed height - will stretch to HStack height
                .foregroundColor(Color("primary100").opacity(0.05)) // Match stroke style

            Text(currencyCode)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color("grey100"))
                .padding(.leading, 4) // Add padding BEFORE text
            
            Image(systemName: "chevron.down")
                .font(.system(size: 16))
                .foregroundColor(Color("grey100"))
        }
        // Restore styling to the overall HStack
        .padding(.horizontal, 8)
        // Removed vertical padding to allow divider to reach edges
        .background( // Apply manual frosted glass effect
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("grey800").opacity(0.15)) // Base color + opacity
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
    
    CurrencySelectorChip(flagEmoji: "🇬🇧", currencyCode: "GBP")
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