# Local Marketplace — Changelog

## Sprint 4 — Search Engine, Messaging, Bulk Listing, Storefront UX

**Date:** April 29, 2026
**Commits:** `f47d84c` through `2ecbf11` (26 commits)

### Tier 2 Audit Fixes
- `f47d84c` — N+1 query optimization: inbox and wanted board batch-fetch profiles/messages in single queries instead of per-item
- `f47d84c` — Block user content filtering: `blockedUserIDs` set in AppState, blocked users hidden from map, inbox, and wanted board; dismiss after blocking

### Bug Fixes from Testing
- `a68217d` — Vendor go-live: pre-populate vendor row from application data (storeName, meetupAddress, categories)
- `a68217d` — New items now show immediately after creation (onDismiss reload)
- `a68217d` — Profile save fixed: proper JSON null handling + edit fields sync on appear
- `ef7c463` — Vendor profile tap opens Edit Storefront instead of Edit Profile

### Card Search Engine Overhaul
- `3de52af` — Smart number detection: handles "098", "006/165", "#098" anywhere in query
- `3de52af` — Popularity sorting: newest sets first (API-level), rarity ranking within sets (client-side), EN before JA
- `3de52af` — Page size increased to 50
- `2ce1e8c` — Wildcard number matching: "03" finds "TG03" via `number:*03`
- `c26b0f5` — Clean display names: just name + number
- `eb41748` — Set name detection: "Charizard Obsidian Flames" auto-filters by expansion
- `eb41748` — Subtype detection: "Charizard ex", "Pikachu VMAX" filter by subtypes
- `8ec77c0` — Local-first autofill: 1,025 Pokémon names embedded, instant suggestions as you type
- `0b4f826` — Partial name wildcard: "pika" → `name:pika*` (plain text only matched full words)
- `65f7a09` — Hide "No results" when suggestions are showing

### Vendor Map
- `28c24df` — Offline vendors visible on map: gray outline pin vs teal filled for active
- `28c24df` — All approved vendors with complete storefronts + geocoded address now show
- `28c24df` — VendorPreviewCard shows Live/Offline status badge

### Messaging System
- `5cecbf1` — Rich inquiry messages: visual card tiles in chat instead of plain text
  - Horizontal scrollable card tiles with image, name, condition, price
  - Tap any card tile for full-screen detail view
  - Structured JSON format (`[INQUIRY]` prefix) — backward compatible
  - Optional custom message alongside card tiles
- `526d531` — Wanted board messages use same visual card inquiry format
- `18b8079` — Distinct buy vs sell intents:
  - Buy inquiries: teal bubble, cart icon, "Wants to Buy", "List $X"
  - Sell offers: orange bubble, tag icon, "Offering to Sell", "Bid $X"
- `1299c28` — List/Bid price labels on individual card tiles
- `76c967a` — Chat timestamps: hour:minute only, no seconds
- `4de39eb` — Inbox relative time: "Just now" for <1 min, no seconds

### Bulk Listing System
- `db37034` — Create listing opens as full screen
- `ba30f57` — Create tab is a real standalone page (not a sheet/redirect hack)
- `7907ed1` — Quick-Add Queue: search → select card → set condition/price → add to queue → repeat → review → publish all
- `7907ed1` — Set Browse: browse expansions → tap cards in grid → add to queue → bulk publish
- `7907ed1` — Entry point: "+" menu with Quick Add vs Detailed Listing options
- `0c9607f` — Create tab shows Quick Add and Detailed Listing as prominent buttons
- `7a3b0ea` — Review queue uses fullScreenCover (fixes dismiss bug)
- `4a77d09` — Non-NM photo warning on publish, photo picker in review queue, inactive badge on storefront
- `10b7446` — Can't set non-NM items active without photos; condition is read-only in edit

### Storefront UX
- `a56918a` — Condition labels: `[NM]`, `[LP]`, etc. shown before card names
- `a56918a` — Long-press context menu: Edit, Mark as Sold, Delete (owner only)
- `a56918a` — New EditItemView for editing existing listings
- `a56918a` — Photo carousel in ItemDetailView with full-screen zoom on tap
- `a56918a` — Mark as Sold works for bindered and unbindered items
- `4a77d09` — Status picker: segmented Active/Inactive/Sold
- `4a77d09` — INACTIVE badge overlay on storefront cards

### Graded Card Slab Visual
- `2ecbf11` — SlabFrameView: premium slab case visual for graded cards
  - Metallic gradient border with drop shadow
  - Grading label: company name in brand color + large grade number
  - Dark inner area with centered card image
  - Brand colors: PSA red, BGS blue, CGC gold, SGC green, ACE purple, TAG orange, MNT teal, KSA indigo
  - Used in storefront cards, detail view, and binder grids

### Remaining / Future
- ❌ CSV bulk import (documented in plan, Phase 3)
- ❌ Camera scanning for card recognition (Phase 4)
- ❌ Scrydex sealed products endpoint not available (404)
- ❌ Apple Developer Program still pending
- ❌ RevenueCat production key needed (test key in place)

---

## Sprint 3 — Live Backend, Card Search, Admin, Vendor Flow, Subscriptions

**Date:** April 28, 2026
**Commits:** `9b17cf3` through `59f2485` (14 commits)

### Connected to Real Supabase Backend
- `9b17cf3` — Config.swift populated with Supabase URL and anon key; app no longer falls back to mock data
- `0e9c06f` — Fixed 3 Swift concurrency warnings (ISO8601DateFormatter `nonisolated(unsafe)`)
- Removed mock preview buttons (Preview as Buyer/Vendor/Admin) from WelcomeView

### Scrydex Card Search Fixed
- `1046afd` — Added Scrydex API key and team ID to Config.swift
- `f6a121b` — Added Japanese card support: `language_code` and `translation` fields on card models; JA cards show English translated names with `[JA]` badge
- `64b167c` — Fixed search to return both EN and JA cards by using plain text query instead of `name:` prefix; excluded TCG Pocket digital-only cards with `-expansion.is_online_only:true`
- Saved full Scrydex API docs at `docs/scrydex-api.md`

### Admin System
- `beff69f` — AdminTabView now has 6 tabs: Home, Storefront, Create, Messages, Admin, Profile (full vendor capabilities + admin panel)
- Added RLS migration `002_admin_role_policy.sql`: admins can update any profile (for promoting users)
- Ron's account (`rc400`) promoted to admin

### Vendor Signup Flow Overhaul
- `af2f8f6` — Phase 1: Removed "Skip for Now" button (application mandatory); fixed legal name bug; vendor row created immediately on application submit with `approved: false`; admin approval now updates existing vendor row instead of insert
- `5617639` — Fixed application form disappearing: vendor signup delays `isAuthenticated` until application is submitted via `pendingVendorApplication` flag and `completeVendorOnboarding()` method
- `c186a6c` — Revamped vendor application fields:
  - First Name + Last Name (separate)
  - Business Name (optional)
  - Contact Email, Phone
  - City / Region
  - What do you primarily sell?
  - How often do you attend card shows?
  - Social media & online presence
  - Why do you want to sell on Local?
  - Terms of Service agreement toggle
  - Auto-timestamp on submission
- Added info note on signup page when "Sell" is selected: warns vendor application follows, takes 5–10 min

### RevenueCat Subscription Integration
- `fb8cab9` — Full RevenueCat SDK integration (SPM package: `purchases-ios-spm`)
  - **SubscriptionService.swift**: RevenueCat wrapper — configure, identify, logout, refresh, entitlement checking for "Local Marketplace Vendor"
  - **VendorPaywallView.swift**: presents RevenueCat PaywallView with purchase/restore callbacks
  - **SubscriptionStatusView.swift**: subscription status display + Customer Center for managing subscriptions
  - **LocalMarketplaceApp.swift**: RevenueCat configured at app launch
  - **AppState.swift**: RevenueCat identify/logout on all auth events
  - **VendorDashboardViewModel.swift**: go-live requires active subscription; "Subscribe to go live" message
  - **VendorActiveCard.swift**: Go Live button shows paywall when subscription needed
- `cfe3d3f`, `18723f8`, `32946f8` — Build fixes: encoder reference, RevenueCatUI v5 modifier-style callbacks, missing import

### RLS Policy Fixes
- `59f2485` — Added `003_admin_vendor_policy.sql`: admins can update any vendor row (fixes approval silently failing due to RLS)

### Remaining from Audit (Tier 2 — High)
- ❌ Search not wired to filtering on home map
- ❌ Vendor expiry client-only (backend never clears is_active)
- ❌ N+1 queries in inbox and wanted board
- ❌ Block user placeholder
- ❌ Delete account incomplete
- ❌ Notification toggle not wired

---

## Sprint 2 — Storefront Persistence, Report Submission, Error Handling

### `b173693` — Sprint 2: Storefront persistence, report submission, and error handling fixes
**Date:** April 23, 2026
**Files changed:** 7 (StorefrontViewModel.swift, VendorDashboardViewModel.swift, ReportSheetView.swift, CreateItemView.swift, InquiryCartView.swift, VendorApplicationFormView.swift, MessagesViewModel.swift)

**What was fixed:**

1. **Storefront management now persists to Supabase** (Critical — from audit)
   - All 8 operations: bulkMarkSold, bulkToggleHide, bulkHide, bulkDelete, bulkMoveToBinder, toggleBinderHidden, moveBinder (reorder), deleteBinder
   - Optimistic local updates kept for responsiveness
   - Failures trigger error toast + reload from server

2. **Report submission actually works** (Critical — from audit)
   - ReportSheetView creates a real Report object and calls SupabaseService.submitReport()
   - Only dismisses on success, shows error on failure

3. **Error handling on critical paths** (High — from audit)
   - VendorDashboardViewModel: go-live/offline reverts local state on failure
   - CreateItemView: image upload failures stop the save, only dismisses on success
   - InquiryCartView: only clears cart on successful send
   - VendorApplicationFormView: only completes on successful submission

**Audit issues resolved:**
- ✅ StorefrontViewModel bulk actions local-only (Critical)
- ✅ ReportSheetView never calls submitReport (Critical)
- ✅ VendorDashboardViewModel go-live/offline try? (High)
- ✅ CreateItemView image upload + dismiss on failure (High)
- ✅ InquiryCartView clears cart on failure (High)
- ✅ VendorApplicationFormView silent failure (High)

**Still open from audit:**
- ❌ Search not wired to filtering (High) — Tier 2
- ❌ Vendor expiry client-only (High) — Tier 2
- ❌ N+1 queries in inbox and wanted board (High) — Tier 2
- ❌ Block user placeholder (High) — Tier 2
- ❌ Delete account incomplete (High) — Tier 2
- ❌ Vendor application drops legal name (High) — Tier 2
- ❌ Notification toggle not wired (High) — Tier 2
- ❌ Various medium/low issues — Post-launch

---

## Sprint 1 — Session Persistence + First-Contact Messaging

### `84eaf9a` — Sprint 1: Session persistence + first-contact messaging fix
**Date:** April 23, 2026
**Files changed:** 6 (SupabaseClient.swift, SupabaseService.swift, AppState.swift, LocalMarketplaceApp.swift, MessagesViewModel.swift, ChatView.swift)

**What was fixed:**

1. **Session persistence** (Critical — from audit)
   - Auth tokens (access, refresh, user ID) now saved to UserDefaults on sign in/sign up
   - Tokens cleared on sign out
   - `restoreSession()` added to AppState — rehydrates user and vendor state on app launch
   - `fetchCurrentUser()` added to SupabaseService
   - Loading overlay shown during session restore (no login screen flash)

2. **First-contact messaging** (Critical — from audit)
   - ChatView creates a real conversation via `startConversation()` before sending the first message
   - `activeConversationID` state tracks the real ID for the session
   - Safety net in `sendMessage()` catches any "new-" prefixed IDs and auto-creates conversation
   - Subsequent messages reuse the real conversation ID

**Audit issues resolved:**
- ✅ `Utilities/AppState.swift:79-87` and `Services/SupabaseClient.swift:145-152` — auth state in-memory only (High)
- ✅ `Views/Messages/ChatView.swift:108` — fake conversation ID on first contact (Critical)

**Still open from audit:**
- ❌ Storefront management doesn't persist (Critical) — Sprint 2
- ❌ Reporting is fake (Critical) — Sprint 2
- ❌ Silent error handling on critical paths (High) — Sprint 2
- ❌ Search not wired to filtering (High) — Tier 2
- ❌ Vendor expiry client-only (High) — Tier 2
- ❌ N+1 queries in inbox and wanted board (High) — Tier 2
- ❌ Block user placeholder (High) — Tier 2
- ❌ Delete account incomplete (High) — Tier 2
- ❌ Vendor application drops legal name (High) — Tier 2
- ❌ Notification toggle not wired (High) — Tier 2
- ❌ Various medium/low issues — Post-launch

---

## Prior Commits (pre-Rotom)

### `493b8ff` — New version from Rork
**Date:** Pre-April 2026
Original Rork export of the full app.

### `8278145` — Initial commit
**Date:** Pre-April 2026
Repository creation.
