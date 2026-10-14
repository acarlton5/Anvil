-- Minimal Anvil Wayland Session

local home = os.getenv("HOME") or ""
local anvil_root = os.getenv("ANVIL_ROOT") or (home .. "/Projects/Projects/Anvil")
local daemon = anvil_root .. "/src/ui/AnvilDaemon.qml"
local overlay_toggle = anvil_root .. "/scripts/anvil-overlay-toggle " .. anvil_root
local qs_bin = os.getenv("ANVIL_QS_BIN") or "qs"

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

-- Essential input and performance optimizations
hl.config({
    input = {
        kb_layout = "us",
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            clickfinger_behavior = true
        }
    },
    animations = {
        enabled = false
    },
    decoration = {
        shadow = {
            enabled = false
        },
        blur = {
            enabled = false
        }
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 1 -- Enable Variable Refresh Rate
    },
    bind = {
        "SHIFT, TAB, exec, " .. overlay_toggle,
        "SUPER SHIFT, O, exec, " .. overlay_toggle,
        "SUPER SHIFT, Q, exit",
    }
})

-- Launch Anvil automatically with full D-Bus & systemd environment
-- Exits Hyprland back to greeter when Anvil terminates or Switch to Desktop is pressed
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("env ANVIL_ROOT=" .. anvil_root .. " " .. qs_bin .. " -p " .. daemon .. "; hyprctl dispatch exit")
end)

