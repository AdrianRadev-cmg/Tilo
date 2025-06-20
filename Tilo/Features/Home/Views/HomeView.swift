//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI
import Charts

// PreferenceKey for measuring purple section height
private struct PurpleSectionHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct StatusBarGradient: View {
    let gradientStops: [Gradient.Stop]
    
    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                gradient: Gradient(stops: gradientStops),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .overlay(Color.black.opacity(0.20))
            .frame(height: geometry.safeAreaInsets.top)
            .edgesIgnoringSafeArea(.top)
        }
    }
}

struct CustomTabBar: View {
    var body: some View {
        HStack(spacing: 0) {
            ForEach(["Home", "Activity", "Profile"], id: \.self) { tab in
                VStack(spacing: 4) {
                    Image(systemName: iconName(for: tab))
                        .font(.system(size: 24))
                    Text(tab)
                        .font(.caption)
                }
                .foregroundColor(tab == "Home" ? Color("primary600") : .gray)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            Color("grey200")
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.2)),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    private func iconName(for tab: String) -> String {
        switch tab {
        case "Home": return "house.fill"
        case "Activity": return "chart.line.uptrend.xyaxis"
        case "Profile": return "person.fill"
        default: return ""
        }
    }
}

@available(iOS 16.0, *)
struct HomeView: View {
    @State private var selectedTab = 0
    @State private var topCardAmountString: String = "50.00"
    @State private var selectedQuickAmount: Double?
    
    // Add state for currency data
    @State private var fromCurrencyName = "British Pound"
    @State private var fromFlagEmoji = "🇬🇧"
    @State private var fromCurrencyCode = "GBP"
    
    @State private var toCurrencyName = "Euro"
    @State private var toFlagEmoji = "🇪🇺"
    @State private var toCurrencyCode = "EUR"
    
    private let gradientStops = [
        Gradient.Stop(color: Color(red: 0.18, green: 0.09, blue: 0.38), location: 0.00),
        Gradient.Stop(color: Color(red: 0.21, green: 0.10, blue: 0.42), location: 0.06),
        Gradient.Stop(color: Color(red: 0.24, green: 0.11, blue: 0.48), location: 0.09),
        Gradient.Stop(color: Color(red: 0.13, green: 0.05, blue: 0.26), location: 0.38),
        Gradient.Stop(color: Color(red: 0.06, green: 0.02, blue: 0.12), location: 1.00)
    ]
    
    private func formatAmount(_ string: String) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        if let number = Decimal(string: string.replacingOccurrences(of: formatter.groupingSeparator, with: "")) {
            return formatter.string(from: number as NSDecimalNumber)
        }
        return nil
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            ZStack(alignment: .top) {
                // Base purple gradient that extends into top safe area
                LinearGradient(
                    gradient: Gradient(stops: gradientStops),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .overlay(Color.black.opacity(0.30))
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Purple section with currency cards and quick conversions
                        VStack(alignment: .leading, spacing: 8) {
                            CurrencyCard(
                                currencyName: $fromCurrencyName,
                                flagEmoji: $fromFlagEmoji,
                                currencyCode: $fromCurrencyCode,
                                amount: topCardAmountString,
                                exchangeRateInfo: "1 \(fromCurrencyCode) = 1.1700 \(toCurrencyCode)"
                            )
                            .padding(.horizontal, 16)
                            .overlay(alignment: .bottom) {
                                SwapButton()
                                    .zIndex(1)
                                    .offset(y: 22)
                            }
                            
                            CurrencyCard(
                                currencyName: $toCurrencyName,
                                flagEmoji: $toFlagEmoji,
                                currencyCode: $toCurrencyCode,
                                amount: "58.50",
                                exchangeRateInfo: "1 \(toCurrencyCode) = 0.8547 \(fromCurrencyCode)"
                            )
                            .padding(.horizontal, 16)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Quick conversions")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                
                                FlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                                    ForEach([1000, 2000, 5000, 10000, 20000], id: \.self) { amount in
                                        QuickAmountChip(
                                            symbol: fromCurrencyCode == "GBP" ? "£" : fromCurrencyCode == "EUR" ? "€" : "$",
                                            amount: amount,
                                            selectedAmount: $selectedQuickAmount,
                                            onSelect: { selectedAmount in
                                                topCardAmountString = String(format: "%.2f", selectedAmount)
                                            }
                                        )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding(.top, 40)
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 40)
                        
                        // Bottom grey section
                        VStack(spacing: 24) {
                            CurrencyChartView(fromCurrency: fromCurrencyCode, toCurrency: toCurrencyCode)
                            // Recent Transactions Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Transactions")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey100"))
                                
                                ForEach(1...5, id: \.self) { index in
                                    HStack {
                                        Circle()
                                            .fill(Color("primary600").opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        VStack(alignment: .leading) {
                                            Text("Transaction \(index)")
                                                .fontWeight(.medium)
                                                .foregroundColor(Color("grey100"))
                                            Text("April \(index + 10), 2024")
                                                .font(.subheadline)
                                                .foregroundColor(Color("grey300"))
                                        }
                                        
                                        Spacer()
                                        
                                        Text("£\(Double(index) * 10.50, specifier: "%.2f")")
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color("grey100"))
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Quick Actions Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Quick Actions")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey100"))
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(["Send", "Request", "Split", "History", "Cards", "More"], id: \.self) { action in
                                        VStack {
                                            Circle()
                                                .fill(Color("primary600").opacity(0.15))
                                                .frame(width: 50, height: 50)
                                            Text(action)
                                                .font(.subheadline)
                                                .foregroundColor(Color("grey100"))
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Spending Insights Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Spending Insights")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey100"))
                                
                                VStack(spacing: 12) {
                                    ForEach(["Food & Drinks", "Shopping", "Transport", "Bills"], id: \.self) { category in
                                        HStack {
                                            Text(category)
                                                .foregroundColor(Color("grey100"))
                                            Spacer()
                                            Text("£\(Int.random(in: 50...200))")
                                                .fontWeight(.medium)
                                                .foregroundColor(Color("grey100"))
                                        }
                                        .padding()
                                        .background(Color("primary600").opacity(0.08))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Settings & Preferences
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Settings & Preferences")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey100"))
                                
                                ForEach(["Account Settings", "Notifications", "Privacy", "Help & Support"], id: \.self) { setting in
                                    HStack {
                                        Text(setting)
                                            .foregroundColor(Color("grey100"))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(Color("grey300"))
                                    }
                                    .padding()
                                    .background(Color("primary600").opacity(0.08))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 16)
                        .background(
                            Color("grey800")
                        )
                    }
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Activity Tab (placeholder)
            Text("Activity")
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Activity")
                }
                .tag(1)
            
            // Profile Tab (placeholder)
            Text("Profile")
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .tint(Color("primary100")) // Use a lighter purple for tab bar elements
        #if os(iOS)
        .toolbarBackground(Color("grey800"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar(.visible, for: .tabBar)
        #endif
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("Home View")
        .previewLayout(.sizeThatFits)
        .previewInterfaceOrientation(.portrait)
}

// Add preference key for height measurement
private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

enum ExchangeRateRange: String, CaseIterable, Identifiable {
    case sevenDays = "7d"
    case oneMonth = "1m"
    case threeMonths = "3m"
    case sixMonths = "6m"
    var id: String { rawValue }
}

struct ExchangeRateInsightsCard: View {
    let isPro: Bool
    @State private var expanded = true
    @State private var selectedRange: ExchangeRateRange = .sevenDays
    
    // Dummy data
    let minValue: Double = 1.10
    let maxValue: Double = 1.22
    let typicalLow: Double = 1.15
    let typicalHigh: Double = 1.18
    let today: Double = 1.16
    let todayLabel: String = "1.16 is typical"
    let summary: String = "The best rates for similar conversions in the last 60 days ranged from 1.10–1.22."
    let history7d: [Double] = [1.16, 1.15, 1.17, 1.18, 1.16, 1.15, 1.16]
    let history1m: [Double] = [1.12, 1.13, 1.15, 1.14, 1.16, 1.18, 1.17, 1.19, 1.22, 1.18, 1.16, 1.15, 1.13, 1.12, 1.14, 1.16, 1.15, 1.13, 1.12, 1.16, 1.15, 1.14, 1.13, 1.12, 1.13, 1.14, 1.15, 1.16, 1.17, 1.16]
    let history3m: [Double] = Array(repeating: 1.15, count: 90).enumerated().map { i, _ in 1.12 + 0.1 * sin(Double(i)/10) }
    let history6m: [Double] = Array(repeating: 1.15, count: 180).enumerated().map { i, _ in 1.10 + 0.12 * sin(Double(i)/18) }

    var selectedHistory: [Double] {
        switch selectedRange {
        case .sevenDays: return history7d
        case .oneMonth: return history1m
        case .threeMonths: return history3m
        case .sixMonths: return history6m
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (Closed State)
            Button(action: { withAnimation { expanded.toggle() } }) {
                HStack(spacing: 16) {
                    // Custom Icon
                    ExchangeTypicalityDotsIcon()
                        .frame(width: 40, height: 24)
                    // Title and subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rate insights")
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(Color("primary400"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if !isPro {
                            Text("Upgrade to TILO Pro for $1.99.")
                                .font(.system(size: 14, weight: .regular, design: .default))
                                .foregroundColor(Color("primary400"))
                        }
                    }
                    Spacer()
                    // Chevron in circle
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.07))
                            .frame(width: 36, height: 36)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color("grey200"))
                            .font(.system(size: 20, weight: .semibold))
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
            }
            .background(Color.clear)

            if expanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Range Bar with marker and tooltip
                    ExchangeRateRangeBar1to1(
                        minValue: minValue,
                        maxValue: maxValue,
                        typicalLow: typicalLow,
                        typicalHigh: typicalHigh,
                        today: today,
                        todayLabel: todayLabel
                    )
                    // Summary
                    Text(summary)
                        .font(.footnote)
                        .foregroundColor(Color("grey300"))
                        .padding(.horizontal, 8)
                    // Segmented control for range
                    Picker("Range", selection: $selectedRange) {
                        ForEach(ExchangeRateRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 4)
                    // Chart
                    ExchangeRateHistoryChart1to1(history: selectedHistory, minValue: minValue, maxValue: maxValue)
                        .frame(height: 90)
                        .padding(.horizontal, 8)
                }
                .padding(.bottom, 16)
            }
        }
        .background(
            Color("grey800")
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("grey200").opacity(0.5), lineWidth: 1.0)
        )
        .shadow(color: Color(red: 192/255, green: 132/255, blue: 252/255).opacity(0.06), radius: 2, y: 1)
        .padding(.horizontal, 4)
        .padding(.top, 8)
    }
}

// Custom icon for the left side of the header: three dots with arrow above yellow
struct ExchangeTypicalityDotsIcon: View {
    var body: some View {
        ZStack {
            // Dots
            HStack(spacing: 1) {
                Circle()
                    .fill(Color(red: 0.38, green: 0.85, blue: 0.53)) // Green
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(Color(red: 1.0, green: 0.89, blue: 0.38)) // Yellow
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(Color(red: 1.0, green: 0.53, blue: 0.47)) // Red
                    .frame(width: 8, height: 8)
            }
            // Arrow above yellow dot
            GeometryReader { geo in
                ArrowDown()
                    .fill(Color("grey200"))
                    .frame(width: 10, height: 8)
                    .position(x: geo.size.width/2, y: 2)
                    .offset(x: 0, y: 0)
            }
        }
    }
}

// Downward arrow shape (not triangle)
struct ArrowDown: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let topY = rect.minY
        let bottomY = rect.maxY
        let arrowWidth = rect.width * 0.5
        let arrowHeight = rect.height * 0.6
        // Arrow shaft
        path.move(to: CGPoint(x: midX, y: topY))
        path.addLine(to: CGPoint(x: midX, y: bottomY - arrowHeight))
        // Left wing
        path.move(to: CGPoint(x: midX - arrowWidth/2, y: bottomY - arrowHeight))
        path.addLine(to: CGPoint(x: midX, y: bottomY))
        // Right wing
        path.addLine(to: CGPoint(x: midX + arrowWidth/2, y: bottomY - arrowHeight))
        return path
    }
}

struct ExchangeRateRangeBar1to1: View {
    let minValue: Double
    let maxValue: Double
    let typicalLow: Double
    let typicalHigh: Double
    let today: Double
    let todayLabel: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                GeometryReader { geo in
                    // Bar
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat((typicalLow - minValue) / (maxValue - minValue)), height: 6)
                        Rectangle()
                            .fill(Color.yellow)
                            .frame(width: geo.size.width * CGFloat((typicalHigh - typicalLow) / (maxValue - minValue)), height: 6)
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: geo.size.width * CGFloat((maxValue - typicalHigh) / (maxValue - minValue)), height: 6)
                    }
                    // Marker and tooltip
                    let markerX = geo.size.width * CGFloat((today - minValue) / (maxValue - minValue))
                    VStack(spacing: 2) {
                        Text(todayLabel)
                            .font(.caption2)
                            .foregroundColor(Color("grey900"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color("primary100"))
                            .cornerRadius(8)
                        Circle()
                            .fill(Color("primary100"))
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 2)
                    }
                    .position(x: markerX, y: -10)
                }
                .frame(height: 38)
            }
            HStack {
                Text(String(format: "%.2f", minValue))
                    .font(.caption2)
                    .foregroundColor(Color("grey400"))
                Spacer()
                Text(String(format: "%.2f", maxValue))
                    .font(.caption2)
                    .foregroundColor(Color("grey400"))
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 8)
    }
}

struct ExchangeRateHistoryChart1to1: View {
    let history: [Double]
    let minValue: Double
    let maxValue: Double
    var body: some View {
        GeometryReader { geo in
            let minY = minValue
            let maxY = maxValue
            let points = history.enumerated().map { (i, v) in
                CGPoint(
                    x: CGFloat(i) / CGFloat(history.count - 1) * geo.size.width,
                    y: geo.size.height - CGFloat((v - minY) / (maxY - minY)) * geo.size.height
                )
            }
            Path { path in
                guard let first = points.first else { return }
                path.move(to: first)
                for pt in points.dropFirst() { path.addLine(to: pt) }
            }
            .stroke(Color("primary100"), lineWidth: 2)
            // Y-axis labels
            VStack {
                Text(String(format: "%.0f", maxY))
                    .font(.caption2)
                    .foregroundColor(Color("grey400"))
                Spacer()
                Text(String(format: "%.0f", minY))
                    .font(.caption2)
                    .foregroundColor(Color("grey400"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // X-axis labels
            HStack {
                Text("60 days ago")
                    .font(.caption2)
                    .foregroundColor(Color("grey400"))
                Spacer()
                Text("Today")
                    .font(.caption2)
                    .foregroundColor(Color("grey400"))
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
            .offset(y: geo.size.height - 12)
        }
    }
}

// New component for feature rows in the upsell dropdown
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("primary400"))
                .font(.system(size: 16, weight: .semibold))
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color("grey100"))
            Spacer()
        }
    }
}
