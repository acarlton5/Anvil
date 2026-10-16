import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: anvil

    property var modelData: null
    property var launchHandler: null
    property var cancelLaunchHandler: null
    property string controllerAction: ""
    property int controllerActionSerial: 0
    property string controllerFamily: "steamdeck"
    property string controllerName: "Controller"
    readonly property string localRoot: {
        let envRoot = Quickshell.env("ANVIL_ROOT");
        if (envRoot && envRoot.length > 0) return envRoot;
        let resolved = decodeURIComponent(Qt.resolvedUrl("../../").toString()).replace("file://", "").replace(/\/$/, "");
        if (resolved && !resolved.startsWith("qrc:")) return resolved;
        return "/usr/local/share/anvil";
    }
    readonly property string anvilRoot: localRoot
    readonly property string bridgePath: anvilRoot + "/src/daemon/anvil-library-bridge"
    readonly property string daemonPath: anvilRoot + "/src/ui/AnvilDaemon.qml"
    readonly property color bg: AnvilTheme.background
    readonly property color panel: AnvilTheme.panelBg
    readonly property color panelRaised: AnvilTheme.panelCard
    readonly property color line: AnvilTheme.outline
    readonly property color fg: AnvilTheme.surfaceText
    readonly property color muted: AnvilTheme.surfaceVariantText
    readonly property color ember: "#ff6537"
    readonly property color emberLight: "#ff8a66"
    readonly property color forgeGold: "#d9ad5f"
    readonly property color relayBlue: "#7aa8ff"
    readonly property color green: "#65d797"
    readonly property int sidebarWidth: 0
    readonly property int contentLeft: 48
    property int activeSection: Number(Quickshell.env("ANVIL_SECTION") || 0)
    property bool powerMenuActive: false
    property bool gameIsLoading: false
    property bool libraryScanRunning: true
    property string libraryScanMessage: "Mounting cartridges"
    property string mediaStatusLabel: "Scanning"
    property string updateStatusLabel: "Checking"
    property bool updateAvailable: false
    property int selectedStoreTile: 0
    property int selectedGameIndex: 0
    property int selectedSetting: 0
    property int selectedCommunityItem: 0
    property int selectedPowerIndex: 3
    property bool profileModalActive: false
    property int selectedProfileIndex: 0
    property string profileGamerTag: "Morphine"
    property string profileBio: "Steam Deck Console Edition"
    property int profileGamerscore: 1420

    function triggerPowerAction(actionName) {
        if (actionName === "Switch to Desktop") {
            Quickshell.execDetached(["sh", "-c", "command -v anvil-switch-desktop >/dev/null 2>&1 && anvil-switch-desktop || hyprctl dispatch exit"]);
            Quickshell.execDetached(["systemctl", "--user", "stop", "anvil.service"]);
            Qt.quit();
        } else if (actionName === "Sleep") {
            Quickshell.execDetached(["sh", "-c", "loginctl suspend 2>/dev/null || systemctl suspend"]);
        } else if (actionName === "Restart") {
            Quickshell.execDetached(["sh", "-c", "loginctl reboot 2>/dev/null || systemctl reboot"]);
        } else if (actionName === "Shut Down") {
            Quickshell.execDetached(["sh", "-c", "loginctl poweroff 2>/dev/null || systemctl poweroff"]);
        }
    }

    function currentGame() {
        if (gameModel.count === 0)
            return null;

        return gameModel.get(Math.max(0, Math.min(selectedGameIndex, gameModel.count - 1)));
    }

    function gameArt(game) {
        if (!game || game.dummy)
            return "";

        return game.hero || "";
    }

    function gameBoxArt(game) {
        if (!game || game.dummy)
            return "";

        return game.grid || "";
    }

    function gameLandscapeArt(game) {
        if (!game || game.dummy)
            return "";

        return game.hero || "";
    }

    function tagLine(game) {
        if (!game || !game.tags)
            return "READY TO PLAY";

        if (Array.isArray(game.tags))
            return game.tags.join(" / ").toUpperCase();

        return String(game.tags).toUpperCase();
    }

    function initials(name) {
        if (!name)
            return "A";

        let words = String(name).replace(/[^A-Za-z0-9 ]/g, " ").split(/\s+/).filter((word) => {
            return word.length > 0;
        });
        if (words.length === 0)
            return "A";

        if (words.length === 1)
            return words[0].slice(0, 2).toUpperCase();

        return (words[0][0] + words[1][0]).toUpperCase();
    }

    function selectSection(index) {
        activeSection = Math.max(0, Math.min(index, navModel.count - 1));
    }

    function currentSectionLabel() {
        if (navModel.count === 0)
            return "Home";

        return navModel.get(Math.max(0, Math.min(activeSection, navModel.count - 1))).label;
    }

    function currentSectionSubtitle() {
        switch (activeSection) {
        case 0:
            return "Jump back in";
        case 1:
            return "Your complete game collection";
        case 2:
            return "Featured titles, specials, discovery";
        case 3:
            return "Activity feed, parties, screenshot showcase";
        case 4:
            return "Level progression, milestones, showcase";
        case 5:
            return "Network queue, background updates, verification";
        case 6:
            return "Display, controller haptics, cloud sync, system";
        default:
            return "Anvil OS";
        }
    }

    function glyph(action) {
        let family = String(controllerFamily || "steamdeck").toLowerCase();
        if (action === "accept")
            action = "south";
        else if (action === "back")
            action = "east";
        else if (action === "prev")
            action = "lt";
        else if (action === "next")
            action = "rt";
        else if (action === "menu")
            action = "start";
        if (family === "steamdeck") {
            if (action === "south")
                return "A";
            if (action === "east")
                return "B";
            if (action === "north")
                return "Y";
            if (action === "west")
                return "X";
            if (action === "start")
                return "≡";
            if (action === "back")
                return "⧉";
            if (action === "guide")
                return "STEAM";
            if (action === "quickaccess")
                return "•••";
            if (action === "lb")
                return "L1";
            if (action === "rb")
                return "R1";
            if (action === "lt")
                return "L2";
            if (action === "rt")
                return "R2";
        } else if (family === "playstation") {
            if (action === "south")
                return "✕";
            if (action === "east")
                return "○";
            if (action === "north")
                return "△";
            if (action === "west")
                return "□";
            if (action === "start")
                return "Options";
            if (action === "guide")
                return "PS";
            if (action === "lb")
                return "L1";
            if (action === "rb")
                return "R1";
            if (action === "lt")
                return "L2";
            if (action === "rt")
                return "R2";
        } else if (family === "nintendo") {
            if (action === "south")
                return "A";
            if (action === "east")
                return "B";
            if (action === "north")
                return "X";
            if (action === "west")
                return "Y";
            if (action === "start")
                return "+";
            if (action === "guide")
                return "Home";
            if (action === "lb")
                return "L";
            if (action === "rb")
                return "R";
            if (action === "lt")
                return "ZL";
            if (action === "rt")
                return "ZR";
        }
        if (action === "south")
            return "A";
        if (action === "east")
            return "B";
        if (action === "north")
            return "Y";
        if (action === "west")
            return "X";
        if (action === "start")
            return "Menu";
        if (action === "guide")
            return "Steam";
        if (action === "lb")
            return "L1";
        if (action === "rb")
            return "R1";
        if (action === "lt")
            return "L2";
        if (action === "rt")
            return "R2";
        return action;
    }

    function glyphColor(action) {
        let family = String(controllerFamily || "xbox").toLowerCase();
        if (action === "accept")
            action = "south";
        else if (action === "back")
            action = "east";
        else if (action === "prev")
            action = "lt";
        else if (action === "next")
            action = "rt";
        if (family === "playstation") {
            if (action === "south")
                return "#74b9ff";
            if (action === "east")
                return "#ff6b6b";
            if (action === "north")
                return "#65d797";
            if (action === "west")
                return "#f08cff";
        }
        return fg;
    }

    function controllerShortName() {
        let family = String(controllerFamily || "steamdeck").toLowerCase();
        if (family === "steamdeck")
            return "Steam Deck";
        if (family === "playstation")
            return "PS Controller";
        if (family === "nintendo")
            return "Switch Controller";
        if (family === "keyboard")
            return "Keyboard";
        if (family === "xbox")
            return "Xbox Controller";
        return "Controller";
    }

    function controllerIcon() {
        let family = String(controllerFamily || "xbox").toLowerCase();
        let prefix = anvilRoot.startsWith("file://") ? "" : "file://";
        if (family === "playstation")
            return prefix + anvilRoot + "/assets/controllercons/solid/ps5.svg";
        if (family === "nintendo")
            return prefix + anvilRoot + "/assets/controllercons/solid/switch-pro.svg";
        if (family === "xbox")
            return prefix + anvilRoot + "/assets/controllercons/solid/xbox-series-x.svg";
        return "";
    }

    function inputRuntimeLabel(game) {
        let mode = game && game.input_action_summary ? String(game.input_action_summary.runtime_mode || "") : "";
        if (mode === "xinput_compat")
            return "XInput";
        if (mode === "forgeworks_input")
            return "Anvil Input";
        if (mode === "native")
            return "Native";
        return "Default";
    }

    function inputGlyphLabel(game) {
        let mode = game && game.input_action_summary ? String(game.input_action_summary.glyph_mode || "") : "";
        if (mode === "game_xbox_only")
            return "Xbox glyphs";
        if (mode === "anvil_glyphs")
            return "Anvil glyphs";
        if (mode === "native")
            return "Native glyphs";
        return "Auto";
    }

    function selectedSettingKey() {
        if (settingsModel.count === 0)
            return "";
        return settingsModel.get(Math.max(0, Math.min(selectedSetting, settingsModel.count - 1))).key || "";
    }

    function settingsOptions(key) {
        if (key === "session")
            return ["Start Anvil on login", "Mount removable game media", "Check for client updates"];
        if (key === "runtime")
            return ["Prefer native Linux builds", "Use compatibility runtime", "Enable in-game overlay"];
        if (key === "cloud")
            return ["Sync save data", "Sync controller layouts", "Allow offline queue"];
        if (key === "guard")
            return ["Require sign-in approval", "Remember this device", "Family controls"];
        return [];
    }

    function inputActionLabel(action) {
        if (action === "south")
            return glyph("south") + " / South";
        if (action === "east")
            return glyph("east") + " / East";
        if (action === "north")
            return glyph("north") + " / North";
        if (action === "west")
            return glyph("west") + " / West";
        if (action === "lb")
            return glyph("lb");
        if (action === "rb")
            return glyph("rb");
        if (action === "lt")
            return glyph("lt");
        if (action === "rt")
            return glyph("rt");
        if (action === "back")
            return "Back";
        if (action === "start")
            return glyph("menu");
        if (action === "guide")
            return glyph("guide");
        if (action === "left" || action === "right" || action === "up" || action === "down")
            return action.charAt(0).toUpperCase() + action.slice(1);
        return "Waiting";
    }

    function launchGame() {
        let game = currentGame();
        if (!game || game.dummy || !game.launch_command)
            return ;

        gameIsLoading = true;
        console.log("Launching: " + game.name);
        if (launchHandler) {
            launchHandler(game.launch_command, game);
            return ;
        }
        launcher.command = ["qs", "ipc", "-p", daemonPath, "call", "anvil", "launch", game.launch_command];
        launcher.running = true;
    }

    function cancelGameLaunch() {
        gameIsLoading = false;
        if (cancelLaunchHandler) {
            cancelLaunchHandler();
            return ;
        }
        cancelLauncher.command = ["qs", "ipc", "-p", daemonPath, "call", "anvil", "kill"];
        cancelLauncher.running = true;
    }

    function moveGameSelection(delta) {
        if (gameModel.count === 0)
            return ;
        let target = Math.max(0, Math.min(gameModel.count - 1, selectedGameIndex + delta));
        selectedGameIndex = target;
        if (activeSection === 0 && gameStrip) {
            gameStrip.currentIndex = target;
            gameStrip.positionViewAtIndex(target, ListView.Contain);
        } else if (activeSection === 1 && libraryGrid) {
            libraryGrid.currentIndex = target;
            libraryGrid.positionViewAtIndex(target, GridView.Contain);
        }
    }

    function handleControllerAction(action) {
        if (gameIsLoading) {
            if (action === "east" || action === "back")
                cancelGameLaunch();
            return ;
        }
        if (profileModalActive) {
            let pOptions = ["Customize Profile", "View Achievements", "Privacy & Online Safety", "Switch User / Sign Out"];
            if (action === "up") {
                selectedProfileIndex = Math.max(0, selectedProfileIndex - 1);
            } else if (action === "down") {
                selectedProfileIndex = Math.min(pOptions.length - 1, selectedProfileIndex + 1);
            } else if (action === "south") {
                if (selectedProfileIndex === 1) {
                    profileModalActive = false;
                    selectSection(3); // Community / Achievements
                } else if (selectedProfileIndex === 0) {
                    profileModalActive = false;
                    selectSection(6); // Settings
                } else {
                    profileModalActive = false;
                }
            } else if (action === "east" || action === "back" || action === "start") {
                profileModalActive = false;
            }
            return;
        }
        if (powerMenuActive) {
            let options = ["Sleep", "Restart", "Shut Down", "Switch to Desktop"];
            if (action === "up") {
                selectedPowerIndex = Math.max(0, selectedPowerIndex - 1);
            } else if (action === "down") {
                selectedPowerIndex = Math.min(options.length - 1, selectedPowerIndex + 1);
            } else if (action === "south") {
                triggerPowerAction(options[selectedPowerIndex]);
            } else if (action === "east" || action === "back" || action === "start") {
                powerMenuActive = false;
            }
            return;
        }
        if (cartridgeModalActive) {
            if (action === "up") {
                selectedCartridgeOption = Math.max(0, selectedCartridgeOption - 1);
            } else if (action === "down") {
                selectedCartridgeOption = Math.min(2, selectedCartridgeOption + 1);
            } else if (action === "south") {
                triggerCartridgeInit(selectedCartridgeOption);
            } else if (action === "east" || action === "back") {
                cartridgeModalActive = false;
            }
            return;
        }
        if (action === "lt" || action === "lb")
            selectSection(activeSection - 1);
        else if (action === "rt" || action === "rb")
            selectSection(activeSection + 1);
        else if (action === "left") {
            if (activeSection === 0 || activeSection === 1) moveGameSelection(-1);
            else if (activeSection === 2) selectedStoreTile = Math.max(0, selectedStoreTile - 1);
        } else if (action === "right") {
            if (activeSection === 0 || activeSection === 1) moveGameSelection(1);
            else if (activeSection === 2) selectedStoreTile = Math.min(storeModel.count - 1, selectedStoreTile + 1);
        } else if (action === "up") {
            if (activeSection === 1) moveGameSelection(-4);
            else if (activeSection === 3) selectedCommunityItem = Math.max(0, selectedCommunityItem - 1);
            else if (activeSection === 6) selectedSetting = Math.max(0, selectedSetting - 1);
        } else if (action === "down") {
            if (activeSection === 1) moveGameSelection(4);
            else if (activeSection === 3) selectedCommunityItem = Math.min(communityModel.count - 1, selectedCommunityItem + 1);
            else if (activeSection === 6) selectedSetting = Math.min(settingsModel.count - 1, selectedSetting + 1);
        } else if (action === "south") {
            if (activeSection === 0 || activeSection === 1) launchGame();
            else if (activeSection === 6 && selectedSettingKey() === "storage") {
                cartridgeModalActive = true;
                cartridgeStatusMsg = "";
            }
        } else if (action === "start")
            powerMenuActive = !powerMenuActive;
        else if (action === "east" || action === "back") {
            if (powerMenuActive)
                powerMenuActive = false;
            else
                selectSection(0);
        }
    }

    onControllerActionSerialChanged: handleControllerAction(controllerAction)

    color: bg
    screen: modelData
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "anvil-launcher"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    ListModel {
        id: gameModel
    }

    ListModel {
        id: navModel

        ListElement {
            label: "Home"
            icon: "user-home-symbolic"
        }

        ListElement {
            label: "Library"
            icon: "view-grid-symbolic"
        }

        ListElement {
            label: "Store"
            icon: "system-software-install-symbolic"
        }

        ListElement {
            label: "Community"
            icon: "system-users-symbolic"
        }

        ListElement {
            label: "Profile"
            icon: "avatar-default-symbolic"
        }

        ListElement {
            label: "Downloads"
            icon: "folder-download-symbolic"
        }

        ListElement {
            label: "Settings"
            icon: "preferences-system-symbolic"
        }

    }

    ListModel {
        id: storeModel

        ListElement {
            title: "Elden Ring: Shadow of the Erdtree"
            eyebrow: "FEATURED THIS WEEK"
            price: "$39.99"
            originalPrice: "$49.99"
            discount: "-20%"
            tag: "Deck Verified · Action RPG"
            rating: "96% Positive"
            art: "https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=800&q=80"
        }

        ListElement {
            title: "Hades II"
            eyebrow: "TOP RATED"
            price: "$29.99"
            originalPrice: "$29.99"
            discount: ""
            tag: "Deck Verified · Roguelike"
            rating: "98% Overwhelmingly Positive"
            art: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?auto=format&fit=crop&w=800&q=80"
        }

        ListElement {
            title: "Outer Wilds: Archeologist Edition"
            eyebrow: "STAFF PICK"
            price: "$24.49"
            originalPrice: "$34.99"
            discount: "-30%"
            tag: "Deck Verified · Exploration"
            rating: "97% Overwhelmingly Positive"
            art: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=800&q=80"
        }

        ListElement {
            title: "Cyberpunk 2077: Ultimate"
            eyebrow: "ANVIL SPOTLIGHT"
            price: "$47.99"
            originalPrice: "$79.99"
            discount: "-40%"
            tag: "Ray Tracing · Open World"
            rating: "89% Very Positive"
            art: "https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=800&q=80"
        }
    }

    ListModel {
        id: communityModel

        ListElement {
            title: "Niko unlocked Shardbearer Godrick"
            body: "“First attempt after 3 hours of practicing dodge timings!”"
            meta: "Achievement · 18m ago"
        }

        ListElement {
            title: "Amaya recommended Outer Wilds"
            body: "“Go into this completely blind. One of the best games ever made on Deck.”"
            meta: "Review · 2h ago"
        }

        ListElement {
            title: "Rowan created a joinable lobby"
            body: "Borderlands 3 — Mayhem Mode 4 farming run. 2 open slots."
            meta: "Co-op Lobby · Joinable"
        }

        ListElement {
            title: "Anvil Community Screenshot of the Day"
            body: "Stunning dusk vista on Mount Gagazet captured in 800p OLED HDR."
            meta: "Screenshot · 84 Likes"
        }
    }

    ListModel {
        id: forgeworksModel

        ListElement {
            title: "App onboarding"
            body: "Create apps, package IDs, tester grants, and sandbox entitlements."
            state: "Mock"
        }

        ListElement {
            title: "Forgepipe builds"
            body: "Upload depots, sign manifests, promote branches, and verify installs."
            state: "Next"
        }

        ListElement {
            title: "Player platform APIs"
            body: "Achievements, cloud saves, lobbies, relay, inventory, and presence."
            state: "Planned"
        }

        ListElement {
            title: "Partner operations"
            body: "Reviews, analytics, crash reports, keys, refunds, payouts, and moderation."
            state: "Planned"
        }

    }

    ListModel {
        id: downloadModel

        ListElement {
            title: "Anvil OS 2.4.1 System Update"
            body: "Proton 11 kernel patches, Deck OLED HDR color profile calibration."
            value: "48.2 MB/s · 86%"
            progress: 86
        }

        ListElement {
            title: "Crash Bandicoot N. Sane Trilogy"
            body: "Vulkan shader pre-caching and Steam Deck controller layout verification."
            value: "Verified & Ready"
            progress: 100
        }

        ListElement {
            title: "Cyberpunk 2077: Phantom Liberty"
            body: "Patch 2.21 compatibility files (14.2 GB)."
            value: "Queued"
            progress: 0
        }
    }

    ListModel {
        id: settingsModel

        ListElement {
            key: "storage"
            title: "Storage & Cartridges"
            body: "Configure removable SD cards, external USB drives, or folders as plug-and-play Anvil game cartridges."
            value: "MicroSD Active · 48 Games"
            badge: "SD"
        }

        ListElement {
            key: "input"
            title: "Controller & Calibration"
            body: "Steam Deck built-in gamepad, zero-drift deadzone filter, decoupled IMU gyro, and live button diagnostics."
            value: "Zero-Drift Active"
            badge: "PAD"
        }

        ListElement {
            key: "display"
            title: "Display & Graphics"
            body: "Steam Deck native 1280x800 resolution lock, 60Hz refresh rate timing, and fullscreen scaling."
            value: "1280x800 · 60Hz"
            badge: "60"
        }

        ListElement {
            key: "runtime"
            title: "Proton & Compatibility"
            body: "Compatibility runner selection, per-cartridge working directory preservation, and prefix isolation."
            value: "GE-Proton"
            badge: "RUN"
        }

        ListElement {
            key: "session"
            title: "System & Hardware"
            body: "Valve Steam Deck hardware specifications, Wayland compositor status, and Anvil OS build information."
            value: "Anvil OS v2.4"
            badge: "SYS"
        }
    }

    Timer {
        id: autoRescanTimer
        interval: 3500
        repeat: true
        running: true
        onTriggered: {
            if (!pythonBridge.running) {
                pythonBridge.running = true;
            }
        }
    }

    Process {
        id: pythonBridge

        command: ["python3", bridgePath]
        running: true

        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0)
                    console.log("[Anvil Bridge stderr]: " + text.trim());
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let payload = text.trim();
                    let jsonStart = payload.indexOf("{");
                    if (jsonStart === -1)
                        jsonStart = payload.indexOf("[");
                    if (jsonStart !== -1)
                        payload = payload.substring(jsonStart);

                    let status = payload.length > 0 ? JSON.parse(payload) : {};
                    let games = Array.isArray(status) ? status : (status.games || []);
                    let newKeys = games.map(g => g.name || g.forgeworks_app_id || g.id || g.title || "").join("||");
                    let currentKeys = [];
                    for (let i = 0; i < gameModel.count; i++) {
                        let item = gameModel.get(i);
                        currentKeys.push(item.name || item.forgeworks_app_id || item.id || item.title || "");
                    }
                    if (newKeys !== currentKeys.join("||")) {
                        gameModel.clear();
                        for (let i = 0; i < games.length; i++) {
                            gameModel.append(games[i]);
                        }
                        selectedGameIndex = Math.min(selectedGameIndex, Math.max(0, gameModel.count - 1));
                    }

                    mediaStatusLabel = status.drives && status.drives.length > 0 ? status.drives.length + " media" : "No media";
                    if (status.mounted && status.mounted.length > 0)
                        mediaStatusLabel = "Mounted " + status.mounted.length;

                    updateStatusLabel = status.update && status.update.label ? status.update.label : "Update status unavailable";
                    updateAvailable = Boolean(status.update && status.update.available);
                    libraryScanMessage = games.length > 0 ? games.length + " cartridges ready" : "No cartridge library found";
                } catch (e) {
                    console.log("Anvil bridge parse error: " + e);
                    libraryScanMessage = "Library scan failed";
                    mediaStatusLabel = "Scan failed";
                    updateStatusLabel = "Update check skipped";
                }
                libraryScanRunning = false;
            }
        }

    }

    Rectangle {
        anchors.fill: parent
        color: bg
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.68

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#151b22"
            }

            GradientStop {
                position: 0.22
                color: "#0b0f14"
            }

            GradientStop {
                position: 0.58
                color: bg
            }

            GradientStop {
                position: 1
                color: bg
            }

        }

    }

    Image {
        id: heroImage

        anchors.fill: parent
        source: gameArt(currentGame())
        fillMode: Image.PreserveAspectCrop
        opacity: source === "" ? 0 : (activeSection === 0 ? 0.88 : 0.18)
        visible: source !== ""

        Behavior on opacity {
            NumberAnimation {
                duration: 320
                easing.type: Easing.OutCubic
            }

        }

    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: activeSection === 0 ? "#ed06080c" : "#f806080c"
            }

            GradientStop {
                position: 0.34
                color: activeSection === 0 ? "#8206080c" : "#ed06080c"
            }

            GradientStop {
                position: 0.72
                color: activeSection === 0 ? "#3006080c" : "#e606080c"
            }

            GradientStop {
                position: 1
                color: activeSection === 0 ? "#b806080c" : "#fa06080c"
            }

        }

    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#0006080c"
            }

            GradientStop {
                position: 0.54
                color: activeSection === 0 ? "#1806080c" : "#b806080c"
            }

            GradientStop {
                position: 0.78
                color: activeSection === 0 ? "#c906080c" : "#ed06080c"
            }

            GradientStop {
                position: 1
                color: "#fa06080c"
            }

        }

    }

    Rectangle {
        id: topbar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 72
        color: "#d8080b0f"
        border.color: "#161e28"
        border.width: 1
        z: 30

        // Profile & Gamer Info (Xbox style interactive chip)
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft - 8
            anchors.verticalCenter: parent.verticalCenter
            height: 44
            width: profileRow.implicitWidth + 20
            radius: 22
            color: profileChipArea.containsMouse || profileModalActive ? "#182330" : "transparent"
            border.color: profileModalActive ? "#ff6537" : (profileChipArea.containsMouse ? "#2f3e50" : "transparent")
            border.width: 1.5

            Row {
                id: profileRow
                anchors.centerIn: parent
                spacing: 11

                Rectangle {
                    width: 34
                    height: 34
                    radius: 10
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#ff6537" }
                        GradientStop { position: 1.0; color: "#cf3810" }
                    }
                    border.color: "#ff8a66"
                    border.width: 1.5
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: profileGamerTag.length > 0 ? profileGamerTag.charAt(0).toUpperCase() : "M"
                        color: "#ffffff"
                        font.pixelSize: 15
                        font.bold: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: profileGamerTag
                        color: "#ffffff"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Row {
                        spacing: 4
                        Text {
                            text: "LEVEL"
                            color: "#ff6537"
                            font.pixelSize: 9
                            font.bold: true
                        }
                        Text {
                            text: "42"
                            color: "#e2e8f0"
                            font.pixelSize: 10
                            font.bold: true
                        }
                    }
                }
            }

            MouseArea {
                id: profileChipArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    profileModalActive = !profileModalActive;
                    if (profileModalActive) powerMenuActive = false;
                }
            }
        }

        // Center Xbox Navigation Tabs
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // LB Trigger badge
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 24
                radius: 4
                color: "#18222e"
                border.color: "#273648"

                Text {
                    anchors.centerIn: parent
                    text: "L1"
                    color: "#94a3b8"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: selectSection(activeSection - 1)
                }
            }

            Repeater {
                model: navModel

                Rectangle {
                    width: Math.max(90, navLabel.implicitWidth + 30)
                    height: 38
                    radius: 8
                    color: activeSection === index ? "#1c2634" : (navMouse.containsMouse ? "#131b24" : "transparent")
                    border.color: activeSection === index ? "#ff6537" : "transparent"
                    border.width: 1.5

                    Row {
                        anchors.centerIn: parent
                        spacing: 7

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 15
                            height: 15
                            source: Quickshell.iconPath(model.icon, true)
                            sourceSize.width: 30
                            sourceSize.height: 30
                            opacity: activeSection === index ? 1 : 0.6
                        }

                        Text {
                            id: navLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: model.label.toUpperCase()
                            color: activeSection === index ? "#ffffff" : "#8e9fad"
                            font.pixelSize: 12
                            font.bold: activeSection === index
                            font.letterSpacing: 0.8
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -1
                        width: activeSection === index ? Math.max(26, navLabel.implicitWidth) : 0
                        height: 3
                        radius: 2
                        color: "#ff6537"
                        visible: activeSection === index
                    }

                    MouseArea {
                        id: navMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: selectSection(index)
                    }
                }
            }

            // RB Trigger badge
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 24
                radius: 4
                color: "#18222e"
                border.color: "#273648"

                Text {
                    anchors.centerIn: parent
                    text: "R1"
                    color: "#94a3b8"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: selectSection(activeSection + 1)
                }
            }
        }

        // System Status (Battery, Clock, Power)
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "h:mm AP")
                color: "#ffffff"
                font.pixelSize: 13
                font.bold: true
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 30
                height: 30
                radius: 6
                color: powerMouse.containsMouse ? "#202b38" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    color: powerMenuActive ? "#22c55e" : "#8e9fad"
                    font.pixelSize: 16
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: powerMenuActive = !powerMenuActive
                }
            }
        }
    }

    Rectangle {
        id: sideNav

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: bottomHints.top
        width: sidebarWidth
        visible: false
        color: "#e706090d"
        border.color: "#24303a"
        z: 24

        Column {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 22
            anchors.bottomMargin: 16
            spacing: 14

            Row {
                width: parent.width
                height: 62
                spacing: 0

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 56
                    height: 56
                    radius: 8
                    color: "#151b22"
                    border.color: ember

                    Text {
                        anchors.centerIn: parent
                        text: "A"
                        color: emberLight
                        font.pixelSize: 30
                        font.bold: true
                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#26313c"
            }

            Repeater {
                model: navModel

                Rectangle {
                    width: parent.width
                    height: 58
                    radius: 8
                    color: activeSection === index ? "#f0ff6537" : (mouseNav.containsMouse ? "#29151d25" : "transparent")
                    border.color: activeSection === index ? ember : (mouseNav.containsMouse ? "#40505f" : "transparent")
                    scale: activeSection === index ? 1.04 : 1.0

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 42
                        radius: 2
                        color: activeSection === index ? "#170b07" : ember
                        visible: activeSection === index
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        radius: 8
                        color: activeSection === index ? "#170b07" : "#121820"
                        border.color: activeSection === index ? "#170b07" : "#2d3844"

                        Image {
                            anchors.centerIn: parent
                            width: 24
                            height: 24
                            source: Quickshell.iconPath(model.icon, true)
                            sourceSize.width: 48
                            sourceSize.height: 48
                            opacity: activeSection === index ? 1 : 0.7
                        }

                    }

                    MouseArea {
                        id: mouseNav

                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: selectSection(index)
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }
                }

            }

            Item {
                width: parent.width
                height: Math.max(0, sideNav.height - 32 - 62 - 14 - 1 - 14 - navModel.count * 72 - 58)
            }

            Rectangle {
                width: parent.width
                height: 58
                radius: 8
                color: "#111820"
                border.color: line

                Text {
                    anchors.centerIn: parent
                    text: libraryScanRunning ? "..." : gameModel.count
                    color: green
                    font.pixelSize: 19
                    font.bold: true
                }

            }

        }

    }

    Item {
        id: homePage

        anchors.fill: parent
        visible: activeSection === 0

        Rectangle {
            id: focusStage

            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            width: Math.min(980, parent.width * 0.62)
            anchors.top: parent.top
            anchors.topMargin: 110
            anchors.bottom: shelf.top
            anchors.bottomMargin: 8
            color: "transparent"

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                spacing: 12

                Image {
                    width: Math.min(480, parent.width)
                    height: 110
                    source: currentGame() ? (currentGame().logo || "") : ""
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    verticalAlignment: Image.AlignBottom
                    visible: source !== ""
                }

                Text {
                    text: currentGame() ? currentGame().name : (libraryScanRunning ? "Scanning Cartridges" : "Anvil Library")
                    color: "#ffffff"
                    font.pixelSize: 40
                    font.bold: true
                    font.letterSpacing: -0.5
                    width: Math.min(680, parent.width)
                    elide: Text.ElideRight
                    visible: !currentGame() || !currentGame().logo
                }

                // Xbox Feature Badges (e.g. X|S ENHANCED, DECK VERIFIED)
                Row {
                    spacing: 8
                    visible: currentGame() !== null

                    Rectangle {
                        height: 22
                        width: xsText.implicitWidth + 16
                        radius: 4
                        color: "#ff6537"
                        Text {
                            id: xsText
                            anchors.centerIn: parent
                            text: "ANVIL OPTIMIZED"
                            color: "#ffffff"
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                    }

                    Rectangle {
                        height: 22
                        width: cartridgePill.implicitWidth + 16
                        radius: 4
                        color: "#1f1d2b"
                        border.color: "#ff6537"
                        Text {
                            id: cartridgePill
                            anchors.centerIn: parent
                            text: "CARTRIDGE · " + (currentGame() && currentGame().runner ? currentGame().runner.toUpperCase() : "PROTON")
                            color: "#ff8a66"
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                    }

                    Rectangle {
                        height: 22
                        width: protonText.implicitWidth + 16
                        radius: 4
                        color: "#16202c"
                        border.color: "#263548"
                        Text {
                            id: protonText
                            anchors.centerIn: parent
                            text: (currentGame() && currentGame().drive) ? currentGame().drive.toUpperCase() : "MOUNTED MEDIA"
                            color: "#94a3b8"
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0.8
                        }
                    }
                }

                // Xbox Action Buttons Row ([A] PLAY, [X] OPTIONS)
                Row {
                    spacing: 12
                    visible: currentGame() !== null

                    Rectangle {
                        width: 160
                        height: 48
                        radius: 8
                        color: ember

                        Row {
                            anchors.centerIn: parent
                            spacing: 10

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: "#ffffff"
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "A"
                                    color: "#107c10"
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "PLAY GAME"
                                color: "#ffffff"
                                font.pixelSize: 14
                                font.bold: true
                                font.letterSpacing: 1.0
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: launchGame()
                        }
                    }

                    Rectangle {
                        width: 130
                        height: 48
                        radius: 8
                        color: "#1a232f"
                        border.color: "#2c3b4e"

                        Row {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: "#2c3b4e"
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    anchors.centerIn: parent
                                    text: "X"
                                    color: "#38bdf8"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "OPTIONS"
                                color: "#94a3b8"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: selectSection(5)
                        }
                    }
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 162
            spacing: 1
            visible: false

            Repeater {
                model: [{
                    "label": "Media",
                    "value": mediaStatusLabel
                }, {
                    "label": "Updates",
                    "value": updateStatusLabel
                }, {
                    "label": "Mode",
                    "value": "Anvil"
                }]

                Rectangle {
                    width: 132
                    height: 86
                    color: "#bb0f141a"
                    border.color: "#2c3743"

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: muted
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.value
                            color: modelData.label === "Updates" && updateAvailable ? emberLight : fg
                            font.pixelSize: 13
                            font.bold: true
                            width: parent.width - 16
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                    }

                }

            }

        }

        Item {
            id: shelf

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 52
            height: 270

            Text {
                anchors.left: parent.left
                anchors.leftMargin: contentLeft
                anchors.top: parent.top
                text: "CARTRIDGES & INSTALLED GAMES"
                color: "#8fa0b5"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.5
            }

            ListView {
                id: gameStrip

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 240
                orientation: ListView.Horizontal
                spacing: 16
                leftMargin: contentLeft
                rightMargin: 72
                model: gameModel
                currentIndex: selectedGameIndex
                focus: !powerMenuActive && activeSection === 0
                preferredHighlightBegin: contentLeft
                preferredHighlightEnd: contentLeft + 340
                highlightRangeMode: ListView.StrictlyEnforceRange
                Keys.onLeftPressed: decrementCurrentIndex()
                Keys.onRightPressed: incrementCurrentIndex()
                onCurrentIndexChanged: selectedGameIndex = currentIndex
                Keys.onReturnPressed: launchGame()
                Keys.onEscapePressed: powerMenuActive = false

                delegate: Item {
                    id: card
                    property string boxSource: model.grid || ""
                    property string landscapeSource: model.hero || ""
                    property string logoSource: model.logo || ""
                    property bool focused: ListView.isCurrentItem || hoverArea.containsMouse

                    width: 154
                    height: 226
                    scale: focused ? 1.05 : 1.0
                    opacity: focused ? 1.0 : 0.65
                    z: focused ? 10 : 1
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: cardSurface

                        anchors.fill: parent
                        radius: 12
                        color: "#131c28"
                        border.color: focused ? ember : "#1e2a3c"
                        border.width: focused ? 3 : 1
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            visible: boxSource === ""

                            Text {
                                anchors.centerIn: parent
                                text: initials(model.name)
                                color: "#94a3b8"
                                opacity: 0.5
                                font.pixelSize: 56
                                font.bold: true
                            }

                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0; color: "#1e293b" }
                                GradientStop { position: 1; color: "#0f172a" }
                            }
                        }

                        Image {
                            id: boxArtImage
                            anchors.fill: parent
                            source: boxSource
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== ""
                        }

                        // Gradient protection at bottom of card
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 60
                            gradient: Gradient {
                                GradientStop { position: 0; color: "transparent" }
                                GradientStop { position: 1; color: "#d0090d14" }
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            spacing: 3

                            Text {
                                text: model.name
                                color: "#ffffff"
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                                visible: boxSource === "" || focused
                            }
                        }
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            selectedGameIndex = index;
                            gameStrip.currentIndex = index;
                        }
                        onClicked: {
                            selectedGameIndex = index;
                            gameStrip.currentIndex = index;
                            gameStrip.forceActiveFocus();
                        }
                        onDoubleClicked: launchGame()
                    }
                }
            }
        }
    }

    Item {
        id: libraryConsolePage

        anchors.fill: parent
        visible: activeSection === 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 126
            text: "Library"
            color: fg
            font.pixelSize: 38
            font.bold: true
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 184
            spacing: 26

            Repeater {
                model: ["ALL  " + gameModel.count, "INSTALLED", "CARTRIDGES"]

                Text {
                    text: modelData
                    color: index === 0 ? fg : muted
                    font.pixelSize: 12
                    font.bold: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.bottom
                        anchors.topMargin: 8
                        height: 3
                        radius: 2
                        color: ember
                        visible: index === 0
                    }

                }

            }

        }

        GridView {
            id: libraryGrid

            x: contentLeft
            y: 234
            width: libraryPreview.x - contentLeft - 34
            height: parent.height - 320
            cellWidth: 186
            cellHeight: 270
            model: gameModel
            currentIndex: selectedGameIndex
            clip: true
            focus: activeSection === 1 && !powerMenuActive
            Keys.onLeftPressed: decrementCurrentIndex()
            Keys.onRightPressed: incrementCurrentIndex()
            Keys.onUpPressed: moveCurrentIndexUp()
            Keys.onDownPressed: moveCurrentIndexDown()
            Keys.onReturnPressed: launchGame()
            onCurrentIndexChanged: selectedGameIndex = currentIndex

            delegate: Item {
                width: 168
                height: 246
                opacity: GridView.isCurrentItem ? 1 : 0.74

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: panelRaised
                    border.color: GridView.isCurrentItem ? ember : "#26313b"
                    border.width: GridView.isCurrentItem ? 3 : 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: gameBoxArt(model)
                        fillMode: Image.PreserveAspectCrop
                        visible: source !== ""
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: gameBoxArt(model) === ""

                        Text {
                            anchors.centerIn: parent
                            text: initials(model.name)
                            color: emberLight
                            font.pixelSize: 46
                            font.bold: true
                        }

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#202a33"
                            }

                            GradientStop {
                                position: 1
                                color: "#12171d"
                            }

                        }

                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 76

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#00000000"
                            }

                            GradientStop {
                                position: 1
                                color: "#f2080a0d"
                            }

                        }

                    }

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 12
                        text: model.name
                        color: fg
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selectedGameIndex = index;
                        libraryGrid.currentIndex = index;
                        libraryGrid.forceActiveFocus();
                    }
                    onDoubleClicked: launchGame()
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

        }

        Rectangle {
            id: libraryPreview

            anchors.right: parent.right
            anchors.rightMargin: 54
            y: 126
            width: Math.min(470, parent.width * 0.3)
            height: parent.height - 212
            radius: 8
            color: "#d90b0e12"
            border.color: "#27313a"
            clip: true

            Image {
                anchors.fill: parent
                source: gameArt(currentGame())
                fillMode: Image.PreserveAspectCrop
                opacity: 0.62
            }

            Rectangle {
                anchors.fill: parent

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#2806080c"
                    }

                    GradientStop {
                        position: 0.52
                        color: "#9a06080c"
                    }

                    GradientStop {
                        position: 1
                        color: "#f506080c"
                    }

                }

            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 26
                spacing: 12

                Image {
                    width: parent.width
                    height: 108
                    source: currentGame() ? (currentGame().logo || "") : ""
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    visible: source !== ""
                }

                Text {
                    width: parent.width
                    text: currentGame() ? currentGame().name : "No games found"
                    color: fg
                    font.pixelSize: 28
                    font.bold: true
                    wrapMode: Text.WordWrap
                    visible: !currentGame() || !currentGame().logo
                }

                Text {
                    width: parent.width
                    text: currentGame() ? (currentGame().proton || "Ready to play") : libraryScanMessage
                    color: muted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 136
                    height: 44
                    radius: 6
                    color: ember

                    Text {
                        anchors.centerIn: parent
                        text: "PLAY"
                        color: "#170b07"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: launchGame()
                    }

                }

            }

        }

    }

    Item {
        id: libraryPage

        anchors.fill: parent
        visible: false

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 54
            anchors.top: parent.top
            anchors.topMargin: 104
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 86
            spacing: 24

            Rectangle {
                id: librarySidebar

                width: 360
                height: parent.height
                radius: 8
                color: "#e80c1015"
                border.color: "#26313c"
                clip: true

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        width: parent.width
                        height: 74
                        color: "#131920"
                        border.color: "#26313c"

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "All Games"
                                color: fg
                                font.pixelSize: 20
                                font.bold: true
                            }

                            Text {
                                text: libraryScanRunning ? "scanning media" : gameModel.count + " ready"
                                color: muted
                                font.pixelSize: 11
                                font.bold: true
                            }

                        }

                    }

                    ListView {
                        id: libraryList

                        width: parent.width
                        height: parent.height - 74
                        model: gameModel
                        currentIndex: selectedGameIndex
                        clip: true
                        focus: activeSection === 1 && !powerMenuActive
                        Keys.onUpPressed: {
                            decrementCurrentIndex();
                            selectedGameIndex = currentIndex;
                        }
                        Keys.onDownPressed: {
                            incrementCurrentIndex();
                            selectedGameIndex = currentIndex;
                        }
                        Keys.onReturnPressed: launchGame()

                        delegate: Rectangle {
                            width: libraryList.width
                            height: 54
                            color: selectedGameIndex === index ? "#1f2933" : (index % 2 === 0 ? "#0f141a" : "#111820")
                            border.color: selectedGameIndex === index ? ember : "transparent"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 3
                                color: ember
                                visible: selectedGameIndex === index
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                anchors.verticalCenter: parent.verticalCenter
                                width: 26
                                height: 26
                                radius: 5
                                color: "#202832"
                                border.color: "#34404d"

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    source: gameBoxArt(model)
                                    fillMode: Image.PreserveAspectFit
                                    visible: source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: initials(model.name)
                                    color: emberLight
                                    font.pixelSize: 9
                                    font.bold: true
                                    visible: gameBoxArt(model) === ""
                                }

                            }

                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 54
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: model.name
                                    color: selectedGameIndex === index ? fg : "#c6d4df"
                                    font.pixelSize: 13
                                    font.bold: selectedGameIndex === index
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: model.proton || "Proton Experimental"
                                    color: muted
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    selectedGameIndex = index;
                                    libraryList.currentIndex = index;
                                    libraryList.forceActiveFocus();
                                }
                                onDoubleClicked: launchGame()
                            }

                        }

                    }

                }

            }

            Rectangle {
                id: libraryDetail

                width: parent.width - librarySidebar.width - 24
                height: parent.height
                radius: 8
                color: "#d90c1015"
                border.color: "#26313c"
                clip: true

                Image {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: Math.max(320, parent.height * 0.48)
                    source: gameArt(currentGame())
                    fillMode: Image.PreserveAspectCrop
                    opacity: source === "" ? 0 : 0.55
                    visible: source !== ""
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: Math.max(320, parent.height * 0.48)
                    visible: gameArt(currentGame()) === ""

                    Text {
                        anchors.centerIn: parent
                        text: initials(currentGame() ? currentGame().name : "Anvil")
                        color: "#f6d0be"
                        opacity: 0.58
                        font.pixelSize: 124
                        font.bold: true
                    }

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: "#131c25"
                        }

                        GradientStop {
                            position: 0.58
                            color: "#26313a"
                        }

                        GradientStop {
                            position: 1
                            color: "#27333c"
                        }

                    }

                }

                Rectangle {
                    anchors.fill: parent

                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#33000000"
                        }

                        GradientStop {
                            position: 0.42
                            color: "#bb080b0f"
                        }

                        GradientStop {
                            position: 0.76
                            color: "#f0080b0f"
                        }

                        GradientStop {
                            position: 1
                            color: "#ff080b0f"
                        }

                    }

                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 38
                    anchors.right: parent.right
                    anchors.rightMargin: 38
                    anchors.top: parent.top
                    anchors.topMargin: 46
                    spacing: 14

                    Text {
                        text: tagLine(currentGame())
                        color: emberLight
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0
                    }

                    Text {
                        text: {
                            if (currentGame())
                                return currentGame().name;

                            return libraryScanRunning ? "Scanning Cartridges" : "No Cartridges Found";
                        }
                        color: fg
                        font.pixelSize: 58
                        font.bold: true
                        wrapMode: Text.WordWrap
                        width: parent.width
                        lineHeight: 0.94
                    }

                    Text {
                        text: currentGame() ? (currentGame().proton || "Proton Experimental") + " / " + (currentGame().steamgriddb_id ? "GridDB artwork linked" : "Local cartridge metadata") : libraryScanMessage
                        color: muted
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Row {
                        spacing: 12

                        Rectangle {
                            width: 150
                            height: 48
                            radius: 8
                            color: ember

                            Text {
                                anchors.centerIn: parent
                                text: "Play"
                                color: "#160b07"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: launchGame()
                            }

                        }

                        Rectangle {
                            width: 150
                            height: 48
                            radius: 8
                            color: "#cc141a20"
                            border.color: "#44ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: "Manage"
                                color: fg
                                font.pixelSize: 14
                                font.bold: true
                            }

                        }

                    }

                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 38
                    anchors.right: parent.right
                    anchors.rightMargin: 38
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 32
                    spacing: 1

                    Repeater {
                        model: [{
                            "label": "Location",
                            "value": currentGame() ? currentGame().path.split("/").pop() : ""
                        }, {
                            "label": "Input",
                            "value": inputRuntimeLabel(currentGame())
                        }, {
                            "label": "Glyphs",
                            "value": inputGlyphLabel(currentGame())
                        }]

                        Rectangle {
                            width: Math.max(180, parent.width / 3)
                            height: 86
                            color: "#aa121820"
                            border.color: "#2c3743"

                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: muted
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 0
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.value
                                    color: fg
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width - 28
                                    horizontalAlignment: Text.AlignHCenter
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    Item {
        id: storeConsolePage

        anchors.fill: parent
        visible: activeSection === 2

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 118
            spacing: 12

            Text {
                text: "Anvil Store"
                color: fg
                font.pixelSize: 32
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                height: 22
                width: 90
                radius: 11
                color: "#1e2938"
                border.color: "#334155"
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: "WEEKLY DEALS"
                    color: "#ff6537"
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }

        Rectangle {
            id: storeFeature

            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 54
            anchors.top: parent.top
            anchors.topMargin: 188
            height: Math.min(430, parent.height * 0.44)
            radius: 7
            color: panel
            clip: true

            Image {
                anchors.fill: parent
                source: gameArt(currentGame())
                fillMode: Image.PreserveAspectCrop
                opacity: source === "" ? 0 : 0.8
            }

            Rectangle {
                anchors.fill: parent

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: "#ef080b0f"
                    }

                    GradientStop {
                        position: 0.46
                        color: "#8c080b0f"
                    }

                    GradientStop {
                        position: 1
                        color: "#25080b0f"
                    }

                }

            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 36
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 32
                width: Math.min(620, parent.width * 0.5)
                spacing: 10

                Text {
                    text: "FEATURED ON ANVIL"
                    color: emberLight
                    font.pixelSize: 10
                    font.bold: true
                }

                Text {
                    text: currentGame() ? currentGame().name : "Discover your next game"
                    color: fg
                    font.pixelSize: 42
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: "Games, demos, events, and cartridges from creators across the Forgeworks network."
                    color: "#d7dbde"
                    font.pixelSize: 14
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: 132
                    height: 44
                    radius: 6
                    color: ember

                    Text {
                        anchors.centerIn: parent
                        text: "EXPLORE"
                        color: "#170b07"
                        font.pixelSize: 12
                        font.bold: true
                    }

                }

            }

        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: storeFeature.bottom
            anchors.topMargin: 26
            text: "Browse Anvil"
            color: fg
            font.pixelSize: 18
            font.bold: true
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 54
            anchors.top: storeFeature.bottom
            anchors.topMargin: 60
            height: 154
            spacing: 14

            Repeater {
                model: storeModel

                Rectangle {
                    width: (parent.width - 42) / 4
                    height: 146
                    radius: 10
                    clip: true
                    color: selectedStoreTile === index ? "#1c2532" : "#121822"
                    border.color: selectedStoreTile === index ? ember : "#232f3e"
                    border.width: selectedStoreTile === index ? 2 : 1
                    scale: selectedStoreTile === index ? 1.02 : 1.0

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 18
                        spacing: 6

                        Text {
                            text: model.eyebrow
                            color: selectedStoreTile === index ? emberLight : forgeGold
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 0.6
                        }

                        Text {
                            width: parent.width
                            text: model.title
                            color: fg
                            font.pixelSize: 17
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.body
                            color: muted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedStoreTile = index;
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }

                    }

                }

            }

        }

    }

    Item {
        id: storePage

        anchors.fill: parent
        visible: false

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 118
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 88
            spacing: 18

            Rectangle {
                width: parent.width * 0.58
                height: parent.height
                radius: 8
                color: "#e00d1117"
                border.color: selectedStoreTile === 0 ? ember : "#2c3743"
                clip: true

                Rectangle {
                    anchors.fill: parent

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: "#101922"
                        }

                        GradientStop {
                            position: 0.58
                            color: "#1d2a34"
                        }

                        GradientStop {
                            position: 1
                            color: "#58311f"
                        }

                    }

                }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 34
                    anchors.right: parent.right
                    anchors.rightMargin: 34
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 34
                    spacing: 14

                    Text {
                        text: "FORGE FRONT"
                        color: forgeGold
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        text: "Anvil Store"
                        color: fg
                        font.pixelSize: 64
                        font.bold: true
                    }

                    Text {
                        text: "Featured games, demos, wishlists, reviews, events, and cartridge-to-online publishing."
                        color: "#d5d7d9"
                        font.pixelSize: 15
                        wrapMode: Text.WordWrap
                        width: parent.width
                        lineHeight: 1.25
                    }

                    Row {
                        spacing: 10

                        Repeater {
                            model: ["Wishlist", "Demo", "Follow", "Cart"]

                            Rectangle {
                                width: 124
                                height: 46
                                radius: 8
                                color: index === 1 ? ember : "#cc131a22"
                                border.color: index === 1 ? ember : "#3a4652"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: index === 1 ? "#170b06" : fg
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                            }

                        }

                    }

                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: selectedStoreTile = 0
                }

            }

            Column {
                width: parent.width * 0.42 - 18
                height: parent.height
                spacing: 12

                Repeater {
                    model: storeModel

                    Rectangle {
                        width: parent.width
                        height: (storePage.height - 188) / 3
                        radius: 8
                        color: selectedStoreTile === index ? "#1f2933" : "#121820"
                        border.color: selectedStoreTile === index ? ember : "#2c3743"
                        scale: selectedStoreTile === index ? 1.02 : 0.97

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 4
                            color: ember
                            visible: selectedStoreTile === index
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 24
                            anchors.rightMargin: 22
                            spacing: 8

                            Text {
                                text: model.eyebrow
                                color: selectedStoreTile === index ? emberLight : forgeGold
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                text: model.title
                                color: fg
                                font.pixelSize: 30
                                font.bold: true
                                width: parent.width
                            }

                            Text {
                                text: model.body
                                color: muted
                                font.pixelSize: 14
                                wrapMode: Text.WordWrap
                                width: parent.width
                                lineHeight: 1.25
                            }

                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: selectedStoreTile = index
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 140
                            }

                        }

                    }

                }

            }

        }

    }

    Item {
        id: communityConsolePage

        anchors.fill: parent
        visible: activeSection === 3

        Text {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 126
            text: "Community"
            color: fg
            font.pixelSize: 38
            font.bold: true
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 184
            text: "ACTIVITY"
            color: muted
            font.pixelSize: 11
            font.bold: true
        }

        Column {
            id: communityFeed

            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: friendsPanel.left
            anchors.rightMargin: 44
            anchors.top: parent.top
            anchors.topMargin: 210
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 72
            spacing: 10

            Repeater {
                model: communityModel

                Rectangle {
                    width: parent.width
                    height: 112
                    radius: 6
                    color: selectedCommunityItem === index ? "#24303a" : "#b811171d"
                    border.color: selectedCommunityItem === index ? ember : "transparent"
                    border.width: selectedCommunityItem === index ? 2 : 0

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 22
                        anchors.right: parent.right
                        anchors.rightMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        Text {
                            text: model.meta
                            color: selectedCommunityItem === index ? emberLight : forgeGold
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: model.title
                            color: fg
                            font.pixelSize: 19
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.body
                            color: muted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedCommunityItem = index;
                        }
                    }

                }

            }

        }

        Item {
            id: friendsPanel

            anchors.right: parent.right
            anchors.rightMargin: 64
            anchors.top: parent.top
            anchors.topMargin: 184
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 72
            width: Math.min(390, parent.width * 0.28)

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                text: "FRIENDS ONLINE"
                color: muted
                font.pixelSize: 11
                font.bold: true
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 42
                spacing: 2

                Repeater {
                    model: ["Alex", "Mira", "Jordan", "Cafe Build Club", "Devlog Watch"]

                    Item {
                        width: parent.width
                        height: 64

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            height: 38
                            radius: 19
                            color: index < 3 ? "#27323b" : "#1b232a"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.charAt(0)
                                color: fg
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                width: 10
                                height: 10
                                radius: 5
                                color: index < 3 ? green : forgeGold
                                border.color: bg
                                border.width: 2
                            }

                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 52
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: parent.width
                                text: modelData
                                color: fg
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: index === 0 ? "Playing a cartridge" : index === 1 ? "Browsing Store" : index === 2 ? "In Anvil Session" : "Online"
                                color: muted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                        }

                    }

                }

            }

        }

    }

    Item {
        id: communityPage

        anchors.fill: parent
        visible: false

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 134
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 90
            spacing: 20

            Rectangle {
                width: parent.width * 0.64
                height: parent.height
                radius: 8
                color: "#e00d1117"
                border.color: ember

                Column {
                    anchors.fill: parent
                    anchors.margins: 26
                    spacing: 16

                    Text {
                        text: "Anvil Community"
                        color: fg
                        font.pixelSize: 58
                        font.bold: true
                    }

                    Text {
                        text: "Friends, patch notes, captures, developer posts, and game hubs."
                        color: muted
                        font.pixelSize: 15
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Repeater {
                        model: communityModel

                        Rectangle {
                            width: parent.width
                            height: 118
                            radius: 8
                            color: index === 0 ? "#1f2933" : "#121820"
                            border.color: index === 0 ? ember : "#2c3743"

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.right: parent.right
                                anchors.rightMargin: 18
                                spacing: 5

                                Text {
                                    text: model.meta
                                    color: forgeGold
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Text {
                                    text: model.title
                                    color: fg
                                    font.pixelSize: 22
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: model.body
                                    color: muted
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    lineHeight: 1.2
                                }

                            }

                        }

                    }

                }

            }

            Rectangle {
                width: parent.width * 0.36 - 20
                height: parent.height
                radius: 8
                color: "#dd0d1117"
                border.color: "#2c3743"

                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    Text {
                        text: "Friends and Hubs"
                        color: fg
                        font.pixelSize: 28
                        font.bold: true
                    }

                    Repeater {
                        model: ["Alex / Playing a cartridge", "Mira / Browsing Forge Front", "Jordan / In Anvil Session", "Cafe Build Club / 12 online", "Devlog Watch / 4 new posts"]

                        Rectangle {
                            width: parent.width
                            height: 68
                            radius: 8
                            color: index === 0 ? "#1f2933" : "#121820"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                text: modelData
                                color: muted
                                font.pixelSize: 14
                                font.bold: true
                            }

                        }

                    }

                }

            }

        }

    }

    Item {
        id: forgeworksPage

        anchors.fill: parent
        visible: false

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 124
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 88
            spacing: 20

            Rectangle {
                width: parent.width * 0.42
                height: parent.height
                radius: 8
                color: "#e00d1117"
                border.color: forgeGold

                Column {
                    anchors.fill: parent
                    anchors.margins: 26
                    spacing: 14

                    Text {
                        text: "Forgeworks"
                        color: fg
                        font.pixelSize: 56
                        font.bold: true
                    }

                    Text {
                        text: "Developer and publisher services for shipping on Anvil."
                        color: muted
                        font.pixelSize: 14
                        wrapMode: Text.WordWrap
                        width: parent.width
                        lineHeight: 1.25
                    }

                    Rectangle {
                        width: parent.width
                        height: 132
                        radius: 8
                        color: "#1f2933"
                        border.color: ember

                        Column {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 8

                            Text {
                                text: "Sandbox App"
                                color: forgeGold
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                text: "LF-APP-00042"
                                color: fg
                                font.pixelSize: 34
                                font.bold: true
                            }

                            Text {
                                text: "Private branch, 18 tester grants, cartridge provider enabled"
                                color: muted
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }

                        }

                    }

                    Repeater {
                        model: ["Create App", "Upload Build", "Grant Testers", "Publish Branch"]

                        Rectangle {
                            width: parent.width
                            height: 48
                            radius: 8
                            color: index === 1 ? "#27313a" : "#121820"
                            border.color: index === 1 ? forgeGold : "#2c3743"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 16
                                text: modelData
                                color: index === 1 ? forgeGold : fg
                                font.pixelSize: 14
                                font.bold: true
                            }

                        }

                    }

                }

            }

            Column {
                width: parent.width * 0.58 - 20
                height: parent.height
                spacing: 12

                Repeater {
                    model: forgeworksModel

                    Rectangle {
                        width: parent.width
                        height: (forgeworksPage.height - 184) / 4
                        radius: 8
                        color: model.state === "Next" ? "#1f2933" : "#121820"
                        border.color: model.state === "Next" ? forgeGold : "#2c3743"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 18

                            Rectangle {
                                width: 92
                                height: parent.height
                                radius: 8
                                color: model.state === "Next" ? "#27313a" : "#121820"
                                border.color: model.state === "Next" ? forgeGold : "#303a45"

                                Text {
                                    anchors.centerIn: parent
                                    text: model.state
                                    color: model.state === "Next" ? forgeGold : muted
                                    font.pixelSize: 12
                                    font.bold: true
                                }

                            }

                            Column {
                                width: parent.width - 110
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 7

                                Text {
                                    text: model.title
                                    color: fg
                                    font.pixelSize: 26
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: model.body
                                    color: muted
                                    font.pixelSize: 13
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    lineHeight: 1.25
                                }

                            }

                        }

                    }

                }

            }

        }

    }

    // Flagship Console Profile Showcase (Tab 4: Profile)
    Item {
        id: fullProfilePage

        anchors.fill: parent
        visible: activeSection === 4

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 54
            anchors.top: parent.top
            anchors.topMargin: 108
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 72
            spacing: 24

            // Left Col: Player ID Card, Gamertag, Level & Showcase
            Rectangle {
                width: 390
                height: parent.height
                radius: 12
                color: "#111722"
                border.color: "#222f3e"
                border.width: 1

                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 18

                    // Player Avatar & Tag
                    Row {
                        spacing: 16
                        Rectangle {
                            width: 68
                            height: 68
                            radius: 16
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#ff6537" }
                                GradientStop { position: 1.0; color: "#b8320a" }
                            }
                            border.color: "#ff8a66"
                            border.width: 2
                            Text {
                                anchors.centerIn: parent
                                text: profileGamerTag.length > 0 ? profileGamerTag.charAt(0).toUpperCase() : "M"
                                color: "#ffffff"
                                font.pixelSize: 30
                                font.bold: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                text: profileGamerTag
                                color: "#ffffff"
                                font.pixelSize: 24
                                font.bold: true
                            }
                            Row {
                                spacing: 6
                                Rectangle {
                                    width: 8
                                    height: 8
                                    radius: 4
                                    color: "#22c55e"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: "Steam Deck · Online"
                                    color: "#4ade80"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }
                            Text {
                                text: "Anvil Console Edition · Founder"
                                color: "#8e9fad"
                                font.pixelSize: 11
                            }
                        }
                    }

                    // Level Progress Card
                    Rectangle {
                        width: parent.width
                        height: 78
                        radius: 10
                        color: "#161f2c"
                        border.color: "#253446"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 18
                                Text {
                                    anchors.left: parent.left
                                    text: "LEVEL 42"
                                    color: ember
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.letterSpacing: 0.8
                                }
                                Text {
                                    anchors.right: parent.right
                                    text: "2,840 / 3,000 XP"
                                    color: "#94a3b8"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 8
                                radius: 4
                                color: "#0b1017"
                                Rectangle {
                                    width: parent.width * 0.94
                                    height: parent.height
                                    radius: 4
                                    color: ember
                                }
                            }

                            Text {
                                text: "160 XP to Level 43 · Master Collector Rank"
                                color: "#64748b"
                                font.pixelSize: 10
                            }
                        }
                    }

                    // Stats Grid (2x2)
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 12

                        Repeater {
                            model: [
                                { label: "CARTRIDGES", val: String(gameModel.count), sub: "Mounted Ready" },
                                { label: "GAMERSCORE", val: "1,420 G", sub: "18 Unlocked" },
                                { label: "HOURS PLAYED", val: "148.5 h", sub: "Last 30 Days" },
                                { label: "PERFECT GAMES", val: "4", sub: "100% Completed" }
                            ]

                            Rectangle {
                                width: (parent.width - 12) / 2
                                height: 86
                                radius: 10
                                color: "#161f2c"
                                border.color: "#233142"

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 4

                                    Text {
                                        text: modelData.label
                                        color: "#8e9fad"
                                        font.pixelSize: 10
                                        font.bold: true
                                        font.letterSpacing: 0.6
                                    }
                                    Text {
                                        text: modelData.val
                                        color: "#ffffff"
                                        font.pixelSize: 22
                                        font.bold: true
                                    }
                                    Text {
                                        text: modelData.sub
                                        color: emberLight
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }

                    // Hardware & System Pill
                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: 8
                        color: "#141d29"
                        border.color: "#233142"
                        Text {
                            anchors.centerIn: parent
                            text: "Valve Steam Deck · 1280x800 · 60Hz Native"
                            color: "#94a3b8"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            // Right Col: Recent Milestones, Library Showcase & Friends
            Column {
                width: parent.width - 414
                height: parent.height
                spacing: 18

                Text {
                    text: "Recent Milestones & Trophies"
                    color: fg
                    font.pixelSize: 20
                    font.bold: true
                }

                Row {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: [
                            { badge: "GOLD", title: "Relic Master", game: "Jak and Daxter", date: "Unlocked Today", xp: "+150 XP" },
                            { badge: "RARE", title: "Wumpa King", game: "Crash Bandicoot 4", date: "Unlocked Yesterday", xp: "+100 XP" },
                            { badge: "EPIC", title: "Park Tycoon", game: "Aquapark Tycoon", date: "3 Days ago", xp: "+250 XP" }
                        ]

                        Rectangle {
                            width: (parent.width - 28) / 3
                            height: 126
                            radius: 10
                            color: "#121924"
                            border.color: "#233142"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 8

                                Item {
                                    width: parent.width
                                    height: 20

                                    Rectangle {
                                        anchors.left: parent.left
                                        height: 20
                                        width: 48
                                        radius: 4
                                        color: "#2a1810"
                                        border.color: ember
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.badge
                                            color: emberLight
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.xp
                                        color: ember
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Text {
                                    text: modelData.title
                                    color: "#ffffff"
                                    font.pixelSize: 16
                                    font.bold: true
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.game
                                    color: "#94a3b8"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    text: modelData.date
                                    color: "#64748b"
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "Active Friends & Sessions"
                    color: fg
                    font.pixelSize: 20
                    font.bold: true
                }

                Row {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: [
                            { avatar: "NK", name: "Niko", game: "Elden Ring", status: "In Boss Fight" },
                            { avatar: "AM", name: "Amaya", game: "Outer Wilds", status: "Exploring Sun Station" },
                            { avatar: "RO", name: "Rowan", game: "Rayman Origins", status: "Co-op Cartridge Session" }
                        ]

                        Rectangle {
                            width: (parent.width - 28) / 3
                            height: 104
                            radius: 10
                            color: "#121924"
                            border.color: "#233142"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 14

                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: 24
                                    color: "#1c2636"
                                    border.color: ember
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.avatar
                                        color: "#ffffff"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 3
                                    Text { text: modelData.name; color: "#ffffff"; font.pixelSize: 15; font.bold: true }
                                    Text { text: modelData.game; color: emberLight; font.pixelSize: 12; font.bold: true }
                                    Text { text: modelData.status; color: "#64748b"; font.pixelSize: 11 }
                                }
                            }
                        }
                    }
                }

                // Quick Cartridge Status Strip
                Rectangle {
                    width: parent.width
                    height: 92
                    radius: 10
                    color: "#121924"
                    border.color: "#233142"

                    Item {
                        anchors.fill: parent
                        anchors.margins: 18

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text {
                                text: "PRIMARY CARTRIDGE MEDIA"
                                color: ember
                                font.pixelSize: 10
                                font.bold: true
                                font.letterSpacing: 1.0
                            }
                            Text {
                                text: "MicroSD Card (/mnt/sdcard) · " + gameModel.count + " Verified Titles Ready"
                                color: "#ffffff"
                                font.pixelSize: 15
                                font.bold: true
                            }
                            Text {
                                text: "Zero-install portable cartridge architecture · Plug & Play"
                                color: "#94a3b8"
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 140
                            height: 38
                            radius: 8
                            color: "#1a2e22"
                            border.color: "#22c55e"
                            Text {
                                anchors.centerIn: parent
                                text: "MOUNTED"
                                color: "#4ade80"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }
                }
            }
        }
    }
    Item {
        id: downloadsPage

        anchors.fill: parent
        visible: activeSection === 5

        Column {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 60
            anchors.top: parent.top
            anchors.topMargin: 112
            spacing: 16

            Row {
                spacing: 14
                Text {
                    text: "Downloads & Updates"
                    color: fg
                    font.pixelSize: 34
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Rectangle {
                    height: 24
                    width: 120
                    radius: 12
                    color: "#1c2532"
                    border.color: ember
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "NETWORK READY"
                        color: emberLight
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            Text {
                text: "Cartridge verification, shader pre-caching, and system updates."
                color: "#94a3b8"
                font.pixelSize: 14
            }

            Repeater {
                model: downloadModel

                Rectangle {
                    width: parent.width
                    height: 118
                    radius: 10
                    color: index === 0 ? "#161f2c" : "#111722"
                    border.color: index === 0 ? ember : "#222f3e"
                    border.width: index === 0 ? 1.5 : 1

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        spacing: 10

                        Item {
                            width: parent.width
                            height: 28

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.title
                                color: fg
                                font.pixelSize: 20
                                font.bold: true
                                width: parent.width - 180
                                elide: Text.ElideRight
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.value
                                color: index === 0 ? emberLight : "#94a3b8"
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }

                        Text {
                            text: model.body
                            color: "#94a3b8"
                            font.pixelSize: 13
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: parent.width
                            height: 6
                            radius: 3
                            color: "#0b1017"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * model.progress / 100
                                radius: 3
                                color: index === 0 ? ember : "#22c55e"
                            }
                        }
                    }
                }
            }
        }
    }
    property int selectedCartridgeOption: 0

    function triggerCartridgeInit(optIndex) {
        if (optIndex === 0) {
            initCartridgeProc.command = ["/usr/local/bin/anvil-cartridge-tool", "init", "/mnt/sdcard", "MicroSD Cartridge"];
            initCartridgeProc.running = true;
            cartridgeStatusMsg = "Verified & updated MicroSD Cartridge (/mnt/sdcard)!";
        } else if (optIndex === 1) {
            initCartridgeProc.command = ["/usr/local/bin/anvil-cartridge-tool", "init", "/mnt/usb", "USB Game Cartridge"];
            initCartridgeProc.running = true;
            cartridgeStatusMsg = "Formatted & registered External USB (/mnt/usb) as an Anvil Cartridge!";
        } else if (optIndex === 2) {
            initCartridgeProc.command = ["/usr/local/bin/anvil-cartridge-tool", "init", "/home/morphine/Games", "Local Cartridge Folder"];
            initCartridgeProc.running = true;
            cartridgeStatusMsg = "Initialized /home/morphine/Games as an Anvil Cartridge folder!";
        }
    }

    Item {
        id: settingsConsolePage

        anchors.fill: parent
        visible: activeSection === 6

        // Header Title & Breadcrumb
        Row {
            id: settingsHeader
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 106
            spacing: 14

            Text {
                text: "Settings"
                color: fg
                font.pixelSize: 34
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 6
                height: 6
                radius: 3
                color: ember
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: settingsModel.get(selectedSetting).title
                color: emberLight
                font.pixelSize: 18
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        // Left Navigation Blade (SteamOS / Xbox Series X style rail)
        Rectangle {
            id: settingsBlade
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: settingsHeader.bottom
            anchors.topMargin: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 68
            width: 360
            color: "#101620"
            radius: 12
            border.color: "#1e2938"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Repeater {
                    model: settingsModel

                    Rectangle {
                        width: parent.width
                        height: 68
                        radius: 8
                        color: selectedSetting === index ? "#1b2534" : (catMouse.containsMouse ? "#141c28" : "transparent")
                        border.color: selectedSetting === index ? ember : "transparent"
                        border.width: selectedSetting === index ? 1.5 : 0

                        // Ember accent pill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            height: 36
                            radius: 2
                            color: ember
                            visible: selectedSetting === index
                        }

                        // Clean Typography Badge (No missing emoji glyphs)
                        Rectangle {
                            id: catIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 36
                            radius: 6
                            color: selectedSetting === index ? ember : "#182230"
                            border.color: selectedSetting === index ? emberLight : "#2a384b"

                            Text {
                                anchors.centerIn: parent
                                text: model.badge
                                color: selectedSetting === index ? "#ffffff" : "#94a3b8"
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 0.5
                            }
                        }

                        // Category text
                        Column {
                            anchors.left: catIcon.right
                            anchors.leftMargin: 14
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                width: parent.width
                                text: model.title
                                color: selectedSetting === index ? "#ffffff" : "#cbd5e1"
                                font.pixelSize: 15
                                font.bold: selectedSetting === index
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: model.value
                                color: selectedSetting === index ? emberLight : "#64748b"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                selectedSetting = index;
                            }
                        }
                    }
                }
            }
        }

        // Right Settings Content Card (Flagship Console Detail Panel)
        Rectangle {
            id: settingsDetailCard
            anchors.left: settingsBlade.right
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.top: settingsHeader.bottom
            anchors.topMargin: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 68
            color: "#101620"
            radius: 12
            border.color: "#1e2938"
            border.width: 1
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 26
                contentWidth: width
                contentHeight: detailColumn.implicitHeight + 24
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: detailColumn
                    width: parent.width
                    spacing: 18

                    // Card Header with Description
                    Column {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: settingsModel.get(selectedSetting).title
                            color: "#ffffff"
                            font.pixelSize: 24
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            text: settingsModel.get(selectedSetting).body
                            color: "#94a3b8"
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                            lineHeight: 1.3
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#1e2938"
                    }

                    // ==========================================
                    // 1. STORAGE & CARTRIDGE MANAGEMENT PANE
                    // ==========================================
                    Column {
                        visible: selectedSettingKey() === "storage"
                        width: parent.width
                        spacing: 14

                        // Primary Action: Format / Register a Drive or Folder as Cartridge
                        Rectangle {
                            width: parent.width
                            height: 68
                            radius: 10
                            color: addCartridgeMouse.containsMouse ? "#261914" : "#1c1514"
                            border.color: ember
                            border.width: 2

                            Item {
                                anchors.fill: parent
                                anchors.margins: 16

                                Rectangle {
                                    id: addBadge
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 44
                                    height: 36
                                    radius: 6
                                    color: ember
                                    Text {
                                        anchors.centerIn: parent
                                        text: "NEW"
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.left: addBadge.right
                                    anchors.leftMargin: 14
                                    anchors.right: initBtnPill.left
                                    anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: "Create or Register an Anvil Game Cartridge"
                                        color: "#ffffff"
                                        font.pixelSize: 15
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: "Turn any SD card, USB drive, or folder into a hot-swappable Anvil cartridge"
                                        color: emberLight
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }

                                Rectangle {
                                    id: initBtnPill
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 156
                                    height: 36
                                    radius: 6
                                    color: ember
                                    Text {
                                        anchors.centerIn: parent
                                        text: "A  CONFIGURE DRIVE"
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                id: addCartridgeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    cartridgeModalActive = true;
                                    cartridgeStatusMsg = "";
                                }
                            }
                        }

                        Text {
                            text: "MOUNTED CARTRIDGE & SYSTEM VOLUMES"
                            color: "#94a3b8"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        // Drive 1: Removable MicroSD Card (Active Cartridge)
                        Rectangle {
                            width: parent.width
                            height: 96
                            radius: 10
                            color: "#151e2b"
                            border.color: "#2a394d"
                            border.width: 1

                            Item {
                                anchors.fill: parent
                                anchors.margins: 16

                                Rectangle {
                                    id: sdIconBox
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 52
                                    height: 52
                                    radius: 10
                                    color: "#231712"
                                    border.color: ember
                                    Text {
                                        anchors.centerIn: parent
                                        text: "SD"
                                        color: emberLight
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.left: sdIconBox.right
                                    anchors.leftMargin: 16
                                    anchors.right: sdStatusBadge.left
                                    anchors.rightMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 5

                                    Row {
                                        spacing: 10
                                        Text {
                                            text: "MicroSD Cartridge (/mnt/sdcard)"
                                            color: "#ffffff"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                        Rectangle {
                                            width: 72
                                            height: 18
                                            radius: 4
                                            color: "#22c55e22"
                                            border.color: "#22c55e"
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "PRIMARY"
                                                color: "#4ade80"
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Text {
                                        text: gameModel.count + " Cartridge Games Loaded · 32 GB Free of 234 GB (87% Used)"
                                        color: "#94a3b8"
                                        font.pixelSize: 12
                                    }

                                    Rectangle {
                                        width: Math.min(360, parent.width)
                                        height: 6
                                        radius: 3
                                        color: "#0b1017"
                                        Rectangle {
                                            width: parent.width * 0.87
                                            height: parent.height
                                            radius: 3
                                            color: ember
                                        }
                                    }
                                }

                                Rectangle {
                                    id: sdStatusBadge
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 108
                                    height: 34
                                    radius: 6
                                    color: "#162920"
                                    border.color: "#22c55e"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "MOUNTED"
                                        color: "#4ade80"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        // Drive 2: Internal NVMe Storage
                        Rectangle {
                            width: parent.width
                            height: 96
                            radius: 10
                            color: "#151e2b"
                            border.color: "#233142"

                            Item {
                                anchors.fill: parent
                                anchors.margins: 16

                                Rectangle {
                                    id: ssdIconBox
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 52
                                    height: 52
                                    radius: 10
                                    color: "#192330"
                                    border.color: "#38bdf8"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "NVMe"
                                        color: "#38bdf8"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.left: ssdIconBox.right
                                    anchors.leftMargin: 16
                                    anchors.right: ssdStatusBadge.left
                                    anchors.rightMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 5

                                    Row {
                                        spacing: 10
                                        Text {
                                            text: "Internal SSD (/dev/nvme0n1p2)"
                                            color: "#ffffff"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                        Rectangle {
                                            width: 68
                                            height: 18
                                            radius: 4
                                            color: "#38bdf822"
                                            border.color: "#38bdf8"
                                            anchors.verticalCenter: parent.verticalCenter
                                            Text {
                                                anchors.centerIn: parent
                                                text: "SYSTEM"
                                                color: "#38bdf8"
                                                font.pixelSize: 9
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Text {
                                        text: "Anvil OS & Shader Cache · 229 GB Free of 238 GB (4% Used)"
                                        color: "#94a3b8"
                                        font.pixelSize: 12
                                    }

                                    Rectangle {
                                        width: Math.min(360, parent.width)
                                        height: 6
                                        radius: 3
                                        color: "#0b1017"
                                        Rectangle {
                                            width: parent.width * 0.04
                                            height: parent.height
                                            radius: 3
                                            color: "#38bdf8"
                                        }
                                    }
                                }

                                Rectangle {
                                    id: ssdStatusBadge
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 108
                                    height: 34
                                    radius: 6
                                    color: "#192330"
                                    border.color: "#334155"
                                    Text {
                                        anchors.centerIn: parent
                                        text: "PROTECTED"
                                        color: "#94a3b8"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // 2. STEAM DECK INPUT & CALIBRATION PANE
                    // ==========================================
                    Column {
                        visible: selectedSettingKey() === "input"
                        width: parent.width
                        spacing: 16

                        Rectangle {
                            width: parent.width
                            height: 92
                            radius: 10
                            color: "#151e2b"
                            border.color: "#253446"

                            Item {
                                anchors.fill: parent
                                anchors.margins: 18

                                Rectangle {
                                    id: padBadge
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 54
                                    height: 54
                                    radius: 10
                                    color: "#231712"
                                    border.color: ember
                                    Text {
                                        anchors.centerIn: parent
                                        text: "DECK"
                                        color: emberLight
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.left: padBadge.right
                                    anchors.leftMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Text {
                                        text: "Steam Deck Built-in Controller (Xbox 360 Bridge Active)"
                                        color: "#ffffff"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }

                                    Text {
                                        text: "Hardware Deadzone Filter: 4000 threshold · Motion IMU Sensor Locked"
                                        color: "#4ade80"
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        text: "Live Input Event: " + (controllerAction !== "" ? inputActionLabel(controllerAction) : "Neutral (Zero Drift)")
                                        color: controllerAction !== "" ? emberLight : "#94a3b8"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }
                        }

                        Text {
                            text: "LIVE BUTTON DIAGNOSTIC MATRIX"
                            color: ember
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        Grid {
                            width: parent.width
                            columns: 5
                            rowSpacing: 10
                            columnSpacing: 10

                            Repeater {
                                model: ["south", "east", "north", "west", "lt", "rt", "lb", "rb", "back", "start", "guide", "up", "down", "left", "right"]

                                Rectangle {
                                    width: (parent.width - 40) / 5
                                    height: 52
                                    radius: 8
                                    color: controllerAction === modelData ? ember : "#151e2b"
                                    border.color: controllerAction === modelData ? emberLight : "#253446"
                                    border.width: controllerAction === modelData ? 2 : 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData === "up" || modelData === "down" || modelData === "left" || modelData === "right" ? inputActionLabel(modelData) : ""
                                        color: "#ffffff"
                                        font.pixelSize: 12
                                        font.bold: true
                                        visible: text !== ""
                                    }

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        visible: modelData !== "up" && modelData !== "down" && modelData !== "left" && modelData !== "right"

                                        ButtonGlyph {
                                            anchors.verticalCenter: parent.verticalCenter
                                            action: modelData
                                            active: controllerAction === modelData
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // 3. DISPLAY & PERFORMANCE PANE
                    // ==========================================
                    Column {
                        visible: selectedSettingKey() === "display"
                        width: parent.width
                        spacing: 14

                        Repeater {
                            model: [
                                { title: "Display Resolution", sub: "Native Steam Deck 16:10 IPS/OLED Panel", pill: "1280 x 800" },
                                { title: "Refresh Rate & Frame Limiter", sub: "Hardware scanout synchronized for smooth frame pacing", pill: "60 Hz Locked" },
                                { title: "Fullscreen Scaling Mode", sub: "Automatic aspect correction for 16:9 and 16:10 titles", pill: "Native Aspect" }
                            ]

                            Rectangle {
                                width: parent.width
                                height: 74
                                radius: 10
                                color: "#151e2b"
                                border.color: "#253446"

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 18

                                    Column {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3
                                        Text {
                                            text: modelData.title
                                            color: "#ffffff"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                        Text {
                                            text: modelData.sub
                                            color: "#94a3b8"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 144
                                        height: 36
                                        radius: 6
                                        color: "#1e293b"
                                        border.color: ember
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.pill
                                            color: "#ffffff"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // 4. PROTON & COMPATIBILITY PANE
                    // ==========================================
                    Column {
                        visible: selectedSettingKey() === "runtime"
                        width: parent.width
                        spacing: 14

                        Repeater {
                            model: [
                                { title: "Default Compatibility Layer", sub: "Used automatically for Windows cartridge executables", pill: "GE-Proton" },
                                { title: "Cartridge Working Directory", sub: "Always cd into executable folder so relative data loads cleanly", pill: "ENABLED" },
                                { title: "Steam API Bridge Override", sub: "Configures WINEDLLOVERRIDES for standalone cartridge play", pill: "ACTIVE" }
                            ]

                            Rectangle {
                                width: parent.width
                                height: 74
                                radius: 10
                                color: "#151e2b"
                                border.color: "#253446"

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 18

                                    Column {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3
                                        Text {
                                            text: modelData.title
                                            color: "#ffffff"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                        Text {
                                            text: modelData.sub
                                            color: "#94a3b8"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 136
                                        height: 36
                                        radius: 6
                                        color: "#1e293b"
                                        border.color: ember
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.pill
                                            color: emberLight
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ==========================================
                    // 5. SYSTEM & HARDWARE PANE
                    // ==========================================
                    Column {
                        visible: selectedSettingKey() === "session"
                        width: parent.width
                        spacing: 10

                        Repeater {
                            model: [
                                { name: "Console Hardware", val: "Valve Steam Deck (Jupiter)" },
                                { name: "System Interface", val: "Anvil Console OS v2.4" },
                                { name: "Compositor & Windowing", val: "Hyprland Wayland + Quickshell" },
                                { name: "Mounted Cartridge Library", val: gameModel.count + " Verified Titles on /mnt/sdcard" },
                                { name: "Guide Button Overlay Guard", val: "Active In-Game Only (Home Locked)" }
                            ]

                            Rectangle {
                                width: parent.width
                                height: 54
                                radius: 8
                                color: "#151e2b"
                                border.color: "#222f3e"

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 16

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        color: "#cbd5e1"
                                        font.pixelSize: 14
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.val
                                        color: emberLight
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // Interactive Cartridge Setup / Drive Modal
    // ==========================================
    property bool cartridgeModalActive: false
    property string cartridgeStatusMsg: ""

    Rectangle {
        id: cartridgeModalOverlay
        anchors.fill: parent
        color: "#dc05080d"
        visible: cartridgeModalActive
        z: 99

        MouseArea {
            anchors.fill: parent
            onClicked: cartridgeModalActive = false
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(720, parent.width - 80)
            height: 480
            radius: 14
            color: "#101620"
            border.color: ember
            border.width: 2

            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 16

                Item {
                    width: parent.width
                    height: 32

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Initialize & Register Anvil Cartridge"
                        color: "#ffffff"
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 90
                        height: 28
                        radius: 6
                        color: "#1e293b"
                        border.color: "#334155"
                        Text {
                            anchors.centerIn: parent
                            text: "B  CLOSE"
                            color: "#cbd5e1"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: cartridgeModalActive = false
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: "Select any storage drive, SD card, or folder below to turn it into an official Anvil Game Cartridge. Anvil creates the Games/ directory and cartridge.meta manifest so games run directly off the media."
                    color: "#94a3b8"
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#1e2938"
                }

                Column {
                    width: parent.width
                    spacing: 10

                    Repeater {
                        model: [
                            { tag: "SD", title: "MicroSD Card (/mnt/sdcard)", sub: "Primary removable slot · 48 Games mounted", btn: "VERIFY / SYNC" },
                            { tag: "USB", title: "External USB Drive (/mnt/usb)", sub: "Format & register USB storage as hot-swap cartridge", btn: "MAKE CARTRIDGE" },
                            { tag: "DIR", title: "Custom Folder (/home/morphine/Games)", sub: "Register local directory as virtual cartridge library", btn: "MAKE CARTRIDGE" }
                        ]

                        Rectangle {
                            width: parent.width
                            height: 64
                            radius: 10
                            color: selectedCartridgeOption === index ? "#1e293b" : "#151e2b"
                            border.color: selectedCartridgeOption === index ? ember : "#253446"
                            border.width: selectedCartridgeOption === index ? 2 : 1

                            Item {
                                anchors.fill: parent
                                anchors.margins: 14

                                Rectangle {
                                    id: optBadge
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 44
                                    height: 36
                                    radius: 6
                                    color: selectedCartridgeOption === index ? ember : "#1e293b"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.tag
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.left: optBadge.right
                                    anchors.leftMargin: 14
                                    anchors.right: optBtn.left
                                    anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: modelData.title
                                        color: "#ffffff"
                                        font.pixelSize: 15
                                        font.bold: true
                                    }
                                    Text {
                                        text: modelData.sub
                                        color: "#94a3b8"
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    id: optBtn
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 136
                                    height: 34
                                    radius: 6
                                    color: selectedCartridgeOption === index ? ember : "#1e293b"
                                    border.color: ember
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.btn
                                        color: "#ffffff"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: selectedCartridgeOption = index
                                onClicked: {
                                    selectedCartridgeOption = index;
                                    triggerCartridgeInit(index);
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: 8
                    color: cartridgeStatusMsg !== "" ? "#162920" : "#151e2b"
                    border.color: cartridgeStatusMsg !== "" ? "#22c55e" : "#222f3e"

                    Text {
                        anchors.centerIn: parent
                        text: cartridgeStatusMsg !== "" ? cartridgeStatusMsg : "Use D-Pad Up/Down and press A to initialize selected drive as an Anvil Cartridge."
                        color: cartridgeStatusMsg !== "" ? "#4ade80" : "#94a3b8"
                        font.pixelSize: 12
                        font.bold: cartridgeStatusMsg !== ""
                    }
                }
            }
        }
    }

    Process {
        id: initCartridgeProc
        onExited: {
            if (!pythonBridge.running) pythonBridge.running = true;
        }
    }

    Item {
        id: settingsPage

        anchors.fill: parent
        visible: false

        Column {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 124
            spacing: 18

            Text {
                text: "Settings"
                color: fg
                font.pixelSize: 58
                font.bold: true
            }

            Grid {
                id: settingsGrid

                width: parent.width
                columns: 2
                rowSpacing: 14
                columnSpacing: 14

                Repeater {
                    model: settingsModel

                    Rectangle {
                        width: (settingsGrid.width - 14) / 2
                        height: 184
                        radius: 8
                        color: index === 0 ? "#1f2933" : "#121820"
                        border.color: index === 0 ? ember : "#2c3743"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 9

                            Text {
                                text: model.title
                                color: fg
                                font.pixelSize: 28
                                font.bold: true
                                width: parent.width
                                elide: Text.ElideRight
                            }

                            Text {
                                text: model.value
                                color: model.value === "Mock" ? forgeGold : emberLight
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Text {
                                text: model.body
                                color: muted
                                font.pixelSize: 13
                                wrapMode: Text.WordWrap
                                width: parent.width
                                lineHeight: 1.22
                            }

                        }

                    }

                }

            }

        }

    }

    Rectangle {
        anchors.fill: parent
        color: "#dd050609"
        opacity: powerMenuActive ? 1 : 0
        visible: opacity > 0
        z: 30

        MouseArea {
            anchors.fill: parent
            onClicked: {
                powerMenuActive = false;
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }

        }

    }

    // Dimmer Backdrop for Modals
    Rectangle {
        anchors.fill: parent
        color: "#99000000"
        visible: profileModalActive
        opacity: profileModalActive ? 1 : 0
        z: 48
        MouseArea {
            anchors.fill: parent
            onClicked: profileModalActive = false
        }
    }

    // Xbox Console Profile Flyout
    Rectangle {
        id: profileFlyout
        width: 480
        height: 460
        anchors.left: parent.left
        anchors.leftMargin: contentLeft
        anchors.top: parent.top
        anchors.topMargin: 74
        radius: 12
        color: "#f50c1117"
        border.color: "#273648"
        border.width: 1.5
        visible: profileModalActive
        opacity: profileModalActive ? 1 : 0
        z: 50

        // Subtle gradient top bar
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 4
            radius: 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ff6537" }
                GradientStop { position: 1.0; color: "#ff8a66" }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header: Avatar, Name, Status
            Row {
                width: parent.width
                spacing: 16

                Rectangle {
                    width: 58
                    height: 58
                    radius: 14
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#ff6537" }
                        GradientStop { position: 1.0; color: "#b82b08" }
                    }
                    border.color: "#ff8a66"
                    border.width: 2.5
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text: profileGamerTag.length > 0 ? profileGamerTag.charAt(0).toUpperCase() : "M"
                        color: "#ffffff"
                        font.pixelSize: 26
                        font.bold: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Row {
                        spacing: 8
                        Text {
                            text: profileGamerTag
                            color: "#ffffff"
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Rectangle {
                            width: 8
                            height: 8
                            radius: 4
                            color: "#22c55e"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Online"
                            color: "#22c55e"
                            font.pixelSize: 11
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: profileBio
                        color: "#8e9fad"
                        font.pixelSize: 12
                    }
                }
            }

            // Gamerscore & Stats Cards Row
            Row {
                width: parent.width
                spacing: 10

                Rectangle {
                    width: (parent.width - 20) / 3
                    height: 56
                    radius: 8
                    color: "#151e28"
                    border.color: "#222f3e"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "★ " + profileGamerscore + " G"
                            color: "#22c55e"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Gamerscore"
                            color: "#8e9fad"
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 20) / 3
                    height: 56
                    radius: 8
                    color: "#151e28"
                    border.color: "#222f3e"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: gameModel.count.toString()
                            color: "#ffffff"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Installed Games"
                            color: "#8e9fad"
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    width: (parent.width - 20) / 3
                    height: 56
                    radius: 8
                    color: "#151e28"
                    border.color: "#222f3e"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Deck Verified"
                            color: "#60a5fa"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Compatibility"
                            color: "#8e9fad"
                            font.pixelSize: 10
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                width: parent.width
                height: 1
                color: "#1e2a38"
            }

            // Action Options List
            Column {
                width: parent.width
                spacing: 6

                Repeater {
                    model: ["Customize Profile", "View Achievements", "Privacy & Online Safety", "Switch User / Sign Out"]

                    Rectangle {
                        width: profileFlyout.width - 48
                        height: 44
                        radius: 6
                        color: selectedProfileIndex === index ? "#1c2836" : (actionMouse.containsMouse ? "#141c26" : "transparent")
                        border.color: selectedProfileIndex === index ? "#ff6537" : "transparent"
                        border.width: 1.5

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Text {
                                text: index === 0 ? "⚙" : index === 1 ? "🏆" : index === 2 ? "🛡" : "👤"
                                color: selectedProfileIndex === index ? "#ff6537" : "#8e9fad"
                                font.pixelSize: 15
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: modelData
                                color: selectedProfileIndex === index ? "#ffffff" : "#c6d4df"
                                font.pixelSize: 13
                                font.bold: selectedProfileIndex === index
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                selectedProfileIndex = index;
                                if (index === 1) {
                                    profileModalActive = false;
                                    selectSection(3);
                                } else if (index === 0) {
                                    profileModalActive = false;
                                    selectSection(5);
                                } else {
                                    profileModalActive = false;
                                }
                            }
                        }
                    }
                }
            }

            // Footer Hint
            Row {
                anchors.right: parent.right
                spacing: 8
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: "#dc2626"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "B"
                        color: "#ffffff"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
                Text {
                    text: "Close"
                    color: "#8e9fad"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Rectangle {
        id: powerMenu

        width: 430
        height: 318
        anchors.centerIn: parent
        radius: 8
        color: "#f0101419"
        border.color: "#2c3743"
        visible: powerMenuActive
        opacity: powerMenuActive ? 1 : 0
        z: 50

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 12

            Text {
                text: "Power"
                color: fg
                font.pixelSize: 28
                font.bold: true
            }

            Repeater {
                model: ["Sleep", "Restart", "Shut Down", "Switch to Desktop"]

                Rectangle {
                    width: parent.width
                    height: 50
                    radius: 8
                    color: selectedPowerIndex === index ? "#1f2933" : "#121820"
                    border.color: selectedPowerIndex === index ? ember : "#2c3743"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        text: modelData
                        color: fg
                        font.pixelSize: 15
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: selectedPowerIndex = index
                        onClicked: {
                            triggerPowerAction(modelData);
                        }
                    }

                }

            }

        }

    }

    Rectangle {
        id: bottomHints

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 46
        color: "#f0080b0f"
        border.color: "#161e28"
        border.width: 1
        z: 30

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22

            Row {
                spacing: 7
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 24
                    height: 18
                    radius: 3
                    color: "#18222e"
                    border.color: "#273648"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "•••"
                        color: "#94a3b8"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Quick Access"
                    color: "#8e9fad"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Row {
                spacing: 7
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 44
                    height: 18
                    radius: 3
                    color: "#18222e"
                    border.color: "#273648"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "STEAM"
                        color: "#94a3b8"
                        font.pixelSize: 8
                        font.bold: true
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Menu"
                    color: "#8e9fad"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: "#18222e"
                    border.color: "#273648"
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "A"
                        color: "#22c55e"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Select"
                    color: "#ffffff"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: "#1e2938"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "B"
                        color: "#ef4444"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Back"
                    color: "#8e9fad"
                    font.pixelSize: 12
                    font.bold: true
                }
            }

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: "#1e2938"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "X"
                        color: "#38bdf8"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Options"
                    color: "#8e9fad"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }
    }

    Rectangle {
        id: loadingScreen

        anchors.fill: parent
        color: bg
        opacity: gameIsLoading || libraryScanRunning ? 1 : 0
        visible: opacity > 0
        focus: visible
        z: 100
        Keys.onEscapePressed: {
            if (gameIsLoading)
                cancelGameLaunch();

        }

        Image {
            anchors.fill: parent
            source: gameArt(currentGame())
            fillMode: Image.PreserveAspectCrop
            opacity: 0.22
        }

        Column {
            anchors.centerIn: parent
            spacing: 12

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: gameIsLoading ? "Starting" : "Preparing Library"
                color: muted
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (libraryScanRunning)
                        return "Scanning Cartridges";

                    let game = currentGame();
                    return game ? game.name : "Game";
                }
                color: fg
                font.pixelSize: 40
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    if (libraryScanRunning)
                        return libraryScanMessage;
                    let game = currentGame();
                    if (game && game.proton)
                        return "Preparing compatibility layer (" + game.proton + ")...";
                    return "Launching game dependencies...";
                }
                color: "#c5c8c9"
                font.pixelSize: 14
                visible: libraryScanRunning || gameIsLoading
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 6
                radius: 3
                color: "#18222b"
                visible: libraryScanRunning || gameIsLoading
                clip: true

                Rectangle {
                    id: progressFill
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    width: parent.width * 0.4
                    radius: 3
                    color: ember

                    SequentialAnimation on anchors.leftMargin {
                        running: libraryScanRunning || gameIsLoading
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: -progressFill.width
                            to: 320
                            duration: 1400
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 170
                height: 42
                radius: 6
                color: cancelMouse.containsMouse ? "#33211b" : "#1a2027"
                border.color: cancelMouse.containsMouse ? ember : "#3a4652"
                visible: gameIsLoading

                Text {
                    anchors.centerIn: parent
                    text: "Cancel Launch"
                    color: fg
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: cancelMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: cancelGameLaunch()
                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 220
            }

        }

    }

    Process {
        id: launcher
    }

    Process {
        id: cancelLauncher
    }

    component ButtonGlyph: Rectangle {
        property string action: ""
        property bool active: false

        width: Math.max(24, glyphLabel.implicitWidth + 12)
        height: 24
        radius: 12
        color: active ? ember : "#151d25"
        border.color: active ? glyphColor(action) : line

        Text {
            id: glyphLabel

            anchors.centerIn: parent
            text: glyph(action)
            color: active ? "#160b07" : glyphColor(action)
            font.pixelSize: text.length > 2 ? 9 : 14
            font.bold: true
        }
    }

}
