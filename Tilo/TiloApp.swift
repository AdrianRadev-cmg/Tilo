import SwiftUI
import UIKit

@main
struct TiloApp: App {
    init() {
        // Force light mode until dark mode is designed
        if #available(iOS 17.0, *) {
            UIView.appearance(whenContainedInInstancesOf: [UIWindow.self]).overrideUserInterfaceStyle = .light
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
        }
    }
} 