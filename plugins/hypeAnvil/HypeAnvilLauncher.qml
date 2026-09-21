import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var pluginService: null
    property string trigger: "anvil"
    property string anvilRoot: ""
    readonly property string pluginId: "hypeAnvil"
    readonly property string pluginRoot: pluginService ? pluginService.getPluginPath(pluginId) : ""
    readonly property string launcherScript: pluginRoot + "/scripts/launch-anvil"

    signal itemsChanged()

    function getItems(query) {
        const items = [{
            "name": "Open Anvil",
            "icon": "material:sports_esports",
            "comment": "Preview Anvil over the current desktop",
            "action": "open",
            "categories": ["Anvil"]
        }, {
            "name": "Open Anvil Library",
            "icon": "material:view_list",
            "comment": "Preview Anvil directly in the library view",
            "action": "library",
            "categories": ["Anvil"]
        }, {
            "name": "Open Anvil Store",
            "icon": "material:storefront",
            "comment": "Preview the Anvil Store mock",
            "action": "store",
            "categories": ["Anvil"]
        }, {
            "name": "Open Forgeworks",
            "icon": "material:construction",
            "comment": "Preview developer and publisher services",
            "action": "forgeworks",
            "categories": ["Anvil", "Forgeworks"]
        }, {
            "name": "Open Anvil Downloads",
            "icon": "material:download",
            "comment": "Preview installs, updates, and verification",
            "action": "downloads",
            "categories": ["Anvil"]
        }, {
            "name": "Open Anvil Settings",
            "icon": "material:settings",
            "comment": "Preview session, runtime, cloud, and account settings",
            "action": "settings",
            "categories": ["Anvil"]
        }, {
            "name": "Test Anvil Overlay",
            "icon": "material:dashboard_customize",
            "comment": "Open the in-game overlay mock by itself",
            "action": "overlay-test",
            "categories": ["Anvil"]
        }, {
            "name": "Install Anvil Session",
            "icon": "material:install_desktop",
            "comment": "Install the dedicated Anvil Wayland session",
            "action": "install-session",
            "categories": ["Anvil"]
        }, {
            "name": "Switch to Anvil Session",
            "icon": "material:logout",
            "comment": "Install the session and log out to the greeter",
            "action": "switch-session",
            "categories": ["Anvil"]
        }, {
            "name": "Refresh Anvil Artwork",
            "icon": "material:imagesmode",
            "comment": "Fetch missing local cartridge artwork",
            "action": "artwork",
            "categories": ["Anvil"]
        }];
        if (!query || query.length === 0)
            return items;

        const lower = query.toLowerCase();
        return items.filter((item) => {
            return item.name.toLowerCase().includes(lower) || item.comment.toLowerCase().includes(lower);
        });
    }

    function executeItem(item) {
        if (!item)
            return ;

        if (item.action === "artwork") {
            runScript(["--fetch-art"]);
            return ;
        }
        if (item.action === "install-session") {
            runScript(["--install-session"]);
            return ;
        }
        if (item.action === "switch-session") {
            runScript(["--install-session", "--logout"]);
            return ;
        }
        if (item.action === "library") {
            runScript(["--section", "1"]);
            return ;
        }
        if (item.action === "store") {
            runScript(["--section", "2"]);
            return ;
        }
        if (item.action === "forgeworks") {
            runScript(["--section", "4"]);
            return ;
        }
        if (item.action === "downloads") {
            runScript(["--section", "5"]);
            return ;
        }
        if (item.action === "settings") {
            runScript(["--section", "6"]);
            return ;
        }
        if (item.action === "overlay-test") {
            runScript(["--overlay-test"]);
            return ;
        }
        runScript([]);
    }

    function runScript(args) {
        if (!launcherScript) {
            console.warn("hypeAnvil: plugin path unavailable");
            return ;
        }
        if (anvilRoot)
            Quickshell.execDetached(["env", "ANVIL_ROOT=" + anvilRoot, "bash", launcherScript].concat(args));
        else
            Quickshell.execDetached(["bash", launcherScript].concat(args));
    }

    Component.onCompleted: {
        if (pluginService)
            trigger = pluginService.loadPluginData(pluginId, "trigger", "anvil");

        if (pluginService)
            anvilRoot = pluginService.loadPluginData(pluginId, "anvilRoot", "");

    }
    onTriggerChanged: {
        if (pluginService)
            pluginService.savePluginData(pluginId, "trigger", trigger);

    }
}
