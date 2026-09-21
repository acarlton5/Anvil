# Anvil

Anvil is a standalone Linux game client and Wayland gaming session. It is being
built as its own product, separate from HypeShell, with a path toward a
Steam-style store, library, overlay, and cartridge-based distribution model.

## Current Scope

- Quickshell/QML launcher and overlay for a dedicated gaming session.
- Local Anvil library services for mounting removable cartridge media, scanning
  `Games/` drives, fetching artwork, and checking for Anvil updates.
- Public Steam Store/CDN artwork fallback with optional SteamGridDB support.
- Proton launch wrapper owned by Anvil: `scripts/anvil-proton-run`.
- Hyprland session files under `session/`.

## Project Boundary

HypeShell can provide a desktop/shell integration point for launching Anvil, but
Anvil owns the game library, game metadata, artwork fetching, Proton runner, and
future store/community UX. Anvil is the Steam-like client made by Legend Forge.
Forgeworks is the developer and publisher service layer used by Anvil,
comparable in role to Steamworks. It uses Constellation for distributed
identity, entitlement, discovery, and delivery infrastructure. While those
integrations are growing, local cartridge files under removable media act as an
offline library provider. Keep Anvil client code in this repo so it can become
installable on any Linux distro without requiring the full HypeShell desktop.

See [docs/ecosystem.md](docs/ecosystem.md) for the product boundaries and the
implementation roadmap.

## Development

Run the daemon scan:

```bash
python3 src/daemon/anvil_library.py --auto-mount --scan
```

Run the full launcher status check:

```bash
python3 src/daemon/anvil_library.py --status
```

Fetch missing artwork, using public Steam assets by default:

```bash
python3 src/daemon/anvil_library.py --fetch-art --scan
```

For higher quality grid and logo assets, set your own SteamGridDB key:

```bash
STEAMGRIDDB_API_KEY=... python3 src/daemon/anvil_library.py --fetch-art --scan
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
