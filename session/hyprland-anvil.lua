-- Minimal Anvil Wayland Session
hl = require("hyprland")

local home = os.getenv("HOME") or ""
local anvil_root = os.getenv("ANVIL_ROOT") or (home .. "/Projects/Projects/Anvil")
local daemon = anvil_root .. "/src/ui/AnvilDaemon.qml"
local overlay_toggle = anvil_root .. "/scripts/anvil-overlay-toggle " .. anvil_root

-- Hardware profile detection (e.g. Steam Deck portrait display rotation)
local deck_transform = 0
local product_name_file = io.open("/sys/devices/virtual/dmi/id/product_name", "r")
if product_name_file then
    local p = product_name_file:read("*a") or ""
    product_name_file:close()
    if p:find("Jupiter") then
        deck_transform = 3
    elseif p:find("Galileo") then
        deck_transform = 1
    end
end

if deck_transform ~= 0 then
    hl.monitor({
        output = "eDP-1",
        mode = "preferred",
        position = "0x0",
        scale = "1",
        transform = deck_transform,
    })
    hl.config({
        input = {
            touchdevice = {
                transform = deck_transform,
                output = "eDP-1"
            }
        }
    })
else
    hl.monitor({
        output = "",
        mode = "preferred",
        position = "auto",
        scale = "auto",
    })
end

-- Essential input
hl.input({
    kb_layout = "us",
    touchpad = {
        natural_scroll = true,
        tap_to_click = true,
        clickfinger_behavior = true
    }
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
hl.bind("SHIFT + TAB", hl.dsp.exec_cmd(overlay_toggle), { locked = true, dont_inhibit = true })
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd(overlay_toggle), { locked = true, dont_inhibit = true })
