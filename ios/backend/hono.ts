import { Hono } from "hono";
import { cors } from "hono/cors";
// v3 - redeploy after hono install

const app = new Hono();

app.use("*", cors());

app.get("/", (c) => {
  return c.json({ status: "ok", message: "API is running" });
});

app.get("/cards/search", async (c) => {
  const query = c.req.query("q")?.trim();
  const page = c.req.query("page") || "1";
  const pageSize = c.req.query("pageSize") || "30";

  console.log(`[cards/search] query="${query}" page=${page} pageSize=${pageSize}`);

  if (!query || query.length < 2) {
    console.log("[cards/search] query too short, returning empty");
    return c.json({ data: [], totalCount: 0 });
  }

  const luceneQuery = buildLuceneQuery(query);
  console.log(`[cards/search] lucene="${luceneQuery}"`);

  const url = new URL("https://api.pokemontcg.io/v2/cards");
  url.searchParams.set("q", luceneQuery);
  url.searchParams.set("page", page);
  url.searchParams.set("pageSize", String(Math.min(Number(pageSize), 40)));
  url.searchParams.set("orderBy", "-set.releaseDate");
  url.searchParams.set("select", "id,name,number,set,subtypes,rarity,images");

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  const apiKey = process.env.POKEMON_TCG_API_KEY;
  if (apiKey) {
    headers["X-Api-Key"] = apiKey;
  } else {
    console.warn("[cards/search] POKEMON_TCG_API_KEY not set - requests may be rate limited");
  }

  console.log(`[cards/search] fetching: ${url.toString()}`);

  try {
    const resp = await fetch(url.toString(), { headers });

    console.log(`[cards/search] upstream status=${resp.status}`);

    if (resp.status === 429) {
      console.warn("[cards/search] rate limited by upstream");
      return c.json({ error: "Rate limited. Try again shortly." }, 429);
    }

    if (!resp.ok) {
      const body = await resp.text();
      console.error(`[cards/search] upstream error status=${resp.status} body=${body.slice(0, 500)}`);
      return c.json({ error: "Upstream API error", status: resp.status }, 502);
    }

    const json = (await resp.json()) as any;
    const cards = (json.data || []).map((card: any) => ({
      id: card.id || "",
      name: card.name || "",
      number: card.number || "",
      setName: card.set?.name || "",
      setId: card.set?.id || "",
      releaseDate: card.set?.releaseDate || "",
      subtypes: card.subtypes || [],
      rarity: card.rarity || "",
      imageSmall: card.images?.small || "",
      imageLarge: card.images?.large || "",
    }));

    console.log(`[cards/search] returning ${cards.length} cards (total=${json.totalCount})`);
    return c.json({ data: cards, totalCount: json.totalCount || cards.length });
  } catch (err: any) {
    console.error("[cards/search] upstream fetch error:", err?.message, err?.stack);
    return c.json({ error: "Failed to reach card database" }, 502);
  }
});

function buildLuceneQuery(input: string): string {
  const normalized = input.replace(/\s+/g, " ").trim().toLowerCase();
  const tokens = normalized.split(" ");

  if (tokens.length === 0) return `name:"${input}*"`;

  let nameParts: string[] = [];
  let numberPart: string | null = null;

  const lastToken = tokens[tokens.length - 1];
  if (tokens.length > 1 && /\d/.test(lastToken)) {
    numberPart = lastToken.includes("/")
      ? lastToken.split("/")[0]
      : lastToken.replace(/^0+/, "") || lastToken;
    nameParts = tokens.slice(0, -1);
  } else {
    nameParts = tokens;
  }

  const name = nameParts.join(" ");
  const escapedName = name.replace(/([+\-!(){}[\]^"~*?:\\])/g, "\\$1");

  let q = "";
  if (escapedName.includes(" ")) {
    q = `name:"${escapedName}*"`;
  } else {
    q = `name:${escapedName}*`;
  }

  if (numberPart) {
    q += ` number:${numberPart}`;
  }

  return q;
}

export default app;
