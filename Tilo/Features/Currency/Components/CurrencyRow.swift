import SwiftUI

struct CurrencyRow: View {
    let code: String
    let name: String
    let flag: String
    @Environment(\._isPressed) private var isPressed: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(flag)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(code)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            isPressed ? Color("grey700") : Color.clear
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    CurrencyRow(code: "GBP", name: "British Pound", flag: "🇬🇧")
        .background(Color("grey900"))
} 