# 🧪 Mock Mode Guide - Save Your API Calls!

## Overview
Your Tilo app now has a **Mock Mode** that prevents API calls during development, saving your monthly API quota.

## How to Use Mock Mode

### 1. **Default Behavior**
- Mock mode is **ON by default** when you build the app
- No API calls are made to CurrencyAPI.com
- Uses realistic mock exchange rates for testing

### 2. **Toggle in Debug Controls**
When running in Xcode Preview or Simulator:
1. Look for the **Debug Controls** panel (bottom of screen)
2. Find the **"API Mode"** section
3. Toggle between:
   - 🧪 **Mock** (No API calls - safe for development)
   - 🌐 **Live** (Real API calls - uses your quota)

### 3. **Mock Data Included**
The mock mode includes realistic exchange rates for:
- USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, SEK, NOK
- Rates are based on typical market values
- Perfect for UI testing and development

### 4. **When to Use Each Mode**

#### 🧪 **Mock Mode (Recommended for Development)**
- ✅ Building and testing UI
- ✅ Working on new features
- ✅ Debugging layout issues
- ✅ Testing currency conversions
- ✅ **No API quota used**

#### 🌐 **Live Mode (Use Sparingly)**
- ✅ Final testing before release
- ✅ Verifying real exchange rates
- ✅ Testing with actual API responses
- ⚠️ **Uses your API quota**

## Code Implementation

### In ExchangeRateService.swift:
```swift
// Mock mode is ON by default
@Published var isMockMode: Bool = true

// Toggle between modes
func toggleMockMode() {
    isMockMode.toggle()
}

// Set mode explicitly
func setMockMode(_ enabled: Bool) {
    isMockMode = enabled
}
```

### Mock Data:
```swift
private let mockRates: [String: Double] = [
    "EUR": 0.85,    // 1 USD = 0.85 EUR
    "GBP": 0.73,    // 1 USD = 0.73 GBP
    "JPY": 110.0,   // 1 USD = 110 JPY
    "CAD": 1.25,    // 1 USD = 1.25 CAD
    "AUD": 1.35,    // 1 USD = 1.35 AUD
    "CHF": 0.92,    // 1 USD = 0.92 CHF
    "CNY": 6.45,    // 1 USD = 6.45 CNY
    "SEK": 8.5,     // 1 USD = 8.5 SEK
    "NOK": 8.8,     // 1 USD = 8.8 NOK
    "USD": 1.0      // 1 USD = 1.0 USD
]
```

## Benefits

### 💰 **Cost Savings**
- No API calls during development
- Preserve your 300 monthly requests for production testing
- No unexpected charges

### ⚡ **Faster Development**
- Instant responses (no network delays)
- Consistent data for testing
- No dependency on internet connection

### 🔧 **Better Testing**
- Predictable exchange rates for UI testing
- Easy to test edge cases
- No rate limiting issues

## Production Deployment

When you're ready to release:
1. Set `isMockMode = false` in `ExchangeRateService.swift`
2. Or use the debug controls to switch to Live mode
3. Test with real API calls
4. Deploy to App Store

## Troubleshooting

### If you see "Mock Mode" in production:
- Check that `isMockMode = false` in the service
- Verify the debug controls are not visible in production builds

### If conversions seem wrong:
- Mock rates are simplified for testing
- Real rates will be more accurate
- This is normal for development

---

**Happy coding without API limits! 🚀**
