import SwiftUI
import UIKit

@main
struct TiloApp: App {
    init() {
        // Force light mode until dark mode is designed
        if #available(iOS 17.0, *) {
            UIView.appearance(whenContainedInInstancesOf: [UIWindow.self]).overrideUserInterfaceStyle = .light
        }
        // Set solid tab bar background color
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "grey700")
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
        }
    }
} 