# Anvil Cross-Platform Client Plan

Anvil needs to be one game platform with multiple hosts, not one Linux shell
that later tries to become a Windows app. The current Quickshell client remains
useful as the first Anvil Session prototype, but the product UI should move to a
shared client layer that can run on Windows, desktop Linux, and inside the
dedicated Linux console session.

## Product Shape

- **Anvil Desktop** is the normal PC client for Windows and Linux desktops. It
  owns account login, library, store, downloads, friends, achievements, cloud
  saves, settings, and developer-facing diagnostics.
- **Anvil Session** is the console-first Linux mode. It boots into the same
  Anvil client experience with a controller-first shell, game launcher, overlay,
  power actions, Proton/runtime integration, and removable cartridge scanning.
- **Anvil Overlay** is a host-specific layer that exposes the same shared
  overlay model. Windows, desktop Linux, and the Linux session may use different
  capture/input/windowing hooks, but they should show the same feature set.
- **Forgeworks** is the developer/platform service layer: achievements, builds,
  manifests, depots, entitlements, cloud saves, lobbies, input APIs, telemetry,
  and publishing tools.
- **Constellation** is infrastructure beneath Forgeworks and Anvil, not the game
  client brand.

## Architecture

```text
apps/
  desktop/          Windows + desktop Linux app host
  session/          Linux console/session host
  overlay/          host-specific overlay entrypoints

packages/
  anvil-core/       library, installs, manifests, game launch, session state
  anvil-ui/         shared Steam Deck-style UI screens and components
  anvil-input/      controller detection, glyphs, action maps, remapping
  anvil-art/        artwork roles, cache, lookup, repair, fallback
  forgeworks-sdk/   client API for achievements, cloud, store, entitlements

platform/
  windows/          Windows launch, overlay, controller, install hooks
  linux-desktop/    desktop Linux launch, runtime, notification hooks
  linux-session/    compositor/session integrations, power, focus, game mode
```

The current `src/ui/*.qml` files can be mined for behavior, but should not be
treated as the permanent UI source. The durable source should become a shared UI
package and a shared Anvil Core API.

## Technology Direction

The Windows client should not be Quickshell. Quickshell is a Linux shell host
for Wayland/X11-style desktop integration. It is appropriate for Anvil Session,
not for a cross-platform desktop application.

Preferred direction:

- Build the shared client UI in a cross-platform app stack.
- Keep the Anvil Core API local-first and host-agnostic.
- Let each platform host provide only what is genuinely platform-specific:
  overlay injection, process supervision, controller backends, install paths,
  notification APIs, startup behavior, and privilege boundaries.

Candidate app hosts:

| Host | Strength | Risk |
| --- | --- | --- |
| Tauri | Smaller app, Rust backend, good desktop packaging | Game overlay hooks still need native work |
| Electron | Fastest UI iteration, mature Windows packaging | Heavier runtime |
| Qt/QML | Can reuse QML thinking, strong native UI/runtime | Windows packaging and web/store surfaces may be more work |

The first serious prototype should optimize for speed and product quality. A
Tauri or Electron shell with a shared UI package is the most practical path for
Windows plus Linux desktop. Quickshell can then host the same data model or a
session-specific renderer for the Linux console mode.

## UI Direction

The visual target is not "dark dashboard." It is a console game shell:

- One dominant selected game.
- Full-screen hero art as the scene.
- Rails of game art, not dense cards.
- Controller focus is always obvious.
- Navigation feels like system chrome, not website tabs.
- Overlay feels like a translucent console OS layer over the game.
- Text is sparse, large, and functional.
- Store, library, downloads, friends, settings, and achievements share one
  design language.

Steam Deck is the closest interaction reference. Anvil should keep the clarity
and controller ergonomics, then add its own Forge/Anvil identity through focus
flame, stronger artwork treatment, cleaner input tools, cartridge awareness,
and developer-friendly Forgeworks surfaces.

## Migration Plan

1. Freeze the current Quickshell UI as the Linux session prototype.
2. Extract the library scanner, artwork logic, game session metadata, input
   manifests, and achievements prototype behind local command/API boundaries.
3. Create a new shared client scaffold with desktop and session hosts.
4. Rebuild Home, Library, Overlay, Downloads, Store, Friends, Achievements, and
   Settings in the shared UI package.
5. Make Windows desktop launch local/native games first, then add install,
   update, account, and Forgeworks features.
6. Reconnect Anvil Session to the shared core and either reuse the shared UI
   directly or keep a thin session renderer that follows the same design system.

## Keep From Current Prototype

- Cartridge scanning and local `Games/` discovery.
- Artwork role classification and repair.
- Proton/game session wrapper concepts.
- Anvil Input manifests and controller family database.
- Overlay action model and exit-game process supervision.
- Local Forgeworks achievements prototype.
- HypeShell plugin only as a launcher/installer bridge, not the product shell.

## Stop Investing In

- Large new feature surfaces built only in Quickshell QML.
- Hyprland-only assumptions for core product behavior.
- UI passes that do not update all major client pages.
- Letter-placeholder icons and dashboard-style mock panels.
- Platform logic embedded directly in visual components.
