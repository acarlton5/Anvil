# Forgeworks Platform Plan

This is the working feature and naming map for building a Legend Forge gaming
ecosystem comparable to Valve's Steam ecosystem. It is a product plan, not a
promise to clone every Valve implementation.

## Canonical Names

| Valve / Steam name | Legend Forge name | Scope |
| --- | --- | --- |
| Valve | Legend Forge | Company, publisher, and platform owner |
| Steam | Anvil | Store, library, social client, overlay, and game session |
| Steamworks | Forgeworks | Developer and publisher services, APIs, SDK, and portal |
| Steamworks Partner | Forgeworks Partner | Publisher onboarding and product administration portal |
| Steamworks SDK / Web API | Forgeworks SDK / Web API | In-game SDK plus authenticated server APIs |
| SteamCMD | Forge CLI | Headless login, build upload, install, update, and server tooling |
| SteamPipe | Forgepipe | Chunking, manifests, release channels, patching, and delivery |
| Steam Direct | Forge Direct | Product submission, fee, review, and release process |
| Steam Store | Anvil Store | Catalog, discovery, purchasing, and account licenses |
| Steam Community | Anvil Community | Profiles, friends, groups, hubs, discussions, and activity |
| Steam Workshop | The Forge | User-created content publishing and subscriptions |
| Steam Community Market | Forge Market | Player-to-player exchange of eligible platform items |
| Steam Inventory Service | Forge Inventory | Durable game item definitions and player inventories |
| Steam Cloud | Anvil Cloud | Cross-device save and configuration synchronization |
| Steam Input | Anvil Input | Controller abstraction, remapping, glyphs, and layouts |
| Steam Overlay | Anvil Overlay | In-game social, browser, capture, invite, and purchase UI |
| Steam Play | Anvil Play | Cross-platform launch and compatibility policy |
| Proton | Proton, managed by Anvil Runtime | Use upstream Proton/GE-Proton; do not rename software we do not own |
| Steam Linux Runtime | Anvil Runtime | Native Linux containers plus Windows compatibility-tool management |
| Steam Remote Play | Anvil Remote | Game streaming and remote co-play |
| Steam Link | Anvil Link | Receiver and device-pairing experience for Anvil Remote |
| Steam Broadcast | Anvil Broadcast | One-click live gameplay broadcast into community surfaces |
| Steam Chat | Anvil Chat | Direct, group, voice, invite, and rich-presence messaging |
| Steam Guard | Forge Guard | MFA, sign-in approval, trusted devices, and account recovery |
| Steam Families | Anvil Families | Household membership, sharing, parental controls, and playtime |
| Steam Game Recording / Timeline | Anvil Capture | Background recording, clips, screenshots, and event timeline |
| Steam Leaderboards | Anvil Leaderboards | Ranked global, regional, and friend score tables |
| Steam Achievements / Stats | Anvil Achievements / Stats | Persistent player progression APIs and profile display |
| Steam Matchmaking / Lobbies | Anvil Lobbies | Parties, searchable lobbies, invites, and match formation |
| Steam Datagram Relay | Constellation Relay | NAT traversal, relay transport, DDoS shielding, and IP privacy |
| Steam Game Servers | Anvil Servers | Dedicated-server discovery, authentication, and management APIs |
| VAC / Game Bans | Anvil Shield | Anti-abuse signals, game bans, appeals, and enforcement APIs |
| Steam Reviews | Anvil Reviews | Verified-owner reviews, summaries, moderation, and discovery input |
| Steam Curators | Anvil Guides | Followable editorial recommendation channels |
| Steam News / Events | Anvil Events | Developer announcements, events, patch notes, and notifications |
| Steam Early Access | Anvil Early Access | Clearly labeled in-development releases and developer disclosures |
| Steam Keys | Forge Keys | External-sale and promotional license activation codes |
| Steam Wallet | Forge Wallet | Stored value, refunds, gifts, and marketplace settlement |
| Steam Trading Cards | Anvil Collectibles | Optional profile collectibles, badges, and rewards |
| Steam Points | Anvil Points | Non-cash loyalty rewards and profile customization |
| SteamVR / OpenVR | Anvil XR | Deferred XR client integration and compatibility program |
| Big Picture / Gaming Mode | Anvil Session | Controller-first dedicated Wayland session, already in progress |
| SteamOS | AnvilOS | Future optional gaming distribution; Anvil remains distro-independent |
| Deck Verified | Anvil Verified | Device and Linux/runtime compatibility testing and disclosure |
| Steam Deck / Steam Machine | Unnamed Legend Forge hardware | Do not name hardware until there is a real hardware program |

`Forgeworks` is the canonical name for Legend Forge's developer and publisher
platform. Legend Forge makes Anvil; developers configure, ship, and operate
their Anvil games through Forgeworks. Before a commercial launch, the company
should still complete the normal trademark review for every public product name.

## What We Need First

The first release is not a full Steam replacement. It is a reliable Linux game
client that can install, update, verify, and launch owned games from local or
remote sources.

| Capability | Current state | First useful milestone |
| --- | --- | --- |
| Anvil Session | Prototype exists | Clean login session, controller navigation, suspend/logout, and resource cleanup |
| Anvil Library | Local cartridge scan exists | Stable provider interface, cache, metadata schema, and drive hotplug refresh |
| Anvil Runtime | Prototype Proton launcher exists | Per-game runtime selection, process supervision, logs, prefixes, and exit recovery |
| Forgepipe / Anvil Content | Not built | Signed manifests, resumable installs, verification, repair, update, rollback, and uninstall |
| Anvil Updater | Status check only | Signed client releases with apply/restart/rollback behavior |
| Identity | Constellation pieces exist | Anvil sign-in, device session, offline token, and account recovery contract |
| Entitlements | Not connected | One normalized ownership record for cartridge, test grant, key, or purchase |
| Catalog | UI concepts only | App IDs, products, packages, supported platforms, metadata, and release channels |
| Partner tooling | Not built | Create app, upload build, grant testers, publish channel, inspect crash/log data |

## Platform Workstreams

### 1. Client Foundation

- Finish Anvil Session lifecycle and controller-first navigation.
- Replace shell command launch strings with a supervised Anvil Runtime service.
- Add a durable local database for games, installs, media, playtime, and settings.
- Define library-provider and content-source interfaces.
- Build download, install, update, verify, repair, move, and uninstall flows.
- Build signed Anvil client updates and recovery.

### 2. Identity, Catalog, and Ownership

- Use Constellation identity behind an Anvil-facing account contract.
- Define stable App IDs, package IDs, build IDs, and entitlement IDs.
- Implement device authorization, Forge Guard, offline licenses, and revocation.
- Build catalog ingestion, store metadata, system requirements, pricing, and regions.
- Merge cartridge ownership and online ownership into the same Anvil Library model.

### 3. Publishing and Content Delivery

- Build Forgeworks Partner onboarding, organizations, roles, and audit logs.
- Build Forge CLI authentication and application management.
- Build Forgepipe chunking, compression, hashes, signed manifests, and deduplication.
- Support depots by OS, architecture, language, DLC, and optional content.
- Support private test branches, release channels, staged rollout, and rollback.
- Add malware scanning, policy review, age ratings, and release approval.

### 4. Player Platform Features

- Anvil Cloud, Achievements, Stats, Leaderboards, Rich Presence, and Invites.
- Anvil Community profiles, friends, groups, game hubs, reviews, and events.
- Anvil Overlay with chat, browser, capture, achievements, invites, and purchases.
- The Forge publishing, moderation, dependencies, subscriptions, and updates.
- Anvil Families, parental controls, household sharing, and playtime management.

### 5. Multiplayer and Network

- Anvil Lobbies, parties, matchmaking queues, and dedicated-server discovery.
- Constellation Relay for NAT traversal, relay transport, IP privacy, and DDoS defense.
- Anvil Servers API, server identity, auth tickets, browser, and health reporting.
- Voice, game notifications, asynchronous-turn notifications, and presence routing.

### 6. Commerce and Operations

- Payments, taxes, currencies, regional pricing, refunds, chargebacks, and fraud controls.
- Publisher revenue reporting, payouts, tax records, and financial reconciliation.
- DLC, bundles, demos, soundtracks, subscriptions, keys, gifts, and free weekends.
- Search, recommendations, wishlists, discovery queues, merchandising, and sales.
- Moderation, support, privacy, data export/deletion, sanctions, and legal compliance.
- Crash reporting, performance telemetry, compatibility reports, and partner analytics.

### 7. Extended Ecosystem

- Anvil Remote and Anvil Link after launch/process/audio/input capture is mature.
- Anvil Capture and Broadcast after storage, privacy, and moderation exist.
- Forge Inventory, Market, Wallet, Collectibles, and Anvil Points only after commerce is proven.
- Anvil XR only when there is a supported runtime and device strategy.
- AnvilOS only after Anvil Session is dependable across multiple Linux distributions.
- Legend Forge hardware only after software compatibility and update operations are mature.

## Phased Delivery

### Phase 0: Current Prototype Stabilization

Exit criteria: all cartridge games populate consistently; artwork and metadata are
cached; launches work; exiting a game restores Anvil; removable storage hotplug
works; the dedicated session installs, updates, and uninstalls cleanly.

### Phase 1: Local Anvil Alpha

Exit criteria: local database, content manager, supervised runtime, install queue,
verification/repair, client updater, controller settings, captures, and useful logs.
No account or storefront is required.

### Phase 2: Forgeworks Sandbox

Exit criteria: developer organization, App ID, test users, entitlement grants,
Forge CLI upload, signed build manifest, private release channel, authenticated
download, and a minimal SDK for identity/ownership.

### Phase 3: Closed Store Alpha

Exit criteria: catalog, product pages, wishlists, purchases in a test payment
environment, refunds, owned library sync, cloud saves, achievements, crash reports,
and controlled external developer onboarding.

### Phase 4: Social and Multiplayer Beta

Exit criteria: friends, chat, presence, invites, groups, hubs, reviews, lobbies,
server discovery, relay networking, moderation, and parental controls.

### Phase 5: Public Distribution Platform

Exit criteria: production payments/payouts, taxes, regional operations, scalable
content delivery, fraud response, support, legal policies, publisher analytics,
release review, discovery, and audited security/reliability targets.

### Phase 6: Ecosystem Expansion

Exit criteria vary by product: Workshop, Market, Remote, Broadcast, AnvilOS,
compatibility certification, XR, and potential hardware each require a separate
approved business and engineering plan.

## Immediate Backlog

1. Freeze the `cartridge.json` schema and create a normalized library record.
2. Split scanning, content management, and process launching into explicit services.
3. Replace raw launch commands crossing QML IPC with structured launch requests.
4. Implement process supervision so the Anvil UI returns immediately on game exit.
5. Add drive hotplug monitoring and incremental refresh instead of boot-only scanning.
6. Design signed content and client-update manifests before adding remote downloads.
7. Define App ID, package, build, channel, depot, and entitlement data contracts.
8. Map the existing Constellation identity and App World APIs onto the Forgeworks boundary.
9. Build the first Forge CLI flow: sign in, create app, upload build, grant test license.
10. Build a private end-to-end test: publish, grant, install, launch, update, rollback.

## Non-Goals and Guardrails

- Do not rename upstream Proton, Wine, Gamescope, or other projects as Legend Forge products.
- Do not expose Constellation internals directly to games; the Forgeworks contract is the boundary.
- Do not require AnvilOS. Anvil must remain installable on general Linux distributions.
- Do not build a real-money player market before identity, commerce, fraud, moderation,
  tax, and account-recovery systems are production-ready.
- Do not claim feature parity from UI mockups; each capability needs a working service,
  client flow, operational controls, and verification.

## Reference Baseline

This inventory was checked against Valve's current public documentation on
September 21, 2026:

- [Steamworks features](https://partner.steamgames.com/doc/features)
- [Steamworks SDK](https://partner.steamgames.com/doc/sdk)
- [Steamworks API reference](https://partner.steamgames.com/doc/api)
- [Steamworks getting started](https://partner.steamgames.com/doc/gettingstarted)
- [Steam client features](https://store.steampowered.com/about/)
- [Steam hardware](https://partner.steamgames.com/doc/steamhardware)
