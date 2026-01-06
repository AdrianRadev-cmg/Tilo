import SwiftUI

struct CurrencyCard: View {
    // Properties
    @Binding var currencyName: String
    @Binding var flagEmoji: String
    @Binding var currencyCode: String
    let amount: String
    let exchangeRateInfo: String
    let currencySymbol: String
    var onAmountChange: ((Double) -> Void)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil
    let isEditable: Bool
    let isCurrentlyActive: Bool
    
    // Preview-only debug controls
    var tintOpacity: Double = 0.6
    var tintBlendMode: BlendMode = .normal
    var gradientColor1: Color = Color(red: 0.18, green: 0.09, blue: 0.38)
    var gradientColor2: Color = Color(red: 0.21, green: 0.10, blue: 0.42)
    var gradientColor3: Color = Color(red: 0.24, green: 0.11, blue: 0.48)
    var gradientColor4: Color = Color(red: 0.13, green: 0.05, blue: 0.26)
    var gradientColor5: Color = Color(red: 0.08, green: 0.03, blue: 0.15)
    
    // State for focus and text input
    @State private var isAmountFocused: Bool = false
    @State private var amountInput: String = ""
    @FocusState private var amountFieldIsFocused: Bool
    @State private var isInputError: Bool = false // State for error tracking
    @State private var showCurrencySelector: Bool = false // Add state for currency selector
    @State private var sheetDetent: PresentationDetent = .large // Default to expanded
    
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
    
    // Locale-aware separators
    private var decimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
    }
    
    private var groupingSeparator: String {
        Locale.current.groupingSeparator ?? ","
    }
    
    // Helper to handle amount input changes
    private func handleAmountInputChange(oldValue: String, newValue: String) {
        // Remove any existing grouping separators (locale-aware)
        let cleanInput = newValue.replacingOccurrences(of: groupingSeparator, with: "")
        
        // Get the decimal separator character
        let decimalChar = Character(decimalSeparator)
        
        // Only allow digits and the locale's decimal separator
        let filtered = cleanInput.filter { $0.isNumber || $0 == decimalChar }
        
        // Prevent multiple decimal separators
        let decimalCount = filtered.filter { $0 == decimalChar }.count
        if decimalCount > 1 {
            amountInput = oldValue
            return
        }
        
        // Convert to Double using locale-aware parsing
        let normalizedForParsing = filtered.replacingOccurrences(of: decimalSeparator, with: ".")
        
        // Apply smart formatting: add grouping separators for numbers >= 1000
        if let doubleValue = Double(normalizedForParsing) {
            // Split into integer and decimal parts
            let parts = filtered.split(separator: decimalChar, maxSplits: 1, omittingEmptySubsequences: false)
            let integerPart = String(parts[0])
            let decimalPart = parts.count > 1 ? String(parts[1]) : nil
            
            // Format integer part with locale grouping separator if >= 1000
            let formattedInteger: String
            if let intValue = Int(integerPart), intValue >= 1000 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.usesGroupingSeparator = true
                // Let formatter use locale's grouping separator automatically
                formattedInteger = formatter.string(from: NSNumber(value: intValue)) ?? integerPart
            } else {
                formattedInteger = integerPart
            }
            
            // Reconstruct the number with decimal if present (using locale separator)
            if let decimal = decimalPart {
                amountInput = formattedInteger + decimalSeparator + decimal
            } else if filtered.hasSuffix(String(decimalChar)) {
                amountInput = formattedInteger + decimalSeparator
            } else {
                amountInput = formattedInteger
            }
            
            // Trigger conversion
            if doubleValue > 0 {
                onAmountChange?(doubleValue)
            } else if filtered.isEmpty {
                onAmountChange?(0)
            }
        } else if filtered.isEmpty {
            amountInput = ""
            onAmountChange?(0)
        } else {
            amountInput = filtered
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(currencyName)
                .font(.title2)
                .foregroundColor(.white)
            
            // Unified HStack Structure
            HStack(spacing: 16) {
                HStack(alignment: .center, spacing: 4) {
                    Text(currencySymbol)
                        .font(.callout.weight(.medium))
                        .foregroundColor(.white)

                    if isAmountFocused && isEditable {
                        TextField("", text: $amountInput)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .tint(.white)
                            .focused($amountFieldIsFocused)
                            .lineLimit(1)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isAmountFocused = false
                                        amountFieldIsFocused = false
                                        onEditingChanged?(false)
                                    }
                                    .font(.body.weight(.semibold))
                                }
                            }
                            .onChange(of: amountInput) { oldValue, newValue in
                                handleAmountInputChange(oldValue: oldValue, newValue: newValue)
                            }
                            .onChange(of: amountFieldIsFocused) { _, newValue in
                                // Sync state when keyboard is dismissed externally (e.g., by scrolling)
                                if !newValue && isAmountFocused {
                                    isAmountFocused = false
                                    onEditingChanged?(false)
                                }
                            }
                    } else {
                        Text(amountInput.isEmpty ? amount : amountInput)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .accessibilityHint("Tap to edit amount")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .overlay {
                    // Show stroke only on error
                        if isInputError {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(red: 0.8, green: 0.2, blue: 0.2), lineWidth: 1)
                    }
                }
                .glassEffect()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("Amount to convert: \(currencyName)")
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditable && !isAmountFocused && isCurrentlyActive {
                        // Clear the input when user taps to edit
                        amountInput = ""
                        isInputError = false
                        isAmountFocused = true
                        onEditingChanged?(true)
                        
                        // Focus the text field to show keyboard
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            amountFieldIsFocused = true
                        }
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
                .font(.callout)
                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                .accessibilityLabel("Exchange rate: \(exchangeRateInfo)")
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge) // Cap scaling to prevent layout breaking
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(currencyName) currency card")
        .onChange(of: amount) { oldAmount, newAmount in
            // Only update amountInput if not currently editing
            if !isAmountFocused {
            amountInput = newAmount
            isInputError = false
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
             if isAmountFocused {
                 // Dismiss keyboard and keep the raw input
                 isAmountFocused = false
                 amountFieldIsFocused = false 
                 onEditingChanged?(false)
             }
         }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(
            ZStack {
                // Glass effect as base layer
                RoundedRectangle(cornerRadius: 16)
                    .glassEffect(in: .rect(cornerRadius: 16))
                
                // Dark purple overlay to reduce grey appearance
            RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 20/255, green: 8/255, blue: 58/255).opacity(0.75))
            }
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // Subtle highlight for glassy elevation effect
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showCurrencySelector, onDismiss: {
            // Reset to large for next open
            sheetDetent = .large
        }) {
            CurrencySelector { selectedCurrency in
                // Update the currency card with selected currency
                currencyName = selectedCurrency.name
                flagEmoji = selectedCurrency.flag
                currencyCode = selectedCurrency.code
            }
            .presentationDetents([.medium, .large], selection: $sheetDetent)
            .presentationDragIndicator(.visible)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    CurrencyCardPreviewWrapper()
}

struct CurrencyCardPreviewWrapper: View {
    @State private var currencyName = "British Pound"
    @State private var flagEmoji = "🇬🇧"
    @State private var currencyCode = "GBP"
    
    private let gradientStops = [
        Gradient.Stop(color: Color("primary600"), location: 0.00),
        Gradient.Stop(color: Color("gradientPurpleMid"), location: 0.06),
        Gradient.Stop(color: Color("primary500"), location: 0.09),
        Gradient.Stop(color: Color("gradientPurpleDark"), location: 0.38),
        Gradient.Stop(color: Color("gradientPurpleDeep"), location: 1.00)
    ]
    
    var body: some View {
    CurrencyCard(
        currencyName: $currencyName,
        flagEmoji: $flagEmoji,
        currencyCode: $currencyCode,
        amount: "50.00",
            exchangeRateInfo: "1 GBP = 1.1700 EUR",
            currencySymbol: "£",
            isEditable: true,
            isCurrentlyActive: true
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
} 
