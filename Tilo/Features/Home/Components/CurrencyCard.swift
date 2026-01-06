import SwiftUI

// MARK: - Fixed Card Height Constant
// This MUST match the height used in HomeView for swap button positioning
let kCurrencyCardHeight: CGFloat = 156

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
    @State private var isInputError: Bool = false
    @State private var showCurrencySelector: Bool = false
    @State private var sheetDetent: PresentationDetent = .large
    
    // Locale-aware separators
    private var decimalSeparator: String {
        Locale.current.decimalSeparator ?? "."
    }
    
    private var groupingSeparator: String {
        Locale.current.groupingSeparator ?? ","
    }
    
    // Helper to handle amount input changes
    private func handleAmountInputChange(oldValue: String, newValue: String) {
        let cleanInput = newValue.replacingOccurrences(of: groupingSeparator, with: "")
        let decimalChar = Character(decimalSeparator)
        let filtered = cleanInput.filter { $0.isNumber || $0 == decimalChar }
        
        let decimalCount = filtered.filter { $0 == decimalChar }.count
        if decimalCount > 1 {
            amountInput = oldValue
            return
        }
        
        let normalizedForParsing = filtered.replacingOccurrences(of: decimalSeparator, with: ".")
        
        if let doubleValue = Double(normalizedForParsing) {
            let parts = filtered.split(separator: decimalChar, maxSplits: 1, omittingEmptySubsequences: false)
            let integerPart = String(parts[0])
            let decimalPart = parts.count > 1 ? String(parts[1]) : nil
            
            let formattedInteger: String
            if let intValue = Int(integerPart), intValue >= 1000 {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.usesGroupingSeparator = true
                formattedInteger = formatter.string(from: NSNumber(value: intValue)) ?? integerPart
            } else {
                formattedInteger = integerPart
            }
            
            if let decimal = decimalPart {
                amountInput = formattedInteger + decimalSeparator + decimal
            } else if filtered.hasSuffix(String(decimalChar)) {
                amountInput = formattedInteger + decimalSeparator
            } else {
                amountInput = formattedInteger
            }
            
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
        // FIXED HEIGHT CONTAINER - This never changes
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: Currency name - FIXED 28pt height
            Text(currencyName)
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(height: 28, alignment: .leading)
            
            Spacer().frame(height: 16)
            
            // Row 2: Amount input - FIXED 52pt height
            HStack(spacing: 16) {
                // Amount field container
                HStack(alignment: .center, spacing: 4) {
                    Text(currencySymbol)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    // Always render BOTH but only one visible - no layout changes
                    ZStack(alignment: .leading) {
                        // TextField - always in DOM
                        TextField("", text: $amountInput)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .tint(.white)
                            .focused($amountFieldIsFocused)
                            .opacity(isAmountFocused && isEditable ? 1 : 0)
                            .allowsHitTesting(isAmountFocused && isEditable)
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") {
                                        isAmountFocused = false
                                        amountFieldIsFocused = false
                                        onEditingChanged?(false)
                                    }
                                    .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .onChange(of: amountInput) { oldValue, newValue in
                                handleAmountInputChange(oldValue: oldValue, newValue: newValue)
                            }
                            .onChange(of: amountFieldIsFocused) { _, newValue in
                                if !newValue && isAmountFocused {
                                    isAmountFocused = false
                                    onEditingChanged?(false)
                                }
                            }
                        
                        // Display text - always in DOM
                        Text(amountInput.isEmpty ? amount : amountInput)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .opacity(isAmountFocused && isEditable ? 0 : 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(height: 52)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay {
                    if isInputError {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.8, green: 0.2, blue: 0.2), lineWidth: 1)
                    }
                }
                .glassEffect()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditable && !isAmountFocused && isCurrentlyActive {
                        amountInput = ""
                        isInputError = false
                        isAmountFocused = true
                        onEditingChanged?(true)
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
            .frame(height: 52)
            
            Spacer().frame(height: 12)
            
            // Row 3: Exchange rate / Error - FIXED 20pt height
            // Always render both, use opacity to switch
            ZStack(alignment: .leading) {
                Text(exchangeRateInfo)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                    .opacity(isInputError ? 0 : 1)
                
                Text("Invalid amount")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0.8, green: 0.2, blue: 0.2))
                    .opacity(isInputError ? 1 : 0)
            }
            .frame(height: 20, alignment: .leading)
        }
        .frame(height: kCurrencyCardHeight - 48) // Content height (total - padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(height: kCurrencyCardHeight) // ABSOLUTE FIXED HEIGHT
        .onChange(of: amount) { oldAmount, newAmount in
            if !isAmountFocused {
                amountInput = newAmount
                isInputError = false
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isAmountFocused {
                isAmountFocused = false
                amountFieldIsFocused = false 
                onEditingChanged?(false)
            }
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .glassEffect(in: .rect(cornerRadius: 16))
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 20/255, green: 8/255, blue: 58/255).opacity(0.75))
            }
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
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
            sheetDetent = .large
        }) {
            CurrencySelector { selectedCurrency in
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
