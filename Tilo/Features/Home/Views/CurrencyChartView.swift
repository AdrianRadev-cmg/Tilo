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
        
        // Reduced delay to 100ms
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Optimized mock data generation
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -range.days, to: endDate)!
        
        // Generate fewer data points for better performance
        let numberOfPoints = min(range.days, 30) // Max 30 points
        let step = range.days / numberOfPoints
        
        rates = (0..<numberOfPoints).map { i in
            let day = i * step
            let date = calendar.date(byAdding: .day, value: day, to: startDate)!
            // Smoother rate changes
            let rate = 1.15 + sin(Double(i) / Double(numberOfPoints) * .pi) * 0.05
            return ExchangeRate(date: date, rate: rate)
        }
        
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
}

// MARK: - View
struct CurrencyChartView: View {
    let fromCurrency: String
    let toCurrency: String
    
    @StateObject private var viewModel: CurrencyChartViewModel
    @State private var selectedRange: TimeRange = .oneMonth
    
    init(fromCurrency: String, toCurrency: String) {
        self.fromCurrency = fromCurrency
        self.toCurrency = toCurrency
        self._viewModel = StateObject(wrappedValue: CurrencyChartViewModel(
            fromCurrency: fromCurrency,
            toCurrency: toCurrency
        ))
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                rangePicker
                
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error)
                } else {
                    chartView
                }
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .cornerRadius(8)
            
            rateInfoView
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .frame(width: 358, alignment: .center)
        .background(Color("grey700"))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.5)
                .stroke(Constants.grey400, lineWidth: 1)
        )
        .task {
            await viewModel.fetchRates(for: selectedRange)
        }
        .onChange(of: selectedRange) { newRange in
            Task {
                await viewModel.fetchRates(for: newRange)
            }
        }
    }
    
    private var rangePicker: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(TimeRange.allCases) { range in
                Text(range.displayText).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 0)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }
    
    private var chartView: some View {
        CurrencyLineChart(
            rates: viewModel.rates,
            startDate: viewModel.startDate,
            endDate: viewModel.endDate
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
            Text("\(fromCurrency) = \(String(format: "%.4f", viewModel.currentRate)) \(toCurrency) today")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color("grey100"))
            Text("Last updated just now")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Color("grey100").opacity(0.7))
        }
        .padding(0)
        .frame(width: 289, alignment: .topLeading)
    }
}

// MARK: - Supporting Views
struct CurrencyLineChart: View {
    let rates: [ExchangeRate]
    let startDate: String
    let endDate: String

    var body: some View {
        Chart(rates) { rate in
            LineMark(
                x: .value("Date", rate.date),
                y: .value("Rate", rate.rate)
            )
            .interpolationMethod(.linear)
            .foregroundStyle(Constants.purple600)
            .lineStyle(StrokeStyle(lineWidth: 2))
            
            if rate.id == rates.last?.id {
                PointMark(
                    x: .value("Date", rate.date),
                    y: .value("Rate", rate.rate)
                )
                .symbolSize(60)
                .foregroundStyle(Constants.purple400)
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                    .foregroundStyle(Color("grey600"))
                AxisValueLabel {
                    Text(value.as(Double.self)?.formatted() ?? "")
                        .foregroundStyle(Color("grey100"))
                        .font(.system(size: 14))
                        .padding(.leading, 4)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: [rates.first?.date, rates.last?.date].compactMap { $0 }) { value in
                AxisValueLabel {
                    Text(value.as(Date.self).map { formatDate($0) } ?? "")
                        .foregroundColor(Color("grey100"))
                        .font(.system(size: 12))
                }
            }
        }
        .frame(height: 132)
        .background(Color.clear)
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