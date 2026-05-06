# Card Search Engine — Implementation Plan

## What's Already Done ✅

| Feature | Status |
|---------|--------|
| Basic name search (plain text, crosses translations) | ✅ Done |
| Number detection anywhere in query | ✅ Done |
| Wildcard number matching (03 → TG03) | ✅ Done |
| Handles "098", "006/165", "#098" formats | ✅ Done |
| Debounced search (400ms) | ✅ Done |
| In-memory cache by query | ✅ Done |
| Sorted by newest set first (API-level) | ✅ Done |
| Client-side rarity ranking within same set | ✅ Done |
| English cards ranked before Japanese | ✅ Done |
| Excludes TCG Pocket digital-only cards | ✅ Done |
| Page size 50 | ✅ Done |
| Clean display name (name + number only) | ✅ Done |
| Set name shown as secondary text | ✅ Done |

---

## Phase 1 — Query Intelligence (Next)

These improvements make the search smarter at understanding what the user typed.

### 1A. Set Name/Abbreviation Detection
**Problem:** Searching "Charizard Obsidian Flames" treats "Obsidian" and "Flames" as part of the card name. The search should detect known set names and filter by expansion.

**Solution:**
- Fetch the expansion list from Scrydex (`GET /pokemon/v1/expansions`) once on app launch, cache it
- Store as `[ExpansionInfo]` with id, name, abbreviation
- When tokenizing a search, check if any consecutive tokens match a known set name (or abbreviation)
- If matched: pull those tokens out, search with `expansion.name:"<set>"` or `expansion.id:<id>`
- Example: "Charizard Obsidian Flames" → `charizard expansion.name:"Obsidian Flames" -expansion.is_online_only:true`

**Files:** `PokemonTCGService.swift` (expansion cache + query builder), new `ExpansionInfo` model or inline struct

### 1B. Rarity/Type Keyword Detection
**Problem:** Users might search "Charizard ex" or "Pikachu VMAX" — the "ex" or "VMAX" is a subtype, not part of the name.

**Solution:**
- Detect common TCG suffixes: ex, EX, GX, V, VMAX, VSTAR, BREAK, LV.X, Prime, Legend
- When detected: use `subtypes:<suffix>` filter alongside the name
- Example: "Charizard VMAX" → `charizard subtypes:vmax -expansion.is_online_only:true`
- Be careful: "ex" appears in card names too (Rayquaza ex). Only extract it if it's the LAST token and matches exactly (case-insensitive).

**Files:** `PokemonTCGService.swift` (query builder)

---

## Phase 2 — Search UX Enhancements

These are UI-level improvements that make the search feel more polished.

### 2A. Filter Chips (Post-Search Refinement)
**What:** After results load, show horizontal scrollable filter chips above the results list.

**Filters:**
- **Set** — extract unique set names from results, show as chips. Tapping one filters results to that set.
- **Rarity** — group rarities into buckets: Common, Uncommon, Rare, Holo Rare, Ultra Rare+, Illustration Rare+
- **Language** — EN / JA toggle if results contain both

**Implementation:**
- All client-side filtering on the already-fetched results array
- No additional API calls needed
- Chips appear in a horizontal ScrollView between search bar and results

**Files:** `TCGCardSearchView.swift` (UI), `PokemonTCGService.swift` (add filtered results computed property)

### 2B. Sort Options
**What:** A sort button (↕ icon) in the toolbar that shows a menu with:
- **Newest First** (default — by release date descending)
- **Oldest First** (release date ascending)
- **Name A-Z**
- **Number Order** (by collector number within set)
- **Rarity** (highest rarity first)

**Implementation:**
- Add `SortOption` enum to `PokemonTCGService`
- `sortedResults` computed property that re-sorts `searchResults` based on selected option
- Persist last selected sort option in `UserDefaults`

**Files:** `PokemonTCGService.swift`, `TCGCardSearchView.swift`

### 2C. Recent Searches
**What:** When the search field is empty, show a "Recent Searches" list below (last 10 queries).

**Implementation:**
- Save search queries to `UserDefaults` array on successful search
- Cap at 10, newest first
- Tapping a recent search fills the search bar and triggers search
- "Clear" button to wipe history

**Files:** `TCGCardSearchView.swift`, small helper or inline in `PokemonTCGService`

### 2D. Set Browser
**What:** A "Browse by Set" entry point (button or tab) that shows all sets grouped by series, newest first. Tapping a set shows all cards in that set.

**Implementation:**
- Uses the expansion cache from Phase 1A
- New `SetBrowserView.swift` — list of expansions grouped by series
- Tapping a set calls `searchCards` with query `expansion.id:<id>`
- Could reuse existing `TCGCardSearchView` results list

**Files:** New `SetBrowserView.swift`, `PokemonTCGService.swift` (fetch expansions method)

---

## Phase 3 — Advanced (Future)

### 3A. Autocomplete / Card Name Suggestions
**What:** As the user types, show a dropdown of suggested card names before hitting the API.

**Options:**
- **Lightweight:** Cache card names from previous searches. Build a local name set over time.
- **Full:** Download Scrydex bulk card name list (if available) or Pokémon TCG API bulk data. Store locally in a SQLite/JSON file.
- Show top 5 matching names as tappable suggestions above the keyboard.

### 3B. Fuzzy Matching / Typo Tolerance
**What:** "Charzard" should suggest "Charizard". "Pikichu" → "Pikachu".

**Options:**
- Client-side: Levenshtein distance matching against cached card names
- Or use Scrydex wildcard: `char*ard` — but this requires knowing where the typo is

**Recommendation:** Combine with 3A — autocomplete naturally fixes typos because users select from suggestions.

### 3C. Price Data Integration
**What:** Show card market price alongside search results. Useful for vendors deciding what to list.

**Implementation:** Scrydex includes `variants[].prices` in card data. Parse and display as a small price badge on each result row.

---

## Priority Order

| Priority | Item | Effort | Impact |
|----------|------|--------|--------|
| 1 | 2C. Recent Searches | Small | High — immediate UX win |
| 2 | 2A. Filter Chips | Medium | High — lets users refine results fast |
| 3 | 1A. Set Name Detection | Medium | Medium — smarter queries |
| 4 | 2B. Sort Options | Small | Medium — user control |
| 5 | 1B. Subtype Detection | Small | Medium — "Charizard ex" works better |
| 6 | 2D. Set Browser | Medium | Medium — browsing vs searching |
| 7 | 3A. Autocomplete | Large | High — but needs data source |
| 8 | 3C. Price Data | Small | Nice-to-have |
| 9 | 3B. Fuzzy Matching | Large | Nice-to-have (autocomplete covers most cases) |

---

*Plan created April 29, 2026. Current search engine baseline: commits through c26b0f5.*

---

## Future: CSV Bulk Import

**Priority:** Phase 3 (after Quick-Add Queue and Set Browse are done)

**Format:** Simple CSV with columns:
- `name` — card name (required)
- `set` — set name or abbreviation (optional, helps disambiguation)
- `number` — collector number (optional)
- `condition` — NM/LP/MP/HP/DMG (default: NM)
- `price` — price in CAD (required)
- `quantity` — default 1
- `binder` — binder name (optional, creates if doesn't exist)

**Flow:**
1. Vendor uploads .csv file (from Files app or share sheet)
2. App parses and matches each row against Scrydex for card data + images
3. Shows match results — green (matched), yellow (ambiguous, pick one), red (not found)
4. Vendor reviews/corrects matches
5. Bulk create all matched items

**Use cases:**
- Migrating inventory from spreadsheet
- Importing from another platform
- Power users who prefer spreadsheet workflow
