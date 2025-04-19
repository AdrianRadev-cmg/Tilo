import SwiftUI

struct CurrencyCard: View {
    // Properties
    let currencyName: String
    let amount: String
    let flagEmoji: String
    let currencyCode: String
    let exchangeRateInfo: String
    
    // State for focus and text input
    @State private var isAmountFocused: Bool = false
    @State private var amountInput: String = ""
    @FocusState private var amountFieldIsFocused: Bool
    @State private var isInputError: Bool = false // State for error tracking
    
    // Helper to format the input string
    private func formatAmount(_ string: String) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal // Use decimal style
        formatter.usesGroupingSeparator = true // Add commas
        formatter.minimumFractionDigits = 2 // Ensure 2 decimal places
        formatter.maximumFractionDigits = 2
        
        // Try converting string to Decimal (better for currency) then format
        if let number = Decimal(string: string.replacingOccurrences(of: formatter.groupingSeparator, with: "")) { // Remove existing commas before conversion
            return formatter.string(from: number as NSDecimalNumber)
        }
        return nil // Return nil if input is not a valid number
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(currencyName)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color("grey100"))
            
            // Unified HStack Structure
            HStack(spacing: 16) { // Remove alignment: .top
                ZStack(alignment: .leading) { // ZStack for amount display
                    // Apply background always
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("grey800").opacity(0.15)) 
                        .blur(radius: 30)
                        .overlay( // Apply diagonal gradient always
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.05), Color.black.opacity(0.05)]),
                                startPoint: .topLeading, 
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        )

                    // Conditional Text or TextField
                    if isAmountFocused {
                        TextField("", text: $amountInput) // Use empty placeholder
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(Color("grey100"))
                            .padding(.vertical, 4) 
                            .padding(.horizontal, 8)
                            .keyboardType(.decimalPad) // Numeric keyboard
                            .tint(.white) // Set cursor/accent color to white
                            .focused($amountFieldIsFocused) // Link focus state
                            .onSubmit { // Format on submit
                                if let formatted = formatAmount(amountInput) {
                                    amountInput = formatted
                                    isInputError = false // Clear error if format succeeds
                                } else {
                                    isInputError = true 
                                }
                                isAmountFocused = false 
                            }
                            .onAppear { // Request focus when appearing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay needed sometimes
                                    amountFieldIsFocused = true
                                }
                            }
                            .accessibilityLabel("Amount to convert: \(currencyName)")
                    } else {
                        Text(amountInput.isEmpty ? amount : amountInput) // Show input or initial value
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(Color("grey100"))
                            .padding(.vertical, 4) 
                            .padding(.horizontal, 8) 
                            .accessibilityLabel("Amount to convert: \(currencyName)")
                            .accessibilityHint("Tap to edit amount")
                    }
                }
                // Conditional Border Overlay
                .overlay {
                    if isAmountFocused {
                        // Active State: Full border (Keep as is: primary100 @ 25%)
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("primary100").opacity(0.25), lineWidth: 1) 
                    } else {
                        // Default State: Border shape/color depends on error
                        if isInputError {
                            // Error State: Full border using error200
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color("error200"), lineWidth: 1) // Use error200
                        } else {
                            // Normal Default State: Curved left path using primary100
                            Path { path in
                                let cornerRadius: CGFloat = 8
                                let h = path.boundingRect.height
                                
                                // Move to start of top-left arc
                                path.move(to: CGPoint(x: cornerRadius, y: 0))
                                // Top-left arc
                                path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                                            radius: cornerRadius,
                                            startAngle: Angle(degrees: -90),
                                            endAngle: Angle(degrees: 180),
                                            clockwise: true)
                                // Vertical line down
                                path.addLine(to: CGPoint(x: 0, y: h - cornerRadius))
                                // Bottom-left arc
                                path.addArc(center: CGPoint(x: cornerRadius, y: h - cornerRadius),
                                            radius: cornerRadius,
                                            startAngle: Angle(degrees: 180),
                                            endAngle: Angle(degrees: 90),
                                            clockwise: true)
                            }
                            .stroke(Color("primary100").opacity(0.05), lineWidth: 1)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8)) // Clip ZStack content
                .frame(maxWidth: isAmountFocused ? .infinity : nil) // Conditional width
                .frame(height: 39) // Restore fixed height for ZStack
                .contentShape(Rectangle()) // Make tappable
                .onTapGesture { // Tapping the amount area
                    if !isAmountFocused {
                        amountInput = "" // Clear field when starting edit
                        isInputError = false // Clear error state on new focus
                        isAmountFocused = true // Activate focus state
                    }
                }
                
                CurrencySelectorChip(flagEmoji: flagEmoji, currencyCode: currencyCode)
                    // Remove fixed height from the chip instance
                // No Spacer needed here
            }
            // Removed fixed height from HStack
            
            // Conditional Error Message
            if isInputError {
                Text("Invalid amount")
                    .font(.footnote)
                    .foregroundColor(Color("error200")) // Use error200
                    .padding(.leading, 8) // Indent slightly like the field
            }
            
            Text(exchangeRateInfo)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color("grey400"))
        }
        // Move onChange before other modifiers
        .onChange(of: amount) { oldAmount, newAmount in // Updated signature
            amountInput = newAmount
            isInputError = false // Clear error when amount is externally updated
        }
        .contentShape(Rectangle()) 
        .onTapGesture { // Tapping card background
             if isAmountFocused { // Only act if dismissing focus
                 let currentInput = amountInput.trimmingCharacters(in: .whitespacesAndNewlines)
                 // Format or reset to 0.00 on background tap dismiss
                 if let formatted = formatAmount(currentInput), !currentInput.isEmpty {
                     amountInput = formatted
                 } else {
                     // If formatting fails OR input was empty, reset to 0.00
                     amountInput = formatAmount("0") ?? "0.00" // Format 0 to get locale correct 0.00
                 }
                 isInputError = false // ALWAYS clear error on background tap dismiss
                 isAmountFocused = false
                 amountFieldIsFocused = false 
             }
         }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color("grey800").opacity(0.25))
                .blur(radius: 15)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("primary100").opacity(0.05), lineWidth: 1)
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
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
