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
            conversions: [(10, 11.70), (20, 23.40), (50, 58.50), (100, 117.00), (200, 234.00), (500, 585.00), (1000, 1170.00)]
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
        let amounts = dataManager.getWidgetAmounts(for: pair.fromCode, count: 7)
        
        // Calculate conversions using cached rate or default
        let rate = pair.exchangeRate ?? 1.0
        let conversions = amounts.map { amount in
            (from: amount, to: amount * rate)
        }
        
        return CurrencyEntry(
            // Use the lastUpdated from the cached pair - this reflects when rates were actually fetched
            date: pair.lastUpdated,
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

// MARK: - Small Widget (4 conversions)
struct SmallWidgetView: View {
    let entry: CurrencyEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with currency codes
            HStack(spacing: 4) {
                Text(entry.currencyPair.fromCode)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text("→")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                Text(entry.currencyPair.toCode)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // 4 conversion rows - alternating backgrounds for visual rhythm
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(entry.conversions.prefix(4).enumerated()), id: \.offset) { index, conversion in
                    HStack {
                        Text(formatAmount(conversion.from))
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        
                        Spacer()
                        
                        Text(formatAmount(conversion.to))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index % 2 == 1 ? Color.white.opacity(0.05) : Color.clear)
                    )
                }
            }
        }
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Medium Widget (5 conversions)
struct MediumWidgetView: View {
    let entry: CurrencyEntry
    
    var body: some View {
        HStack(spacing: 20) {
            // Left side - Header (centered vertically with table)
            VStack(alignment: .leading, spacing: 10) {
                // Flags side by side with 8px gap, in circles
                HStack(spacing: 8) {
                    Text(entry.currencyPair.fromFlag)
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                    Text(entry.currencyPair.toFlag)
                        .font(.system(size: 20))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
                
                // Currency codes
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(entry.currencyPair.fromCode)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("→")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                        Text(entry.currencyPair.toCode)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Exchange rate
                    if let rate = entry.currencyPair.exchangeRate {
                        Text("1 = \(String(format: "%.2f", rate))")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            .frame(width: 90)
            
            // Right side - Conversions (5 rows)
            VStack(spacing: 2) {
                ForEach(Array(entry.conversions.prefix(5).enumerated()), id: \.offset) { index, conversion in
                    HStack {
                        Text(formatWithSymbol(symbol: getCurrencySymbol(for: entry.currencyPair.fromCode), amount: formatAmount(conversion.from)))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(formatWithSymbol(symbol: getCurrencySymbol(for: entry.currencyPair.toCode), amount: formatAmount(conversion.to)))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
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
        .padding(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Large Widget (7 conversions)
struct LargeWidgetView: View {
    let entry: CurrencyEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 12) {
                // Currency codes left-aligned
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.currencyPair.fromCode)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("→")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text(entry.currencyPair.toCode)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    if let rate = entry.currencyPair.exchangeRate {
                        Text("1 = \(String(format: "%.4f", rate))")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                // Flags right-aligned, side by side with 8px gap, in circles
                HStack(spacing: 8) {
                    Text(entry.currencyPair.fromFlag)
                        .font(.system(size: 22))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                    Text(entry.currencyPair.toFlag)
                        .font(.system(size: 22))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.15))
                        )
                }
            }
            
            // Conversion rows
            VStack(spacing: 2) {
                ForEach(Array(entry.conversions.prefix(7).enumerated()), id: \.offset) { index, conversion in
                    HStack {
                        Text(formatWithSymbol(symbol: getCurrencySymbol(for: entry.currencyPair.fromCode), amount: formatAmount(conversion.from)))
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(formatWithSymbol(symbol: getCurrencySymbol(for: entry.currencyPair.toCode), amount: formatAmount(conversion.to)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(index % 2 == 1 ? Color.white.opacity(0.04) : Color.clear)
                    )
                }
            }
            
        }
        .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Helpers

private func formatAmount(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = amount >= 1000 || amount == floor(amount) ? 0 : 2
    formatter.minimumFractionDigits = 0
    formatter.usesGroupingSeparator = true
    return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
}

private func getCurrencySymbol(for code: String) -> String {
    switch code {
    case "USD", "CAD", "AUD", "NZD", "SGD", "HKD", "MXN", "ARS", "CLP", "COP": return "$"
    case "EUR": return "€"
    case "GBP": return "£"
    case "JPY", "CNY": return "¥"
    case "KRW": return "₩"
    case "INR": return "₹"
    case "RUB": return "₽"
    case "THB": return "฿"
    case "CHF": return "Fr"
    case "SEK", "NOK", "DKK", "ISK": return "kr"
    case "PLN": return "zł"
    case "CZK": return "Kč"
    case "HUF": return "Ft"
    case "TRY": return "₺"
    case "ZAR": return "R"
    case "BRL": return "R$"
    case "ILS": return "₪"
    case "AED", "SAR", "QAR": return "﷼"
    case "PHP": return "₱"
    case "MYR": return "RM"
    case "IDR": return "Rp"
    case "VND": return "₫"
    case "EGP": return "E£"
    case "NGN": return "₦"
    case "KES", "UGX", "TZS": return "Sh"
    case "PKR", "LKR", "NPR": return "Rs"
    default: return code
    }
}

// Helper to determine if symbol needs a space (letter-based symbols)
private func needsSpaceAfterSymbol(_ symbol: String) -> Bool {
    let noSpaceSymbols: Set<String> = ["$", "€", "£", "¥", "₩", "₹", "₽", "฿", "₺", "₪", "﷼", "₱", "₫", "₦"]
    return !noSpaceSymbols.contains(symbol)
}

private func formatWithSymbol(symbol: String, amount: String) -> String {
    if needsSpaceAfterSymbol(symbol) {
        return "\(symbol) \(amount)"
    }
    return "\(symbol)\(amount)"
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
        .contentMarginsDisabled()
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
