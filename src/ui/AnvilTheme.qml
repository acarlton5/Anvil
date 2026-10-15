import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

Item {
    id: theme

    // Defaults (matches HypeShell theme fallback)
    property color primary: "#76a081"
    property color primaryText: "#101410"
    property color primaryContainer: "#546f5f"
    property color secondary: "#8ca889"
    property color surface: "#333a3c"
    property color surfaceText: "#c7d7c5"
    property color surfaceVariant: "#343b3f"
    property color surfaceVariantText: "#b5c7b8"
    property color background: "#1a2020"
    property color backgroundText: "#c7d7c5"
    property color outline: "#8ca889"
    property color error: "#ffb4ab"
    property color warning: "#d8a657"
    property color accent: primary

    // Dark panel tints based on surface & background
    property color panelBg: Qt.rgba(surface.r * 0.4, surface.g * 0.4, surface.b * 0.4, 0.94)
    property color panelCard: Qt.rgba(surface.r * 0.6, surface.g * 0.6, surface.b * 0.6, 0.92)
    property color panelDeep: Qt.rgba(background.r * 0.3, background.g * 0.3, background.b * 0.3, 0.96)
    property color stroke: outline

    FileView {
        id: themeFileView
        path: Quickshell.env("HOME") + "/.config/HypeShell/themes/abyssgreen/theme.json"
        
        onLoaded: {
            loadTheme(text());
        }
    }

    Process {
        id: settingsReader
        command: ["sh", "-c", "cat ~/.config/HypeShell/settings.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text);
                    if (d.customThemeFile && d.customThemeFile.length > 0) {
                        themeFileView.path = d.customThemeFile;
                    }
                } catch(e) {}
            }
        }
    }

    function loadTheme(jsonText) {
        if (!jsonText || jsonText.trim().length === 0) return;
        try {
            let d = JSON.parse(jsonText);
            let palette = d.dark || d.light || d;
            if (palette.primary) primary = palette.primary;
            if (palette.primaryText) primaryText = palette.primaryText;
            if (palette.primaryContainer) primaryContainer = palette.primaryContainer;
            if (palette.secondary) secondary = palette.secondary;
            if (palette.surface) surface = palette.surface;
            if (palette.surfaceText) surfaceText = palette.surfaceText;
            if (palette.surfaceVariant) surfaceVariant = palette.surfaceVariant;
            if (palette.surfaceVariantText) surfaceVariantText = palette.surfaceVariantText;
            if (palette.background) background = palette.background;
            if (palette.backgroundText) backgroundText = palette.backgroundText;
            if (palette.outline) outline = palette.outline;
            if (palette.error) error = palette.error;
            if (palette.warning) warning = palette.warning;
            accent = primary;
        } catch(e) {
            console.log("[AnvilTheme] Error parsing theme JSON: " + e);
        }
    }

    Component.onCompleted: {
        settingsReader.running = true;
    }
}
