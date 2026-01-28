import SwiftUI
import UIKit
import AppTrackingTransparency
import FBSDKCoreKit

@main
struct TiloApp: App {
    init() {
        // Set solid tab bar background color
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "grey700")
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        
        // MARK: - Initialize Facebook SDK
        ApplicationDelegate.shared.application(
            UIApplication.shared,
            didFinishLaunchingWithOptions: nil
        )
        
        // MARK: - Initialize Analytics
        Analytics.shared.initialize()
        
        // MARK: - Early Adopter Flag
        // Set this flag on first launch to identify early users for future grandfathering
        // When adding a paywall later, check this flag to give early adopters free access
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "isEarlyAdopter")
            UserDefaults.standard.set(Date(), forKey: "firstLaunchDate")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
        
        // MARK: - App Open Count (for review prompt on 2nd open)
        let currentOpenCount = UserDefaults.standard.integer(forKey: "appOpenCount")
        UserDefaults.standard.set(currentOpenCount + 1, forKey: "appOpenCount")
        
        // Track app open
        Analytics.shared.track(Analytics.Event.appOpened, with: [
            "open_count": currentOpenCount + 1,
            "is_early_adopter": UserDefaults.standard.bool(forKey: "isEarlyAdopter")
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
    }
}

struct AppContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
            HomeView()
                .preferredColorScheme(.dark)
            .onOpenURL { url in
                // Handle widget tap
                if url.scheme == "tilo" && url.host == "widget-tap" {
                    Analytics.shared.track(Analytics.Event.widgetTapped, with: [
                        "source": "home_screen_widget"
                    ])
            }
        }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .background {
                    // Track session end when app goes to background
                    Analytics.shared.trackSessionEnd()
                }
        }
            .onAppear {
                // Request App Tracking Transparency permission
                // Delayed slightly to ensure app is fully loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    requestTrackingPermission()
                }
            }
    }
    
    private func requestTrackingPermission() {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                // Enable Facebook tracking
                Settings.shared.isAdvertiserTrackingEnabled = true
                debugLog("📊 ATT: Authorized - tracking enabled")
            case .denied, .restricted:
                Settings.shared.isAdvertiserTrackingEnabled = false
                debugLog("📊 ATT: Denied/Restricted - tracking disabled")
            case .notDetermined:
                debugLog("📊 ATT: Not determined")
            @unknown default:
                debugLog("📊 ATT: Unknown status")
            }
        }
    }
}
