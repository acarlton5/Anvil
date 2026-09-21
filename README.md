# Anvil

Anvil is a standalone Linux game client and Wayland gaming session. It is being
built as its own product, separate from HypeShell, with a path toward a
Steam-style store, library, overlay, and cartridge-based distribution model.

## Current Scope

- Quickshell/QML launcher and overlay for a dedicated gaming session.
- Local cartridge scanning from mounted `Games/` drives.
- Public Steam Store/CDN artwork fallback with optional SteamGridDB support.
- Proton launch wrapper owned by Anvil: `scripts/anvil-proton-run`.
- Hyprland session files under `session/`.

## Project Boundary

HypeShell can provide a desktop/shell integration point for launching Anvil, but
Anvil owns the game library, game metadata, artwork fetching, Proton runner, and
future store/community UX. Keep platform code in this repo so Anvil can become
installable on any Linux distro without requiring the full HypeShell desktop.

## Development

Run the daemon scan:

```bash
python3 src/daemon/constellation.py --scan
```

Fetch missing artwork, using public Steam assets by default:

```bash
python3 src/daemon/constellation.py --fetch-art --scan
```

For higher quality grid and logo assets, set your own SteamGridDB key:

```bash
STEAMGRIDDB_API_KEY=... python3 src/daemon/constellation.py --fetch-art --scan
```

Run the launcher from a checkout:

```bash
ANVIL_ROOT="$PWD" qs -p src/ui/AnvilDaemon.qml
```

Launch the dedicated session:

```bash
ANVIL_ROOT="$PWD" ./session/anvil-session.sh
```

## Dependencies

- Quickshell
- Hyprland
- Python 3
- Steam with Proton or GE-Proton installed for Windows game launches

