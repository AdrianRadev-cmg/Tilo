import SwiftUI

struct TravelView: View {
    // Passed from Currency tab
    @Binding var fromCurrencyCode: String
    @Binding var fromCurrencyName: String
    @Binding var fromFlagEmoji: String
    @Binding var toCurrencyCode: String
    @Binding var toCurrencyName: String
    @Binding var toFlagEmoji: String
    
    // Local state
    @State private var showFromSelector = false
    @State private var showToSelector = false
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            // Base purple gradient (same as Currency tab)
            LinearGradient(
                gradient: Gradient(stops: [
                    Gradient.Stop(color: Color(red: 0.18, green: 0.09, blue: 0.38), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.21, green: 0.10, blue: 0.42), location: 0.06),
                    Gradient.Stop(color: Color(red: 0.24, green: 0.11, blue: 0.48), location: 0.09),
                    Gradient.Stop(color: Color(red: 0.13, green: 0.05, blue: 0.26), location: 0.38),
                    Gradient.Stop(color: Color(red: 0.08, green: 0.03, blue: 0.15), location: 1.00)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .overlay(Color.black.opacity(0.30))
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        HStack {
                            Text("Quick Reference")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        .padding(.top, max(20, geometry.size.height * 0.02))
                        
                        // Currency selector card
                        HStack(spacing: 12) {
                            // From currency selector
                            CurrencySelectorChip(
                                flagEmoji: fromFlagEmoji,
                                currencyCode: fromCurrencyCode,
                                action: { showFromSelector = true }
                            )
                            .frame(maxWidth: .infinity)
                            
                            // Swap button with left/right arrows
                            Button(action: swapCurrencies) {
                                Image(systemName: "arrow.left.arrow.right.circle")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundStyle(Color("grey100"))
                                    .frame(width: 44, height: 44)
                                    .glassEffect()
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    )
                                    .clipShape(Circle())
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .shadow(color: .black.opacity(0.20), radius: 10, x: 0, y: 3)
                            
                            // To currency selector
                            CurrencySelectorChip(
                                flagEmoji: toFlagEmoji,
                                currencyCode: toCurrencyCode,
                                action: { showToSelector = true }
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .padding(16)
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
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        
                        // Conversion table
                        ConversionTable(
                            fromCurrencyCode: fromCurrencyCode,
                            fromCurrencyName: fromCurrencyName,
                            fromFlagEmoji: fromFlagEmoji,
                            toCurrencyCode: toCurrencyCode,
                            toCurrencyName: toCurrencyName,
                            toFlagEmoji: toFlagEmoji
                        )
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .sheet(isPresented: $showFromSelector) {
            CurrencySelector { selectedCurrency in
                fromCurrencyName = selectedCurrency.name
                fromFlagEmoji = selectedCurrency.flag
                fromCurrencyCode = selectedCurrency.code
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showToSelector) {
            CurrencySelector { selectedCurrency in
                toCurrencyName = selectedCurrency.name
                toFlagEmoji = selectedCurrency.flag
                toCurrencyCode = selectedCurrency.code
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Swap Currencies
    
    private func swapCurrencies() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Swap the currency values
        let tempCode = fromCurrencyCode
        let tempFlag = fromFlagEmoji
        let tempName = fromCurrencyName
        
        fromCurrencyCode = toCurrencyCode
        fromFlagEmoji = toFlagEmoji
        fromCurrencyName = toCurrencyName
        
        toCurrencyCode = tempCode
        toFlagEmoji = tempFlag
        toCurrencyName = tempName
    }
}

// MARK: - Conversion Table

struct ConversionTable: View {
    let fromCurrencyCode: String
    let fromCurrencyName: String
    let fromFlagEmoji: String
    let toCurrencyCode: String
    let toCurrencyName: String
    let toFlagEmoji: String
    
    @State private var conversions: [(amount: Double, converted: Double)] = []
    @State private var exchangeRate: Double?
    @State private var isLoading = false
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Table content
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text(fromCurrencyName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(toCurrencyName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                
                // Conversion rows
                if isLoading {
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(conversions.enumerated()), id: \.offset) { index, conversion in
                        HStack {
                            Text(formatAmount(conversion.amount, for: fromCurrencyCode))
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(formatAmount(conversion.converted, for: toCurrencyCode))
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(Color("primary100"))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            index % 2 == 0 ? Color.clear : Color.white.opacity(0.03)
                        )
                    }
                }
            }
            
            // Footer with exchange rate and export button
            HStack {
                // Exchange rate info
                if let rate = exchangeRate {
                    Text("1 \(fromCurrencyCode) = \(String(format: "%.4f", rate)) \(toCurrencyCode)")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                }
                
                Spacer()
                
                // Export button (icon only, glass style)
                Button(action: exportTable) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Color("grey100"))
                        .frame(width: 44, height: 44)
                        .glassEffect()
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                        )
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .shadow(color: .black.opacity(0.20), radius: 10, x: 0, y: 3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .background(
            ZStack {
                // Glass effect as base layer
                RoundedRectangle(cornerRadius: 16)
                    .glassEffect(in: .rect(cornerRadius: 16))
                
                // Dark purple overlay
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
        .task {
            await fetchConversions()
        }
        .onChange(of: fromCurrencyCode) { _, _ in
            Task { await fetchConversions() }
        }
        .onChange(of: toCurrencyCode) { _, _ in
            Task { await fetchConversions() }
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchConversions() async {
        isLoading = true
        
        // Fetch exchange rate
        if let rate = await exchangeService.getRate(from: fromCurrencyCode, to: toCurrencyCode) {
            exchangeRate = rate
        }
        
        let amounts = getTableAmounts(for: fromCurrencyCode)
        var results: [(amount: Double, converted: Double)] = []
        
        for amount in amounts {
            if let converted = await exchangeService.convert(amount: amount, from: fromCurrencyCode, to: toCurrencyCode) {
                results.append((amount: amount, converted: converted))
            }
        }
        
        conversions = results
        isLoading = false
    }
    
    // MARK: - Helper Functions
    
    private func getTableAmounts(for currencyCode: String) -> [Double] {
        // Very high-value currencies - 8 values
        let veryHighValue = ["KWD", "BHD", "OMR", "JOD", "GBP"]
        if veryHighValue.contains(currencyCode) {
            return [1, 5, 10, 20, 50, 100, 200, 500]
        }
        
        // High-value currencies - 8 values
        let highValue = [
            "EUR", "USD", "CHF", "CAD", "AUD", "NZD", "SGD", "AED", "SAR", "QAR",
            "ILS", "BND", "BSD", "PAB", "FJD", "BWP", "AZN", "RON", "BGN", "GEL",
            "PEN", "BOB", "GTQ", "UAH", "RSD", "JMD", "BBD", "TTD", "MUR", "MVR"
        ]
        if highValue.contains(currencyCode) {
            return [10, 50, 100, 200, 500, 1000, 2000, 5000]
        }
        
        // Medium-value currencies - 8 values
        let mediumValue = [
            "CNY", "HKD", "TWD", "SEK", "NOK", "DKK", "PLN", "CZK", "MXN", "ZAR",
            "BRL", "INR", "THB", "MYR", "PHP", "TRY", "EGP", "RUB", "MDL", "MKD",
            "DOP", "HNL", "NIO", "MAD", "TND", "KES", "UGX", "TZS", "GHS", "NAD"
        ]
        if mediumValue.contains(currencyCode) {
            return [100, 500, 1000, 2000, 5000, 10000, 20000, 50000]
        }
        
        // Low-value currencies - 8 values
        let lowValue = [
            "JPY", "KRW", "HUF", "ISK", "CLP", "ARS", "COP", "PKR", "LKR", "BDT",
            "MMK", "NGN", "AMD", "KZT", "KGS", "ALL", "RWF", "BIF", "DJF", "GNF",
            "KMF", "MGA", "PYG", "KHR", "MNT"
        ]
        if lowValue.contains(currencyCode) {
            return [1000, 5000, 10000, 20000, 50000, 100000, 200000, 500000]
        }
        
        // Very low-value currencies - 8 values
        let veryLowValue = [
            "VND", "IDR", "IRR", "LAK", "UZS", "SLL", "LBP", "SYP", "STN", "VES"
        ]
        if veryLowValue.contains(currencyCode) {
            return [10000, 50000, 100000, 200000, 500000, 1000000, 2000000, 5000000]
        }
        
        // Default to high-value
        return [10, 50, 100, 200, 500, 1000, 2000, 5000]
    }
    
    private func formatAmount(_ amount: Double, for currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ","
        
        // For very large amounts or whole numbers, don't show decimals
        if amount >= 1000 || amount == floor(amount) {
            formatter.maximumFractionDigits = 0
        }
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    // MARK: - Export Function
    
    private func exportTable() {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Create a snapshot of the table
        let renderer = ImageRenderer(content: tableSnapshotView)
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            // Present share sheet
            let activityVC = UIActivityViewController(
                activityItems: [image],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                // Find the topmost presented view controller
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                topVC.present(activityVC, animated: true)
            }
        }
    }
    
    // Snapshot view for export (pretty version without export button)
    private var tableSnapshotView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                Text(fromCurrencyName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(toCurrencyName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.08))
            
            // Conversion rows
            ForEach(Array(conversions.enumerated()), id: \.offset) { index, conversion in
                HStack {
                    Text(formatAmount(conversion.amount, for: fromCurrencyCode))
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(formatAmount(conversion.converted, for: toCurrencyCode))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    index % 2 == 0 ? Color.clear : Color.white.opacity(0.03)
                )
            }
            
            // Branding footer
            HStack {
                Spacer()
                Text("Made with Tilo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            .padding(.vertical, 12)
        }
        .background(
            ZStack {
                // Glass effect as base layer
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 20/255, green: 8/255, blue: 58/255).opacity(0.95))
                
                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.24, green: 0.11, blue: 0.48).opacity(0.6),
                        Color(red: 0.13, green: 0.05, blue: 0.26).opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(width: 400)
        .padding(20)
    }
}

#Preview {
    TravelView(
        fromCurrencyCode: .constant("JPY"),
        fromCurrencyName: .constant("Japanese Yen"),
        fromFlagEmoji: .constant("🇯🇵"),
        toCurrencyCode: .constant("GBP"),
        toCurrencyName: .constant("British Pound"),
        toFlagEmoji: .constant("🇬🇧")
    )
    .preferredColorScheme(.dark)
}

