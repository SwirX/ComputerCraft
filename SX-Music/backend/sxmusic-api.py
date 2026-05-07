# to run use: uvicorn sxmusic_api:app --host 0.0.0.0 --port 3000

from fastapi import FastAPI, HTTPException
from ytmusicapi import YTMusic
from pathlib import Path
from typing import Any
import time

CONFIG_DIR = Path.home() / ".config" / "sxmusic"
AUTH_FILE = CONFIG_DIR / "browser.json"

CACHE_TTL = 600
MAX_TRACKS = 30

app = FastAPI()

# ---------- AUTH ----------

if AUTH_FILE.exists():
    ytm = YTMusic(str(AUTH_FILE))
else:
    ytm = YTMusic()

# ---------- CACHE ----------

cache = {}

def cached(key, fetcher):
    now = time.time()

    if key in cache:
        item = cache[key]
        if item["expires"] > now:
            return item["data"]

    data = fetcher()

    cache[key] = {
        "expires": now + CACHE_TTL,
        "data": data
    }

    return data

# ---------- NORMALIZATION ----------

def normalize_track(item: dict[str, Any]):
    if not item:
        return None

    video_id = item.get("videoId")

    if not video_id:
        return None

    artists = item.get("artists", [])

    artist_name = "Unknown Artist"

    if artists and isinstance(artists, list):
        artist_name = artists[0].get("name", artist_name)

    thumbnails = []

    thumb_data = (
        item.get("thumbnails")
        or item.get("thumbnail")
        or []
    )

    for thumb in thumb_data:
        thumbnails.append({
            "url": thumb.get("url"),
            "width": thumb.get("width"),
            "height": thumb.get("height")
        })

    return {
        "id": video_id,
        "title": item.get("title") or item.get("name"),
        "artist": artist_name,
        "album": (
            item.get("album", {}) or {}
        ).get("name", "Unknown"),
        "duration": item.get("duration_seconds")
            or item.get("lengthSeconds")
            or 0,
        "thumbnails": thumbnails
    }

# ---------- ROUTES ----------

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/search")
def search(q: str):
    try:
        results = ytm.search(q, filter="songs")

        songs = []

        for item in results:
            track = normalize_track(item)

            if track:
                songs.append(track)

            if len(songs) >= MAX_TRACKS:
                break

        return songs

    except Exception as e:
        raise HTTPException(500, str(e))

@app.get("/featured")
def featured():
    try:
        def fetch():
            songs = []

            home = ytm.get_home()

            for section in home:
                for item in section.get("contents", []):

                    track = normalize_track(item)

                    if track:
                        songs.append(track)

                    if len(songs) >= MAX_TRACKS:
                        break

                if len(songs) >= MAX_TRACKS:
                    break

            return songs

        return cached("featured", fetch)

    except Exception as e:
        raise HTTPException(500, str(e))

@app.get("/related")
def related(id: str):
    try:
        def fetch():
            items = []

            watch_playlist = ytm.get_watch_playlist(
                videoId=id
            )

            # Primary source:
            tracks = watch_playlist.get("tracks", [])

            for item in tracks:
                track = normalize_track(item)

                if (
                    track
                    and track["id"] != id
                ):
                    items.append(track)

                if len(items) >= MAX_TRACKS:
                    break

            # Secondary source:
            related_browse = watch_playlist.get("related")

            if (
                len(items) < 10
                and related_browse
            ):
                related_sections = ytm.get_song_related(
                    related_browse
                )

                for section in related_sections:
                    for item in section.get("contents", []):

                        track = normalize_track(item)

                        if (
                            track
                            and track["id"] != id
                            and track not in items
                        ):
                            items.append(track)

                        if len(items) >= MAX_TRACKS:
                            break

                    if len(items) >= MAX_TRACKS:
                        break

            return items

        return cached(f"related:{id}", fetch)

    except Exception as e:
        raise HTTPException(500, str(e))

@app.get("/song")
def song(id: str):
    try:
        data = ytm.get_song(id)

        video_details = data.get("videoDetails", {})

        return {
            "id": id,
            "title": video_details.get("title"),
            "artist": video_details.get("author"),
            "duration": video_details.get("lengthSeconds"),
            "views": video_details.get("viewCount"),
            "thumbnails": video_details.get("thumbnail", {}).get("thumbnails", [])
        }

    except Exception as e:
        raise HTTPException(500, str(e))