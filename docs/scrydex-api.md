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

### Query Syntax
- `q=charizard` — simple name search
- `q=name:charizard*` — wildcard name search
- `q=name:"charizard ex"*` — multi-word name with wildcard
- `q=name:charizard* number:4` — name + card number

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
