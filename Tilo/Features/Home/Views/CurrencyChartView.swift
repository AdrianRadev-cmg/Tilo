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
    
    private let fromCurrency: String
    private let toCurrency: String
    
    init(fromCurrency: String, toCurrency: String) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
    }
    
    func fetchRates(for range: TimeRange) async {
        isLoading = true
        error = nil
        try? await Task.sleep(nanoseconds: 100_000_000)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -range.days, to: endDate)!
        let numberOfPoints = min(range.days, 30)
        let step = range.days / numberOfPoints
        // Simulate a more dynamic random walk for currency rates
        var ratesArray: [ExchangeRate] = []
        var lastRate = 1.15 + Double.random(in: -0.05...0.05)
        for i in 0..<numberOfPoints {
            let day = i * step
            let date = calendar.date(byAdding: .day, value: day, to: startDate)!
            // Add sinusoidal trend and random spikes
            let trend = sin(Double(i) / Double(numberOfPoints) * 2 * .pi) * 0.08
            let spike = Double.random(in: -0.03...0.03)
            let change = Double.random(in: -0.02...0.02) + trend + spike
            lastRate = max(0.8, min(1.6, lastRate + change))
            ratesArray.append(ExchangeRate(date: date, rate: lastRate))
        }
        rates = ratesArray
        isLoading = false
    }
    
    var currentRate: Double {
        rates.last?.rate ?? 0.0
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
        // This is a placeholder for future real API integration
        // For now, just update the properties if needed
        // (You may need to refactor the ViewModel to support this in the future)
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
                // Currency selector chips row
                HStack(spacing: 8) {
                    CurrencySelectorChip(
                        flagEmoji: fromFlagEmoji,
                        currencyCode: fromCurrencyCode,
                        action: { showFromSelector = true }
                    )
                    .frame(maxWidth: .infinity)
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.prepare()
                        swapCurrencies()
                        generator.impactOccurred()
                    }) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(SwapButtonStyle())
                    .accessibilityLabel("Swap currencies")
                    CurrencySelectorChip(
                        flagEmoji: toFlagEmoji,
                        currencyCode: toCurrencyCode,
                        action: { showToSelector = true }
                    )
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                // Move rateInfoView here, directly below chips
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
        .background(Color("grey700").opacity(0.2))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .stroke(Color("grey400").opacity(0.1), lineWidth: 1)
        )
        .task {
            await viewModel.fetchRates(for: selectedRange)
        }
        .onChange(of: fromCurrencyCode) { newCode in
            viewModel.updateCurrencies(from: newCode, to: toCurrencyCode)
            Task {
                await viewModel.fetchRates(for: selectedRange)
            }
        }
        .onChange(of: toCurrencyCode) { newCode in
            viewModel.updateCurrencies(from: fromCurrencyCode, to: newCode)
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
            selectedRate: $selectedRate
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
            let dateString = formatRateDate(selected.date)
            return "\(fromCurrencyCode) = \(String(format: "%.4f", selected.rate)) \(toCurrencyCode) \(dateString)"
        } else {
            return "\(fromCurrencyCode) = \(String(format: "%.4f", viewModel.currentRate)) \(toCurrencyCode) Today"
        }
    }
    
    private func formatRateDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct CurrencyLineChart: View {
    let rates: [ExchangeRate]
    let startDate: String
    let endDate: String
    @Binding var selectedRate: ExchangeRate?
    
    private var minRate: Double {
        rates.map(\.rate).min() ?? 0
    }
    
    private var maxRate: Double {
        rates.map(\.rate).max() ?? 0
    }
    
    private var rateRange: Double {
        maxRate - minRate
    }

    var body: some View {
        ZStack {
            Chart(rates) { rate in
                // Area fill
                AreaMark(
                    x: .value("Date", rate.date),
                    y: .value("Rate", rate.rate)
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
            .chartYAxis {
                AxisMarks() { value in
                    AxisGridLine()
                        .foregroundStyle(Color("grey600").opacity(0.3))
                    AxisValueLabel() {
                        if let rate = value.as(Double.self) {
                            let index = value.index
                            if [0, 2, 4].contains(index) {
                                Text(String(format: "%.4f", rate))
                                    .foregroundStyle(Color("grey100"))
                                    .font(.system(size: 12))
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: [rates.first?.date, rates.last?.date].compactMap { $0 }) { value in
                    AxisGridLine()
                        .foregroundStyle(Color("grey600").opacity(0.3))
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            if date == rates.first?.date {
                                Text("A month ago")
                                    .foregroundColor(Color("grey100"))
                                    .font(.system(size: 12))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else if date == rates.last?.date {
                                Text("Today")
                                    .foregroundColor(Color("grey100"))
                                    .font(.system(size: 12))
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
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
            .frame(height: 164)
            .background(Color.clear)
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