# CineScroll API (Cloudflare Worker)

Thin TMDB proxy so the **API key never ships in the iOS app**.

## Routes

The Worker mirrors TMDB v3 paths used by the app:

| App request | Proxied to |
|-------------|------------|
| `GET /movie/now_playing?page=n` | TMDB `/movie/now_playing` |
| `GET /movie/{id}` | TMDB `/movie/{id}` |
| `GET /movie/{id}/credits` | TMDB `/movie/{id}/credits` |
| `GET /search/movie?query=…&page=n` | TMDB `/search/movie` |
| `GET /` | API index (discovery JSON) |
| `GET /health` | Worker health check |

Poster/backdrop images still load from `image.tmdb.org` on the device (public CDN, no secret).

## Setup

```bash
cd worker
npm install
cp .dev.vars.example .dev.vars   # add TMDB_API_KEY for local dev
npm run dev                       # http://127.0.0.1:8787
```

## Deploy

```bash
cd worker
npx wrangler login
# First-time only: register workers.dev subdomain in the dashboard, or via API (see project README).
npx wrangler secret put TMDB_API_KEY   # TMDB v3 key — never commit this
npm run deploy
```

Production URL (deployed):

`https://cinescroll-api.cinescroll-abdofoda.workers.dev`

Set in iOS `Config/Secrets.xcconfig`:

`CINESCROLL_API_BASE_URL = https:$(SLASH)/cinescroll-api.cinescroll-abdofoda.workers.dev` (see `Secrets.xcconfig.example`)

## iOS local development

Point the app at the local Worker:

```
CINESCROLL_API_BASE_URL = "http://127.0.0.1:8787"
```

`Support/CineScroll-Info.plist` sets `NSAllowsLocalNetworking` so `http://127.0.0.1:8787` works in the Simulator. On a physical device, use `wrangler dev --ip 0.0.0.0` and your Mac’s LAN IP in `CINESCROLL_API_BASE_URL`, or deploy and use HTTPS.
