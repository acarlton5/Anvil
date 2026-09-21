#!/bin/bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export ANVIL_ROOT="${ANVIL_ROOT:-$(dirname -- "$script_dir")}"

exec Hyprland -c "$ANVIL_ROOT/session/hyprland-anvil.lua"
