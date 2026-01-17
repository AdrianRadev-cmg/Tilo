import SwiftUI
import UIKit

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
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
    }
}

struct AppContentView: View {
    var body: some View {
        HomeView()
            .preferredColorScheme(.dark)
    }
}
