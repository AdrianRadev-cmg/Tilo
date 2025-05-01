//
//  ContentView.swift
//  Tilo
//
//  Created by Adrian Radev on 12/04/2025.
//

import SwiftUI

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
    
    // Add state for currency data
    @State private var fromCurrencyName = "British Pound"
    @State private var fromFlagEmoji = "🇬🇧"
    @State private var fromCurrencyCode = "GBP"
    
    @State private var toCurrencyName = "Euro"
    @State private var toFlagEmoji = "🇪🇺"
    @State private var toCurrencyCode = "EUR"
    
    private let gradientStops = [
        Gradient.Stop(color: Color(red: 0.12, green: 0.03, blue: 0.30), location: 0.00),
        Gradient.Stop(color: Color(red: 0.15, green: 0.04, blue: 0.36), location: 0.06),
        Gradient.Stop(color: Color(red: 0.18, green: 0.05, blue: 0.42), location: 0.09),
        Gradient.Stop(color: Color(red: 0.07, green: 0.01, blue: 0.20), location: 0.38),
        Gradient.Stop(color: Color(red: 0.02, green: 0.00, blue: 0.08), location: 1.00)
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
                                        QuickAmountChip(symbol: "¥", amount: amount)
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
                            // Recent Transactions Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Transactions")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                ForEach(1...5, id: \.self) { index in
                                    HStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 40, height: 40)
                                        
                                        VStack(alignment: .leading) {
                                            Text("Transaction \(index)")
                                                .fontWeight(.medium)
                                            Text("April \(index + 10), 2024")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("£\(Double(index) * 10.50, specifier: "%.2f")")
                                            .fontWeight(.semibold)
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
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(["Send", "Request", "Split", "History", "Cards", "More"], id: \.self) { action in
                                        VStack {
                                            Circle()
                                                .fill(Color.purple.opacity(0.1))
                                                .frame(width: 50, height: 50)
                                            Text(action)
                                                .font(.subheadline)
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
                                
                                VStack(spacing: 12) {
                                    ForEach(["Food & Drinks", "Shopping", "Transport", "Bills"], id: \.self) { category in
                                        HStack {
                                            Text(category)
                                            Spacer()
                                            Text("£\(Int.random(in: 50...200))")
                                                .fontWeight(.medium)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
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
                                
                                ForEach(["Account Settings", "Notifications", "Privacy", "Help & Support"], id: \.self) { setting in
                                    HStack {
                                        Text(setting)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 16)
                        .background(
                            Color("grey200")
                                .ignoresSafeArea(edges: .bottom)
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
        .tint(Color("primary600")) // Sets the accent color for selected tab
        #if os(iOS)
        .toolbarBackground(Color("grey200"), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbar(.visible, for: .tabBar)
        #endif
    }
}

#Preview {
    HomeView()
}

// Add preference key for height measurement
private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
