-- Minimal Anvil Wayland Session
hl = require("hyprland")

local home = os.getenv("HOME") or ""
local anvil_root = os.getenv("ANVIL_ROOT") or (home .. "/Projects/Projects/Anvil")
local daemon = anvil_root .. "/src/ui/AnvilDaemon.qml"

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

-- Overlay Hotkey
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd("ANVIL_ROOT=" .. anvil_root .. " qs -p " .. daemon .. " ipc call anvil toggle"))
