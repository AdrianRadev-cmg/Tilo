import SwiftUI

struct CurrencySelector: View {
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    let onSelect: (Currency) -> Void
    
    private var filteredCurrencies: [Currency] {
        let sortedCurrencies = Currency.allCurrenciesSorted
        if searchText.isEmpty {
            return sortedCurrencies
        } else {
            return sortedCurrencies.filter { currency in
            currency.name.localizedCaseInsensitiveContains(searchText) ||
            currency.code.localizedCaseInsensitiveContains(searchText)
            }
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
                                .font(.body.weight(.semibold))
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
                        .accessibilityLabel("Close")
                        .accessibilityHint("Double tap to close currency selector")
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
                        .accessibilityAddTraits(.isHeader)
                    
                    // Search Bar
                    SearchBar(text: $searchText, placeholder: "Search currency name or code", isFocused: $isSearchFocused)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
                .background(Color("grey800"))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Recently Used Section (last 5 used currencies)
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recently used")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey600"))
                                    .textCase(.uppercase)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                ForEach(Currency.recentlyUsed) { currency in
                                    Button(action: {
                                        Analytics.shared.track(Analytics.Event.currencySelected, with: [
                                            "currency_code": currency.code,
                                            "source": "recently_used"
                                        ])
                                        Currency.addToRecentlyUsed(currency)
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
                                    Analytics.shared.track(Analytics.Event.currencySelected, with: [
                                        "currency_code": currency.code,
                                        "source": searchText.isEmpty ? "all_currencies" : "search_results"
                                    ])
                                    Currency.addToRecentlyUsed(currency)
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
                .scrollDismissesKeyboard(.immediately)
            }
            .background(Color("grey800"))
            .navigationBarHidden(true)
        }
        .background(Color("grey800").ignoresSafeArea())
        .edgesIgnoringSafeArea(.horizontal)
        .onAppear {
            // Track selector opened
            Analytics.shared.track(Analytics.Event.currencySelectorOpened)
        }
        .onChange(of: searchText) { oldValue, newValue in
            // Track search when user types (debounced by only tracking non-empty)
            if !newValue.isEmpty && oldValue.isEmpty {
                Analytics.shared.track(Analytics.Event.currencySearched)
            }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    var isFocused: FocusState<Bool>.Binding
    
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
                    .focused(isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onAppear {
                        // Focus immediately when TextField is rendered
                        isFocused.wrappedValue = true
                    }
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
            isFocused.wrappedValue = true
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