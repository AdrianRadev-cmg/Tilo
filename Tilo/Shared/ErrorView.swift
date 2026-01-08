import SwiftUI

/// A reusable error view that matches the app's glass morphism style
struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    init(
        title: String = "Something went wrong",
        message: String = "Unable to load exchange rates. Please check your connection and try again.",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Error icon
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle.weight(.light))
                .foregroundColor(Color("primary100").opacity(0.7))
            
            // Title
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Retry button
            if let retryAction = retryAction {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    retryAction()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                        Text("Try Again")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color("primary500").opacity(0.8))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Try again")
                .accessibilityHint("Double tap to retry loading exchange rates")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .glassEffect(in: .rect(cornerRadius: 16))
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 20/255, green: 8/255, blue: 58/255).opacity(0.75))
            }
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02),
                            Color.clear
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .contain)
    }
}

/// A compact inline error banner for less intrusive error display
struct ErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.callout.weight(.medium))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Dismiss error")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 40/255, green: 20/255, blue: 60/255).opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Toast-style notification for transient messages
struct ToastView: View {
    enum ToastType {
        case success
        case error
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return Color("primary100")
            }
        }
    }
    
    let message: String
    let type: ToastType
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: type.icon)
                .font(.body.weight(.medium))
                .foregroundColor(type.color)
            
            Text(message)
                .font(.callout.weight(.medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(Color(red: 30/255, green: 20/255, blue: 60/255).opacity(0.95))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview("Error View") {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.18, green: 0.09, blue: 0.38),
                Color(red: 0.08, green: 0.03, blue: 0.15)
            ]),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
        
        ErrorView(retryAction: {})
            .padding()
    }
}

#Preview("Error Banner") {
    ZStack {
        Color(red: 0.08, green: 0.03, blue: 0.15)
            .ignoresSafeArea()
        
        VStack {
            ErrorBanner(message: "Unable to connect. Using cached rates.", onDismiss: {})
                .padding()
            Spacer()
        }
    }
}

#Preview("Toast Views") {
    ZStack {
        Color(red: 0.08, green: 0.03, blue: 0.15)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            ToastView(message: "Saved to Photos", type: .success)
            ToastView(message: "Connection failed", type: .error)
            ToastView(message: "Using cached rates", type: .info)
        }
    }
}



