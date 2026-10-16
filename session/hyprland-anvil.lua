-- Minimal Anvil Wayland Session (Tauri / WebKit2GTK Hardware-Accelerated Shell)

local home = os.getenv("HOME") or ""
local anvil_root = os.getenv("ANVIL_ROOT") or "/usr/local/share/anvil"
local webui_daemon = anvil_root .. "/scripts/anvil-webui-daemon"

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

update_displays()

hl.on("monitor.added", function()
    update_displays()
end)

hl.on("monitor.removed", function()
    update_displays()
end)

-- Essential input and borderless console layout
hl.config({
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 0
    },
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
        rounding = 0,
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
        vrr = 1
    }
})

-- Audio & Brightness Hardware Keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })
hl.bind("SUPER + SHIFT + Q", hl.dsp.exit())

-- Launch Anvil WebKit2/Tauri Console UI automatically
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP")
    hl.exec_cmd("env ANVIL_ROOT=" .. anvil_root .. " " .. webui_daemon .. "; hyprctl dispatch exit")
end)
