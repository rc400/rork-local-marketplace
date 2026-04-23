# Local Marketplace iOS Audit

Note: the requested destination `/Users/ron/.openclaw/workspace/projects/local-marketplace/AUDIT-REPORT.md` is outside the writable sandbox for this session. The report is saved at `/Users/ron/.openclaw/workspace/projects/local-marketplace/ios/AUDIT-REPORT.md`.

## 1. File Structure Map

```text
LocalMarketplace/
├── Config.swift — Build-generated environment config wrapper for Supabase, Scrydex, and leftover Rork variables.
├── ContentView.swift — Root authenticated/unauthenticated switch plus buyer/vendor/admin tab shells.
├── LocalMarketplaceApp.swift — App entry point that injects `AppState` into the environment.
├── Models/
│   ├── Binder.swift — Binder model for grouping storefront items.
│   ├── Block.swift — Block relationship model between two users.
│   ├── CardShow.swift — Limited-time event model with single-day and multi-day helpers.
│   ├── Conversation.swift — Conversation model with derived other-participant helper.
│   ├── Enums.swift — Shared enums for roles, item state, grading, reports, and vendor activity durations.
│   ├── EventDaySchedule.swift — Per-day schedule model for multi-day events.
│   ├── Follow.swift — Follow relationship model between buyer and vendor.
│   ├── InquiryCartItem.swift — Local cart wrapper for inquiry quantities.
│   ├── MarketplaceItem.swift — Storefront item model with listing completeness helpers.
│   ├── Message.swift — Chat message model.
│   ├── NotificationPrefs.swift — Notification preference model for push enablement.
│   ├── Report.swift — Moderation report model.
│   ├── TCGCard.swift — Pokemon card search result model from Scrydex.
│   ├── UserProfile.swift — User profile model stored in Supabase `profiles`.
│   ├── Vendor.swift — Vendor storefront profile model with approval and activity helpers.
│   ├── VendorApplication.swift — Vendor application model for admin review.
│   ├── WantedCard.swift — Wanted-board listing model with location and grading metadata.
│   └── WantedCardStats.swift — Aggregated wanted-card stats model that is currently unused.
├── Services/
│   ├── LocationService.swift — CoreLocation and MapKit wrapper for permission, geocoding, and address search.
│   ├── MockDataService.swift — In-memory mock dataset used whenever Supabase config is empty.
│   ├── PokemonTCGService.swift — Scrydex-backed Pokémon card search service with debouncing and cache.
│   ├── SupabaseClient.swift — Low-level REST/auth/storage client for Supabase.
│   └── SupabaseService.swift — Higher-level backend facade for profiles, vendors, items, messages, reports, and wanted cards.
├── Utilities/
│   └── AppState.swift — Global auth/session/toast state and mock-mode switching logic.
├── ViewModels/
│   ├── AdminViewModel.swift — Admin dashboard state for applications, reports, and user search.
│   ├── CardShowViewModel.swift — Event loading, creation, attendance, spotlighting, and editing logic.
│   ├── HomeViewModel.swift — Home map/list state, filtering, and map camera control.
│   ├── MessagesViewModel.swift — Conversations, message loading, message sending, and inquiry flow state.
│   ├── ProfileViewModel.swift — Profile editing, avatar upload, follows, and notification preference state.
│   ├── StorefrontViewModel.swift — Storefront loading, inquiry cart, binders, items, and bulk-actions state.
│   ├── VendorDashboardViewModel.swift — Vendor live/offline status and duration handling.
│   └── WantedBoardViewModel.swift — Wanted-board feed, personal board, radius, persistence, and direct messaging logic.
├── Views/
│   ├── Admin/
│   │   ├── AdminDashboardView.swift — Segmented admin shell for applications, reports, and user management.
│   │   ├── ReportsQueueView.swift — Admin list of open reports with dismiss/disable actions.
│   │   ├── UserManagementView.swift — Admin user search and promote-to-admin screen.
│   │   └── VendorApplicationsQueueView.swift — Admin vendor-application review screen.
│   ├── Auth/
│   │   ├── LoginView.swift — Email/password sign-in form.
│   │   ├── SignUpView.swift — Account creation flow with buyer/vendor role selection.
│   │   ├── VendorApplicationFormView.swift — Post-signup vendor application form.
│   │   └── WelcomeView.swift — Landing screen with auth entry points and mock preview buttons.
│   ├── CardShows/
│   │   ├── CardShowDetailView.swift — Full event detail screen with organizer and attendee management.
│   │   ├── CardShowPreviewCard.swift — Bottom-sheet event preview launched from the map/list.
│   │   ├── CreateCardShowView.swift — Event creation form with address autocomplete and image upload.
│   │   ├── EditCardShowView.swift — Event editing form for existing shows.
│   │   └── MyEventsView.swift — Vendor-owned event list with create and edit entry points.
│   ├── Components/
│   │   ├── CategoryBadge.swift — Reusable badge and verified icon components.
│   │   ├── ImagePickerView.swift — Reusable photo picker with circular/rectangular preview modes.
│   │   ├── ReportSheetView.swift — Report form sheet UI.
│   │   └── ToastView.swift — Global transient toast banner.
│   ├── Home/
│   │   ├── HomeMapView.swift — Buyer/vendor home screen with map, list, search, and event/vendor previews.
│   │   ├── VendorActiveCard.swift — Vendor “Go Live / Go Offline” status card.
│   │   └── VendorPreviewCard.swift — Vendor preview sheet with storefront and message entry points.
│   ├── Messages/
│   │   ├── ChatView.swift — Chat thread screen and composer.
│   │   ├── InboxView.swift — Conversations list screen.
│   │   └── InquiryCartView.swift — Inquiry cart review and send screen.
│   ├── Profile/
│   │   ├── EditProfileView.swift — Profile edit form with avatar picker.
│   │   ├── ProfileView.swift — Main profile screen for buyer/vendor/admin.
│   │   └── SettingsView.swift — Settings, account actions, and placeholder legal pages.
│   ├── Storefront/
│   │   ├── BinderManagementView.swift — Binder list with reorder, hide, and delete UI.
│   │   ├── CreateItemView.swift — New item form for singles, slabs, sealed products, and accessories.
│   │   ├── EditBinderSheet.swift — Binder rename sheet.
│   │   ├── EditStorefrontView.swift — Storefront edit form with address autocomplete and image upload.
│   │   ├── FullBinderView.swift — Full-screen binder grid with bulk actions and inquiry actions.
│   │   ├── ItemDetailView.swift — Item detail screen with optional add-to-inquiry action.
│   │   ├── NewBinderSheet.swift — New binder creation sheet.
│   │   ├── SoldItemsView.swift — Sold-items archive grid.
│   │   ├── TCGCardSearchView.swift — Pokémon card search picker used during item creation.
│   │   └── VendorStorefrontView.swift — Main storefront page with binders, items, sold preview, and owner actions.
│   └── WantedBoard/
│       ├── AddEditWantedCardView.swift — Wanted-card create/edit form plus embedded card search picker.
│       ├── MyBoardView.swift — Five-slot personal wanted-board editor.
│       ├── RadiusPickerView.swift — Radius picker with map circle preview.
│       ├── WantedBoardView.swift — Wanted-board feed, search, help overlay, and sheet routing.
│       ├── WantedCardDetailSheet.swift — Wanted-card detail and direct message sheet.
│       └── WantedCardRow.swift — Row view for wanted-board feed results.
```

## 2. Architecture Overview

The app is nominally MVVM, but it is only partially disciplined. SwiftUI `View`s own `@State` view-model instances, and almost every view model is an `@Observable @MainActor` class. `AppState` is the one real global container; it is injected through `.environment(appState)` and stores auth state, current user/vendor, toast state, and mock-mode decisions.

Views usually talk directly to view models for screen state and user actions. View models then call the singleton `SupabaseService`, which itself wraps the singleton `SupabaseClient` for raw REST/auth/storage calls. Some views also bypass their view model and call `SupabaseService` directly for uploads, which breaks the layering and makes error handling inconsistent.

State management is a mix of:
- Global `AppState` for authentication, current user/vendor, mock mode, and toasts.
- Per-screen `@State private var viewModel` objects for feature state.
- Local `@State` in forms for transient UI fields.

Navigation is all SwiftUI-driven:
- `TabView` for role-based top-level navigation.
- `NavigationStack` / `NavigationLink` / `navigationDestination` for pushes.
- `.sheet` and `.fullScreenCover` for modal flows.

Authentication is handled in `AppState` via `SupabaseService.signIn` / `signUp` / `signOut`. There is no persisted session restoration on launch; auth tokens live only in memory inside `SupabaseClient`, so the user will effectively start logged out after app restart. If Supabase config is empty, the entire app falls back to `MockDataService`.

## 3. Feature Inventory

### Authentication and onboarding
- `WelcomeView`, `LoginView`, and `SignUpView` implement basic buyer/vendor/admin entry.
- Real Supabase signup/signin code exists, but there is no session restore, no email validation, and vendor signup relies on a follow-up form that can be skipped.
- Mock preview mode is fully wired and appears intentionally left in the production UI when env vars are missing.

### Profile and account
- Profile viewing and basic editing work in code: display name, bio, avatar upload, sign out, delete account.
- Followed vendors and notification preferences are loaded by `ProfileViewModel`.
- Settings are incomplete: the notification toggle is not wired to persistence, and legal pages are placeholders.

### Home map and vendor discovery
- Home map/list loads active vendors and visible card shows, supports map annotations and detail previews.
- Vendor activity status card is implemented for vendors.
- Search is only partially implemented: address geocoding works on submit, but the local search field is not wired to `HomeViewModel.searchText`, so list filtering does not actually happen.

### Storefront browsing and vendor storefront management
- Storefront browsing is largely implemented: cover/profile image, bio, categories, meetup location, binders, unbindered items, item detail, sold preview.
- Owner-facing storefront editing and item creation are implemented.
- Inquiry cart flow is implemented.
- Binder management and bulk item actions are only locally implemented; most of those changes do not persist to Supabase.

### Messaging
- Inbox and loading existing conversations/messages are implemented.
- Sending messages inside an existing conversation is implemented.
- Starting a brand-new conversation from storefront/vendor preview is broken because `ChatView` does not create a conversation before sending.
- Blocking and reporting from chat/storefront are UI-only placeholders.

### Wanted board
- Wanted-board feed, search, radius filtering, my-board slots, create/edit/delete listing flow, and direct message flow are all present.
- Real backend persistence exists for wanted cards.
- Mock-mode support is incomplete: `loadFeed` and `loadMyBoard` immediately return in mock mode, so the feature is effectively unavailable in preview builds.

### Limited-time events / card shows
- Event creation, editing, detail views, attendance toggling, spotlighting, and vendor “My Events” listing are implemented.
- Image upload and address autocomplete are implemented.
- Organizer/attendee vendor resolution is incomplete in live mode because detail/preview screens mostly rely on `CardShowViewModel.vendorProfile(for:)`, which only returns the current vendor or mock data.

### Admin
- Applications queue, reports queue, and user search/promote screens are present.
- Supabase-backed load and moderation actions exist.
- Some admin actions are optimistic or silently ignore backend failures.

## 4. Issues Found

### Critical

- `Views/Messages/ChatView.swift:108` — `sendMessage(conversationID: conversationID ?? "new-\(otherUserID)")` sends to a fake conversation ID when no thread exists. First-contact messaging from vendor preview/storefront will either fail backend constraints or create orphaned messages. Severity: Critical.
- `Views/Components/ReportSheetView.swift:56` — report submission never calls `SupabaseService.submitReport`; it only shows a toast and dismisses. Reporting is a fake success path everywhere it is used. Severity: Critical.
- `ViewModels/StorefrontViewModel.swift:227`, `250`, `282`, `288`, `300`, `308`, `317` — bulk mark sold/hide/delete/move, binder hidden toggle, binder reorder, and binder delete all mutate local arrays only. On refresh, server state will revert, so core inventory-management flows are non-persistent. Severity: Critical.

### High

- `Views/Profile/SettingsView.swift:14-19` — the push notification toggle is purely local state; it never reads `ProfileViewModel.notificationPrefs` and never calls `toggleNotifications`. The screen implies persistence that does not exist. Severity: High.
- `Views/Auth/VendorApplicationFormView.swift:98-121` — the form collects `legalName` but drops it when creating `VendorApplication`; that data is never persisted. Severity: High.
- `Views/Auth/VendorApplicationFormView.swift:114-117` — vendor application submission is wrapped in `try?`, then the UI always shows “Application submitted!” and completes. Backend failure is silent. Severity: High.
- `Views/Home/HomeMapView.swift:10`, `55`, `117`, `135` and `ViewModels/HomeViewModel.swift:56-70` — the screen uses local `searchText` for `.searchable`, but vendor/card-show filtering reads `viewModel.searchText`, which is never updated. Search only geocodes on submit and does not filter map/list content. Severity: High.
- `ViewModels/CardShowViewModel.swift:215-223`, `225-233`; `Views/CardShows/CardShowPreviewCard.swift:10-12`; `Views/CardShows/CardShowDetailView.swift:12-14`, `344-411` — live event preview/detail relies on `vendorProfile(for:)`, which only returns current vendor or mock data. Organizer and attendee vendor rows are therefore missing or incomplete against real backend data. Severity: High.
- `Views/CardShows/CreateCardShowView.swift:210-214` and `Views/CardShows/EditCardShowView.swift:229-233` — image uploads use `try?`; failures are suppressed and the event still saves/dismisses with missing media. Severity: High.
- `Views/Auth/VendorApplicationFormView.swift:65-67` — “Skip for Now” lets a vendor finish signup without submitting an application, but the app still created a vendor-role account path. That undermines the approval model and creates ambiguous backend state. Severity: High.
- `ViewModels/VendorDashboardViewModel.swift:72-74`, `84-86` — go-live/offline updates ignore Supabase errors with `try?`, so UI state can claim a vendor is live when the backend never updated. Severity: High.
- `ViewModels/VendorDashboardViewModel.swift:89-95` and `ViewModels/HomeViewModel.swift:48-53` — expiration is corrected only on the client. Backend `vendors.is_active` never gets cleared when a vendor expires, so stale active vendors can remain visible to other clients. Severity: High.
- `Services/SupabaseService.swift:123-125` — `fetchActiveVendors()` filters on `is_active` but not `active_until`, so expired vendors stay active unless a specific client happens to run its own expiry logic. Severity: High.
- `Services/SupabaseService.swift:186-206` — conversations are loaded with an N+1 pattern: two conversation queries, then one profile query plus one full message query per conversation. This will degrade badly as inbox size grows. Severity: High.
- `Services/SupabaseService.swift:290-298` — wanted-board feed performs an extra profile lookup per card. This is another N+1 backend pattern and will scale poorly. Severity: High.
- `Views/Storefront/CreateItemView.swift:43-46`, `325-333`, `355-360` — accessories advertise a required photo, but `isValid` does not enforce it; upload failures are swallowed; the app can save active accessory listings with no image. Severity: High.
- `Views/Storefront/CreateItemView.swift:336-387` — after `await viewModel.saveItem(item)`, the view always dismisses even if the save failed and `StorefrontViewModel` only showed an error toast. Severity: High.
- `Views/Storefront/VendorStorefrontView.swift:146-153` and `Views/Messages/ChatView.swift:85-92` — block vendor/user actions are placeholders that only show a toast and never call `SupabaseService.blockUser`. Severity: High.
- `Views/Messages/InquiryCartView.swift:52-60` — inquiry cart clears and dismisses immediately after `sendInquiry`, even though the send path can fail. There is no success check before deleting the local cart. Severity: High.
- `Utilities/AppState.swift:94-97` — delete-account flow only soft-deletes the `profiles` row, then signs out. It does not remove auth credentials or related data such as vendor, items, messages, follows, wanted cards, or reports. The UI promises permanent deletion, but the implementation is not close to that. Severity: High.
- `Utilities/AppState.swift:79-87` and `Services/SupabaseClient.swift:145-152` — auth state is in-memory only. There is no session restore on launch, so users are effectively logged out every cold start. Severity: High.
- `Services/SupabaseService.swift:14-35` — signup tries to `signIn` immediately after `.userCreated`. On projects requiring email confirmation, that path can fail even though signup succeeded. Severity: High.
- `Services/SupabaseClient.swift:224` — requests use `Authorization: Bearer \(accessToken ?? anonKey)` even when unauthenticated. Using the anon key as a bearer token is not the standard Supabase auth model and can cause confusing RLS/auth behavior. Severity: High.

### Medium

- `Services/SupabaseClient.swift:194` — `URL(string: "\(baseURL)/storage/v1/object/\(bucket)/\(path)")!` force-unwraps a URL built from config and path input. Bad config or unsafe characters would crash the app. Severity: Medium.
- `Utilities/AppState.swift:51` — `currentUser!.id` is force-unwrapped during sign-in even though the value comes from an async path that can fail. It is currently guarded by surrounding logic, but the unwrap is unnecessary runtime risk. Severity: Medium.
- `Services/MockDataService.swift:118-120` — mock multi-day schedules force-unwrap calendar date generation. Low-probability crash path, but still a direct force unwrap. Severity: Medium.
- `Services/SupabaseService.swift:97-110` — approving an application inserts a new `vendors` row with blank required profile fields and no duplicate handling. Re-approvals or partially existing vendor rows can fail. Severity: Medium.
- `Services/SupabaseService.swift:287` — `searchUsers(query:)` interpolates raw user input into an `ilike` filter string. Special characters can break the request or broaden matching unexpectedly because there is no escaping. Severity: Medium.
- `Views/CardShows/CreateCardShowView.swift:187-200` and `Views/CardShows/EditCardShowView.swift:207-220` — multi-day schedule preservation uses `Date.description` as the dictionary key. That is locale/timezone/string-format dependent and brittle for matching dates. Severity: Medium.
- `ViewModels/CardShowViewModel.swift:96-145` — attendance/spotlight/removal updates are optimistic and use background `Task { try? ... }`. Failures leave the UI diverged from the backend with no rollback. Severity: Medium.
- `ViewModels/WantedBoardViewModel.swift:50-66` — mock mode is not implemented for feed or personal board; both methods return without data. Preview builds expose the feature but it appears empty/broken. Severity: Medium.
- `Views/Profile/EditProfileView.swift:80-84` — the sheet dismisses after `saveProfile()` regardless of whether saving actually failed. Severity: Medium.
- `Views/Storefront/EditStorefrontView.swift:127-145` — in mock mode, choosing profile/cover images explicitly sets the vendor image URLs to `nil`, so preview editing loses images instead of simulating them. Severity: Medium.
- `Views/Storefront/ItemDetailView.swift:142-176` — singles with required damage photos still render the TCG database image first; uploaded front/back condition photos are not viewable from item detail, which makes “damage photo required” only partially useful. Severity: Medium.
- `Views/WantedBoard/AddEditWantedCardView.swift:12` — `cardSearchText` is declared but unused. Severity: Medium.
- `Views/WantedBoard/AddEditWantedCardView.swift:125` and `Views/Storefront/TCGCardSearchView.swift:6` — both flows use the shared singleton `PokemonTCGService`, so stale results/error state can leak between screens. Severity: Medium.
- `Views/WantedBoard/MyBoardView.swift:6` — `locationService` is passed in but never used. Severity: Medium.
- `Views/Home/VendorActiveCard.swift:63` — the “Go Live” button is disabled when the storefront is incomplete but active items exist, which prevents the user from tapping it to see why activation is blocked. Severity: Medium.
- `Views/Auth/SignUpView.swift:17-19` and `Views/Auth/LoginView.swift:56-78` — auth forms only validate non-empty fields and password length; there is no email-format validation, username validation, or duplicate-name feedback. Severity: Medium.
- `Services/SupabaseService.swift:319-325` — notification preference upsert treats every insert failure as “row exists, do update”. Real backend errors are hidden. Severity: Medium.
- `Utilities/AppState.swift:39-45` — mock login from the sign-in form always logs in as the first buyer account, regardless of entered credentials. Severity: Medium.
- `Views/Home/HomeMapView.swift:64-66` — the screen loads card shows through both `HomeViewModel` and a separate `CardShowViewModel`, but only the home view model’s data is rendered. The second load is redundant and confusing. Severity: Medium.

### Low

- `Config.swift:7-15` — leftover `EXPO_PUBLIC_RORK_*`, `TEAM_ID`, and `TOOLKIT_URL` variables are still generated but unused by the app. Severity: Low.
- `Views/Auth/WelcomeView.swift:75-77` — mock preview buttons are exposed from the main welcome screen whenever env vars are missing. This is useful for development but is a Rork/export artifact if the intent is a production build. Severity: Low.
- `Views/Profile/SettingsView.swift:99` — legal pages are explicit placeholders. Severity: Low.
- `Views/Profile/SettingsView.swift`, `Views/Home/HomeMapView.swift`, `Views/Storefront/VendorStorefrontView.swift`, and most other views — strings are hardcoded throughout the UI; there is no localization strategy. Severity: Low.
- `Views/*` across many files — numerous icon-only buttons lack explicit accessibility labels or hints (`ellipsis.circle`, `questionmark.circle`, `pencil.circle`, quick-add buttons). Severity: Low.
- `Services/LocationService.swift:70` — `didFailWithError` is empty, so location failures disappear silently. Severity: Low.
- `Views/Components/CategoryBadge.swift:30-35` — `VerifiedBadge` is always shown on vendors without any verification source of truth. Severity: Low.
- `Views/Admin/ReportsQueueView.swift:15-18` and related admin screens — IDs are shown directly rather than resolved display names, which makes moderation UI harder to use. Severity: Low.

## 5. Dependencies & External Services

### Supabase

Used through `SupabaseClient` and `SupabaseService`.

Auth endpoints:
- `/auth/v1/signup`
- `/auth/v1/token?grant_type=password`
- `/auth/v1/logout`

REST tables referenced:
- `profiles`
- `vendor_applications`
- `vendors`
- `binders`
- `items`
- `card_shows`
- `conversations`
- `messages`
- `follows`
- `blocks`
- `reports`
- `wanted_cards`
- `notification_prefs`

Storage buckets referenced:
- `avatars`
- `events`
- `vendors`
- `items`

Notable hardcoded/backend details:
- Base URL comes from `Config.EXPO_PUBLIC_SUPABASE_URL`.
- Anon key comes from `Config.EXPO_PUBLIC_SUPABASE_ANON_KEY`.
- Images are exposed through `publicURL(bucket:path:)`, so uploads are treated as public objects.

### Scrydex / Pokémon card search

The app does not call the official Pokémon TCG API directly. It calls:
- `https://api.scrydex.com/pokemon/v1/cards`

Headers:
- `X-Api-Key` from `Config.EXPO_PUBLIC_SCRYDEX_API_KEY`
- `X-Team-ID` from `Config.EXPO_PUBLIC_SCRYDEX_TEAM_ID`

### Apple frameworks / device services

- `MapKit` for map rendering, `MKLocalSearch`, and `MKLocalSearchCompleter`.
- `CoreLocation` for user location and geocoding.
- `PhotosUI` for image picking.
- `UIKit` only for JPEG compression in `ProfileViewModel`.

### Leftover Rork/export artifacts

Still present in config:
- `EXPO_PUBLIC_RORK_API_BASE_URL`
- `EXPO_PUBLIC_RORK_AUTH_URL`
- `EXPO_PUBLIC_PROJECT_ID`
- `EXPO_PUBLIC_TEAM_ID`
- `EXPO_PUBLIC_TOOLKIT_URL`

These are not referenced by the native Swift code that was audited.

## 6. Recommended Restructuring

Only the changes that would materially help this codebase:

1. Split the backend layer into feature repositories.
   Replace the single `SupabaseService` god object with feature-focused repositories such as `AuthRepository`, `StorefrontRepository`, `MessagingRepository`, `WantedBoardRepository`, and `CardShowRepository`. That will reduce coupling and make testing/fixing each area tractable.

2. Separate real and mock implementations behind protocols.
   Right now mock mode is scattered through views, view models, and `AppState`. Introduce protocols plus `Live...Repository` / `Mock...Repository` implementations so the feature code stops branching on `isMockMode` everywhere.

3. Make `AppState` an actual session manager.
   Session restore, sign-out/delete reliability, and role hydration belong in a dedicated auth/session component. Keep `AppState` thin and move token persistence and current-user bootstrap into one place.

4. Move uploads and backend writes out of SwiftUI views.
   Views like `CreateItemView`, `CreateCardShowView`, `EditCardShowView`, and `EditStorefrontView` call `SupabaseService` directly. Push that logic into view models or repositories so failures can be handled consistently and the UI stops dismissing on failed saves.

5. Break up the oversized feature views.
   `VendorStorefrontView`, `CreateItemView`, `CardShowDetailView`, and `HomeMapView` are carrying too much logic. Each should be split into smaller subviews with focused responsibilities: header, list/grid sections, action bars, and modal routers.

6. Add a persistence boundary for owner actions.
   Binder management, bulk item actions, and vendor status changes need dedicated backend methods instead of local array mutation. This is the most important structural change on the storefront side because several owner workflows currently only “work” until the next refresh.

7. Introduce a lightweight query/join strategy for Supabase reads.
   The current N+1 inbox and wanted-board reads will become a performance problem quickly. Repository-level joined queries or batched fetches should replace per-row follow-up requests.

