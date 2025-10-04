import SwiftUI

struct CurrencySelector: View {
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (Currency) -> Void
    
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            // Add more dummy currencies for demo and sort alphabetically by code
            let demoCurrencies = [
                Currency(code: "AUD", name: "Australian Dollar", flag: "🇦🇺"),
                Currency(code: "BRL", name: "Brazilian Real", flag: "🇧🇷"),
                Currency(code: "CAD", name: "Canadian Dollar", flag: "🇨🇦"),
                Currency(code: "CHF", name: "Swiss Franc", flag: "🇨🇭"),
                Currency(code: "CNY", name: "Chinese Yuan", flag: "🇨🇳"),
                Currency(code: "EUR", name: "Euro", flag: "🇪🇺"),
                Currency(code: "GBP", name: "British Pound", flag: "🇬🇧"),
                Currency(code: "INR", name: "Indian Rupee", flag: "🇮🇳"),
                Currency(code: "JPY", name: "Japanese Yen", flag: "🇯🇵"),
                Currency(code: "KRW", name: "South Korean Won", flag: "🇰🇷"),
                Currency(code: "MXN", name: "Mexican Peso", flag: "🇲🇽"),
                Currency(code: "NZD", name: "New Zealand Dollar", flag: "🇳🇿"),
                Currency(code: "SGD", name: "Singapore Dollar", flag: "🇸🇬"),
                Currency(code: "USD", name: "US Dollar", flag: "🇺🇸")
            ]
            return demoCurrencies.sorted { $0.code < $1.code }
        }
        return Currency.mockData.filter { currency in
            currency.name.localizedCaseInsensitiveContains(searchText) ||
            currency.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Navigation Bar
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color("grey800"))
                                .background(.ultraThickMaterial)
                                .glassEffect()
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.2), lineWidth: 0.8)
                                )
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    Text("Choose a currency")
                        .font(.title)
                        .bold()
                        .kerning(0.38)
                        .foregroundColor(Color("grey100"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Search Bar
                    SearchBar(text: $searchText, placeholder: "Search currency name or code")
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
                .background(Color("grey800"))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Frequently Used Section
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Frequently used")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey600"))
                                    .textCase(.uppercase)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                ForEach(Currency.frequentlyUsed) { currency in
                                    Button(action: {
                                        onSelect(currency)
                                        dismiss()
                                    }) {
                                        CurrencyRow(
                                            code: currency.code,
                                            name: currency.name,
                                            flag: currency.flag
                                        )
                                    }
                                    .buttonStyle(CurrencyRowHighlightButtonStyle())
                                }
                            }
                        }
                        // Divider between sections
                        Divider()
                            .background(Color("grey600"))
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        // All Currencies Section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("All currencies")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(Color("grey600"))
                                .textCase(.uppercase)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                            ForEach(filteredCurrencies) { currency in
                                Button(action: {
                                    onSelect(currency)
                                    dismiss()
                                }) {
                                    CurrencyRow(
                                        code: currency.code,
                                        name: currency.name,
                                        flag: currency.flag
                                    )
                                }
                                .buttonStyle(CurrencyRowHighlightButtonStyle())
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .background(Color("grey800"))
            .navigationBarHidden(true)
        }
        .background(Color("grey800").ignoresSafeArea())
        .edgesIgnoringSafeArea(.horizontal)
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color("grey500"))
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color("grey500"))
                }
                TextField("", text: $text)
                    .foregroundColor(Color("grey500"))
                    .tint(Color("grey500"))
                    .focused($isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("grey500"))
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(Color("grey700"))
        .cornerRadius(8)
        .onTapGesture {
            isFocused = true
        }
    }
}

#Preview {
    ZStack {
        Color("grey700").ignoresSafeArea()
        CurrencySelector(onSelect: { _ in })
    }
}

struct CurrencyRowHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\._isPressed, configuration.isPressed)
    }
}

private struct _IsPressedKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var _isPressed: Bool {
        get { self[_IsPressedKey.self] }
        set { self[_IsPressedKey.self] = newValue }
    }
} 