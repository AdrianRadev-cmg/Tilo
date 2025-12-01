//
//  TiloWidget.swift
//  TiloWidget
//
//  Created by Adrian Radev on 01/12/2025.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct CurrencyEntry: TimelineEntry {
    let date: Date
    let currencyPair: CurrencyPair
    let conversions: [(from: Double, to: Double)]
    
    static var placeholder: CurrencyEntry {
        CurrencyEntry(
            date: Date(),
            currencyPair: CurrencyPair(
                fromCode: "GBP",
                fromName: "British Pound",
                fromFlag: "🇬🇧",
                toCode: "EUR",
                toName: "Euro",
                toFlag: "🇪🇺",
                exchangeRate: 1.17
            ),
            conversions: [(10, 11.70), (50, 58.50), (100, 117.00), (500, 585.00)]
        )
    }
}

// MARK: - Timeline Provider
struct CurrencyProvider: TimelineProvider {
    func placeholder(in context: Context) -> CurrencyEntry {
        CurrencyEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (CurrencyEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<CurrencyEntry>) -> Void) {
        let entry = createEntry()
        
        // Update every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
    
    private func createEntry() -> CurrencyEntry {
        let dataManager = SharedCurrencyDataManager.shared
        let pair = dataManager.currentCurrencyPair ?? CurrencyPair(
            fromCode: "GBP",
            fromName: "British Pound",
            fromFlag: "🇬🇧",
            toCode: "EUR",
            toName: "Euro",
            toFlag: "🇪🇺"
        )
        
        // Get amounts based on currency
        let amounts = dataManager.getWidgetAmounts(for: pair.fromCode, count: 8)
        
        // Calculate conversions using cached rate or default
        let rate = pair.exchangeRate ?? 1.0
        let conversions = amounts.map { amount in
            (from: amount, to: amount * rate)
        }
        
        return CurrencyEntry(
            date: Date(),
            currencyPair: pair,
            conversions: conversions
        )
    }
}

// MARK: - Main Widget Entry View

struct TiloWidgetEntryView: View {
    var entry: CurrencyEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (2 conversions)
struct SmallWidgetView: View {
    let entry: CurrencyEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with flags
            HStack(spacing: 4) {
                Text(entry.currencyPair.fromFlag)
                    .font(.system(size: 18))
                Text("→")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(entry.currencyPair.toFlag)
                    .font(.system(size: 18))
            }
            
            // Currency codes
            HStack(spacing: 4) {
                Text(entry.currencyPair.fromCode)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text("→")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                Text(entry.currencyPair.toCode)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(red: 0.85, green: 0.75, blue: 1.0))
            }
            
            Spacer()
            
            // 2 conversion rows
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(entry.conversions.prefix(2).enumerated()), id: \.offset) { _, conversion in
                    HStack {
                        Text(formatAmount(conversion.from))
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white)
                        Spacer()
                        Text(formatAmount(conversion.to))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.75, blue: 1.0))
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget (4 conversions)
struct MediumWidgetView: View {
    let entry: CurrencyEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Header
            VStack(alignment: .leading, spacing: 6) {
                // Overlapping flags
                ZStack {
                    Text(entry.currencyPair.fromFlag)
                        .font(.system(size: 24))
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                        )
                        .offset(x: -6, y: -4)
                        .zIndex(1)
                    Text(entry.currencyPair.toFlag)
                        .font(.system(size: 24))
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 36, height: 36)
                        )
                        .offset(x: 6, y: 4)
                }
                .frame(width: 50, height: 44)
                
                // Currency codes
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(entry.currencyPair.fromCode)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("→")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Text(entry.currencyPair.toCode)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.75, blue: 1.0))
                    }
                    
                    // Rate
                    if let rate = entry.currencyPair.exchangeRate {
                        Text("1 = \(String(format: "%.2f", rate))")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            .frame(width: 90)
            
            // Right side - Conversions
            VStack(spacing: 4) {
                ForEach(Array(entry.conversions.prefix(4).enumerated()), id: \.offset) { index, conversion in
                    HStack {
                        Text(formatAmount(conversion.from))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Dots
                        Text("···")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.2))
                        
                        Spacer()
                        
                        Text(formatAmount(conversion.to))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.75, blue: 1.0))
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index % 2 == 1 ? Color.white.opacity(0.05) : Color.clear)
                    )
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Large Widget (6-8 conversions)
struct LargeWidgetView: View {
    let entry: CurrencyEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 10) {
                // Overlapping flags
                ZStack {
                    Text(entry.currencyPair.fromFlag)
                        .font(.system(size: 26))
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                        )
                        .offset(x: -8, y: -4)
                        .zIndex(1)
                    Text(entry.currencyPair.toFlag)
                        .font(.system(size: 26))
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 40, height: 40)
                        )
                        .offset(x: 8, y: 4)
                }
                .frame(width: 56, height: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.currencyPair.fromCode)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("→")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Text(entry.currencyPair.toCode)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.85, green: 0.75, blue: 1.0))
                    }
                    
                    if let rate = entry.currencyPair.exchangeRate {
                        Text("1 \(entry.currencyPair.fromCode) = \(String(format: "%.4f", rate)) \(entry.currencyPair.toCode)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            // Conversion rows
            VStack(spacing: 2) {
                ForEach(Array(entry.conversions.prefix(8).enumerated()), id: \.offset) { index, conversion in
                    HStack {
                        Text(formatAmount(conversion.from))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                            .frame(width: 70, alignment: .leading)
                        
                        // Dotted line
                        HStack(spacing: 3) {
                            ForEach(0..<8, id: \.self) { _ in
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 2, height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text(formatAmount(conversion.to))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.75, blue: 1.0))
                            .frame(width: 90, alignment: .trailing)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(index % 2 == 1 ? Color.white.opacity(0.04) : Color.clear)
                    )
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Spacer()
                Text("Updated \(formattedTime)")
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Helpers

private func formatAmount(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = amount >= 1000 || amount == floor(amount) ? 0 : 2
    formatter.minimumFractionDigits = 0
    formatter.groupingSeparator = ","
    return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
}

// MARK: - Widget Gradient Background
private var widgetGradient: some View {
    LinearGradient(
        gradient: Gradient(stops: [
            Gradient.Stop(color: Color(red: 0.22, green: 0.12, blue: 0.45), location: 0.00),
            Gradient.Stop(color: Color(red: 0.18, green: 0.09, blue: 0.38), location: 0.30),
            Gradient.Stop(color: Color(red: 0.12, green: 0.05, blue: 0.28), location: 0.70),
            Gradient.Stop(color: Color(red: 0.08, green: 0.03, blue: 0.18), location: 1.00)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Widget Configuration

struct TiloWidget: Widget {
    let kind: String = "TiloWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CurrencyProvider()) { entry in
            if #available(iOS 17.0, *) {
                TiloWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        widgetGradient
                    }
            } else {
                TiloWidgetEntryView(entry: entry)
                    .background(widgetGradient)
            }
        }
        .configurationDisplayName("Currency Converter")
        .description("Quick currency conversions at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    TiloWidget()
} timeline: {
    CurrencyEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    TiloWidget()
} timeline: {
    CurrencyEntry.placeholder
}

#Preview("Large", as: .systemLarge) {
    TiloWidget()
} timeline: {
    CurrencyEntry.placeholder
}
