#!/usr/bin/env python3
"""
Anvil Library — local cartridge provider for the Anvil client.

Scans mounted USB/SD drives for game folders with cartridge.json metadata,
fetches missing artwork from SteamGridDB, and outputs a JSON game library
that the QML UI consumes. This is an offline Anvil provider; future online
library providers will enter through Forgeworks services backed by
Constellation infrastructure.

Usage:
    anvil_library.py --scan          Print JSON library to stdout and exit
    anvil_library.py --fetch-art     Fetch missing artwork from SteamGridDB
    anvil_library.py --scan --fetch-art  Do both
"""

import argparse
import json
import os
import shlex
import subprocess
import sys
import re
import time
import urllib.request
import urllib.error
import urllib.parse
from pathlib import Path

# Where to look for mounted game drives
MEDIA_ROOTS = ["/run/media"]
GAMES_DIR_NAME = "Games"
ANVIL_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_RUNNER = ANVIL_ROOT / "scripts" / "anvil-proton-run"
RELEASE_FILE = ANVIL_ROOT / "release.json"
REMOVABLE_TRANSPORTS = {"usb", "mmc"}

# SteamGridDB API
SGDB_API_BASE = "https://www.steamgriddb.com/api/v2"
SGDB_API_KEY = os.environ.get("STEAMGRIDDB_API_KEY", "")
HTTP_USER_AGENT = "Anvil/0.1"
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
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ARTWORK_ROLE_HINTS = {
    "hero": ("hero", "header", "capsule", "landscape", "background", "banner"),
    "grid": ("grid", "cover", "poster", "library", "capsule", "portrait"),
    "logo": ("logo", "clearlogo"),
}


def _truthy(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, int):
        return value != 0
    return str(value).lower() in {"1", "true", "yes", "on"}


def _run_command(command, timeout=8, cwd=None):
    return subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True,
        timeout=timeout,
        cwd=cwd,
    )


def _walk_lsblk_devices(devices, parent=None):
    for device in devices:
        merged = dict(parent or {})
        merged.update(device)
        children = merged.pop("children", []) or []
        yield merged
        yield from _walk_lsblk_devices(children, merged)


def _device_mountpoints(device):
    points = device.get("mountpoints")
    if isinstance(points, list):
        return [point for point in points if point]
    point = device.get("mountpoint")
    return [point] if point else []


def _is_removable_device(device):
    return (
        _truthy(device.get("rm"))
        or _truthy(device.get("hotplug"))
        or str(device.get("tran") or "").lower() in REMOVABLE_TRANSPORTS
    )


def list_unmounted_removable_devices():
    """Return removable filesystems that udisks can mount for cartridges."""
    try:
        result = _run_command([
            "lsblk",
            "-J",
            "-o",
            "NAME,PATH,TYPE,FSTYPE,MOUNTPOINT,MOUNTPOINTS,RM,HOTPLUG,TRAN,LABEL,UUID",
        ])
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        print(f"[anvil-library] Cannot inspect removable media: {e}", file=sys.stderr)
        return []

    if result.returncode != 0:
        print(f"[anvil-library] lsblk failed: {result.stderr.strip()}", file=sys.stderr)
        return []

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        print(f"[anvil-library] lsblk returned invalid JSON: {e}", file=sys.stderr)
        return []

    candidates = []
    for device in _walk_lsblk_devices(payload.get("blockdevices", [])):
        if device.get("type") not in {"part", "disk"}:
            continue
        if not device.get("path") or not device.get("fstype"):
            continue
        if _device_mountpoints(device):
            continue
        if not _is_removable_device(device):
            continue
        candidates.append(device)

    return candidates


def automount_removable_media():
    """Mount USB/SD filesystems so game cartridges are visible on session boot."""
    mounted = []
    if os.environ.get("ANVIL_AUTO_MOUNT", "1") == "0":
        return mounted
    if not shutil_which("udisksctl"):
        print("[anvil-library] udisksctl not found; skipping removable media mount.",
              file=sys.stderr)
        return mounted

    for device in list_unmounted_removable_devices():
        path = device["path"]
        try:
            result = _run_command(["udisksctl", "mount", "-b", path], timeout=20)
        except subprocess.TimeoutExpired:
            print(f"[anvil-library] Mount timed out for {path}", file=sys.stderr)
            continue
        except FileNotFoundError:
            return mounted

        output = (result.stdout + result.stderr).strip()
        if result.returncode == 0:
            mounted.append({
                "path": path,
                "label": device.get("label") or device.get("uuid") or os.path.basename(path),
                "message": output,
            })
            print(f"[anvil-library] Mounted removable media: {path}", file=sys.stderr)
        elif "already mounted" not in output.lower():
            print(f"[anvil-library] Could not mount {path}: {output}", file=sys.stderr)

    if mounted:
        time.sleep(1.0)
    return mounted


def shutil_which(command):
    for directory in os.environ.get("PATH", "").split(os.pathsep):
        candidate = os.path.join(directory, command)
        if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
            return candidate
    return None


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


def discover_game_drives(auto_mount=False):
    """Mount removable media if requested, then return cartridge drive paths."""
    mounted = automount_removable_media() if auto_mount else []
    drives = find_game_drives()
    return drives, mounted


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
                    print(f"[anvil-library] Generated cartridge.json for {game_folder}",
                          file=sys.stderr)
                except OSError as e:
                    print(f"[anvil-library] Cannot write stub for {game_folder}: {e}",
                          file=sys.stderr)
                    continue

            try:
                with open(cartridge_file) as f:
                    cartridge = json.load(f)
            except (json.JSONDecodeError, OSError) as e:
                print(f"[anvil-library] Bad cartridge.json in {game_folder}: {e}",
                      file=sys.stderr)
                continue

            game = build_game_entry(cartridge, game_path, drive_root)
            if not game.get("launch_command"):
                print(f"[anvil-library] Skipping no-launch cartridge: {game['name']}",
                      file=sys.stderr)
                continue
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
        "input_profile": infer_input_profile(display_name),
        "controller_layout": infer_controller_layout(display_name),
        "tags": ["Uncategorized"],
    }


def infer_input_profile(name):
    clean = re.sub(r"[^a-z0-9]+", " ", name.lower()).strip()
    if any(token in clean for token in ["jak", "daxter", "ratchet", "sly cooper", "uncharted", "god of war"]):
        return "gamepad/playstation"
    return "gamepad/default"


def infer_controller_layout(name):
    clean = re.sub(r"[^a-z0-9]+", " ", name.lower()).strip()
    if any(token in clean for token in ["jak", "daxter", "ratchet", "sly cooper", "uncharted", "god of war"]):
        return "dualshock-action-adventure"
    return "standard-gamepad"


def build_game_entry(cartridge, game_path, drive_root):
    """Build the JSON entry the QML UI expects from a cartridge.json."""
    name = cartridge.get("name", os.path.basename(game_path))
    exe_path = cartridge.get("exe_path", "")
    launch_options = cartridge.get("launch_options", "")
    proton = cartridge.get("proton_version", "Proton Experimental")
    tags = cartridge.get("tags", [])
    input_profile = cartridge.get("input_profile") or infer_input_profile(name)
    controller_layout = cartridge.get("controller_layout") or infer_controller_layout(name)
    sgdb_id = cartridge.get("steamgriddb_id", None)
    steam_appid = cartridge.get("steam_appid", None)

    # Resolve absolute exe path from drive-relative path
    abs_exe = os.path.join(drive_root, exe_path) if exe_path else ""
    start_dir = cartridge.get("start_dir", "")
    abs_start_dir = os.path.join(drive_root, start_dir) if start_dir else os.path.dirname(abs_exe)

    # Strip %command% placeholder for anvil-proton-run
    clean_options = launch_options.replace("%command%", "").strip()

    launch_cmd = ""
    if abs_exe:
        native_target = (
            str(proton).strip().lower() in {"", "null", "none", "native"}
            or os.path.splitext(abs_exe.lower())[1] in {".sh", ".appimage"}
        )
        if native_target:
            launch_cmd = " ".join([
                "cd",
                shlex.quote(abs_start_dir or os.path.dirname(abs_exe)),
                "&&",
                shlex.quote(abs_exe),
            ])
            if clean_options:
                launch_cmd = f"{launch_cmd} {clean_options}"
        else:
            runner = os.environ.get("ANVIL_PROTON_RUN", "")
            if not runner:
                runner = str(DEFAULT_RUNNER if DEFAULT_RUNNER.is_file() else "anvil-proton-run")
            launch_cmd = " ".join([
                shlex.quote(runner),
                shlex.quote(name),
                shlex.quote(proton),
                shlex.quote(abs_exe),
            ])
            if clean_options:
                launch_cmd = f"{launch_cmd} {clean_options}"

    # Check for artwork
    artwork_dir = os.path.join(game_path, "artwork")
    hero = find_artwork(game_path, artwork_dir, [
        "hero.jpg",
        "hero.png",
        "hero.webp",
        "library_hero.jpg",
        "library_hero.png",
        "header.jpg",
        "header.png",
        "capsule_616x353.jpg",
        "capsule_616x353.png",
    ], "hero")
    grid = find_artwork(game_path, artwork_dir, [
        "grid.png",
        "grid.jpg",
        "grid.webp",
        "cover.jpg",
        "cover.png",
        "poster.jpg",
        "poster.png",
        "library_600x900.jpg",
        "library_600x900.png",
        "library_600x900.webp",
        "capsule_616x353.jpg",
        "capsule_616x353.png",
        "capsule_231x87.jpg",
        "capsule_231x87.png",
        "header.jpg",
        "header.png",
    ], "grid")
    logo = find_artwork(game_path, artwork_dir, ["logo.png", "logo.jpg", "logo.webp", "clearlogo.png"], "logo")

    return {
        "name": name,
        "path": game_path,
        "launch_command": launch_cmd,
        "proton": proton,
        "tags": tags,
        "hero": hero or "",
        "grid": grid or "",
        "logo": logo or "",
        "input_profile": input_profile,
        "controller_layout": controller_layout,
        "steamgriddb_id": str(sgdb_id) if sgdb_id else "",
        "steam_appid": str(steam_appid) if steam_appid else "",
        "dummy": False,
    }


def _image_files(directory):
    if not os.path.isdir(directory):
        return []
    images = []
    try:
        for entry in os.listdir(directory):
            path = os.path.join(directory, entry)
            if os.path.isfile(path) and os.path.splitext(entry.lower())[1] in IMAGE_EXTENSIONS:
                images.append(path)
    except OSError:
        return []
    return sorted(images)


def find_artwork(game_path, artwork_dir, candidates, role="hero"):
    """Look for artwork in common locations with case-insensitive fallbacks."""
    search_dirs = [artwork_dir, game_path]
    lowered_candidates = {candidate.lower() for candidate in candidates}

    for directory in search_dirs:
        for path in _image_files(directory):
            if os.path.basename(path).lower() in lowered_candidates:
                return path

    hints = ARTWORK_ROLE_HINTS.get(role, ())
    for directory in search_dirs:
        for path in _image_files(directory):
            name = os.path.basename(path).lower()
            if any(hint in name for hint in hints):
                return path

    for directory in search_dirs:
        images = _image_files(directory)
        if images:
            return images[0]

    return None


# --- SteamGridDB Artwork Fetching ---

def sgdb_request(endpoint):
    """Make an authenticated GET request to SteamGridDB API."""
    if not SGDB_API_KEY:
        return None
    url = f"{SGDB_API_BASE}{endpoint}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {SGDB_API_KEY}",
        "User-Agent": HTTP_USER_AGENT,
    })
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode())
    except (urllib.error.URLError, json.JSONDecodeError, OSError) as e:
        print(f"[anvil-library] SGDB API error: {e}", file=sys.stderr)
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
        req = urllib.request.Request(url, headers={"User-Agent": HTTP_USER_AGENT})
        with urllib.request.urlopen(req, timeout=20) as resp:
            with open(dest_path, "wb") as f:
                f.write(resp.read())
        print(f"[anvil-library] Downloaded: {dest_path}", file=sys.stderr)
        return True
    except (urllib.error.URLError, OSError) as e:
        print(f"[anvil-library] Download failed for {url}: {e}", file=sys.stderr)
        return False


def url_exists(url):
    """Return True when a public asset URL exists."""
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": HTTP_USER_AGENT})
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
        print(f"[anvil-library] Steam search error for {name}: {e}", file=sys.stderr)
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
        print(f"[anvil-library] Could not update {cartridge_path}: {e}", file=sys.stderr)
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
        print(f"[anvil-library] Steam could not match: {name}", file=sys.stderr)
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
            print(f"[anvil-library] Could not find SGDB ID for: {name}", file=sys.stderr)

    # Always try the no-key public Steam fallback for anything still missing.
    fetch_steam_artwork_for_game(game_entry)


def fetch_all_artwork(games):
    """Fetch artwork for all games that are missing it."""
    if not SGDB_API_KEY:
        print("[anvil-library] No STEAMGRIDDB_API_KEY set; using public Steam fallback.",
              file=sys.stderr)
    for game in games:
        fetch_artwork_for_game(game)


def _git_value(args, cwd):
    try:
        result = _run_command(["git", *args], timeout=10, cwd=cwd)
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()


def current_release_info():
    """Return the local Anvil revision and update remote when known."""
    if RELEASE_FILE.is_file():
        try:
            with RELEASE_FILE.open() as f:
                payload = json.load(f)
            return {
                "revision": payload.get("revision", ""),
                "remote": payload.get("remote", ""),
                "source": "installed",
            }
        except (json.JSONDecodeError, OSError):
            pass

    if (ANVIL_ROOT / ".git").exists():
        return {
            "revision": _git_value(["rev-parse", "HEAD"], ANVIL_ROOT),
            "remote": _git_value(["config", "--get", "remote.origin.url"], ANVIL_ROOT),
            "source": "checkout",
        }

    return {"revision": "", "remote": "", "source": "unknown"}


def check_for_updates():
    """Check the Anvil git remote for a newer main branch revision."""
    info = current_release_info()
    current = info.get("revision", "")
    remote = info.get("remote", "")
    update = {
        "state": "unavailable",
        "label": "Update status unavailable",
        "current": current[:12] if current else "",
        "latest": "",
        "remote": remote,
        "source": info.get("source", "unknown"),
        "available": False,
    }

    if os.environ.get("ANVIL_UPDATE_CHECK", "1") == "0":
        update["state"] = "disabled"
        update["label"] = "Update check disabled"
        return update

    if not current or not remote:
        return update

    try:
        result = _run_command(["git", "ls-remote", remote, "refs/heads/main"], timeout=10)
    except (FileNotFoundError, subprocess.TimeoutExpired) as e:
        update["state"] = "offline"
        update["label"] = f"Update check failed: {e}"
        return update

    if result.returncode != 0:
        update["state"] = "offline"
        update["label"] = "Update check failed"
        return update

    latest = result.stdout.split()[0] if result.stdout.split() else ""
    update["latest"] = latest[:12] if latest else ""
    if latest and latest != current:
        update["state"] = "available"
        update["available"] = True
        update["label"] = "Update available"
    else:
        update["state"] = "current"
        update["label"] = "Up to date"

    return update


# --- Main ---

def main():
    parser = argparse.ArgumentParser(description="Anvil Library - Anvil game library daemon")
    parser.add_argument("--scan", action="store_true", help="Scan drives and output JSON library")
    parser.add_argument("--fetch-art", action="store_true", help="Fetch missing artwork from SteamGridDB and public Steam CDN")
    parser.add_argument("--auto-mount", action="store_true", help="Mount removable USB/SD media before scanning")
    parser.add_argument("--check-updates", action="store_true", help="Check whether the Anvil remote has a newer release")
    parser.add_argument("--status", action="store_true", help="Output a JSON status object with games, drives, mounts, and updates")
    args = parser.parse_args()

    if not args.scan and not args.fetch_art and not args.check_updates and not args.status:
        args.scan = True  # Default to scan mode

    if args.check_updates and not args.scan and not args.fetch_art and not args.status:
        print(json.dumps(check_for_updates()))
        return

    drives, mounted = discover_game_drives(auto_mount=args.auto_mount or args.status)
    if not drives:
        print("[anvil-library] No game drives found.", file=sys.stderr)
        if args.status:
            print(json.dumps({
                "games": [],
                "drives": [],
                "mounted": mounted,
                "update": check_for_updates() if args.check_updates or args.status else {},
            }))
            return
        if args.scan:
            print("[]")
        return

    print(f"[anvil-library] Found game drives: {drives}", file=sys.stderr)
    games = scan_games(drives)
    print(f"[anvil-library] Found {len(games)} games.", file=sys.stderr)

    if args.fetch_art:
        fetch_all_artwork(games)
        # Re-scan to pick up freshly downloaded artwork paths
        games = scan_games(drives)

    if args.status:
        print(json.dumps({
            "games": games,
            "drives": drives,
            "mounted": mounted,
            "update": check_for_updates() if args.check_updates or args.status else {},
        }))
    elif args.scan:
        print(json.dumps(games))


if __name__ == "__main__":
    main()
