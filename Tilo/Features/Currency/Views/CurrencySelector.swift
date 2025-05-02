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
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(Color("grey500"))
                                .frame(width: 32, height: 32)
                                .background(Color("grey700"))
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
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Frequently used")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey600"))
                                    .textCase(.uppercase)
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
                            }
                        }
                        
                        // All Currencies Section
                        VStack(alignment: .leading, spacing: 0) {
                            if searchText.isEmpty {
                                Divider()
                                    .background(Color("grey600"))
                                    .padding(.bottom, 16)
                                Text("All currencies")
                                    .font(.footnote)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color("grey600"))
                                    .textCase(.uppercase)
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