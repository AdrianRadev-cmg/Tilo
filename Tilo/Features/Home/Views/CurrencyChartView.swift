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
    
    init(fromCurrency: String, toCurrency: String) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
    }
    
    func fetchRates(for range: TimeRange = .oneWeek) async {
        isLoading = true
        error = nil
        
        print("📊 ViewModel fetchRates: \(fromCurrency) → \(toCurrency)")
        
        // Fetch historical data from ExchangeRateService (30 days)
        if let historicalData = await exchangeService.fetchHistoricalRates(from: fromCurrency, to: toCurrency, days: 30) {
            print("📊 Received \(historicalData.count) historical data points")
            // Convert to ExchangeRate format
            var ratesArray = historicalData.map { histRate in
                ExchangeRate(date: histRate.date, rate: histRate.rate)
            }
            
            // Ensure today's rate matches the live rate from main cards
            if let liveRate = await exchangeService.getRate(from: fromCurrency, to: toCurrency) {
                // Update the last (today's) rate with the live rate
                if let lastIndex = ratesArray.indices.last {
                    ratesArray[lastIndex] = ExchangeRate(date: ratesArray[lastIndex].date, rate: liveRate)
                }
            }
            
            rates = ratesArray
            print("📊 Chart rates updated: \(rates.count) points")
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
        let sorted = rates.map(\.rate).sorted()
        guard !sorted.isEmpty else { return 0.0 }
        let mid = sorted.count / 2
        if sorted.count % 2 == 0 {
            return (sorted[mid - 1] + sorted[mid]) / 2.0
        } else {
            return sorted[mid]
        }
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
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(error.localizedDescription)
                .foregroundColor(Color("grey100"))
                .multilineTextAlignment(.center)
        }
        .frame(height: 132)
        .frame(maxWidth: .infinity)
    }
    
    private var rateInfoView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(rateInfoText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("grey100"))
        }
        .padding(0)
        .frame(width: 289, alignment: .topLeading)
    }
    
    private var rateInfoText: String {
        if let selected = selectedRate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dateString = dateFormatter.string(from: selected.date)
            return "1 \(fromCurrencyCode) = \(String(format: "%.4f", selected.rate)) \(toCurrencyCode) · \(dateString)"
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            let dateString = dateFormatter.string(from: Date())
            return "1 \(fromCurrencyCode) = \(String(format: "%.4f", viewModel.currentRate)) \(toCurrencyCode) · \(dateString)"
        }
    }
    
    private func formatRateDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
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
        VStack(spacing: 8) {
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
                            Text(String(format: "%.4f", rate))
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
                                    let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                    guard x >= 0, x <= geometry[proxy.plotAreaFrame].width else { return }
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
            
            // Date labels below chart
            HStack {
                Text("A month ago")
                    .foregroundColor(Color("grey100"))
                    .font(.system(size: 12))
                
                Spacer()
                
                Text(formatTodayDate())
                    .foregroundColor(Color("grey100"))
                    .font(.system(size: 12))
            }
            .padding(.leading, 16)
            .padding(.trailing, 60)
        }
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
#Preview {
    CurrencyChartView(fromCurrency: "GBP", toCurrency: "EUR")
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .previewLayout(.sizeThatFits)
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