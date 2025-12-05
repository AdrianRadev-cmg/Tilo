import SwiftUI
import Photos

// MARK: - Image Saver Helper
class ImageSaver: NSObject {
    static let shared = ImageSaver()
    private var completion: ((Bool) -> Void)?
    
    func saveImage(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        self.completion = completion
        
        // Check if we're in a preview or simulator environment where this might fail
        #if targetEnvironment(simulator)
        // Still try to save on simulator
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
        #else
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
        #endif
    }
    
    @objc func saveCompleted(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            self.completion?(error == nil)
        }
    }
}

struct TravelView: View {
    // Passed from Convert tab
    @Binding var fromCurrencyCode: String
    @Binding var fromCurrencyName: String
    @Binding var fromFlagEmoji: String
    @Binding var toCurrencyCode: String
    @Binding var toCurrencyName: String
    @Binding var toFlagEmoji: String
    
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
                        // Title and subtitle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cheat Sheet")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("Save to photos for quick reference while shopping, eating out, tipping, or paying for transport when travelling abroad.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        .padding(.top, max(36, geometry.size.height * 0.02 + 16))
                        
                        // Conversion table with flip gesture
                        ConversionTable(
                            fromCurrencyCode: $fromCurrencyCode,
                            fromCurrencyName: $fromCurrencyName,
                            fromFlagEmoji: $fromFlagEmoji,
                            toCurrencyCode: $toCurrencyCode,
                            toCurrencyName: $toCurrencyName,
                            toFlagEmoji: $toFlagEmoji
                        )
                        .padding(.horizontal, max(16, geometry.size.width * 0.04))
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Conversion Table

struct ConversionTable: View {
    @Binding var fromCurrencyCode: String
    @Binding var fromCurrencyName: String
    @Binding var fromFlagEmoji: String
    @Binding var toCurrencyCode: String
    @Binding var toCurrencyName: String
    @Binding var toFlagEmoji: String
    
    @State private var conversions: [(amount: Double, converted: Double)] = []
    @State private var exchangeRate: Double?
    @State private var isLoading = false
    @State private var isFlipped = false
    @State private var flipDegrees: Double = 0
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentLevel: Int = 0 // 0 = base level, 1 = higher values
    @State private var showValueHighlight: Bool = false // For flash effect after flip
    @State private var showWidgetGuide: Bool = false
    @StateObject private var exchangeService = ExchangeRateService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tableContentView
            flipHintView
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Currency conversion table from \(fromCurrencyCode) to \(toCurrencyCode)")
        .accessibilityHint("Tap right side for higher values, left side for lower values")
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
        // 3D flip effect
        .rotation3DEffect(
            .degrees(flipDegrees),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.5
        )
        // Tap left/right to change value levels
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    // Detect which side was tapped
                    let tapX = value.location.x
                    // We'll use the startLocation to determine tap position
                    handleTap(at: value.startLocation.x)
                }
        )
        .task {
            await fetchConversions()
        }
        .onChange(of: fromCurrencyCode) { _, _ in
            currentLevel = 0 // Reset to base level when currency changes
            Task { await fetchConversions() }
        }
        .onChange(of: toCurrencyCode) { _, _ in
            currentLevel = 0 // Reset to base level when currency changes
            Task { await fetchConversions() }
        }
        .sheet(isPresented: $showWidgetGuide) {
            WidgetGuideView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Tap Handling
    
    private func handleTap(at xPosition: CGFloat) {
        // Get the width of the view to determine left/right
        // We'll use UIScreen as a fallback - the gesture provides relative position
        let screenWidth = UIScreen.main.bounds.width - 32 // Account for padding
        let midPoint = screenWidth / 2
        
        if xPosition > midPoint {
            // Tapped right side - increase level
            if currentLevel < 1 {
                flipCard(increasing: true)
            } else {
                // Already at max level - haptic feedback only
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } else {
            // Tapped left side - decrease level
            if currentLevel > 0 {
                flipCard(increasing: false)
            } else {
                // Already at min level - haptic feedback only
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    // MARK: - Flip Animation
    
    private func flipCard(increasing: Bool) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Flip direction: right tap = flip right (positive), left tap = flip left (negative)
        let firstHalfTarget: Double = increasing ? 90 : -90
        let secondHalfStart: Double = increasing ? -90 : 90
        
        // Animate first half of flip
        withAnimation(.easeIn(duration: 0.15)) {
            flipDegrees = firstHalfTarget
        }
        
        // At 90 degrees (edge-on), change the level and recalculate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // Change level while card is edge-on (invisible)
            if increasing {
                currentLevel = min(1, currentLevel + 1)
            } else {
                currentLevel = max(0, currentLevel - 1)
            }
            
            // Recalculate conversions with new level
            Task {
                await updateConversionsForCurrentLevel()
            }
            
            // Set to opposite side so we animate back to 0 (completing the illusion)
            flipDegrees = secondHalfStart
            
            // Animate second half of flip back to 0
            withAnimation(.easeOut(duration: 0.15)) {
                flipDegrees = 0
            }
            
            // Trigger highlight effect after flip completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.1)) {
                    showValueHighlight = true
                }
                // Fade out the highlight after 0.4s
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showValueHighlight = false
                    }
                }
            }
        }
    }
    
    private func updateConversionsForCurrentLevel() async {
        guard let rate = exchangeRate else { return }
        
        let amounts = getTableAmounts(for: fromCurrencyCode, level: currentLevel)
        var results: [(amount: Double, converted: Double)] = []
        
        for amount in amounts {
            let converted = amount * rate
            results.append((amount: amount, converted: converted))
        }
        
        conversions = results
    }
    
    // MARK: - Data Fetching
    
    private func fetchConversions() async {
        isLoading = true
        
        showError = false
        
        // Fetch exchange rate
        if let rate = await exchangeService.getRate(from: fromCurrencyCode, to: toCurrencyCode) {
            exchangeRate = rate
            
            let amounts = getTableAmounts(for: fromCurrencyCode, level: currentLevel)
            var results: [(amount: Double, converted: Double)] = []
            
            for amount in amounts {
                if let converted = await exchangeService.convert(amount: amount, from: fromCurrencyCode, to: toCurrencyCode) {
                    results.append((amount: amount, converted: converted))
                }
            }
            
            conversions = results
        } else {
            // Show error if rate couldn't be fetched
            if let serviceError = exchangeService.errorMessage {
                errorMessage = serviceError
            } else {
                errorMessage = "Unable to fetch exchange rates"
            }
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Functions
    
    private func getTableAmounts(for currencyCode: String, level: Int = 0) -> [Double] {
        // Very high-value currencies (GBP, KWD, etc.) - practical travel amounts
        let veryHighValue = ["KWD", "BHD", "OMR", "JOD", "GBP", "CHF"]
        if veryHighValue.contains(currencyCode) {
            if level == 0 {
                return [10, 20, 50, 100, 200, 500, 1000, 2000]
            } else {
                return [3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]
            }
        }
        
        // High-value currencies (EUR, USD, etc.) - practical travel amounts
        let highValue = [
            "EUR", "USD", "CAD", "AUD", "NZD", "SGD", "AED", "SAR", "QAR",
            "ILS", "BND", "BSD", "PAB", "FJD", "BWP", "AZN", "RON", "BGN", "GEL",
            "PEN", "BOB", "GTQ", "BBD", "TTD", "MUR", "MVR"
        ]
        if highValue.contains(currencyCode) {
            if level == 0 {
                return [10, 20, 50, 100, 200, 500, 1000, 2000]
            } else {
                return [3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]
            }
        }
        
        // Medium-value currencies (CNY, THB, MXN, etc.) - amounts you'd spend on meals, transport
        let mediumValue = [
            "CNY", "HKD", "TWD", "SEK", "NOK", "DKK", "PLN", "CZK", "MXN", "ZAR",
            "BRL", "MYR", "TRY", "EGP", "RUB", "MDL", "MKD", "UAH", "RSD", "JMD",
            "DOP", "HNL", "NIO", "MAD", "TND", "GHS", "NAD"
        ]
        if mediumValue.contains(currencyCode) {
            if level == 0 {
                return [50, 100, 200, 500, 1000, 2000, 5000, 10000]
            } else {
                return [15000, 20000, 25000, 30000, 40000, 50000, 75000, 100000]
            }
        }
        
        // Lower-medium currencies (THB, INR, PHP) - common travel spending
        let lowerMedium = ["THB", "INR", "PHP", "KES", "UGX", "TZS"]
        if lowerMedium.contains(currencyCode) {
            if level == 0 {
                return [100, 200, 500, 1000, 2000, 5000, 10000, 20000]
            } else {
                return [30000, 40000, 50000, 60000, 70000, 80000, 90000, 100000]
            }
        }
        
        // Low-value currencies (JPY, KRW, etc.) - amounts for everyday purchases
        let lowValue = [
            "JPY", "KRW", "HUF", "ISK", "CLP", "ARS", "COP", "PKR", "LKR", "BDT",
            "MMK", "NGN", "AMD", "KZT", "KGS", "ALL", "RWF", "BIF", "DJF", "GNF",
            "KMF", "MGA", "PYG", "KHR", "MNT"
        ]
        if lowValue.contains(currencyCode) {
            if level == 0 {
                return [500, 1000, 2000, 5000, 10000, 20000, 50000, 100000]
            } else {
                return [150000, 200000, 300000, 400000, 500000, 750000, 1000000, 2000000]
            }
        }
        
        // Very low-value currencies (VND, IDR, etc.) - large denominations common
        let veryLowValue = [
            "VND", "IDR", "IRR", "LAK", "UZS", "SLL", "LBP", "SYP", "STN", "VES"
        ]
        if veryLowValue.contains(currencyCode) {
            if level == 0 {
                return [10000, 20000, 50000, 100000, 200000, 500000, 1000000, 2000000]
            } else {
                return [3000000, 4000000, 5000000, 6000000, 7000000, 8000000, 9000000, 10000000]
            }
        }
        
        // Default to high-value pattern
        if level == 0 {
            return [10, 20, 50, 100, 200, 500, 1000, 2000]
        } else {
            return [3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]
        }
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
    
    // MARK: - Table Content Views
    
    private var tableContentView: some View {
        VStack(spacing: 0) {
            tableHeaderView
            
            if isLoading {
                loadingView
            } else if showError {
                errorStateView
            } else {
                conversionRowsView
            }
        }
    }
    
    private var conversionRowsView: some View {
        ForEach(Array(conversions.enumerated()), id: \.offset) { index, conversion in
            ConversionRowView(
                fromAmount: formatAmount(conversion.amount, for: fromCurrencyCode),
                toAmount: formatAmount(conversion.converted, for: toCurrencyCode),
                fromCode: fromCurrencyCode,
                toCode: toCurrencyCode,
                isAlternate: index % 2 != 0,
                isHighlighted: showValueHighlight
            )
        }
    }
    
    private var flipHintView: some View {
        HStack(spacing: 6) {
            Image(systemName: "chevron.left")
                .font(.system(size: 10, weight: .medium))
                .opacity(currentLevel > 0 ? 1.0 : 0.3)
            Text(currentLevel == 0 ? "Tap right for higher values" : "Tap left for lower values")
                .font(.system(size: 12, weight: .medium))
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .medium))
                .opacity(currentLevel < 1 ? 1.0 : 0.3)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityHidden(true)
    }
    
    // MARK: - Loading & Error States
    
    private var loadingView: some View {
        ProgressView()
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Loading conversion rates")
    }
    
    private var errorStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color("primary100").opacity(0.6))
            
            Text("Unable to load rates")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Button(action: {
                Task { await fetchConversions() }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Retry")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color("primary500").opacity(0.6))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retry loading rates")
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Header Components
    
    private var tableHeaderView: some View {
        HStack(spacing: 16) {
            overlappingFlagsView
            currencyInfoView
            Spacer()
            addWidgetButtonView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05))
    }
    
    private var overlappingFlagsView: some View {
        ZStack(alignment: .center) {
            // From flag (top-left, front)
            Text(fromFlagEmoji)
                .font(.system(size: 24))
                .frame(width: 36, height: 36)
                .glassEffect()
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .clipShape(Circle())
                .zIndex(1)
                .offset(x: -10, y: -8)
            
            // To flag (bottom-right, behind)
            Text(toFlagEmoji)
                .font(.system(size: 24))
                .frame(width: 36, height: 36)
                .glassEffect()
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
                .clipShape(Circle())
                .offset(x: 10, y: 8)
        }
        .frame(width: 56, height: 52)
    }
    
    private var currencyInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Currency codes with arrow
            HStack(spacing: 8) {
                Text(fromCurrencyCode)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("grey100"))
                
                Text("→")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("grey100"))
                
                Text(toCurrencyCode)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color("grey100"))
            }
            
            // Rate info
            if let rate = exchangeRate {
                Text("1 \(fromCurrencyCode) = \(String(format: "%.4f", rate)) \(toCurrencyCode)")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
            }
        }
    }
    
    private var addWidgetButtonView: some View {
        Button(action: { showWidgetGuide = true }) {
            Image(systemName: "plus.rectangle.on.rectangle")
                .font(.system(size: 20, weight: .regular))
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
        .accessibilityLabel("Add Widget")
        .accessibilityHint("Double tap to learn how to add Tilo widget to your home screen")
    }
    
    // Snapshot view for export (kept for potential future use)
    private var tableSnapshotView: some View {
        ZStack {
            // Flag-based gradient background
            flagGradientBackground
            
            VStack(alignment: .leading, spacing: 0) {
                // Header with currency codes (no flags)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(fromCurrencyCode)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("→")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(toCurrencyCode)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    if let rate = exchangeRate {
                        Text("1 \(fromCurrencyCode) = \(String(format: "%.4f", rate)) \(toCurrencyCode)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                
                // Conversion rows with dotted lines (same as app)
                ForEach(Array(conversions.enumerated()), id: \.offset) { index, conversion in
                    HStack(spacing: 0) {
                        Text(formatAmount(conversion.amount, for: fromCurrencyCode))
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(.white)
                        
                        // Dotted leader line
                        GeometryReader { geo in
                            Path { path in
                                let y = geo.size.height / 2
                                var x: CGFloat = 8
                                while x < geo.size.width - 8 {
                                    path.move(to: CGPoint(x: x, y: y))
                                    path.addLine(to: CGPoint(x: x + 2, y: y))
                                    x += 6
                                }
                            }
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        }
                        .frame(height: 24)
                        
                        Text(formatAmount(conversion.converted, for: toCurrencyCode))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color("primary100"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        index % 2 == 0 ? Color.clear : Color.white.opacity(0.03)
                    )
                }
                
                // Branding footer
                HStack {
                    Spacer()
                    Text("Made with Tilo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(24)
        }
        .frame(width: 400)
    }
    
    // Flag-based gradient background for export (based on destination/to currency)
    private var flagGradientBackground: some View {
        let colors = getFlagColors(for: toCurrencyCode)
        return ZStack {
            // Base dark layer
            Color.black
            
            // Primary flag color gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: colors.0, location: 0.0),
                    .init(color: colors.1, location: 0.5),
                    .init(color: colors.0.opacity(0.8), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.85)
            
            // Dark overlay for readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    // Get flag colors for currency - using actual flag hex colors
    private func getFlagColors(for currencyCode: String) -> (Color, Color) {
        switch currencyCode {
        // Japan - Hinomaru red
        case "JPY": return (Color(red: 0.74, green: 0.07, blue: 0.17), Color(red: 0.95, green: 0.95, blue: 0.95))
            
        // China - Chinese red and gold
        case "CNY": return (Color(red: 0.87, green: 0.16, blue: 0.06), Color(red: 1.0, green: 0.87, blue: 0.0))
            
        // UK - Union Jack blue and red
        case "GBP": return (Color(red: 0.0, green: 0.14, blue: 0.42), Color(red: 0.81, green: 0.06, blue: 0.19))
            
        // USA - Old Glory blue and red
        case "USD": return (Color(red: 0.0, green: 0.13, blue: 0.30), Color(red: 0.70, green: 0.13, blue: 0.20))
            
        // EU - European blue and gold stars
        case "EUR": return (Color(red: 0.0, green: 0.20, blue: 0.50), Color(red: 1.0, green: 0.80, blue: 0.0))
            
        // Switzerland - Swiss red
        case "CHF": return (Color(red: 0.85, green: 0.0, blue: 0.05), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Canada - Maple red
        case "CAD": return (Color(red: 0.85, green: 0.08, blue: 0.16), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Australia - Australian blue
        case "AUD": return (Color(red: 0.0, green: 0.0, blue: 0.55), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Thailand - Thai blue and red
        case "THB": return (Color(red: 0.14, green: 0.23, blue: 0.46), Color(red: 0.65, green: 0.15, blue: 0.22))
            
        // India - Saffron and green
        case "INR": return (Color(red: 1.0, green: 0.60, blue: 0.20), Color(red: 0.07, green: 0.53, blue: 0.03))
            
        // Singapore - Red and white
        case "SGD": return (Color(red: 0.93, green: 0.11, blue: 0.14), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Hong Kong - Bauhinia red
        case "HKD": return (Color(red: 0.87, green: 0.0, blue: 0.15), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // South Korea - Taegukgi blue and red
        case "KRW": return (Color(red: 0.0, green: 0.28, blue: 0.58), Color(red: 0.80, green: 0.15, blue: 0.20))
            
        // Taiwan - Blue sky and white sun
        case "TWD": return (Color(red: 0.0, green: 0.0, blue: 0.60), Color(red: 0.87, green: 0.16, blue: 0.19))
            
        // Vietnam - Vietnamese red and gold star
        case "VND": return (Color(red: 0.85, green: 0.09, blue: 0.09), Color(red: 1.0, green: 0.80, blue: 0.0))
            
        // Indonesia - Red and white
        case "IDR": return (Color(red: 0.80, green: 0.0, blue: 0.0), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Malaysia - Jalur Gemilang
        case "MYR": return (Color(red: 0.0, green: 0.0, blue: 0.55), Color(red: 0.80, green: 0.0, blue: 0.0))
            
        // Philippines - Blue, red, gold
        case "PHP": return (Color(red: 0.0, green: 0.22, blue: 0.55), Color(red: 0.80, green: 0.07, blue: 0.19))
            
        // Mexico - Green, white, red
        case "MXN": return (Color(red: 0.0, green: 0.40, blue: 0.24), Color(red: 0.80, green: 0.12, blue: 0.18))
            
        // Brazil - Green and gold
        case "BRL": return (Color(red: 0.0, green: 0.60, blue: 0.30), Color(red: 1.0, green: 0.87, blue: 0.0))
            
        // Turkey - Turkish red
        case "TRY": return (Color(red: 0.89, green: 0.04, blue: 0.17), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // South Africa - Rainbow nation
        case "ZAR": return (Color(red: 0.0, green: 0.47, blue: 0.28), Color(red: 1.0, green: 0.72, blue: 0.0))
            
        // UAE - Green, white, black, red
        case "AED": return (Color(red: 0.0, green: 0.45, blue: 0.24), Color(red: 0.80, green: 0.0, blue: 0.0))
            
        // Saudi Arabia - Green
        case "SAR": return (Color(red: 0.0, green: 0.44, blue: 0.24), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Egypt - Red, white, black
        case "EGP": return (Color(red: 0.78, green: 0.09, blue: 0.21), Color(red: 0.0, green: 0.0, blue: 0.0))
            
        // New Zealand - Blue and red
        case "NZD": return (Color(red: 0.0, green: 0.14, blue: 0.42), Color(red: 0.80, green: 0.0, blue: 0.15))
            
        // Sweden - Blue and gold
        case "SEK": return (Color(red: 0.0, green: 0.41, blue: 0.65), Color(red: 0.99, green: 0.80, blue: 0.0))
            
        // Norway - Red, white, blue
        case "NOK": return (Color(red: 0.73, green: 0.12, blue: 0.19), Color(red: 0.0, green: 0.20, blue: 0.50))
            
        // Denmark - Danish red
        case "DKK": return (Color(red: 0.78, green: 0.06, blue: 0.18), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Poland - White and red
        case "PLN": return (Color(red: 0.86, green: 0.12, blue: 0.22), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Czech - Blue, white, red
        case "CZK": return (Color(red: 0.07, green: 0.20, blue: 0.53), Color(red: 0.84, green: 0.09, blue: 0.20))
            
        // Hungary - Red, white, green
        case "HUF": return (Color(red: 0.80, green: 0.25, blue: 0.22), Color(red: 0.28, green: 0.55, blue: 0.27))
            
        // Russia - White, blue, red
        case "RUB": return (Color(red: 0.0, green: 0.22, blue: 0.55), Color(red: 0.84, green: 0.09, blue: 0.20))
            
        // Israel - Blue and white
        case "ILS": return (Color(red: 0.0, green: 0.22, blue: 0.55), Color(red: 1.0, green: 1.0, blue: 1.0))
            
        // Default - Tilo purple brand
        default: return (Color(red: 0.31, green: 0.19, blue: 0.65), Color(red: 0.18, green: 0.09, blue: 0.38))
        }
    }
    
    // Helper to format current date
    private var formattedCurrentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    // Helper to format current time
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
}

// MARK: - Conversion Row View

private struct ConversionRowView: View {
    let fromAmount: String
    let toAmount: String
    let fromCode: String
    let toCode: String
    let isAlternate: Bool
    let isHighlighted: Bool
    
    // Highlight color for the flash effect
    private var highlightColor: Color {
        Color(white: 0.55) // Subtle grey flash
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(fromAmount)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(isHighlighted ? highlightColor : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            
            DottedLineView()
                .frame(height: 24)
                .accessibilityHidden(true)
            
            Text(toAmount)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(isHighlighted ? highlightColor : Color("primary100"))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isAlternate ? Color.white.opacity(0.03) : Color.clear)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fromAmount) \(fromCode) equals \(toAmount) \(toCode)")
    }
}

private struct DottedLineView: View {
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let y = geo.size.height / 2
                var x: CGFloat = 8
                while x < geo.size.width - 8 {
                    path.move(to: CGPoint(x: x, y: y))
                    path.addLine(to: CGPoint(x: x + 2, y: y))
                    x += 6
                }
            }
            .stroke(Color.white.opacity(0.2), lineWidth: 1)
        }
    }
}

// MARK: - Widget Guide View

struct WidgetGuideView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("primary300"), Color("primary500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Add Tilo Widget")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color("grey100"))
                
                Text("Quick access to exchange rates on your home screen")
                    .font(.system(size: 15))
                    .foregroundColor(Color("grey300"))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            // Steps
            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, text: "Long press on your home screen")
                StepRow(number: 2, text: "Tap the + button in the top corner")
                StepRow(number: 3, text: "Search for \"Tilo\"")
                StepRow(number: 4, text: "Choose your preferred widget size")
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Got it button
            Button(action: { dismiss() }) {
                Text("Got it")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color("primary500"))
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .padding(.top, 24)
        .background(Color("background"))
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(number)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color("primary500"))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color("primary500").opacity(0.15))
                )
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Color("grey100"))
        }
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

