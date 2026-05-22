#!/usr/bin/env python3
"""Regenerates PreviewMovieCatalog.swift from TMDB movie/{id} responses.

Usage:
  export TMDB_API_KEY=your_key
  python3 scripts/fetch_preview_catalog.py
"""
import json
import os
import subprocess
import sys
from pathlib import Path

ENTRIES = [
    (101, 603),
    (102, 27205),
    (103, 157336),
    (104, 155),
    (105, 496243),
    (106, 438631),
    (107, 872585),
    (108, 545611),
    (109, 76341),
    (110, 569094),
]


def esc(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", " ")


def fetch_movie(tmdb_id: int, api_key: str) -> dict:
    url = f"https://api.themoviedb.org/3/movie/{tmdb_id}?api_key={api_key}"
    result = subprocess.run(
        ["curl", "-sf", url],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def main() -> None:
    api_key = os.environ.get("TMDB_API_KEY")
    if not api_key:
        print("Set TMDB_API_KEY before running.", file=sys.stderr)
        sys.exit(1)

    lines = [
        "import Foundation",
        "",
        "/// Static preview catalog with TMDB poster/backdrop paths (sourced from TMDB API).",
        "enum PreviewMovieCatalog {",
        "    static let movies: [Movie] = [",
    ]

    for preview_id, tmdb_id in ENTRIES:
        data = fetch_movie(tmdb_id, api_key)
        lines.append(
            f"""        Movie(
            id: {preview_id},
            title: "{esc(data['title'])}",
            overview: "{esc(data['overview'])}",
            posterPath: "{esc(data.get('poster_path') or '')}",
            backdropPath: "{esc(data.get('backdrop_path') or '')}",
            releaseDate: "{data.get('release_date') or ''}",
            voteAverage: {data.get('vote_average', 0)}
        ),"""
        )

    lines.append("    ]")
    lines.append("}")

    root = Path(__file__).resolve().parents[1]
    out = root / "CineScroll/App/PreviewMovieCatalog.swift"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
