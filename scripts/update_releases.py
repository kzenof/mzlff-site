#!/usr/bin/env python3
"""Fetch mzlff releases from Yandex Music API and write data/releases.json."""

import json
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ARTIST_ID = "6236891"
ARTIST_NAME = "mzlff"
API_BASE = "https://api.music.yandex.net"
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "releases.json"
PAGE_SIZE = 50


def fetch_albums(page):
    url = (
        f"{API_BASE}/artists/{ARTIST_ID}/direct-albums"
        f"?sort-by=year&page={page}&page-size={PAGE_SIZE}"
    )
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "Accept-Language": "ru-RU,ru;q=0.9",
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            ),
            "Origin": "https://music.yandex.ru",
            "Referer": "https://music.yandex.ru/",
        },
    )
    with urllib.request.urlopen(request, timeout=45) as response:
        return json.load(response)


def fetch_albums_with_retry(page, attempts=3):
    last_error = None
    for attempt in range(1, attempts + 1):
        try:
            return fetch_albums(page)
        except urllib.error.HTTPError as error:
            body = error.read().decode("utf-8", errors="replace")[:300]
            last_error = f"HTTP {error.code} {error.reason}: {body}"
            print(f"Attempt {attempt}/{attempts} failed: {last_error}", file=sys.stderr)
        except urllib.error.URLError as error:
            last_error = str(error.reason or error)
            print(f"Attempt {attempt}/{attempts} failed: {last_error}", file=sys.stderr)
        if attempt < attempts:
            time.sleep(3 * attempt)
    raise SystemExit(f"Yandex Music API error after {attempts} attempts: {last_error}")


def cover_url(cover_uri):
    if not cover_uri:
        return None
    return "https://" + cover_uri.replace("%%", "400x400")


def release_type(album):
    if album.get("type") == "single":
        return "single"
    return "album"


def featuring(album):
    names = [
        artist["name"]
        for artist in album.get("artists", [])
        if str(artist.get("id")) != ARTIST_ID
        and artist.get("name", "").lower() != ARTIST_NAME
    ]
    return ", ".join(names) if names else None


def map_album(album):
    release_date = album.get("releaseDate") or "0000-01-01"
    item = {
        "title": album.get("title", "Без названия"),
        "year": album.get("year") or int(release_date[:4]),
        "type": release_type(album),
        "cover": cover_url(album.get("coverUri")),
        "link": f"https://music.yandex.ru/album/{album['id']}",
        "yandexId": album["id"],
    }
    feat = featuring(album)
    if feat:
        item["featuring"] = feat
    return item


def load_all_releases():
    releases = []
    page = 0

    while True:
        payload = fetch_albums_with_retry(page)
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


def main():
    print(f"Python {sys.version}")
    print(f"Output: {OUTPUT}")

    releases = load_all_releases()

    if not releases:
        raise SystemExit("No releases returned from Yandex Music API")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(
        json.dumps(
            {
                "source": "yandex-music",
                "artistId": ARTIST_ID,
                "updatedAutomatically": True,
                "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
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
