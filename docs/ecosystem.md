# Legend Forge Gaming Ecosystem

This document defines the product boundaries for Legend Forge's gaming stack.
Names here describe ownership and API boundaries; they are not interchangeable
process names.

The complete Valve-to-Legend-Forge feature inventory and delivery sequence is
maintained in [platform-plan.md](platform-plan.md).

## Product Map

| Legend Forge product | Role | Comparable Valve product |
| --- | --- | --- |
| Legend Forge | Company and publisher | Valve |
| Anvil | Player-facing store, library, community, overlay, and gaming session | Steam |
| Anvilworks | Developer SDK, publishing portal, commerce, builds, releases, achievements, multiplayer, and operational APIs | Steamworks |
| Constellation | Shared distributed infrastructure used for identity, entitlements, discovery, delivery, and application networking | Infrastructure beneath Valve services |

Anvil is a client of Anvilworks. Anvilworks is a customer
of Constellation infrastructure. Constellation is not an Anvil daemon and its
name must not be used for local library scanning, game launching, or session
processes.

## Anvil-Owned Services

The standalone Linux client owns these local capabilities:

- Anvil Library: combines installed, removable-cartridge, and future online
  library providers into one player library.
- Anvil Content: installs, verifies, repairs, updates, and removes game builds.
- Anvil Runtime: selects compatibility tools, creates game prefixes, launches
  games, tracks their lifecycle, and exposes the overlay.
- Anvil Session: provides the dedicated controller-first Wayland session.
- Anvil Updater: checks, downloads, verifies, and applies client updates.

The current `anvil_library.py` process is the first local Anvil Library
provider. It is intentionally not named after Constellation or Legend Forge
Platform.

## Anvilworks Services

The developer and publisher layer should grow as contracts that both Anvil and
game integrations can consume:

1. Identity and application registration
2. Catalog, pricing, purchasing, refunds, and regional availability
3. Licenses, ownership, family sharing, and device authorization
4. Build depots, release channels, manifests, patching, and CDN delivery
5. Cloud saves, achievements, stats, leaderboards, and rich presence
6. Friends, parties, lobbies, matchmaking, relay, and server discovery
7. User-created content publishing, moderation, and subscriptions
8. Crash reporting, telemetry, anti-abuse, and developer analytics
9. Publisher portal, SDKs, command-line tools, documentation, and sandboxing

These APIs may be backed by Constellation, but their public contract belongs to
Anvilworks. Anvil should consume that contract instead of reaching
directly into Constellation internals.

## Delivery Order

Build the platform in slices that produce a usable Anvil client at every step:

1. Finish local library, content installation, runtime, updates, and session
   lifecycle using cartridge manifests.
2. Define provider interfaces so local cartridges and online ownership produce
   the same normalized library records.
3. Add application IDs, build manifests, entitlements, and authenticated
   downloads through Anvilworks.
4. Add cloud saves, achievements, social presence, lobbies, and matchmaking.
5. Add publisher tooling and user-created content after the distribution and
   entitlement contracts are stable.

## Naming Rules

- Use `anvil-*` for player-machine processes, commands, files, and IPC.
- Use `Anvilworks` for developer-facing services, SDKs, APIs, and documentation.
- Use `constellation-*` only for actual Constellation infrastructure clients or
  services.
- Do not call a local helper `forge`, because Legend Forge is the company and
  the word does not identify what that helper does.
