# Scrydex API Reference (Local Marketplace)

## Authentication
- Headers: `X-Api-Key` and `X-Team-ID` on every request
- All requests over HTTPS
- Team ID: `localmarketplace`

## Base URL
```
https://api.scrydex.com/pokemon/v1/cards
```

### Language Scoping
- Default (no lang): returns both English AND Japanese cards
- English only: `/pokemon/v1/en/cards`
- Japanese only: `/pokemon/v1/ja/cards`

## Search Cards
```
GET /pokemon/v1/cards?q=<query>&pageSize=<n>&page=<n>
```

### Query Syntax (Lucene-like)

**Plain text vs field search:**
- `q=charizard` — plain text, searches across ALL fields including translations (returns EN + JA)
- `q=name:charizard*` — field-specific, only matches literal `name` field (EN only, JA cards have Japanese names)
- **Use plain text for general search, field syntax only when combining with number/filters**

**Keyword matching:**
- `name:charizard` — contains "charizard" in name field
- `name:"venusaur v"` — phrase match
- `name:charizard subtypes:mega` — AND multiple conditions
- `name:charizard (subtypes:mega OR subtypes:vmax)` — OR conditions

**Exclusions:**
- `-types:water` — exclude water types
- `-expansion.is_online_only:true` — exclude digital-only (TCG Pocket) cards

**Wildcards:**
- `name:char*` — starts with "char"
- `name:char*der` — starts with "char", ends with "der"

**Exact match:**
- `!name:charizard` — name is EXACTLY "charizard"

**Range searches:**
- `national_pokedex_numbers:[1 TO 151]` — inclusive range
- `hp:[150 TO *]` — HP >= 150
- `hp:{100 TO 200}` — exclusive range

**Nested fields:**
- `expansion.id:sm1` — filter by expansion
- `attacks.name:Hypnosis` — cards with specific attack
- `legalities.standard:banned` — legality filter

**Sorting:**
- `?orderBy=number` — sort by number
- `?orderBy=name,-number` — name ASC, number DESC

### Pagination
- `pageSize` — number of results per page (default 100)
- `page` — page number (1-indexed)
- Response includes: `page`, `page_size`, `count`, `total_count`
- Note: `limit` does NOT work — use `pageSize`

### Response Fields (select param is silently ignored — full objects always returned)
Key fields on card object:
- `id` — unique card ID
- `name` — card name (in card's language)
- `language` — "English" or "Japanese"
- `language_code` — "EN" or "JA"
- `number` / `printed_number`
- `rarity` / `rarity_code`
- `supertype` / `subtypes` / `types`
- `hp`, `attacks`, `abilities`, `weaknesses`, `resistances`
- `artist`, `flavor_text`, `regulation_mark`
- `images` — array of `{ type, small, medium, large }`
- `expansion` — `{ id, name, series, total, printed_total, language, language_code, release_date, is_online_only }`
- `variants` — array of `{ name, images, prices }`

### Japanese Cards
- Japanese card fields (`name`, `supertype`, `subtypes`, `types`, attacks, etc.) are in Japanese
- `translation` field contains `translation.en` object with English equivalents
- If a Japanese field is missing, it falls back to the English value
- Example: JA card `name: "リザードン"` → `translation.en.name: "Charizard"`

### Image URLs
- Format: `https://images.scrydex.com/pokemon/<card-id>/<size>`
- Sizes: `small`, `medium`, `large`
- Images are on `images` array, typically one entry with `type: "front"`

## Best Practices
1. **Cache images locally** — store URLs in DB, optionally download to own CDN
2. **Cache API responses** — card metadata/expansions: cache for hours/days; prices: cache 24h
3. **Never hardcode image URLs** — always use URLs from API response
4. **Use fallback placeholder** for missing images
5. **Rate limits apply** — unauthenticated requests have heavily reduced limits
6. **Copyrights** — images belong to respective holders, provide attribution

## Other Endpoints
- `GET /pokemon/v1/cards/:id` — get single card
- `GET /pokemon/v1/expansions` — list expansions
- `GET /pokemon/v1/expansions/:id` — get single expansion
- `GET /pokemon/v1/sealed_products` — sealed products
- `GET /pokemon/v1/listings` — marketplace listings
- `GET /pokemon/v1/price_history/:id` — price history for a card
