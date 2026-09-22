-- Minimal Anvil Wayland Session
hl = require("hyprland")

local home = os.getenv("HOME") or ""
local anvil_root = os.getenv("ANVIL_ROOT") or (home .. "/Projects/Projects/Anvil")
local daemon = anvil_root .. "/src/ui/AnvilDaemon.qml"
local overlay_toggle = "ANVIL_ROOT=" .. anvil_root .. " qs ipc --any-display -p " .. daemon .. " call anvil toggle"
local overlay_bind_shift = "hyprctl keyword bindl \"SHIFT,TAB,exec," .. overlay_toggle .. "\""
local overlay_bind_super = "hyprctl keyword bindl \"SUPER SHIFT,O,exec," .. overlay_toggle .. "\""

hl.monitor({ name = "", resolution = "preferred", position = "auto", scale = "auto" })

-- Essential input
hl.input({
    kb_layout = "us",
    touchpad = { natural_scroll = false }
})

-- Animations disabled for max performance
hl.animations({ enabled = false })
hl.decoration({ drop_shadow = false, blur = { enabled = false } })
hl.misc({
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    vrr = 1 -- Enable Variable Refresh Rate
})

-- Launch Anvil automatically
hl.exec_once("ANVIL_ROOT=" .. anvil_root .. " qs -p " .. daemon)
hl.exec_once(overlay_bind_shift)
hl.exec_once(overlay_bind_super)

-- Overlay Hotkey
hl.bind("SHIFT + TAB", hl.dsp.exec_cmd(overlay_toggle))
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd(overlay_toggle))
