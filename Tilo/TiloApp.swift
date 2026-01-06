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
    }
    
    var body: some Scene {
        WindowGroup {
            AppContentView()
        }
    }
}

struct AppContentView: View {
    @State private var showSplash = false
    
    var body: some View {
        ZStack {
            HomeView()
                .preferredColorScheme(.dark)
            
            if showSplash {
                SplashScreenView(onFinished: {
                    // Mark that user has seen splash screen today
                    let today = Calendar.current.startOfDay(for: Date())
                    UserDefaults.standard.set(today, forKey: "lastSplashDate")
                    
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .onAppear {
            checkShouldShowSplash()
        }
    }
    
    private func checkShouldShowSplash() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get last date splash was shown
        if let lastSplashDate = UserDefaults.standard.object(forKey: "lastSplashDate") as? Date {
            let lastSplashDay = Calendar.current.startOfDay(for: lastSplashDate)
            
            // Show splash if it's a different day
            if today != lastSplashDay {
                showSplash = true
            }
        } else {
            // First time ever - show splash
            showSplash = true
        }
    }
}
