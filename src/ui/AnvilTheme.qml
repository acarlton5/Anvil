import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: theme

    // AAA Console Design System (Xbox Series X / Anvil OS)
    property color primary: "#107c10"          // Official Xbox Emerald Green
    property color primaryText: "#ffffff"
    property color primaryContainer: "#1e8e20"
    property color secondary: "#22c55e"        // Xbox Neon Focus
    property color surface: "#11161d"
    property color surfaceText: "#ffffff"
    property color surfaceVariant: "#161e28"
    property color surfaceVariantText: "#8e9fae"
    property color background: "#080b0f"       // Deep Obsidian Carbon
    property color backgroundText: "#ffffff"
    property color outline: "#202d3d"
    property color outlineVariant: "#2a3b4f"
    property color error: "#ef4444"
    property color warning: "#f59e0b"
    property color green: "#22c55e"
    property color accent: primary
    property color surfaceContainerHigh: "#1a2432"

    // Dark glass panel tints
    property color panelBg: "#0d1218"
    property color panelCard: "#141c26"
    property color panelDeep: "#080b0f"
    property color stroke: outline

    FileView {
        id: themeFileView
        path: Quickshell.env("HOME") + "/.config/Anvil/theme.json"
        
        onLoaded: {
            loadTheme(text());
        }
    }

    function loadTheme(jsonText) {
        if (!jsonText || jsonText.trim().length === 0) return;
        try {
            let d = JSON.parse(jsonText);
            let palette = d.dark || d.light || d;
            if (palette.primary) primary = palette.primary;
            if (palette.primaryText) primaryText = palette.primaryText;
            if (palette.secondary) secondary = palette.secondary;
            if (palette.surface) surface = palette.surface;
            if (palette.surfaceText) surfaceText = palette.surfaceText;
            if (palette.background) background = palette.background;
            if (palette.outline) outline = palette.outline;
            accent = primary;
        } catch(e) {
            console.log("[AnvilTheme] Error parsing theme JSON: " + e);
        }
    }
}
