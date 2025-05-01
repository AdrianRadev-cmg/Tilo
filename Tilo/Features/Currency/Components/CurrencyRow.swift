import SwiftUI

struct CurrencyRow: View {
    let code: String
    let name: String
    let flag: String
    
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
        .contentShape(Rectangle())
    }
}

#Preview {
    CurrencyRow(code: "GBP", name: "British Pound", flag: "🇬🇧")
        .background(Color("grey900"))
} 