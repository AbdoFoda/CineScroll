/**
 * CineScroll TMDB proxy — keeps the API key on the server.
 * Forwards GET requests under `/movie/*` and `/search/*` to TMDB v3.
 */

const TMDB_ORIGIN = "https://api.themoviedb.org/3";
const ALLOWED_PREFIXES = ["/movie/", "/search/"] as const;

export interface Env {
  TMDB_API_KEY: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (url.pathname === "/" || url.pathname === "") {
      return Response.json({
        name: "cinescroll-api",
        status: "ok",
        endpoints: [
          "GET /health",
          "GET /movie/now_playing?page=1",
          "GET /movie/{id}",
          "GET /movie/{id}/credits",
          "GET /search/movie?query=…&page=1",
        ],
      });
    }

    if (url.pathname === "/health") {
      return Response.json({ status: "ok" });
    }

    if (request.method !== "GET") {
      return jsonError("Method not allowed", 405);
    }

    if (!env.TMDB_API_KEY) {
      return jsonError("Server misconfigured: TMDB_API_KEY secret missing", 500);
    }

    if (!isAllowedPath(url.pathname)) {
      return jsonError("Not found", 404);
    }

    const upstream = new URL(TMDB_ORIGIN + url.pathname);
    upstream.search = url.search;
    upstream.searchParams.set("api_key", env.TMDB_API_KEY);

    const upstreamResponse = await fetch(upstream.toString(), {
      method: "GET",
      headers: {
        Accept: "application/json",
      },
    });

    return new Response(upstreamResponse.body, {
      status: upstreamResponse.status,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Cache-Control": upstreamResponse.headers.get("Cache-Control") ?? "public, max-age=60",
      },
    });
  },
};

function isAllowedPath(pathname: string): boolean {
  return ALLOWED_PREFIXES.some((prefix) => pathname.startsWith(prefix));
}

function jsonError(message: string, status: number): Response {
  return Response.json({ error: message }, { status });
}
