import SwiftUI

struct CurrencyCard: View {
    // Properties
    @Binding var currencyName: String
    @Binding var flagEmoji: String
    @Binding var currencyCode: String
    let amount: String
    let exchangeRateInfo: String
    
    // State for focus and text input
    @State private var isAmountFocused: Bool = false
    @State private var amountInput: String = ""
    @FocusState private var amountFieldIsFocused: Bool
    @State private var isInputError: Bool = false // State for error tracking
    @State private var showCurrencySelector: Bool = false // Add state for currency selector
    
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
                .foregroundColor(.white)
            
            // Unified HStack Structure
            HStack(spacing: 16) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.15))
                        .blur(radius: 30)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white.opacity(0.05), Color.black.opacity(0.05)]),
                                startPoint: .topLeading, 
                                endPoint: .bottomTrailing
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        )

                    if isAmountFocused {
                        TextField("", text: $amountInput)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 4) 
                            .padding(.horizontal, 8)
                            .keyboardType(.decimalPad)
                            .tint(.white)
                            .focused($amountFieldIsFocused)
                            .onSubmit {
                                if let formatted = formatAmount(amountInput) {
                                    amountInput = formatted
                                    isInputError = false
                                } else {
                                    isInputError = true 
                                }
                                isAmountFocused = false 
                            }
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    amountFieldIsFocused = true
                                }
                            }
                            .accessibilityLabel("Amount to convert: \(currencyName)")
                    } else {
                        Text(amountInput.isEmpty ? amount : amountInput)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 4) 
                            .padding(.horizontal, 8) 
                            .accessibilityLabel("Amount to convert: \(currencyName)")
                            .accessibilityHint("Tap to edit amount")
                    }
                }
                .overlay {
                    if isAmountFocused {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.7, green: 0.7, blue: 0.7).opacity(0.25), lineWidth: 1)
                    } else {
                        if isInputError {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.8, green: 0.2, blue: 0.2), lineWidth: 1)
                        } else {
                            Path { path in
                                let cornerRadius: CGFloat = 8
                                let h = path.boundingRect.height
                                path.move(to: CGPoint(x: cornerRadius, y: 0))
                                path.addArc(center: CGPoint(x: cornerRadius, y: cornerRadius),
                                            radius: cornerRadius,
                                            startAngle: Angle(degrees: -90),
                                            endAngle: Angle(degrees: 180),
                                            clockwise: true)
                                path.addLine(to: CGPoint(x: 0, y: h - cornerRadius))
                                path.addArc(center: CGPoint(x: cornerRadius, y: h - cornerRadius),
                                            radius: cornerRadius,
                                            startAngle: Angle(degrees: 180),
                                            endAngle: Angle(degrees: 90),
                                            clockwise: true)
                            }
                            .stroke(Color(red: 0.7, green: 0.7, blue: 0.7).opacity(0.05), lineWidth: 1)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: isAmountFocused ? .infinity : nil)
                .frame(height: 39)
                .contentShape(Rectangle())
                .onTapGesture {
                    if !isAmountFocused {
                        amountInput = ""
                        isInputError = false
                        isAmountFocused = true
                    }
                }
                
                CurrencySelectorChip(
                    flagEmoji: flagEmoji, 
                    currencyCode: currencyCode,
                    action: { showCurrencySelector = true }
                )
            }
            
            if isInputError {
                Text("Invalid amount")
                    .font(.footnote)
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                    .padding(.leading, 8)
            }
            
            Text(exchangeRateInfo)
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
        }
        .onChange(of: amount) { oldAmount, newAmount in
            amountInput = newAmount
            isInputError = false
        }
        .contentShape(Rectangle())
        .onTapGesture {
             if isAmountFocused {
                 let currentInput = amountInput.trimmingCharacters(in: .whitespacesAndNewlines)
                 if let formatted = formatAmount(currentInput), !currentInput.isEmpty {
                     amountInput = formatted
                 } else {
                     amountInput = formatAmount("0") ?? "0.00"
                 }
                 isInputError = false
                 isAmountFocused = false
                 amountFieldIsFocused = false 
             }
         }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.25))
                .blur(radius: 15)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.7, green: 0.7, blue: 0.7).opacity(0.05), lineWidth: 1)
        )
        .sheet(isPresented: $showCurrencySelector) {
            CurrencySelector { selectedCurrency in
                // Update the currency card with selected currency
                currencyName = selectedCurrency.name
                flagEmoji = selectedCurrency.flag
                currencyCode = selectedCurrency.code
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
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
    
    @State var currencyName = "British Pound"
    @State var flagEmoji = "🇬🇧"
    @State var currencyCode = "GBP"
    
    CurrencyCard(
        currencyName: $currencyName,
        flagEmoji: $flagEmoji,
        currencyCode: $currencyCode,
        amount: "50.00",
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
