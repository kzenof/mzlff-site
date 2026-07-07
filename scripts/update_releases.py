#!/usr/bin/env python3
"""Fetch artist releases from Yandex Music API into {slug}/data/ and {slug}/js/."""

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
API_BASE = "https://api.music.yandex.net"
PAGE_SIZE = 50

ARTISTS = {
    "mzlff": {
        "yandex_id": "6236891",
        "names": {"mzlff", "mazellovvv"},
        "display_name": "MZLFF",
        "yandex_url": "https://music.yandex.ru/artist/6236891",
    },
    "ilyukha-rep": {
        "yandex_id": "25098870",
        "names": {"илюха реп", "ilyukha rep"},
        "display_name": "Илюха реп",
        "yandex_url": "https://music.yandex.ru/artist/25098870",
    },
}


def fetch_albums(artist_id, page):
    url = (
        f"{API_BASE}/artists/{artist_id}/direct-albums"
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


def fetch_albums_with_retry(artist_id, page, attempts=3):
    last_error = None
    for attempt in range(1, attempts + 1):
        try:
            return fetch_albums(artist_id, page)
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


def featuring(album, artist_id, artist_names):
    names = [
        artist["name"]
        for artist in album.get("artists", [])
        if str(artist.get("id")) != artist_id
        and artist.get("name", "").lower() not in artist_names
    ]
    return ", ".join(names) if names else None


def map_album(album, artist_id, artist_names):
    release_date = album.get("releaseDate") or "0000-01-01"
    item = {
        "title": album.get("title", "Без названия"),
        "year": album.get("year") or int(release_date[:4]),
        "type": release_type(album),
        "cover": cover_url(album.get("coverUri")),
        "link": f"https://music.yandex.ru/album/{album['id']}",
        "yandexId": album["id"],
    }
    feat = featuring(album, artist_id, artist_names)
    if feat:
        item["featuring"] = feat
    return item


def load_all_releases(artist_id, artist_names):
    releases = []
    page = 0
    normalized_names = {name.lower() for name in artist_names}

    while True:
        payload = fetch_albums_with_retry(artist_id, page)
        albums = payload.get("result", {}).get("albums", [])
        if not albums:
            break

        releases.extend(map_album(album, artist_id, normalized_names) for album in albums)

        pager = payload.get("result", {}).get("pager", {})
        total = pager.get("total", len(releases))
        page += 1
        if page * PAGE_SIZE >= total:
            break

    releases.sort(key=lambda item: (item["year"], item.get("yandexId", 0)), reverse=True)
    return releases


def write_outputs(slug, config, releases):
    payload = {
        "source": "yandex-music",
        "slug": slug,
        "artistId": config["yandex_id"],
        "displayName": config["display_name"],
        "yandexUrl": config["yandex_url"],
        "updatedAutomatically": True,
        "updatedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "releases": releases,
    }

    artist_dir = ROOT / slug
    json_path = artist_dir / "data" / "releases.json"
    js_path = artist_dir / "js" / "releases-data.js"

    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(releases)} releases to {json_path}")

    js_path.parent.mkdir(parents=True, exist_ok=True)
    js_path.write_text(
        f"// Auto-generated by scripts/update_releases.py ({slug})\n"
        "window.RELEASES_DATA = "
        + json.dumps(payload, ensure_ascii=False)
        + ";\n",
        encoding="utf-8",
    )
    print(f"Wrote JS bundle to {js_path}")


def main():
    parser = argparse.ArgumentParser(description="Update releases for an artist")
    parser.add_argument(
        "artist",
        choices=sorted(ARTISTS.keys()),
        help="Artist folder slug: mzlff or ilyukha-rep",
    )
    args = parser.parse_args()
    config = ARTISTS[args.artist]

    print(f"Updating {config['display_name']} (ID {config['yandex_id']})...")
    releases = load_all_releases(config["yandex_id"], config["names"])

    if not releases:
        raise SystemExit("No releases returned from Yandex Music API")

    write_outputs(args.artist, config, releases)


if __name__ == "__main__":
    main()
