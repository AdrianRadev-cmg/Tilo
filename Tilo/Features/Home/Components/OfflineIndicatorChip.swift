//
//  OfflineIndicatorChip.swift
//  Tilo
//
//  Created by Adrian Radev on 07/01/2026.
//

import SwiftUI

/// A chip that displays when the user is offline, showing when rates were last updated
struct OfflineIndicatorChip: View {
    let lastUpdated: Date?
    
    private var formattedTime: String {
        guard let lastUpdated = lastUpdated else {
            return "Unknown"
        }
        
        let now = Date()
        let interval = now.timeIntervalSince(lastUpdated)
        
        // Less than 1 minute
        if interval < 60 {
            return "just now"
        }
        
        // Less than 1 hour - show minutes
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        }
        
        // Less than 24 hours - show hours
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
        
        // More than 24 hours - show date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: lastUpdated)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 12, weight: .medium))
            
            Text("Offline")
                .font(.system(size: 13, weight: .semibold))
            
            Text("•")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
            
            Text("Last updated \(formattedTime)")
                .font(.system(size: 13, weight: .regular))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            .ultraThinMaterial,
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.2), lineWidth: 0.5)
        )
    }
}

#Preview {
    ZStack {
        // Purple gradient background like the app
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.18, green: 0.09, blue: 0.38),
                Color(red: 0.08, green: 0.03, blue: 0.15)
            ]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Just now
            OfflineIndicatorChip(lastUpdated: Date())
            
            // 5 minutes ago
            OfflineIndicatorChip(lastUpdated: Date().addingTimeInterval(-5 * 60))
            
            // 2 hours ago
            OfflineIndicatorChip(lastUpdated: Date().addingTimeInterval(-2 * 60 * 60))
            
            // Yesterday
            OfflineIndicatorChip(lastUpdated: Date().addingTimeInterval(-25 * 60 * 60))
            
            // Unknown
            OfflineIndicatorChip(lastUpdated: nil)
        }
    }
}

