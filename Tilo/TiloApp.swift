import SwiftUI
import UIKit

@main
struct TiloApp: App {
    init() {
        #if os(iOS)
        // Set tab bar appearance for the entire app
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(named: "grey200")
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light) // Force light mode
        }
    }
} 