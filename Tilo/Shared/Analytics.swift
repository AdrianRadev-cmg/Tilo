//
//  Analytics.swift
//  Tilo
//
//  Aptabase analytics integration for tracking app usage
//  Native implementation - no external SDK required
//

import Foundation
import UIKit

/// Analytics wrapper for Aptabase
/// Usage: Analytics.shared.track("event_name", with: ["key": "value"])
final class Analytics {
    static let shared = Analytics()
    
    private let appKey = "A-EU-7589395908"
    private let baseURL = "https://eu.aptabase.com"  // EU region based on app key prefix
    private var sessionId: String
    private let isDebug: Bool
    private var sessionStartTime: Date?
    
    private init() {
        // Generate a unique session ID
        self.sessionId = UUID().uuidString
        
        #if DEBUG
        self.isDebug = true
        #else
        self.isDebug = false
        #endif
    }
    
    /// Initialize analytics - call this once on app launch
    func initialize() {
        // Generate new session ID on each app launch
        sessionId = UUID().uuidString
        sessionStartTime = Date()
        debugLog("📊 Analytics initialized (session: \(sessionId.prefix(8))...)")
        
        // Flush any pending widget events
        flushWidgetEvents()
        
        // Track session start
        track(Event.sessionStarted)
    }
    
    /// Call when app goes to background
    func trackSessionEnd() {
        guard let startTime = sessionStartTime else { return }
        
        let duration = Int(Date().timeIntervalSince(startTime))
        track(Event.sessionEnded, with: [
            "duration_seconds": duration
        ])
    }
    
    /// Send any widget events that were stored while the app was closed
    private func flushWidgetEvents() {
        let widgetEvents = SharedCurrencyDataManager.shared.flushWidgetEvents()
        
        if !widgetEvents.isEmpty {
            debugLog("📊 Flushing \(widgetEvents.count) widget events")
            
            for event in widgetEvents {
                // Send each widget event with its original timestamp
                var props = event.properties
                props["event_source"] = "widget"
                props["original_timestamp"] = ISO8601DateFormatter().string(from: event.timestamp)
                track(event.eventName, with: props)
            }
        }
    }
    
    /// Track an event with optional properties
    func track(_ event: String, with properties: [String: Any]? = nil) {
        // Build the event payload
        var payload: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "sessionId": sessionId,
            "eventName": event,
            "systemProps": [
                "isDebug": isDebug,
                "osName": "iOS",
                "osVersion": UIDevice.current.systemVersion,
                "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "appBuildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
                "deviceModel": UIDevice.current.model,
                "locale": Locale.current.identifier,
                "sdkVersion": "aptabase-swift@0.3.0"
            ]
        ]
        
        if let properties = properties {
            // Convert all values to strings for consistency
            var stringProps: [String: String] = [:]
            for (key, value) in properties {
                stringProps[key] = String(describing: value)
            }
            payload["props"] = stringProps
        }
        
        // Send event asynchronously
        sendEvent(payload)
        
        debugLog("📊 Event: \(event)" + (properties != nil ? " \(properties!)" : ""))
    }
    
    private func sendEvent(_ payload: [String: Any]) {
        guard let url = URL(string: "\(baseURL)/api/v0/event") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appKey, forHTTPHeaderField: "App-Key")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            debugLog("📊 Analytics error: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                debugLog("📊 Analytics send error: \(error.localizedDescription)")
                return
            }
            
            // Debug: Log response status
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                    debugLog("📊 Analytics response: \(httpResponse.statusCode)")
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        debugLog("📊 Response body: \(body)")
                    }
                }
            }
        }.resume()
    }
}

// MARK: - Event Names (for consistency)
extension Analytics {
    enum Event {
        // App lifecycle & sessions
        static let appOpened = "app_opened"
        static let appBackgrounded = "app_backgrounded"
        static let sessionStarted = "session_started"
        static let sessionEnded = "session_ended"
        
        // Tab navigation
        static let tabChanged = "tab_changed"
        
        // Conversions
        static let conversionPerformed = "conversion_performed"
        static let manualAmountEntered = "manual_amount_entered"
        static let swapButtonTapped = "swap_button_tapped"
        
        // Quick conversion chips
        static let quickChipTapped = "quick_chip_tapped"
        
        // Currency selector
        static let currencySelectorOpened = "currency_selector_opened"
        static let currencySearched = "currency_searched"
        static let currencySelected = "currency_selected"
        
        // Chart
        static let chartInteraction = "chart_interaction"
        
        // Price guide
        static let priceGuideViewed = "price_guide_viewed"
        static let priceGuideScrolled = "price_guide_scrolled"
        static let widgetGuideOpened = "widget_guide_opened"
        
        // Review flow - Satisfaction prompt
        static let satisfactionPromptShown = "satisfaction_prompt_shown"
        static let satisfactionYesTapped = "satisfaction_yes_tapped"
        static let satisfactionNoTapped = "satisfaction_no_tapped"
        
        // Review flow - Native iOS prompt (Note: Apple doesn't allow tracking user actions inside the native prompt)
        static let nativeReviewPromptShown = "native_review_prompt_shown"
        
        // Widget
        static let widgetDisplayed = "widget_displayed"
        static let widgetInstalled = "widget_installed"  // First display per size
        static let widgetTapped = "widget_tapped"
        
        // Errors
        static let errorShown = "error_shown"
        static let offlineModeEntered = "offline_mode_entered"
        static let offlineModeExited = "offline_mode_exited"
    }
}
