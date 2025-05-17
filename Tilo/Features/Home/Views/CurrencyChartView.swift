import SwiftUI
import Charts

struct CurrencyChartView: View {
    let fromCurrency: String
    let toCurrency: String
    
    @State private var selectedRange: Int = 1 // 0: 1w, 1: 1m, 2: 3m, 3: 6m
    @State private var lastUpdated: Date = Date()
    
    // Dummy data for each range
    let rates1w: [Double] = [1.16, 1.15, 1.17, 1.18, 1.16, 1.15, 1.16]
    let rates1m: [Double] = [1.12, 1.13, 1.15, 1.14, 1.16, 1.18, 1.17, 1.19, 1.22, 1.18, 1.16, 1.15, 1.13, 1.12, 1.14, 1.16, 1.15, 1.13, 1.12, 1.16, 1.15, 1.14, 1.13, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.16]
    let rates3m: [Double] = (0..<90).map { i in 1.12 + 0.1 * sin(Double(i)/10) }
    let rates6m: [Double] = (0..<180).map { i in 1.10 + 0.12 * sin(Double(i)/18) }
    
    var selectedRates: [Double] {
        switch selectedRange {
        case 0: return rates1w
        case 1: return rates1m
        case 2: return rates3m
        case 3: return rates6m
        default: return rates1m
        }
    }
    
    var minValue: Double { selectedRates.min() ?? 1.0 }
    var maxValue: Double { selectedRates.max() ?? 1.0 }
    var currentValue: Double { selectedRates.last ?? 1.0 }
    var startDate: String {
        switch selectedRange {
        case 0: return "1w ago"
        case 1: return "Mar 6"
        case 2: return "3m ago"
        case 3: return "6m ago"
        default: return "Start"
        }
    }
    var endDate: String { "Today" }
    
    var chartData: [(Int, Double)] {
        Array(selectedRates.enumerated())
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Range", selection: $selectedRange) {
                    Text("1w").tag(0)
                    Text("1m").tag(1)
                    Text("3m").tag(2)
                    Text("6m").tag(3)
                }
                .pickerStyle(.segmented)
                .padding(.top, 0)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity)
                
                CurrencyLineChart(
                    chartData: chartData,
                    selectedRatesCount: selectedRates.count,
                    startDate: startDate,
                    endDate: endDate
                )
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 24) {
                Text("\(fromCurrency) = \(String(format: "%.4f", currentValue)) \(toCurrency) today")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("grey100"))
                Text("Last updated \(relativeDateString(from: lastUpdated))")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("grey100").opacity(0.7))
            }
            .padding(0)
            .frame(width: 289, alignment: .topLeading)
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
    }
    
    func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CurrencyLineChart: View {
    let chartData: [(Int, Double)]
    let selectedRatesCount: Int
    let startDate: String
    let endDate: String

    var body: some View {
        Chart {
            ForEach(chartData, id: \.0) { idx, value in
                LineMark(
                    x: .value("Index", idx),
                    y: .value("Rate", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Constants.purple600)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                if idx == selectedRatesCount - 1 {
                    PointMark(
                        x: .value("Index", idx),
                        y: .value("Rate", value)
                    )
                    .symbolSize(80)
                    .foregroundStyle(Constants.purple400)
                    .annotation(position: .overlay) {
                        Circle()
                            .fill(Constants.purple400.opacity(0.25))
                            .frame(width: 22, height: 22)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [4]))
                    .foregroundStyle(Color("grey600"))
                AxisValueLabel {
                    Text(value.as(Double.self)?.formatted() ?? "")
                        .foregroundStyle(Color("grey100"))
                        .font(.system(size: 16, weight: .regular))
                        .padding(.leading, 4)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, selectedRatesCount - 1]) { value in
                AxisValueLabel() {
                    Text(value.index == 0 ? startDate : endDate)
                        .foregroundColor(Color("grey100"))
                        .font(.system(size: 14, weight: .regular))
                }
            }
        }
        .frame(height: 132)
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .background(Color.clear)
    }
}

struct Constants {
    static let colourGrey100: Color = .white
    static let grey400: Color = Color(red: 0.84, green: 0.83, blue: 0.87)
    static let purple400: Color = Color(red: 0.42, green: 0.39, blue: 0.88)
    static let purple600: Color = Color(red: 0.31, green: 0.19, blue: 0.65)
}

#Preview {
    CurrencyChartView(fromCurrency: "GBP", toCurrency: "EUR")
} 