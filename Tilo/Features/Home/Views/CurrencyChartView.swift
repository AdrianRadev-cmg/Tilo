import SwiftUI
import Charts

// MARK: - Models
struct ExchangeRate: Identifiable {
    let id = UUID()
    let date: Date
    let rate: Double
}

// MARK: - ViewModel
@MainActor
final class CurrencyChartViewModel: ObservableObject {
    @Published private(set) var rates: [ExchangeRate] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private var fromCurrency: String
    private var toCurrency: String
    private let exchangeService = ExchangeRateService.shared
    
    // Track if we've successfully fetched data for the current currency pair
    private var hasFetchedForCurrentPair: Bool = false
    private var lastFetchedPair: String = ""
    
    init(fromCurrency: String, toCurrency: String) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
    }
    
    func fetchRates(for range: TimeRange = .oneWeek, forceRefresh: Bool = false) async {
        let currentPair = "\(fromCurrency)_\(toCurrency)"
        
        // Skip fetch if we already have data for this pair (prevents re-fetch on tab switch)
        if !forceRefresh && hasFetchedForCurrentPair && lastFetchedPair == currentPair && !rates.isEmpty {
            print("📊 Skipping fetch - already have data for \(currentPair) (\(rates.count) points)")
            return
        }
        
        isLoading = true
        error = nil
        
        print("📊 ViewModel fetchRates: \(fromCurrency) → \(toCurrency) (forceRefresh: \(forceRefresh))")
        
        // Fetch historical data from ExchangeRateService (14 days)
        if let historicalData = await exchangeService.fetchHistoricalRates(from: fromCurrency, to: toCurrency, days: 14) {
            print("📊 Received \(historicalData.count) historical data points")
            // Convert to ExchangeRate format
            // Note: Historical data already excludes today (starts from yesterday)
            // This ensures we only show complete daily data
            let ratesArray = historicalData.map { histRate in
                ExchangeRate(date: histRate.date, rate: histRate.rate)
            }
            
            rates = ratesArray
            hasFetchedForCurrentPair = true
            lastFetchedPair = currentPair
            print("📊 Chart rates updated: \(rates.count) points, marked as fetched for \(currentPair)")
        } else {
            print("❌ No historical data received!")
            error = NSError(domain: "CurrencyChart", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch historical data"])
            rates = []
        }
        
        isLoading = false
        print("📊 fetchRates completed, isLoading: \(isLoading), rates count: \(rates.count)")
    }
    
    var currentRate: Double {
        rates.last?.rate ?? 0.0
    }
    
    var highRate: Double {
        rates.map(\.rate).max() ?? 0.0
    }
    
    var lowRate: Double {
        rates.map(\.rate).min() ?? 0.0
    }
    
    var medianRate: Double {
        // Calculate the visual middle point between high and low
        // This ensures the middle line is always in the center of the chart
        return (highRate + lowRate) / 2.0
    }
    
    var startDate: String {
        guard let firstDate = rates.first?.date else { return "" }
        return formatDate(firstDate)
    }
    
    var endDate: String {
        guard let lastDate = rates.last?.date else { return "" }
        return formatDate(lastDate)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    func updateCurrencies(from: String, to: String) {
        self.fromCurrency = from
        self.toCurrency = to
        // Reset fetch flag when currencies change so we fetch new data
        self.hasFetchedForCurrentPair = false
    }
}

// MARK: - View
struct CurrencyChartView: View {
    @State private var fromCurrencyName: String = "British Pound"
    @State private var fromFlagEmoji: String = "🇬🇧"
    @State private var fromCurrencyCode: String
    @State private var toCurrencyName: String = "Euro"
    @State private var toFlagEmoji: String = "🇪🇺"
    @State private var toCurrencyCode: String
    @State private var showFromSelector: Bool = false
    @State private var showToSelector: Bool = false
    @State private var selectedRange: TimeRange = .oneMonth // Always .oneMonth, no UI for changing
    @State private var selectedRate: ExchangeRate? = nil
    @StateObject private var viewModel: CurrencyChartViewModel
    @GestureState private var isSwapPressed: Bool = false
    
    init(fromCurrency: String, toCurrency: String) {
        print("🔄 CurrencyChartView init: \(fromCurrency) → \(toCurrency)")
        self._fromCurrencyCode = State(initialValue: fromCurrency)
        self._toCurrencyCode = State(initialValue: toCurrency)
        self._viewModel = StateObject(wrappedValue: CurrencyChartViewModel(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency
        ))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                rateInfoView
                chartView
                    .padding(.top, 16)
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
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
        .task {
            print("📊 .task triggered for chart")
            await viewModel.fetchRates(for: selectedRange)
        }
        .onChange(of: fromCurrencyCode) { oldValue, newValue in
            print("📊 fromCurrencyCode changed: \(oldValue) → \(newValue)")
            viewModel.updateCurrencies(from: newValue, to: toCurrencyCode)
            Task {
                await viewModel.fetchRates(for: selectedRange)
            }
        }
        .onChange(of: toCurrencyCode) { oldValue, newValue in
            print("📊 toCurrencyCode changed: \(oldValue) → \(newValue)")
            viewModel.updateCurrencies(from: fromCurrencyCode, to: newValue)
            Task {
                await viewModel.fetchRates(for: selectedRange)
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
    
    private func swapCurrencies() {
        let tempName = fromCurrencyName
        let tempFlag = fromFlagEmoji
        let tempCode = fromCurrencyCode
        fromCurrencyName = toCurrencyName
        fromFlagEmoji = toFlagEmoji
        fromCurrencyCode = toCurrencyCode
        toCurrencyName = tempName
        toFlagEmoji = tempFlag
        toCurrencyCode = tempCode
    }
    
    private var chartView: some View {
        CurrencyLineChart(
            rates: viewModel.rates,
            startDate: viewModel.startDate,
            endDate: viewModel.endDate,
            selectedRate: $selectedRate,
            highRate: viewModel.highRate,
            medianRate: viewModel.medianRate,
            lowRate: viewModel.lowRate
        )
    }
    
    private var loadingView: some View {
        ProgressView()
            .frame(height: 132)
            .frame(maxWidth: .infinity)
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(Color("primary100").opacity(0.6))
            
            Text("Unable to load chart data")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Button(action: {
                Task { await viewModel.fetchRates(for: selectedRange) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Retry")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color("primary500").opacity(0.6))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retry loading chart")
        }
        .frame(height: 132)
        .frame(maxWidth: .infinity)
    }
    
    
    private var rateInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Rate text with styled date
            HStack(spacing: 0) {
                Text(rateMainText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("grey100"))
                
                Text(rateDateText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
            }
            .id(selectedRate?.id) // Force re-render when selection changes
            
            // Daily change indicator
            if let changeText = dailyChangeText {
                HStack(spacing: 4) {
                    // SF Symbol arrow icon
                    Image(systemName: dailyChangeIcon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(dailyChangeColor)
                    
                    Text(changeText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(dailyChangeColor)
                }
            }
        }
        .padding(0)
        .frame(width: 289, alignment: .topLeading)
    }
    
    private func formatRateDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // Rate insight view
    private var rateInsightView: some View {
        HStack(spacing: 8) {
            Image(systemName: rateInsightIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(rateInsightColor)
            
            Text(rateInsightText)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Glass effect as base layer
                RoundedRectangle(cornerRadius: 8)
                    .glassEffect(in: .rect(cornerRadius: 8))
                
                // Dark purple overlay to reduce grey appearance
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 20/255, green: 8/255, blue: 58/255).opacity(0.75))
            }
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            // Subtle highlight for glassy elevation effect
            RoundedRectangle(cornerRadius: 8)
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Split rate text for styling
    private var rateMainText: String {
        if let selected = selectedRate {
            return "1 \(fromCurrencyCode) = \(String(format: "%.3f", selected.rate)) \(toCurrencyCode) · "
        } else {
            return "1 \(fromCurrencyCode) = \(String(format: "%.3f", viewModel.currentRate)) \(toCurrencyCode) · "
        }
    }
    
    private var rateDateText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE MMM d" // e.g., "Sun Dec 20"
        
        if let selected = selectedRate {
            return dateFormatter.string(from: selected.date)
        } else {
            // Show the last date in the chart (yesterday, since today is excluded)
            if let lastDate = viewModel.rates.last?.date {
                return dateFormatter.string(from: lastDate)
            }
            // Fallback to yesterday if no data
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return dateFormatter.string(from: yesterday)
        }
    }
    
    // Get flag emoji for currency code
    private func getFlag(for currencyCode: String) -> String {
        // Use the same currency data as the main app
        if let currency = Currency.mockData.first(where: { $0.code == currencyCode }) {
            return currency.flag
        }
        return "🏳️" // Default flag if not found
    }
    
    // Threshold for considering change as "essentially zero" (0.01% = negligible)
    private let negligibleChangeThreshold: Double = 0.01
    
    // Dynamic daily change calculation based on selected or current rate
    private var dailyChangeText: String? {
        guard viewModel.rates.count >= 2 else { return nil }
        
        let (currentRate, previousRate) = getDailyChangeRates()
        
        guard currentRate > 0 && previousRate > 0 else { return nil }
        
        let change = currentRate - previousRate
        let percentageChange = (change / previousRate) * 100
        
        // Check if change is negligible (essentially zero)
        if abs(percentageChange) < negligibleChangeThreshold {
            return "0.00% Past day"
        }
        
        let sign = change > 0 ? "+" : ""
        
        return "\(sign)\(String(format: "%.2f", percentageChange))% Past day"
    }
    
    // Get the appropriate SF Symbol arrow
    private var dailyChangeIcon: String {
        guard viewModel.rates.count >= 2 else { return "equal" }
        
        let (currentRate, previousRate) = getDailyChangeRates()
        
        guard currentRate > 0 && previousRate > 0 else { return "equal" }
        
        let change = currentRate - previousRate
        let percentageChange = (change / previousRate) * 100
        
        // Check if change is negligible (essentially zero)
        if abs(percentageChange) < negligibleChangeThreshold {
            return "equal" // Neutral equal sign for no change
        }
        
        if change > 0 {
            return "arrow.up.right" // Angled up arrow
        } else {
            return "arrow.down.right" // Angled down arrow
        }
    }
    
    private var dailyChangeColor: Color {
        guard viewModel.rates.count >= 2 else { return Color(red: 0.6, green: 0.6, blue: 0.7) }
        
        let (currentRate, previousRate) = getDailyChangeRates()
        
        guard currentRate > 0 && previousRate > 0 else { return Color(red: 0.6, green: 0.6, blue: 0.7) }
        
        let change = currentRate - previousRate
        let percentageChange = (change / previousRate) * 100
        
        // Check if change is negligible (essentially zero)
        if abs(percentageChange) < negligibleChangeThreshold {
            return Color(red: 0.6, green: 0.6, blue: 0.7) // Accessible neutral blue-grey
        }
        
        if change > 0 {
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Accessible green
        } else {
            return Color(red: 0.9, green: 0.3, blue: 0.3) // Accessible red
        }
    }
    
    // Helper to get the current and previous rates based on selection
    private func getDailyChangeRates() -> (current: Double, previous: Double) {
        guard viewModel.rates.count >= 2 else { return (0, 0) }
        
        if let selected = selectedRate {
            // Find the index of the selected rate
            if let selectedIndex = viewModel.rates.firstIndex(where: { $0.id == selected.id }) {
                let currentRate = selected.rate
                
                // Get the previous day's rate (one index before)
                if selectedIndex > 0 {
                    let previousRate = viewModel.rates[selectedIndex - 1].rate
                    return (currentRate, previousRate)
                } else {
                    // If it's the first day, compare with itself (no change)
                    return (currentRate, currentRate)
                }
            }
        }
        
        // Default to today vs yesterday
        let todayRate = viewModel.rates.last?.rate ?? 0
        let yesterdayRate = viewModel.rates[viewModel.rates.count - 2].rate
        return (todayRate, yesterdayRate)
    }
    
    // Intelligent rate analysis
    private var rateInsightText: String {
        guard viewModel.rates.count >= 7 else { return "Analyzing rate trends..." }
        
        let currentRate = viewModel.currentRate
        let highRate = viewModel.highRate
        let lowRate = viewModel.lowRate
        let rates = viewModel.rates.map(\.rate)
        
        // Calculate percentile position (0-100)
        let rateRange = highRate - lowRate
        let currentPosition = ((currentRate - lowRate) / rateRange) * 100
        
        // Calculate recent trend (last 7 days)
        let recentRates = Array(rates.suffix(7))
        let weekAgoRate = recentRates.first ?? currentRate
        let weekTrend = ((currentRate - weekAgoRate) / weekAgoRate) * 100
        
        // Calculate volatility
        let avgRate = rates.reduce(0, +) / Double(rates.count)
        let variance = rates.map { pow($0 - avgRate, 2) }.reduce(0, +) / Double(rates.count)
        let volatility = sqrt(variance) / avgRate * 100
        
        // Generate insights based on analysis
        switch currentPosition {
        case 80...100:
            if weekTrend > 2 {
                return "Excellent rate! Near 30-day high and trending up. Great time to exchange."
            } else if weekTrend < -2 {
                return "Good rate but declining. Consider exchanging soon before further drops."
            } else {
                return "Excellent rate! You're getting near the best rate of the month."
            }
            
        case 60...79:
            if weekTrend > 1 {
                return "Good rate and improving. Rates are trending upward this week."
            } else if volatility > 3 {
                return "Good rate but volatile. Consider exchanging if you need certainty."
            } else {
                return "Good rate. Above average for the month - reasonable time to exchange."
            }
            
        case 40...59:
            if weekTrend > 2 {
                return "Average rate but improving fast. Might be worth waiting a few days."
            } else if weekTrend < -2 {
                return "Average rate and declining. Consider exchanging to avoid further drops."
            } else {
                return "Average rate. Consider waiting for better rates or exchange if urgent."
            }
            
        case 20...39:
            if weekTrend > 1 {
                return "Below average but recovering. Rates are improving - consider waiting."
            } else if volatility > 4 {
                return "Below average rate in volatile market. Wait for better rates if possible."
            } else {
                return "Below average rate. Consider waiting for improvement unless urgent."
            }
            
        case 0...19:
            if weekTrend > 0 {
                return "Poor rate but showing signs of recovery. Wait if you can."
            } else {
                return "Poor rate near 30-day low. Only exchange if absolutely necessary."
            }
            
        default:
            return "Rate analysis available with more data."
        }
    }
    
    private var rateInsightIcon: String {
        guard viewModel.rates.count >= 7 else { return "chart.line.uptrend.xyaxis" }
        
        let currentRate = viewModel.currentRate
        let highRate = viewModel.highRate
        let lowRate = viewModel.lowRate
        let currentPosition = ((currentRate - lowRate) / (highRate - lowRate)) * 100
        
        switch currentPosition {
        case 80...100:
            return "star.fill" // Excellent
        case 60...79:
            return "checkmark.circle.fill" // Good
        case 40...59:
            return "minus.circle.fill" // Average
        case 20...39:
            return "exclamationmark.triangle.fill" // Below average
        case 0...19:
            return "xmark.circle.fill" // Poor
        default:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    private var rateInsightColor: Color {
        guard viewModel.rates.count >= 7 else { return Color("grey100") }
        
        let currentRate = viewModel.currentRate
        let highRate = viewModel.highRate
        let lowRate = viewModel.lowRate
        let currentPosition = ((currentRate - lowRate) / (highRate - lowRate)) * 100
        
        switch currentPosition {
        case 80...100:
            return Color(red: 0.2, green: 0.8, blue: 0.4) // Green - Excellent
        case 60...79:
            return Color(red: 0.4, green: 0.7, blue: 0.9) // Blue - Good
        case 40...59:
            return Color(red: 0.9, green: 0.7, blue: 0.3) // Yellow - Average
        case 20...39:
            return Color(red: 0.9, green: 0.5, blue: 0.2) // Orange - Below average
        case 0...19:
            return Color(red: 0.9, green: 0.3, blue: 0.3) // Red - Poor
        default:
            return Color("grey100")
        }
    }
}

// MARK: - Supporting Views
struct CurrencyLineChart: View {
    let rates: [ExchangeRate]
    let startDate: String
    let endDate: String
    @Binding var selectedRate: ExchangeRate?
    let highRate: Double
    let medianRate: Double
    let lowRate: Double
    
    private var minRate: Double {
        lowRate
    }
    
    private var maxRate: Double {
        highRate
    }
    
    private var rateRange: Double {
        maxRate - minRate
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    private func formatTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(spacing: 12) {
        ZStack {
            Chart(rates) { rate in
                // Area fill
                AreaMark(
                    x: .value("Date", rate.date),
                    yStart: .value("Low", lowRate),
                    yEnd: .value("Rate", rate.rate)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Constants.purple600.opacity(0.3),
                            Constants.purple600.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // Line
                LineMark(
                    x: .value("Date", rate.date),
                    y: .value("Rate", rate.rate)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Constants.purple600)
                .lineStyle(StrokeStyle(lineWidth: 2))
                // Selected point indicator (show for selectedRate or latest value)
                let showDot = (selectedRate?.id ?? rates.last?.id) == rate.id
                if showDot {
                    PointMark(
                        x: .value("Date", rate.date),
                        y: .value("Rate", rate.rate)
                    )
                    .symbol {
                        ZStack {
                            // Halo
                            Circle()
                                .fill(Constants.purple600.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            // Dot
                            Circle()
                                .fill(Constants.purple600)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .chartYScale(domain: lowRate...highRate)
            .chartYAxis {
                AxisMarks(position: .trailing, values: [lowRate, medianRate, highRate]) { value in
                    AxisGridLine()
                        .foregroundStyle(Color("grey600").opacity(0.3))
                    AxisValueLabel() {
                        if let rate = value.as(Double.self) {
                                Text(String(format: "%.3f", rate))
                                    .foregroundStyle(Color("grey100"))
                                    .font(.system(size: 12))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [rates.first?.date, rates.last?.date].compactMap { $0 }) { value in
                    AxisGridLine()
                        .foregroundStyle(Color("grey600").opacity(0.3))
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let x = value.location.x - geometry[plotFrame].origin.x
                                    guard x >= 0, x <= geometry[plotFrame].width else { return }
                                    // Convert x to date
                                    if let date = proxy.value(atX: x, as: Date.self) {
                                        // Find the closest rate
                                        if let closest = rates.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                            selectedRate = closest
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    // Reset to latest value
                                    selectedRate = nil
                                }
                        )
                }
            }
            .frame(height: 180)
            .background(Color.clear)
            .chartPlotStyle { plotArea in
                plotArea.background(Color.clear)
            }
            }
            
            // Date label below chart
            HStack {
                Text("A month ago")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exchange rate chart showing historical rates. High: \(String(format: "%.3f", highRate)), Median: \(String(format: "%.3f", medianRate)), Low: \(String(format: "%.3f", lowRate))")
        .accessibilityHint("Drag horizontally to explore rates on different dates")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types
enum TimeRange: Int, CaseIterable, Identifiable {
    case oneWeek
    case oneMonth
    case threeMonths
    case sixMonths
    
    var id: Int { rawValue }
    
    var displayText: String {
        switch self {
        case .oneWeek: return "1w"
        case .oneMonth: return "1m"
        case .threeMonths: return "3m"
        case .sixMonths: return "6m"
        }
    }
    
    var days: Int {
        switch self {
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        }
    }
}

// MARK: - Constants
struct Constants {
    static let colourGrey100: Color = .white
    static let grey400: Color = Color(red: 0.84, green: 0.83, blue: 0.87)
    static let purple400: Color = Color(red: 0.42, green: 0.39, blue: 0.88)
    static let purple600: Color = Color(red: 0.31, green: 0.19, blue: 0.65)
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    CurrencyChartView(fromCurrency: "GBP", toCurrency: "EUR")
        .preferredColorScheme(.dark)
        .frame(width: 375, height: 200)
        .padding()
        .background(Color("grey800"))
}

// Custom button style for swap button
struct SwapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.75 : 1.0)
            .opacity(configuration.isPressed ? 0.5 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
} 