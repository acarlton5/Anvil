#!/usr/bin/env python3
"""
Constellation — Anvil's game library daemon.

Scans mounted USB/SD drives for game folders with cartridge.json metadata,
fetches missing artwork from SteamGridDB, and outputs a JSON game library
that the QML UI consumes.

Usage:
    constellation.py --scan          Print JSON library to stdout and exit
    constellation.py --fetch-art     Fetch missing artwork from SteamGridDB
    constellation.py --scan --fetch-art  Do both
"""

import argparse
import json
import os
import sys
import re
import urllib.request
import urllib.error
import urllib.parse
from pathlib import Path

# Where to look for mounted game drives
MEDIA_ROOTS = ["/run/media"]
GAMES_DIR_NAME = "Games"

# SteamGridDB API
SGDB_API_BASE = "https://www.steamgriddb.com/api/v2"
SGDB_API_KEY = os.environ.get("STEAMGRIDDB_API_KEY", "")
STEAM_SEARCH_API = "https://store.steampowered.com/api/storesearch/"
STEAM_CDN_BASE = "https://cdn.cloudflare.steamstatic.com/steam/apps"
STEAM_SEARCH_ALIASES = {
    "blind box shop simulator": "Blind Box Shop Simulator",
    "blueys quest for the gold pen": "Bluey's Quest For The Gold Pen",
    "bowling alley simulator": "Bowling Alley Simulator",
    "cellar keeper": "Cellar Keeper",
    "doraemon story of seasons fotgk": "DORAEMON STORY OF SEASONS Friends of the Great Kingdom",
    "hello kitty and sanrio friends racing": "Hello Kitty and Sanrio Friends Racing",
    "librarian tidy up the arcane library": "Librarian Tidy Up the Arcane Library",
    "pac man ce 2": "PAC-MAN Championship Edition 2",
    "rayman origins": "Rayman Origins",
}

# Artwork filenames we store in each game folder
ARTWORK_MAP = {
    "hero":  "hero.jpg",
    "grid":  "grid.png",
    "logo":  "logo.png",
}


def find_game_drives():
    """Find all mounted drives that contain a Games/ directory."""
    drives = []
    for root in MEDIA_ROOTS:
        if not os.path.isdir(root):
            continue
        for user_dir in os.listdir(root):
            user_path = os.path.join(root, user_dir)
            if not os.path.isdir(user_path):
                continue
            for drive in os.listdir(user_path):
                games_path = os.path.join(user_path, drive, GAMES_DIR_NAME)
                if os.path.isdir(games_path):
                    drives.append(games_path)
    return drives


def scan_games(drives):
    """Scan all game directories and return a list of game dicts."""
    games = []
    for games_root in drives:
        drive_root = os.path.dirname(games_root)  # e.g. /run/media/morph/44E1-4292
        for game_folder in sorted(os.listdir(games_root)):
            game_path = os.path.join(games_root, game_folder)
            if not os.path.isdir(game_path):
                continue

            cartridge_file = os.path.join(game_path, "cartridge.json")
            if not os.path.isfile(cartridge_file):
                # Auto-generate a stub cartridge.json
                stub = generate_cartridge_stub(game_folder, game_path, drive_root)
                try:
                    with open(cartridge_file, "w") as f:
                        json.dump(stub, f, indent=2)
                    print(f"[constellation] Generated cartridge.json for {game_folder}",
                          file=sys.stderr)
                except OSError as e:
                    print(f"[constellation] Cannot write stub for {game_folder}: {e}",
                          file=sys.stderr)
                    continue

            try:
                with open(cartridge_file) as f:
                    cartridge = json.load(f)
            except (json.JSONDecodeError, OSError) as e:
                print(f"[constellation] Bad cartridge.json in {game_folder}: {e}",
                      file=sys.stderr)
                continue

            game = build_game_entry(cartridge, game_path, drive_root)
            games.append(game)

    return games


def generate_cartridge_stub(folder_name, game_path, drive_root):
    """Generate a minimal cartridge.json by scanning for a .exe file."""
    display_name = folder_name.replace("_", " ").replace(".", " ")
    # Try to find an .exe
    exe_candidates = []
    for root, dirs, files in os.walk(game_path):
        for f in files:
            if f.lower().endswith(".exe") and "unins" not in f.lower() and "setup" not in f.lower():
                exe_candidates.append(os.path.join(root, f))

    # Pick the deepest .exe (usually the actual game binary)
    exe_path = ""
    if exe_candidates:
        exe_candidates.sort(key=lambda p: len(p), reverse=True)
        # Make relative to drive root
        exe_path = os.path.relpath(exe_candidates[0], drive_root)

    return {
        "name": display_name,
        "exe_path": exe_path,
        "start_dir": os.path.dirname(exe_path) if exe_path else "",
        "launch_options": 'WINEDLLOVERRIDES="steam_api64=n,b" %command%',
        "tags": ["Uncategorized"],
    }


def build_game_entry(cartridge, game_path, drive_root):
    """Build the JSON entry the QML UI expects from a cartridge.json."""
    name = cartridge.get("name", os.path.basename(game_path))
    exe_path = cartridge.get("exe_path", "")
    launch_options = cartridge.get("launch_options", "")
    proton = cartridge.get("proton_version", "Proton Experimental")
    tags = cartridge.get("tags", [])
    sgdb_id = cartridge.get("steamgriddb_id", None)
    steam_appid = cartridge.get("steam_appid", None)

    # Resolve absolute exe path from drive-relative path
    abs_exe = os.path.join(drive_root, exe_path) if exe_path else ""

    # Strip %command% placeholder for anvil-proton-run
    clean_options = launch_options.replace("%command%", "").strip()

    # Build the launch command for anvil-proton-run
    launch_cmd = ""
    if abs_exe:
        launch_cmd = (
            f"anvil-proton-run '{name}' '{proton}' '{abs_exe}' {clean_options}"
        )

    # Check for artwork
    artwork_dir = os.path.join(game_path, "artwork")
    hero = find_artwork(game_path, artwork_dir, [
        "hero.jpg",
        "library_hero.jpg",
        "header.jpg",
        "capsule_616x353.jpg",
    ])
    grid = find_artwork(game_path, artwork_dir, [
        "grid.png",
        "library_600x900.jpg",
        "library_600x900.png",
        "capsule_616x353.jpg",
        "capsule_231x87.jpg",
        "header.jpg",
    ])
    logo = find_artwork(game_path, artwork_dir, ["logo.png"])

    return {
        "name": name,
        "path": game_path,
        "launch_command": launch_cmd,
        "proton": proton,
        "tags": tags,
        "hero": hero or "",
        "grid": grid or "",
        "logo": logo or "",
        "steamgriddb_id": str(sgdb_id) if sgdb_id else "",
        "steam_appid": str(steam_appid) if steam_appid else "",
        "dummy": False,
    }


def find_artwork(game_path, artwork_dir, candidates):
    """Look for artwork in both the game root and artwork/ subfolder."""
    for candidate in candidates:
        # Check artwork/ subfolder first
        path = os.path.join(artwork_dir, candidate)
        if os.path.isfile(path):
            return path
        # Check game root
        path = os.path.join(game_path, candidate)
        if os.path.isfile(path):
            return path
    return None


# --- SteamGridDB Artwork Fetching ---

def sgdb_request(endpoint):
    """Make an authenticated GET request to SteamGridDB API."""
    if not SGDB_API_KEY:
        return None
    url = f"{SGDB_API_BASE}{endpoint}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {SGDB_API_KEY}"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode())
    except (urllib.error.URLError, json.JSONDecodeError, OSError) as e:
        print(f"[constellation] SGDB API error: {e}", file=sys.stderr)
        return None


def sgdb_search_game(name):
    """Search SteamGridDB for a game by name, return the game ID."""
    clean_name = re.sub(r'[^\w\s]', '', name).strip()
    encoded = urllib.parse.quote(clean_name)
    result = sgdb_request(f"/search/autocomplete/{encoded}")
    if result and result.get("success") and result.get("data"):
        return result["data"][0]["id"]
    return None


def sgdb_fetch_image(game_id, art_type):
    """Fetch the best image URL for a given art type (grids, heroes, logos)."""
    result = sgdb_request(f"/{art_type}/game/{game_id}")
    if result and result.get("success") and result.get("data"):
        return result["data"][0]["url"]
    return None


def download_image(url, dest_path):
    """Download an image to disk."""
    try:
        os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        urllib.request.urlretrieve(url, dest_path)
        print(f"[constellation] Downloaded: {dest_path}", file=sys.stderr)
        return True
    except (urllib.error.URLError, OSError) as e:
        print(f"[constellation] Download failed for {url}: {e}", file=sys.stderr)
        return False


def url_exists(url):
    """Return True when a public asset URL exists."""
    req = urllib.request.Request(url, method="HEAD")
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return 200 <= resp.status < 400
    except (urllib.error.URLError, OSError):
        return False


def normalize_title(name):
    """Normalize a game title for public store searches."""
    cleaned = re.sub(r"[_\.]+", " ", name)
    cleaned = re.sub(r"\b(v\d+(?:\.\d+)*)\b", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\b(multiplayer|complete|deluxe|ultimate|edition|repack)\b", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned


def steam_search_query(name):
    """Return the best public Steam search query for a cartridge title."""
    normalized = normalize_title(name)
    key = re.sub(r"[^\w\s]", "", normalized).lower()
    key = re.sub(r"\s+", " ", key).strip()
    return STEAM_SEARCH_ALIASES.get(key, normalized)


def steam_search_game(name):
    """Search Steam's public store API for a game and return an app id."""
    query = urllib.parse.urlencode({
        "term": steam_search_query(name),
        "l": "english",
        "cc": "us",
    })
    url = f"{STEAM_SEARCH_API}?{query}"
    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            result = json.loads(resp.read().decode())
    except (urllib.error.URLError, json.JSONDecodeError, OSError) as e:
        print(f"[constellation] Steam search error for {name}: {e}", file=sys.stderr)
        return None

    items = result.get("items", [])
    if not items:
        return None

    return items[0].get("id")


def write_cartridge_field(game_path, key, value):
    """Persist discovered metadata back into cartridge.json."""
    cartridge_path = os.path.join(game_path, "cartridge.json")
    try:
        with open(cartridge_path) as f:
            cartridge = json.load(f)
        cartridge[key] = value
        with open(cartridge_path, "w") as f:
            json.dump(cartridge, f, indent=2)
        return True
    except (json.JSONDecodeError, OSError) as e:
        print(f"[constellation] Could not update {cartridge_path}: {e}", file=sys.stderr)
        return False


def fetch_steam_artwork_for_game(game_entry):
    """Fetch artwork from Steam's public CDN when a Steam app can be matched."""
    game_path = game_entry["path"]
    artwork_dir = os.path.join(game_path, "artwork")
    name = game_entry["name"]

    steam_appid = game_entry.get("steam_appid")
    if not steam_appid:
        steam_appid = steam_search_game(name)
        if steam_appid:
            write_cartridge_field(game_path, "steam_appid", steam_appid)

    if not steam_appid:
        print(f"[constellation] Steam could not match: {name}", file=sys.stderr)
        return

    assets = [
        ("hero", f"{STEAM_CDN_BASE}/{steam_appid}/library_hero.jpg", os.path.join(artwork_dir, "library_hero.jpg")),
        ("grid", f"{STEAM_CDN_BASE}/{steam_appid}/library_600x900.jpg", os.path.join(artwork_dir, "library_600x900.jpg")),
        ("logo", f"{STEAM_CDN_BASE}/{steam_appid}/logo.png", os.path.join(artwork_dir, "logo.png")),
        ("header", f"{STEAM_CDN_BASE}/{steam_appid}/header.jpg", os.path.join(artwork_dir, "header.jpg")),
        ("capsule", f"{STEAM_CDN_BASE}/{steam_appid}/capsule_616x353.jpg", os.path.join(artwork_dir, "capsule_616x353.jpg")),
        ("capsule", f"{STEAM_CDN_BASE}/{steam_appid}/capsule_231x87.jpg", os.path.join(artwork_dir, "capsule_231x87.jpg")),
    ]

    for field, url, dest in assets:
        if field == "hero" and game_entry.get("hero"):
            continue
        if field == "grid" and game_entry.get("grid"):
            continue
        if field == "logo" and game_entry.get("logo"):
            continue
        if field == "header" and game_entry.get("hero"):
            continue
        if field == "capsule" and game_entry.get("hero") and game_entry.get("grid"):
            continue
        if url_exists(url):
            download_image(url, dest)


def fetch_artwork_for_game(game_entry):
    """Fetch missing artwork for a single game from SteamGridDB and public Steam CDN."""
    game_path = game_entry["path"]
    artwork_dir = os.path.join(game_path, "artwork")
    name = game_entry["name"]

    # Check what's already present
    has_hero = bool(game_entry.get("hero"))
    has_grid = bool(game_entry.get("grid"))
    has_logo = bool(game_entry.get("logo"))

    if has_hero and has_grid and has_logo:
        return  # All artwork present

    if SGDB_API_KEY:
        # Find the SteamGridDB game ID
        sgdb_id = game_entry.get("steamgriddb_id")
        if not sgdb_id:
            sgdb_id = sgdb_search_game(name)
            if sgdb_id:
                write_cartridge_field(game_path, "steamgriddb_id", sgdb_id)

        if sgdb_id:
            # Fetch missing artwork
            if not has_hero:
                url = sgdb_fetch_image(sgdb_id, "heroes")
                if url:
                    download_image(url, os.path.join(artwork_dir, "hero.jpg"))

            if not has_grid:
                url = sgdb_fetch_image(sgdb_id, "grids")
                if url:
                    download_image(url, os.path.join(artwork_dir, "grid.png"))

            if not has_logo:
                url = sgdb_fetch_image(sgdb_id, "logos")
                if url:
                    download_image(url, os.path.join(artwork_dir, "logo.png"))
        else:
            print(f"[constellation] Could not find SGDB ID for: {name}", file=sys.stderr)

    # Always try the no-key public Steam fallback for anything still missing.
    fetch_steam_artwork_for_game(game_entry)


def fetch_all_artwork(games):
    """Fetch artwork for all games that are missing it."""
    if not SGDB_API_KEY:
        print("[constellation] No STEAMGRIDDB_API_KEY set; using public Steam fallback.",
              file=sys.stderr)
    for game in games:
        fetch_artwork_for_game(game)


# --- Main ---

def main():
    parser = argparse.ArgumentParser(description="Constellation - Anvil game library daemon")
    parser.add_argument("--scan", action="store_true", help="Scan drives and output JSON library")
    parser.add_argument("--fetch-art", action="store_true", help="Fetch missing artwork from SteamGridDB and public Steam CDN")
    args = parser.parse_args()

    if not args.scan and not args.fetch_art:
        args.scan = True  # Default to scan mode

    drives = find_game_drives()
    if not drives:
        print("[constellation] No game drives found.", file=sys.stderr)
        if args.scan:
            print("[]")
        return

    print(f"[constellation] Found game drives: {drives}", file=sys.stderr)
    games = scan_games(drives)
    print(f"[constellation] Found {len(games)} games.", file=sys.stderr)

    if args.fetch_art:
        fetch_all_artwork(games)
        # Re-scan to pick up freshly downloaded artwork paths
        games = scan_games(drives)

    if args.scan:
        print(json.dumps(games))


if __name__ == "__main__":
    main()
