-- Minimal Anvil Wayland Session

local home = os.getenv("HOME") or ""
local anvil_root = os.getenv("ANVIL_ROOT") or "/usr/local/share/anvil"
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

local function has_external_display()
    local p = io.popen("for s in /sys/class/drm/card*-DP-*/status /sys/class/drm/card*-HDMI-*/status; do [ -f \"$s\" ] && grep -q '^connected' \"$s\" 2>/dev/null && echo 'yes' && exit 0; done; echo 'no'")
    if p then
        local res = p:read("*l") or "no"
        p:close()
        return res:find("yes") ~= nil
    end
    return false
end

local function update_displays()
    if deck_transform ~= 0 then
        if has_external_display() then
            hl.monitor({
                output = "eDP-1",
                disabled = true,
            })
        else
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
        end
    else
        hl.monitor({
            output = "",
            mode = "preferred",
            position = "auto",
            scale = "auto",
        })
    end
end

-- Apply initial monitor configuration based on external display
update_displays()

-- Auto-switch display when external monitor is connected or disconnected
hl.on("monitor.added", function()
    update_displays()
end)

hl.on("monitor.removed", function()
    update_displays()
end)

local quickaccess_toggle = anvil_root .. "/scripts/anvil-quickaccess-toggle " .. anvil_root
local keyboard_toggle = anvil_root .. "/scripts/anvil-keyboard-toggle " .. anvil_root

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
    }
})

-- Audio, Brightness, and Overlay Hotkeys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })

-- Quick Access Menu, On-Screen Keyboard, and Overlay Toggles
hl.bind("SHIFT + TAB", hl.dsp.exec_cmd(overlay_toggle), { locked = true, dont_inhibit = true })
hl.bind("SUPER + SHIFT + O", hl.dsp.exec_cmd(overlay_toggle), { locked = true, dont_inhibit = true })
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd(quickaccess_toggle), { locked = true, dont_inhibit = true })
hl.bind("XF86Shop", hl.dsp.exec_cmd(quickaccess_toggle), { locked = true, dont_inhibit = true })
hl.bind("XF86Search", hl.dsp.exec_cmd(quickaccess_toggle), { locked = true, dont_inhibit = true })
hl.bind("SUPER + Q", hl.dsp.exec_cmd(quickaccess_toggle), { locked = true, dont_inhibit = true })
hl.bind("SUPER + K", hl.dsp.exec_cmd(keyboard_toggle), { locked = true, dont_inhibit = true })
hl.bind("SUPER + X", hl.dsp.exec_cmd(keyboard_toggle), { locked = true, dont_inhibit = true })
hl.bind("SUPER + SHIFT + Q", hl.dsp.exit())

-- Launch Anvil automatically with full D-Bus & systemd environment
-- Exits Hyprland back to greeter when Anvil terminates or Switch to Desktop is pressed
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("env ANVIL_ROOT=" .. anvil_root .. " " .. qs_bin .. " -p " .. daemon .. "; hyprctl dispatch exit")
end)

