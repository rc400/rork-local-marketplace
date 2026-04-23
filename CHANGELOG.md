# Local Marketplace — Changelog

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
