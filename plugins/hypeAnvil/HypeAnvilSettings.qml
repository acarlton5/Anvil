import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "hypeAnvil"

    StyledText {
        width: parent.width
        text: "Anvil"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Launch the standalone Anvil game client from HypeShell. Anvil stays installed and updated as its own app; this plugin only bridges HypeShell to it."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "anvilRoot"
        label: "Anvil Root"
        description: "Optional path to an Anvil checkout or installation. Leave blank to auto-detect common locations."
        defaultValue: ""
        placeholder: "$HOME/Projects/Projects/Anvil"
    }

    StringSetting {
        settingKey: "trigger"
        label: "Launcher Trigger"
        description: "Text that activates Anvil actions in the HypeShell launcher."
        defaultValue: "anvil"
        placeholder: "anvil"
    }

}
