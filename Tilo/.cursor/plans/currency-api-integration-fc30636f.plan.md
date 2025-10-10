<!-- fc30636f-0d7c-4d8b-a9c9-3c3d4a48ddf2 57e78cb8-64ba-4110-a978-f370203e3d25 -->
# Currency API Integration Plan

## Overview
Replace dummy currency data with real exchange rates from currencyapi.com, add 170+ currencies, and implement historical data for charts with smart caching strategy.

## Implementation Steps

### 1. API Service Setup
**File**: `Features/Home/Services/ExchangeRateService.swift`
- Create networking service for currencyapi.com
- Implement authentication with API key
- Add request/response models for current and historical rates
- Build caching layer (6h for current rates, 24h for historical)
- Add error handling for network failures

### 2. Expand Currency List
**File**: `Features/Currency/Models/Currency.swift`
- Replace 6 mock currencies with 170+ real currencies
- Fetch currency list from API or use comprehensive static list
- Keep flag emojis for UI
- Update frequently used currencies

### 3. Update Currency Cards
**Files**: 
- `Features/Home/Components/CurrencyCard.swift`
- `Features/Home/Views/HomeView.swift`

- Replace hardcoded exchange rates with live API data
- Update conversion calculations to use real rates
- Add loading states while fetching rates
- Add error states with cached data fallback
- Show last update timestamp

### 4. Integrate Historical Data for Charts
**File**: `Features/Home/Views/CurrencyChartView.swift`
- Replace dummy chart data with real historical rates
- Fetch 30-day historical data from API
- Implement caching for historical data (24h)
- Update chart when currency pair changes
- Handle loading and error states

### 5. Update Currency Selector
**File**: `Features/Currency/Views/CurrencySelector.swift`
- Update to show all 170+ currencies
- Improve search functionality
- Keep glass effect UI
- Sort alphabetically

### 6. Caching Strategy
- **Current rates**: Cache for 6 hours
- **Historical data**: Cache for 24 hours
- **Currency list**: Cache indefinitely
- Use UserDefaults or lightweight local storage
- Add cache invalidation logic

### 7. Error Handling & UX
- Show cached data when API fails
- Display "Last updated: X hours ago" 
- Add retry mechanism for failed requests
- Graceful degradation (show cached even if stale)
- Loading indicators during API calls

## Key Technical Decisions
- **API**: currencyapi.com (300 free requests/month, 170+ currencies)
- **Caching**: 6h current, 24h historical (reduces API usage by ~90%)
- **Storage**: UserDefaults for cache (simple, lightweight)
- **API Key**: Hardcoded in service (acceptable for portfolio app)
- **Error Strategy**: Show cached data with warning banner

## Files to Modify
1. `Features/Home/Services/ExchangeRateService.swift` - Main API service
2. `Features/Currency/Models/Currency.swift` - Currency list expansion
3. `Features/Home/Components/CurrencyCard.swift` - Live rate display
4. `Features/Home/Views/HomeView.swift` - Integration with service
5. `Features/Home/Views/CurrencyChartView.swift` - Historical data
6. `Features/Currency/Views/CurrencySelector.swift` - Full currency list

## Expected Outcome
- Real-time currency conversion with 170+ currencies
- Historical charts showing actual market data
- Smart caching keeping API usage under 300 requests/month
- Graceful error handling with cached data fallback
- Fast, responsive UI with loading states


### To-dos

- [ ] Create currencyapi.com service with networking, authentication, and caching
- [ ] Add 170+ currencies to Currency model
- [ ] Replace hardcoded rates with live API data in CurrencyCard and HomeView
- [ ] Integrate historical data API for CurrencyChartView
- [ ] Update CurrencySelector to show all currencies with search
- [ ] Build caching layer with 6h/24h expiration logic
- [ ] Add loading states, error handling, and cache fallback
- [ ] Test API integration, caching, and error scenarios