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
    property string controllerFamily: "xbox"
    property string controllerName: "Controller"
    readonly property string localRoot: decodeURIComponent(Qt.resolvedUrl("../../").toString()).replace("file://", "").replace(/\/$/, "")
    readonly property string anvilRoot: Quickshell.env("ANVIL_ROOT") || localRoot
    readonly property string bridgePath: anvilRoot + "/src/daemon/anvil-library-bridge"
    readonly property string daemonPath: anvilRoot + "/src/ui/AnvilDaemon.qml"
    readonly property color bg: "#040608"
    readonly property color panel: "#0d1217"
    readonly property color panelRaised: "#151b22"
    readonly property color line: "#313b46"
    readonly property color fg: "#f5f5f2"
    readonly property color muted: "#aeb6bd"
    readonly property color ember: "#ff6537"
    readonly property color emberLight: "#ff8a66"
    readonly property color forgeGold: "#d9ad5f"
    readonly property color relayBlue: "#7aa8ff"
    readonly property color green: "#65d797"
    readonly property int sidebarWidth: 112
    readonly property int contentLeft: 154
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
            return "Resume";
        case 1:
            return "Installed and removable games";
        case 2:
            return "Discovery, demos, wishlists";
        case 3:
            return "Friends, hubs, activity";
        case 4:
            return "Queue, verify, update";
        case 5:
            return "Session and runtime";
        case 6:
            return "Apps, builds, publishing";
        default:
            return "Anvil";
        }
    }

    function glyph(action) {
        let family = String(controllerFamily || "xbox").toLowerCase();
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
        if (family === "playstation") {
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
            return "Xbox";
        if (action === "lb")
            return "LB";
        if (action === "rb")
            return "RB";
        if (action === "lt")
            return "LT";
        if (action === "rt")
            return "RT";
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
        let family = String(controllerFamily || "xbox").toLowerCase();
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
        if (family === "playstation")
            return anvilRoot + "/assets/controllercons/solid/ps5.svg";
        if (family === "nintendo")
            return anvilRoot + "/assets/controllercons/solid/switch-pro.svg";
        if (family === "xbox")
            return anvilRoot + "/assets/controllercons/solid/xbox-series-x.svg";
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
        selectedGameIndex = Math.max(0, Math.min(gameModel.count - 1, selectedGameIndex + delta));
    }

    function handleControllerAction(action) {
        if (gameIsLoading) {
            if (action === "east" || action === "back")
                cancelGameLaunch();
            return ;
        }
        if (action === "lt" || action === "lb")
            selectSection(activeSection - 1);
        else if (action === "rt" || action === "rb")
            selectSection(activeSection + 1);
        else if (action === "left")
            activeSection === 0 || activeSection === 1 ? moveGameSelection(-1) : selectSection(activeSection - 1);
        else if (action === "right")
            activeSection === 0 || activeSection === 1 ? moveGameSelection(1) : selectSection(activeSection + 1);
        else if (action === "up")
            activeSection === 1 ? moveGameSelection(-4) : activeSection === 5 ? selectedSetting = Math.max(0, selectedSetting - 1) : selectSection(activeSection - 1);
        else if (action === "down")
            activeSection === 1 ? moveGameSelection(4) : activeSection === 5 ? selectedSetting = Math.min(settingsModel.count - 1, selectedSetting + 1) : selectSection(activeSection + 1);
        else if (action === "south" && (activeSection === 0 || activeSection === 1))
            launchGame();
        else if (action === "start")
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
    WlrLayershell.layer: WlrLayer.Overlay
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
            title: "Featured"
            eyebrow: "FORGE FRONT"
            body: "Featured releases, demos, launches, and events."
        }

        ListElement {
            title: "Discovery"
            eyebrow: "DISCOVERY QUEUE"
            body: "Curated rails shaped by tags, friends, and play."
        }

        ListElement {
            title: "Cartridges"
            eyebrow: "LOCAL + ONLINE"
            body: "Local game media now. Signed Forgepipe builds next."
        }

    }

    ListModel {
        id: communityModel

        ListElement {
            title: "Patch notes from Legend Forge"
            body: "Anvil Session mounts removable media and refreshes the library on launch."
            meta: "News"
        }

        ListElement {
            title: "Screenshots and clips"
            body: "Capture lane for screenshots, clips, and timeline markers."
            meta: "Activity"
        }

        ListElement {
            title: "Guides, reviews, discussions"
            body: "Game hubs for posts, reviews, guides, workshop notes, and events."
            meta: "Hub"
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
            title: "Cartridge scan"
            body: "USB and SD libraries indexed into Anvil Library."
            value: "Live"
            progress: 100
        }

        ListElement {
            title: "Client update"
            body: "Signed Anvil release check with staged apply and rollback."
            value: "Preview"
            progress: 42
        }

        ListElement {
            title: "Forgepipe install"
            body: "Depot download, verify, repair, move, uninstall, and delta updates."
            value: "Planned"
            progress: 24
        }

    }

    ListModel {
        id: settingsModel

        ListElement {
            key: "session"
            title: "Anvil Session"
            body: "Dedicated Wayland session, controller navigation, focus, logout, and cleanup."
            value: "Installed by plugin"
        }

        ListElement {
            key: "runtime"
            title: "Anvil Runtime"
            body: "Per-game Proton, prefixes, launch logs, overlay hooks, and exit recovery."
            value: "Prototype"
        }

        ListElement {
            key: "input"
            title: "Anvil Input"
            body: "Controller identity, glyphs, per-game maps, and live button testing."
            value: "Live"
        }

        ListElement {
            key: "cloud"
            title: "Anvil Cloud"
            body: "Save sync, settings sync, offline queue, and conflicts."
            value: "Coming soon"
        }

        ListElement {
            key: "guard"
            title: "Forge Guard"
            body: "Device trust, sign-in approval, family controls, and account recovery."
            value: "Coming soon"
        }

    }

    Process {
        id: pythonBridge

        command: ["python3", bridgePath]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let payload = text.trim();
                    let status = payload.length > 0 ? JSON.parse(payload) : {
                    };
                    let games = Array.isArray(status) ? status : (status.games || []);
                    gameModel.clear();
                    for (let i = 0; i < games.length; i++) gameModel.append(games[i])
                    selectedGameIndex = 0;
                    mediaStatusLabel = status.drives && status.drives.length > 0 ? status.drives.length + " media" : "No media";
                    if (status.mounted && status.mounted.length > 0)
                        mediaStatusLabel = "Mounted " + status.mounted.length;

                    updateStatusLabel = status.update && status.update.label ? status.update.label : "Update status unavailable";
                    updateAvailable = status.update && status.update.available;
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
        height: 92
        color: "#76040609"
        z: 20

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: 6
                color: ember

                Text {
                    anchors.centerIn: parent
                    text: "A"
                    color: "#170b07"
                    font.pixelSize: 22
                    font.bold: true
                }

            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "ANVIL"
                    color: fg
                    font.pixelSize: 20
                    font.bold: true
                }

                Text {
                    text: currentSectionLabel().toUpperCase() + " / " + currentSectionSubtitle()
                    color: muted
                    font.pixelSize: 10
                    font.bold: true
                    elide: Text.ElideRight
                    width: 360
                }
            }

        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: false

            Repeater {
                model: navModel

                Item {
                    width: Math.max(88, navLabel.implicitWidth + 40)
                    height: 54

                    Row {
                        anchors.centerIn: parent
                        spacing: 9

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            source: Quickshell.iconPath(model.icon, true)
                            sourceSize.width: 36
                            sourceSize.height: 36
                            opacity: activeSection === index ? 1 : 0.68
                        }

                        Text {
                            id: navLabel

                            anchors.verticalCenter: parent.verticalCenter
                            text: model.label
                            color: activeSection === index ? fg : "#b1b7bd"
                            font.pixelSize: 14
                            font.bold: activeSection === index
                        }

                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: activeSection === index ? Math.max(24, navLabel.implicitWidth) : 0
                        height: 3
                        radius: 2
                        color: ember

                        Behavior on width {
                            NumberAnimation {
                                duration: 180
                                easing.type: Easing.OutCubic
                            }

                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: selectSection(index)
                    }

                }

            }

        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 48
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 286
                height: 34
                radius: 17
                color: "#9810161d"
                border.color: line

                Row {
                    anchors.centerIn: parent
                    spacing: 8

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 16
                        source: controllerIcon()
                        sourceSize.width: 48
                        sourceSize.height: 32
                        opacity: source === "" ? 0 : 0.86
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: controllerShortName()
                        color: fg
                        font.pixelSize: 11
                        font.bold: true
                    }

                    ButtonGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        action: "accept"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Select"
                        color: muted
                        font.pixelSize: 10
                        font.bold: true
                    }

                    ButtonGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        action: "back"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Back"
                        color: muted
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                source: Quickshell.iconPath("folder-download-symbolic", true)
                sourceSize.width: 40
                sourceSize.height: 40
                opacity: 0.72
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "h:mm AP")
                color: fg
                font.pixelSize: 13
                font.bold: true
            }

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                source: Quickshell.iconPath("system-shutdown-symbolic", true)
                sourceSize.width: 44
                sourceSize.height: 44
                opacity: powerMenuActive ? 1 : 0.72

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -12
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
        visible: true
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
            width: Math.min(980, parent.width * 0.58)
            anchors.top: parent.top
            anchors.topMargin: 132
            anchors.bottom: shelf.top
            anchors.bottomMargin: 8
            color: "transparent"
            border.color: "transparent"

            Image {
                anchors.fill: parent
                source: gameArt(currentGame())
                fillMode: Image.PreserveAspectCrop
                visible: false
            }

            Rectangle {
                anchors.fill: parent
                visible: false

                Text {
                    anchors.centerIn: parent
                    text: initials(currentGame() ? currentGame().name : "Anvil")
                    color: "#f4c4ae"
                    opacity: 0.55
                    font.pixelSize: 132
                    font.bold: true
                }

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: "#18222b"
                    }

                    GradientStop {
                        position: 0.46
                        color: "#27333a"
                    }

                    GradientStop {
                        position: 1
                        color: "#50351f"
                    }

                }

            }

            Rectangle {
                anchors.fill: parent
                visible: false

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: "#f807090d"
                    }

                    GradientStop {
                        position: 0.42
                        color: "#7607090d"
                    }

                    GradientStop {
                        position: 0.72
                        color: "#2407090d"
                    }

                    GradientStop {
                        position: 1
                        color: "#9907090d"
                    }

                }

            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.min(210, parent.height * 0.46)
                visible: false

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#0007090d"
                    }

                    GradientStop {
                        position: 1
                        color: "#f807090d"
                    }

                }

            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 0
                anchors.right: parent.right
                anchors.rightMargin: 34
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                spacing: 10

                Image {
                    width: Math.min(560, parent.width)
                    height: 164
                    source: currentGame() ? (currentGame().logo || "") : ""
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    verticalAlignment: Image.AlignBottom
                    visible: source !== ""
                }

                Text {
                    text: tagLine(currentGame())
                    color: emberLight
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0
                }

                Text {
                    text: {
                        let game = currentGame();
                        if (game)
                            return game.name;

                        return libraryScanRunning ? "Scanning Cartridges" : "Anvil Library";
                    }
                    color: fg
                    font.pixelSize: 52
                    font.bold: true
                    width: Math.min(720, parent.width)
                    elide: Text.ElideRight
                    lineHeight: 0.94
                    visible: !currentGame() || !currentGame().logo
                }

                Text {
                    text: libraryScanRunning ? "Mounting removable media and checking your cartridge shelf." : ((currentGame() && currentGame().proton) ? currentGame().proton : "Ready to play")
                    color: "#d4d8d9"
                    font.pixelSize: 14
                    width: Math.min(520, parent.width)
                    elide: Text.ElideRight
                }

                Row {
                    spacing: 10
                    visible: currentGame() !== null

                    Rectangle {
                        width: 138
                        height: 46
                        radius: 6
                        color: ember

                        Text {
                            anchors.centerIn: parent
                            text: "PLAY"
                            color: "#160b07"
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 0
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: launchGame()
                        }

                    }

                    Rectangle {
                        width: 46
                        height: 46
                        radius: 6
                        color: "#dd111820"
                        border.color: "#3b4652"

                        Text {
                            anchors.centerIn: parent
                            text: "⋯"
                            color: fg
                            font.pixelSize: 22
                            font.bold: true
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
            anchors.bottomMargin: 58
            height: 292

            Text {
                anchors.left: parent.left
                anchors.leftMargin: contentLeft
                anchors.top: parent.top
                text: "RECENT GAMES"
                color: fg
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 0
            }

            Image {
                anchors.left: parent.left
                anchors.leftMargin: contentLeft - 40
                anchors.bottom: gameStrip.top
                anchors.bottomMargin: -52
                width: 430
                height: 190
                source: anvilRoot + "/assets/anvil-focus-flame.png"
                fillMode: Image.PreserveAspectFit
                opacity: 0.48
                visible: false

                SequentialAnimation on opacity {
                    running: homePage.visible
                    loops: Animation.Infinite

                    NumberAnimation {
                        from: 0.38
                        to: 0.56
                        duration: 1200
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        from: 0.56
                        to: 0.38
                        duration: 1450
                        easing.type: Easing.InOutSine
                    }

                }

            }

            ListView {
                id: gameStrip

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 252
                orientation: ListView.Horizontal
                spacing: 16
                leftMargin: contentLeft
                rightMargin: 72
                model: gameModel
                currentIndex: selectedGameIndex
                focus: !powerMenuActive && activeSection === 0
                preferredHighlightBegin: contentLeft
                preferredHighlightEnd: contentLeft + 420
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
                    property bool hasLandscapeArt: landscapeSource !== ""
                    property bool focused: ListView.isCurrentItem || hoverArea.containsMouse
                    property bool expanded: focused && hasLandscapeArt

                    width: expanded ? 424 : 150
                    height: 222
                    opacity: focused ? 1 : 0.7
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.centerIn: cardSurface
                        anchors.verticalCenterOffset: expanded ? -8 : -4
                        width: cardSurface.width + (expanded ? 78 : 54)
                        height: cardSurface.height + (expanded ? 82 : 62)
                        source: anvilRoot + "/assets/anvil-focus-flame.png"
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.46
                        visible: focused

                        SequentialAnimation on opacity {
                            running: focused
                            loops: Animation.Infinite

                            NumberAnimation {
                                from: 0.36
                                to: 0.56
                                duration: 1200
                                easing.type: Easing.InOutSine
                            }

                            NumberAnimation {
                                from: 0.56
                                to: 0.36
                                duration: 1450
                                easing.type: Easing.InOutSine
                            }

                        }

                    }

                    Rectangle {
                        id: cardSurface

                        anchors.fill: parent
                        radius: 8
                        color: panelRaised
                        border.color: focused ? ember : "#32404d"
                        border.width: focused ? 3 : 1
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            visible: boxSource === "" && !expanded

                            Text {
                                anchors.centerIn: parent
                                text: initials(model.name)
                                color: "#f6d0be"
                                opacity: 0.68
                                font.pixelSize: focused ? 82 : 54
                                font.bold: true
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                anchors.top: parent.top
                                anchors.topMargin: 18
                                width: 42
                                height: 42
                                radius: 6
                                color: "#181f27"
                                border.color: ember

                                Text {
                                    anchors.centerIn: parent
                                    text: "A"
                                    color: emberLight
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                            }

                            gradient: Gradient {
                                orientation: Gradient.Vertical

                                GradientStop {
                                    position: 0
                                    color: "#27333d"
                                }

                                GradientStop {
                                    position: 0.52
                                    color: "#151d25"
                                }

                                GradientStop {
                                    position: 1
                                    color: "#432719"
                                }

                            }

                        }

                        Image {
                            id: boxArtImage

                            anchors.fill: parent
                            source: boxSource
                            fillMode: Image.PreserveAspectFit
                            opacity: expanded ? 0 : 1
                            visible: source !== "" && opacity > 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                        }

                        Image {
                            id: landscapeArtImage

                            anchors.fill: parent
                            source: landscapeSource
                            fillMode: Image.PreserveAspectCrop
                            opacity: expanded ? 1 : 0
                            visible: source !== "" && opacity > 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent

                            gradient: Gradient {
                                GradientStop {
                                    position: 0
                                    color: focused ? "#11000000" : "#22000000"
                                }

                                GradientStop {
                                    position: focused ? 0.48 : 0.62
                                    color: focused ? "#33000000" : "#55000000"
                                }

                                GradientStop {
                                    position: 1
                                    color: "#ee05070a"
                                }

                            }

                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 15
                            anchors.top: parent.top
                            anchors.topMargin: 14
                            text: (model.hero || model.grid) ? "READY" : "LOCAL"
                            color: model.steamgriddb_id ? green : muted
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 0
                            visible: focused
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 15
                            spacing: 6

                            Image {
                                width: parent.width
                                height: focused ? 64 : 34
                                source: logoSource
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignLeft
                                verticalAlignment: Image.AlignBottom
                                mipmap: true
                                visible: source !== ""
                            }

                            Text {
                                text: model.name
                                color: fg
                                font.pixelSize: focused ? 23 : 14
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                                visible: logoSource === ""
                            }

                            Text {
                                text: model.proton || "Proton Experimental"
                                color: "#a5aaae"
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                                visible: focused
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

                    Behavior on width {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }

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
                        fillMode: Image.PreserveAspectFit
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

        Text {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 126
            text: "Store"
            color: fg
            font.pixelSize: 38
            font.bold: true
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
            anchors.topMargin: 64
            anchors.bottom: bottomHints.top
            anchors.bottomMargin: 20
            spacing: 16

            Repeater {
                model: storeModel

                Rectangle {
                    width: Math.min(310, (parent.width - 32) / 3)
                    height: 154
                    radius: 7
                    color: selectedStoreTile === index ? "#e5242d35" : "#d4161c22"
                    border.color: selectedStoreTile === index ? ember : "#2b343d"
                    border.width: selectedStoreTile === index ? 2 : 1
                    scale: selectedStoreTile === index ? 1 : 0.96

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 20
                        spacing: 7

                        Text {
                            text: model.eyebrow
                            color: selectedStoreTile === index ? emberLight : forgeGold
                            font.pixelSize: 9
                            font.bold: true
                        }

                        Text {
                            text: model.title
                            color: fg
                            font.pixelSize: 23
                            font.bold: true
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
            anchors.topMargin: 218
            anchors.bottom: bottomHints.top
            anchors.bottomMargin: 24
            spacing: 8

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
            anchors.bottom: bottomHints.top
            anchors.bottomMargin: 28
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
        visible: activeSection === 6

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

    Item {
        id: downloadsPage

        anchors.fill: parent
        visible: activeSection === 4

        Column {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 124
            spacing: 18

            Text {
                text: "Downloads"
                color: fg
                font.pixelSize: 58
                font.bold: true
            }

            Text {
                text: "Scans, client updates, installs, verification, repair, and rollback."
                color: muted
                font.pixelSize: 14
            }

            Repeater {
                model: downloadModel

                Rectangle {
                    width: parent.width
                    height: 142
                    radius: 8
                    color: index === 0 ? "#1f2933" : "#121820"
                    border.color: index === 0 ? ember : "#2c3743"

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 22
                        anchors.rightMargin: 22
                        spacing: 10

                        Row {
                            width: parent.width

                            Text {
                                text: model.title
                                color: fg
                                font.pixelSize: 28
                                font.bold: true
                                width: parent.width - 90
                                elide: Text.ElideRight
                            }

                            Text {
                                text: model.value
                                color: model.value === "Live" ? green : forgeGold
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                                width: 90
                            }

                        }

                        Text {
                            text: model.body
                            color: muted
                            font.pixelSize: 12
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: parent.width
                            height: 8
                            radius: 4
                            color: "#28313a"

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * model.progress / 100
                                radius: 4
                                color: model.value === "Live" ? forgeGold : ember
                            }

                        }

                    }

                }

            }

        }

    }

    Item {
        id: settingsConsolePage

        anchors.fill: parent
        visible: activeSection === 5

        Text {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 126
            text: "Settings"
            color: fg
            font.pixelSize: 38
            font.bold: true
        }

        Column {
            id: settingsList

            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 196
            anchors.bottom: bottomHints.top
            anchors.bottomMargin: 28
            width: Math.min(470, parent.width * 0.32)
            spacing: 6

            Repeater {
                model: settingsModel

                Rectangle {
                    width: parent.width
                    height: 74
                    radius: 6
                    color: selectedSetting === index ? "#25303a" : "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 4
                        height: 42
                        radius: 2
                        color: ember
                        visible: selectedSetting === index
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 22
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            width: parent.width
                            text: model.title
                            color: selectedSetting === index ? fg : "#c6cbd0"
                            font.pixelSize: 17
                            font.bold: selectedSetting === index
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: model.value
                            color: selectedSetting === index ? emberLight : muted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedSetting = index;
                        }
                    }

                }

            }

        }

        Item {
            anchors.left: settingsList.right
            anchors.leftMargin: 72
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 202
            anchors.bottom: bottomHints.top
            anchors.bottomMargin: 32

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 16

                Text {
                    width: parent.width
                    text: settingsModel.get(selectedSetting).title
                    color: fg
                    font.pixelSize: 32
                    font.bold: true
                }

                Text {
                    width: parent.width
                    text: settingsModel.get(selectedSetting).body
                    color: muted
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    lineHeight: 1.3
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#313942"
                }

                Column {
                    visible: selectedSettingKey() === "input"
                    width: parent.width
                    spacing: 14

                    Rectangle {
                        width: parent.width
                        height: 118
                        radius: 8
                        color: "#121820"
                        border.color: "#2d3944"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 18
                            spacing: 18

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 88
                                height: 72
                                radius: 8
                                color: "#191f27"
                                border.color: line

                                Image {
                                    anchors.centerIn: parent
                                    width: 58
                                    height: 38
                                    source: controllerIcon()
                                    sourceSize.width: 116
                                    sourceSize.height: 76
                                    opacity: source === "" ? 0 : 0.92
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: controllerIcon() === ""
                                    text: "PAD"
                                    color: muted
                                    font.pixelSize: 16
                                    font.bold: true
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 112
                                spacing: 7

                                Text {
                                    text: controllerShortName()
                                    color: fg
                                    font.pixelSize: 26
                                    font.bold: true
                                }

                                Text {
                                    text: "Last input: " + inputActionLabel(controllerAction)
                                    color: controllerAction === "" ? muted : emberLight
                                    font.pixelSize: 13
                                    font.bold: true
                                }

                                Text {
                                    text: "Game: " + inputRuntimeLabel(currentGame()) + " / " + inputGlyphLabel(currentGame())
                                    color: muted
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }
                    }

                    Grid {
                        width: parent.width
                        columns: 5
                        rowSpacing: 10
                        columnSpacing: 10

                        Repeater {
                            model: ["south", "east", "north", "west", "lt", "rt", "lb", "rb", "back", "start", "guide", "up", "down", "left", "right"]

                            Rectangle {
                                width: (parent.width - parent.columnSpacing * (parent.columns - 1)) / parent.columns
                                height: 54
                                radius: 6
                                color: controllerAction === modelData ? ember : "#141b23"
                                border.color: controllerAction === modelData ? emberLight : "#2b3540"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData === "up" || modelData === "down" || modelData === "left" || modelData === "right" ? inputActionLabel(modelData) : ""
                                    color: controllerAction === modelData ? "#160b07" : fg
                                    font.pixelSize: 12
                                    font.bold: true
                                    width: parent.width - 14
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
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

                    Text {
                        width: parent.width
                        text: "This is the first Anvil Input surface: controller family, glyph translation, per-game maps, and live button events in one place."
                        color: muted
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        lineHeight: 1.25
                    }
                }

                Repeater {
                    model: settingsOptions(selectedSettingKey())
                    visible: selectedSettingKey() !== "input"

                    Rectangle {
                        width: parent.width
                        height: 62
                        color: "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: fg
                            font.pixelSize: 15
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 48
                            height: 26
                            radius: 13
                            color: index === 1 ? "#39434c" : ember

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: index === 1 ? 4 : parent.width - width - 4
                                width: 18
                                height: 18
                                radius: 9
                                color: fg
                            }

                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: "#222a31"
                        }

                    }

                }

            }

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
                    color: index === 3 ? "#1f2933" : "#121820"
                    border.color: index === 3 ? ember : "#2c3743"

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
                        onClicked: {
                            if (modelData === "Switch to Desktop")
                                Qt.quit();

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
        height: 62
        color: "#e0050609"
        border.color: "#202832"
        z: 20

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24

            Text {
                text: "Sections"
                color: muted
                font.pixelSize: 12
                font.bold: true
            }

            ButtonGlyph {
                anchors.verticalCenter: parent.verticalCenter
                action: "lt"
            }

            ButtonGlyph {
                anchors.verticalCenter: parent.verticalCenter
                action: "rt"
            }

            Text {
                text: "Select"
                color: muted
                font.pixelSize: 12
                font.bold: true
            }

            ButtonGlyph {
                anchors.verticalCenter: parent.verticalCenter
                action: "accept"
            }

            Text {
                text: "Back"
                color: muted
                font.pixelSize: 12
                font.bold: true
            }

            ButtonGlyph {
                anchors.verticalCenter: parent.verticalCenter
                action: "back"
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
                text: libraryScanRunning ? libraryScanMessage : ""
                color: "#c5c8c9"
                font.pixelSize: 14
                visible: libraryScanRunning
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
