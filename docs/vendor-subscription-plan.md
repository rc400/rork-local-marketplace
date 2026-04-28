# Vendor Subscription Plan

## Pricing
- Monthly: $9.99/mo (auto-renew)
- Yearly: $99.99/year (auto-renew)
- Free trial: 1 week
- Apple Small Business Program: YES (15% commission)
- Payment processor: RevenueCat (wrapping StoreKit)

## Promo Codes
- Use Apple's built-in Offer Codes (generated in App Store Connect)
- Up to 150,000 codes per quarter
- Each code grants X months free, then auto-renews at full price

## Implementation Phases

### Phase 1: Fix Vendor Signup Flow (no payment yet)
- Remove "Skip for Now" from VendorApplicationFormView
- Fix legal name bug (save legalName to application)
- Create `vendors` row immediately on application submit (with approved: false)
- After submit → dismiss to home (full app access, can't go live)
- Update admin approval to just set vendors.approved = true (row already exists)

### Phase 2: RevenueCat Integration
- Add RevenueCat SDK (via Swift Package Manager)
- Configure with API key
- Initialize on app launch
- Identify user with Supabase user ID
- Add subscription status check to vendor model

### Phase 3: Subscription Paywall
- New SubscriptionPaywallView showing monthly/yearly options + free trial
- Triggered when approved vendor tries to go live without active subscription
- RevenueCat handles purchase flow, receipt validation, auto-renew
- On successful purchase → allow go-live

### Phase 4: Subscription Management
- Show subscription status in vendor settings/profile
- Allow managing subscription (links to Apple subscription management)
- Handle expiry: vendor goes offline when subscription lapses
- Webhook from RevenueCat → Supabase to sync subscription status server-side

## Go-Live Check (Updated)
```
canGoLive = vendor.approved 
    && vendor.hasRequiredFields 
    && hasActiveItems 
    && hasActiveSubscription
```

## Database Changes
- `vendor_subscriptions` table: vendor_id, status, plan_type, started_at, expires_at, 
  revenuecat_id, is_trial, created_at, updated_at
- RevenueCat webhooks update this table server-side

## Manual Setup Required (Ron)
1. Apple Developer Program account ($99/year)
2. App Store Connect → create subscription group + products
3. RevenueCat account → create project → get API key
4. Apply for Apple Small Business Program
