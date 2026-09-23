# Anvil Input

Anvil Input is the controller abstraction layer for Anvil and the developer
contract exposed through the Forgeworks SDK. Its job is to make the best input
path the easiest input path for developers: actions, remapping, player slots,
controller families, and correct glyphs should come from Anvil instead of every
game reinventing controller detection.

## Goals

- Detect physical controllers as Xbox, PlayStation, Nintendo, keyboard, or
  generic families.
- Let games read named actions such as `jump`, `pause`, and `accept` instead of
  hard-coding physical buttons.
- Let games ask Anvil which glyph to display for an action and player.
- Support action sets such as gameplay, menu, vehicle, dialogue, and minigame.
- Support multiple controllers and player assignment.
- Keep compatibility modes for games that only understand XInput, SDL, or raw
  devices.

## Runtime Modes

| Mode | Purpose | Glyph behavior |
| --- | --- | --- |
| `forgeworks_input` | Native Anvil/Forgeworks games | Correct glyphs through Anvil |
| `sdl_controller` | Games using SDL controller APIs | Correct glyphs if the game asks SDL or ships matching art |
| `raw_hid` | Games with native DualSense/DualShock support | Correct glyphs if the game supports that device |
| `xinput_compat` | Maximum Windows/Proton compatibility | Usually Xbox glyphs inside the game |

## Glyph Modes

| Mode | Meaning |
| --- | --- |
| `anvil_glyphs` | Game asks Anvil for glyphs by action/player |
| `game_selectable` | Game has an in-game glyph setting |
| `native_playstation` | Game detects PlayStation hardware directly |
| `sdl_detected` | Game can detect family through SDL |
| `game_xbox_only` | Game works, but in-game prompts are expected to stay Xbox |
| `unknown` | Needs compatibility testing |

## Manifest

Each game can provide or inherit an input action manifest:

```json
{
  "id": "example-actions",
  "runtime_mode": "forgeworks_input",
  "glyph_mode": "anvil_glyphs",
  "action_sets": {
    "gameplay": {
      "jump": {
        "type": "digital",
        "default": "south",
        "label": "Jump"
      }
    }
  }
}
```

Cartridge metadata can reference one directly:

```json
{
  "name": "Example Game",
  "input_actions": "default-gamepad.json"
}
```

If a game does not provide `input_actions`, Anvil infers a profile from the
game name and compatibility database.

## Developer API Shape

The Forgeworks SDK should expose a small native API first, then Unity and Unreal
plugins on top:

```c
ForgeInput_Init();
ForgeInput_ActivateActionSet(player, "gameplay");

if (ForgeInput_GetDigitalAction(player, "jump").pressed) {
    player_jump();
}

const char *glyph = ForgeInput_GetGlyphForAction(player, "jump");
```

The game should not need to know whether player 1 is using DualSense, DualShock,
Xbox, Switch, or a remapped generic controller. Anvil resolves that.

## Compatibility Truth

For existing games, Anvil should be honest:

```text
Controller: DualSense
Anvil overlay glyphs: PlayStation
Game runtime mode: XInput compatibility
In-game glyphs: Xbox only
```

That is still useful. It tells players why Bluey-like PC builds may show Xbox
prompts even when Anvil correctly detects a PlayStation controller, while giving
developers a clear upgrade path: add Forgeworks Input and get correct glyphs.
