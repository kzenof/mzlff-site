#!/usr/bin/env python3
"""Fetch mzlff releases from Yandex Music API and write data/releases.json."""

import json
import urllib.error
import urllib.request
from pathlib import Path

ARTIST_ID = "6236891"
ARTIST_NAME = "mzlff"
API_BASE = "https://api.music.yandex.net"
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "releases.json"
PAGE_SIZE = 50


def fetch_albums(page: int) -> dict:
    url = (
        f"{API_BASE}/artists/{ARTIST_ID}/direct-albums"
        f"?sort-by=year&page={page}&page-size={PAGE_SIZE}"
    )
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "mzlff-site/1.0 (fan site; github actions)",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def cover_url(cover_uri: str | None) -> str | None:
    if not cover_uri:
        return None
    return "https://" + cover_uri.replace("%%", "400x400")


def release_type(album: dict) -> str:
    if album.get("type") == "single":
        return "single"
    return "album"


def featuring(album: dict) -> str | None:
    names = [
        artist["name"]
        for artist in album.get("artists", [])
        if str(artist.get("id")) != ARTIST_ID
        and artist.get("name", "").lower() != ARTIST_NAME
    ]
    return ", ".join(names) if names else None


def map_album(album: dict) -> dict:
    item = {
        "title": album.get("title", "Без названия"),
        "year": album.get("year") or int(album.get("releaseDate", "0000")[:4]),
        "type": release_type(album),
        "cover": cover_url(album.get("coverUri")),
        "link": f"https://music.yandex.ru/album/{album['id']}",
        "yandexId": album["id"],
    }
    feat = featuring(album)
    if feat:
        item["featuring"] = feat
    return item


def load_all_releases() -> list[dict]:
    releases: list[dict] = []
    page = 0

    while True:
        payload = fetch_albums(page)
        albums = payload.get("result", {}).get("albums", [])
        if not albums:
            break

        releases.extend(map_album(album) for album in albums)

        pager = payload.get("result", {}).get("pager", {})
        total = pager.get("total", len(releases))
        page += 1
        if page * PAGE_SIZE >= total:
            break

    releases.sort(key=lambda item: (item["year"], item.get("yandexId", 0)), reverse=True)
    return releases


def main() -> None:
    try:
        releases = load_all_releases()
    except urllib.error.URLError as error:
        raise SystemExit(f"Yandex Music API error: {error}") from error

    if not releases:
        raise SystemExit("No releases returned from Yandex Music API")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(
            {
                "source": "yandex-music",
                "artistId": ARTIST_ID,
                "updatedAutomatically": True,
                "releases": releases,
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(releases)} releases to {OUTPUT}")


if __name__ == "__main__":
    main()
