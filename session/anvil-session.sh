#!/bin/bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export ANVIL_ROOT="${ANVIL_ROOT:-$(dirname -- "$script_dir")}"

# Standard Wayland session environment
export XDG_CURRENT_DESKTOP="Hyprland"
export XDG_SESSION_DESKTOP="Hyprland"
export XDG_SESSION_TYPE="wayland"
export HYPRLAND_CONFIG="$ANVIL_ROOT/session/hyprland-anvil.lua"
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

if command -v qs >/dev/null 2>&1; then
    export ANVIL_QS_BIN="qs"
elif command -v quickshell >/dev/null 2>&1; then
    export ANVIL_QS_BIN="quickshell"
else
    export ANVIL_QS_BIN="qs"
fi

if command -v hypeshell-hyprland-session >/dev/null 2>&1; then
    exec hypeshell-hyprland-session -- --config "$ANVIL_ROOT/session/hyprland-anvil.lua"
elif command -v start-hyprland >/dev/null 2>&1; then
    exec start-hyprland -- --config "$ANVIL_ROOT/session/hyprland-anvil.lua"
else
    exec Hyprland -c "$ANVIL_ROOT/session/hyprland-anvil.lua"
fi

