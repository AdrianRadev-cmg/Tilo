import SwiftUI

struct CurrencySelector: View {
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    let onSelect: (Currency) -> Void
    
    private var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.mockData
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
                VStack(spacing: 0) {
                    HStack {
                        Text("Choose a currency")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color("grey200"))
                        Spacer()
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(Color("grey200"))
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Search Bar
                    SearchBar(text: $searchText, placeholder: "Search currency")
                        .padding(.horizontal)
                        .padding(.top, 16)
                }
                .background(Color("grey700"))
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Frequently Used Section
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Frequently used")
                                    .font(.headline)
                                    .foregroundColor(Color("grey300"))
                                    .padding(.horizontal)
                                
                                ForEach(Currency.frequentlyUsed) { currency in
                                    Button {
                                        onSelect(currency)
                                        dismiss()
                                    } label: {
                                        CurrencyRow(
                                            code: currency.code,
                                            name: currency.name,
                                            flag: currency.flag
                                        )
                                    }
                                }
                                
                                Divider()
                                    .background(Color("grey600"))
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        // All Currencies Section
                        VStack(alignment: .leading, spacing: 16) {
                            if searchText.isEmpty {
                                Text("All currencies")
                                    .font(.headline)
                                    .foregroundColor(Color("grey300"))
                                    .padding(.horizontal)
                            }
                            
                            ForEach(filteredCurrencies) { currency in
                                Button {
                                    onSelect(currency)
                                    dismiss()
                                } label: {
                                    CurrencyRow(
                                        code: currency.code,
                                        name: currency.name,
                                        flag: currency.flag
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 16)
                }
            }
            .background(Color("grey700"))
            .navigationBarHidden(true)
        }
        .background(Color("grey700"))
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
                .foregroundColor(Color("grey300"))
            
            TextField(placeholder, text: $text)
                .foregroundColor(Color("grey200"))
                .tint(Color("grey200"))
                .focused($isFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color("grey300"))
                }
            }
        }
        .padding(8)
        .background(Color("grey800"))
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