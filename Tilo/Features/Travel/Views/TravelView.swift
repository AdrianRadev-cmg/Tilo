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
    @State private var recentPairs: [CurrencyPair] = []
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
                        
                        // Recent conversions chips carousel
                        RecentConversionsCarousel(
                            recentPairs: recentPairs,
                            onSelectPair: { pair in
                                selectCurrencyPair(pair)
                            }
                        )
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        
                        // Currency selectors
                        VStack(spacing: 16) {
                            // From currency selector
                            CurrencySelectorChip(
                                flagEmoji: fromFlagEmoji,
                                currencyCode: fromCurrencyCode,
                                action: { showFromSelector = true }
                            )
                            
                            // To currency selector
                            CurrencySelectorChip(
                                flagEmoji: toFlagEmoji,
                                currencyCode: toCurrencyCode,
                                action: { showToSelector = true }
                            )
                        }
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        
                        // Conversion table
                        ConversionTable(
                            fromCurrencyCode: fromCurrencyCode,
                            fromFlagEmoji: fromFlagEmoji,
                            toCurrencyCode: toCurrencyCode,
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
                saveRecentPair()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showToSelector) {
            CurrencySelector { selectedCurrency in
                toCurrencyName = selectedCurrency.name
                toFlagEmoji = selectedCurrency.flag
                toCurrencyCode = selectedCurrency.code
                saveRecentPair()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            loadRecentPairs()
            saveRecentPair() // Save current pair when view appears
        }
    }
    
    // MARK: - Recent Pairs Management
    
    private func saveRecentPair() {
        let newPair = CurrencyPair(
            fromCode: fromCurrencyCode,
            fromFlag: fromFlagEmoji,
            toCode: toCurrencyCode,
            toFlag: toFlagEmoji
        )
        
        // Remove if already exists
        recentPairs.removeAll { $0.id == newPair.id }
        
        // Add to front
        recentPairs.insert(newPair, at: 0)
        
        // Keep only 5 most recent
        if recentPairs.count > 5 {
            recentPairs = Array(recentPairs.prefix(5))
        }
        
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(recentPairs) {
            UserDefaults.standard.set(encoded, forKey: "recentCurrencyPairs")
        }
    }
    
    private func loadRecentPairs() {
        if let data = UserDefaults.standard.data(forKey: "recentCurrencyPairs"),
           let decoded = try? JSONDecoder().decode([CurrencyPair].self, from: data) {
            recentPairs = decoded
        }
    }
    
    private func selectCurrencyPair(_ pair: CurrencyPair) {
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        fromCurrencyCode = pair.fromCode
        fromFlagEmoji = pair.fromFlag
        toCurrencyCode = pair.toCode
        toFlagEmoji = pair.toFlag
        
        // Move this pair to front
        saveRecentPair()
    }
}

// MARK: - Currency Pair Model

struct CurrencyPair: Identifiable, Codable, Equatable {
    var id: String {
        "\(fromCode)-\(toCode)"
    }
    let fromCode: String
    let fromFlag: String
    let toCode: String
    let toFlag: String
}

// MARK: - Recent Conversions Carousel

struct RecentConversionsCarousel: View {
    let recentPairs: [CurrencyPair]
    let onSelectPair: (CurrencyPair) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(recentPairs) { pair in
                    Button(action: {
                        onSelectPair(pair)
                    }) {
                        HStack(spacing: 6) {
                            Text(pair.fromFlag)
                                .font(.system(size: 18))
                            Text(pair.fromCode)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text("-")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.white.opacity(0.6))
                            Text(pair.toCode)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                            Text(pair.toFlag)
                                .font(.system(size: 18))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .glassEffect(in: .rect(cornerRadius: 20))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Conversion Table

struct ConversionTable: View {
    let fromCurrencyCode: String
    let fromFlagEmoji: String
    let toCurrencyCode: String
    let toFlagEmoji: String
    
    @State private var conversions: [(amount: Double, converted: Double)] = []
    @State private var isLoading = false
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with export button
            HStack {
                Spacer()
                Button(action: exportTable) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .medium))
                        Text("Export")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(Color("primary100"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Table content
            VStack(spacing: 0) {
                // Header row
                HStack {
                    HStack(spacing: 6) {
                        Text(fromFlagEmoji)
                            .font(.system(size: 18))
                        Text(fromCurrencyCode)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 6) {
                        Text(toFlagEmoji)
                            .font(.system(size: 18))
                        Text(toCurrencyCode)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
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
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text(formatAmount(conversion.converted, for: toCurrencyCode))
                                .font(.system(size: 20, weight: .semibold))
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
        // Very high-value currencies
        let veryHighValue = ["KWD", "BHD", "OMR", "JOD", "GBP"]
        if veryHighValue.contains(currencyCode) {
            return [1, 5, 10, 20, 50]
        }
        
        // High-value currencies
        let highValue = [
            "EUR", "USD", "CHF", "CAD", "AUD", "NZD", "SGD", "AED", "SAR", "QAR",
            "ILS", "BND", "BSD", "PAB", "FJD", "BWP", "AZN", "RON", "BGN", "GEL",
            "PEN", "BOB", "GTQ", "UAH", "RSD", "JMD", "BBD", "TTD", "MUR", "MVR"
        ]
        if highValue.contains(currencyCode) {
            return [10, 50, 100, 200, 500]
        }
        
        // Medium-value currencies
        let mediumValue = [
            "CNY", "HKD", "TWD", "SEK", "NOK", "DKK", "PLN", "CZK", "MXN", "ZAR",
            "BRL", "INR", "THB", "MYR", "PHP", "TRY", "EGP", "RUB", "MDL", "MKD",
            "DOP", "HNL", "NIO", "MAD", "TND", "KES", "UGX", "TZS", "GHS", "NAD"
        ]
        if mediumValue.contains(currencyCode) {
            return [100, 500, 1000, 2000, 5000]
        }
        
        // Low-value currencies
        let lowValue = [
            "JPY", "KRW", "HUF", "ISK", "CLP", "ARS", "COP", "PKR", "LKR", "BDT",
            "MMK", "NGN", "AMD", "KZT", "KGS", "ALL", "RWF", "BIF", "DJF", "GNF",
            "KMF", "MGA", "PYG", "KHR", "MNT"
        ]
        if lowValue.contains(currencyCode) {
            return [1000, 5000, 10000, 20000, 50000]
        }
        
        // Very low-value currencies
        let veryLowValue = [
            "VND", "IDR", "IRR", "LAK", "UZS", "SLL", "LBP", "SYP", "STN", "VES"
        ]
        if veryLowValue.contains(currencyCode) {
            return [10000, 50000, 100000, 200000, 500000]
        }
        
        // Default to high-value
        return [10, 50, 100, 200, 500]
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
                HStack(spacing: 6) {
                    Text(fromFlagEmoji)
                        .font(.system(size: 22))
                    Text(fromCurrencyCode)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 6) {
                    Text(toFlagEmoji)
                        .font(.system(size: 22))
                    Text(toCurrencyCode)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.08))
            
            // Conversion rows
            ForEach(Array(conversions.enumerated()), id: \.offset) { index, conversion in
                HStack {
                    Text(formatAmount(conversion.amount, for: fromCurrencyCode))
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(formatAmount(conversion.converted, for: toCurrencyCode))
                        .font(.system(size: 24, weight: .bold))
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

