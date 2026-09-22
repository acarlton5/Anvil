import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: anvil

    property var modelData: null
    property var launchHandler: null
    readonly property string localRoot: decodeURIComponent(Qt.resolvedUrl("../../").toString()).replace("file://", "").replace(/\/$/, "")
    readonly property string anvilRoot: Quickshell.env("ANVIL_ROOT") || localRoot
    readonly property string bridgePath: anvilRoot + "/src/daemon/anvil-library-bridge"
    readonly property string daemonPath: anvilRoot + "/src/ui/AnvilDaemon.qml"
    readonly property color bg: "#050609"
    readonly property color panel: "#101419"
    readonly property color panelRaised: "#171d23"
    readonly property color line: "#2f3740"
    readonly property color fg: "#f5f5f2"
    readonly property color muted: "#aeb6bd"
    readonly property color ember: "#ff6537"
    readonly property color emberLight: "#ff8a66"
    readonly property color forgeGold: "#d9ad5f"
    readonly property color relayBlue: "#7aa8ff"
    readonly property color green: "#65d797"
    readonly property int sidebarWidth: 112
    readonly property int contentLeft: sidebarWidth + 44
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

    function currentGame() {
        if (gameModel.count === 0)
            return null;

        return gameModel.get(Math.max(0, Math.min(selectedGameIndex, gameModel.count - 1)));
    }

    function gameArt(game) {
        if (!game || game.dummy)
            return "";

        return game.hero || game.grid || "";
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
            return "Apps, builds, publishing";
        case 5:
            return "Queue, verify, update";
        case 6:
            return "Session and runtime";
        default:
            return "Anvil";
        }
    }

    function launchGame() {
        let game = currentGame();
        if (!game || game.dummy || !game.launch_command)
            return ;

        gameIsLoading = true;
        console.log("Launching: " + game.name);
        if (launchHandler) {
            launchHandler(game.launch_command);
            return ;
        }
        launcher.command = ["qs", "ipc", "-p", daemonPath, "call", "anvil", "launch", game.launch_command];
        launcher.running = true;
    }

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
            icon: "◆"
        }

        ListElement {
            label: "Library"
            icon: "▦"
        }

        ListElement {
            label: "Store"
            icon: "⬢"
        }

        ListElement {
            label: "Community"
            icon: "◌"
        }

        ListElement {
            label: "Forgeworks"
            icon: "⚒"
        }

        ListElement {
            label: "Downloads"
            icon: "↓"
        }

        ListElement {
            label: "Settings"
            icon: "⚙"
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
            value: "Mock"
            progress: 42
        }

        ListElement {
            title: "Forgepipe install"
            body: "Depot download, verify, repair, move, uninstall, and delta updates."
            value: "Design"
            progress: 24
        }

    }

    ListModel {
        id: settingsModel

        ListElement {
            title: "Anvil Session"
            body: "Dedicated Wayland session, controller navigation, focus, logout, and cleanup."
            value: "Installed by plugin"
        }

        ListElement {
            title: "Anvil Runtime"
            body: "Per-game Proton, prefixes, launch logs, overlay hooks, and exit recovery."
            value: "Prototype"
        }

        ListElement {
            title: "Anvil Cloud"
            body: "Save sync, settings sync, offline queue, and conflicts."
            value: "Mock"
        }

        ListElement {
            title: "Forge Guard"
            body: "Device trust, sign-in approval, family controls, and account recovery."
            value: "Mock"
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
        opacity: source === "" ? 0 : 0.42
        visible: source !== ""
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#f2080b0f"
            }

            GradientStop {
                position: 0.42
                color: "#aa080b0f"
            }

            GradientStop {
                position: 0.72
                color: "#ee080b0f"
            }

            GradientStop {
                position: 1
                color: "#ff080b0f"
            }

        }

    }

    Rectangle {
        id: topbar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 76
        color: "#d8050609"
        border.color: "#202832"
        z: 20

        Row {
            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 38
                radius: 2
                color: ember
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    text: currentSectionLabel()
                    color: fg
                    font.pixelSize: 20
                    font.bold: true
                    font.letterSpacing: 0
                }

                Text {
                    text: currentSectionSubtitle()
                    color: muted
                    font.pixelSize: 11
                    font.bold: true
                    font.letterSpacing: 0
                }

            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 106
                height: 28
                radius: 8
                color: "#17212a"
                border.color: "#2f3a45"

                Text {
                    anchors.centerIn: parent
                    text: "SESSION"
                    color: forgeGold
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 0
                }

            }

        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 92
                height: 36
                radius: 8
                color: "#131a21"
                border.color: "#2c3743"

                Text {
                    anchors.centerIn: parent
                    text: Qt.formatTime(new Date(), "h:mm AP")
                    color: muted
                    font.pixelSize: 13
                    font.bold: true
                }

            }

            Rectangle {
                width: 38
                height: 36
                radius: 8
                color: powerMenuActive ? "#30201a" : "#131a21"
                border.color: powerMenuActive ? ember : "#27323d"

                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    color: powerMenuActive ? emberLight : muted
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
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
        color: "#f006080c"
        border.color: "#202833"
        z: 24

        Column {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            spacing: 14

            Row {
                width: parent.width
                height: 62
                spacing: 0

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 58
                    height: 58
                    radius: 8
                    color: "#171d23"
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
                    color: activeSection === index ? "#1b242d" : "transparent"
                    border.color: activeSection === index ? "#3c4855" : "transparent"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: 34
                        radius: 2
                        color: ember
                        visible: activeSection === index
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        radius: 8
                        color: activeSection === index ? ember : "#121820"
                        border.color: activeSection === index ? ember : "#2d3844"

                        Text {
                            anchors.centerIn: parent
                            text: model.icon
                            color: activeSection === index ? "#160b07" : muted
                            font.pixelSize: 19
                            font.bold: true
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: selectSection(index)
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
            id: fallbackHero

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 76
            height: Math.max(470, parent.height * 0.62)
            visible: heroImage.source === ""

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 120
                anchors.topMargin: 70
                width: 360
                height: 220
                radius: 8
                color: "#16ffffff"
                border.color: "#22ffffff"
                rotation: -4
            }

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "#111820"
                }

                GradientStop {
                    position: 0.46
                    color: "#263238"
                }

                GradientStop {
                    position: 0.78
                    color: "#4f3a29"
                }

                GradientStop {
                    position: 1
                    color: "#10151b"
                }

            }

        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 76
            height: Math.max(470, parent.height * 0.62)

            gradient: Gradient {
                orientation: Gradient.Horizontal

                GradientStop {
                    position: 0
                    color: "#fb080b0f"
                }

                GradientStop {
                    position: 0.38
                    color: "#dd080b0f"
                }

                GradientStop {
                    position: 0.72
                    color: "#44080b0f"
                }

                GradientStop {
                    position: 1
                    color: "#aa080b0f"
                }

            }

        }

        Column {
            id: heroCopy

            anchors.left: parent.left
            anchors.leftMargin: contentLeft
            anchors.top: parent.top
            anchors.topMargin: 126
            width: Math.min(480, parent.width * 0.4)
            spacing: 9

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
                font.pixelSize: 34
                font.bold: true
                width: parent.width
                wrapMode: Text.WordWrap
                lineHeight: 0.96
            }

            Text {
                text: libraryScanRunning ? "Mounting removable media and checking your cartridge shelf." : ((currentGame() && currentGame().proton) ? currentGame().proton : "Ready to play")
                color: "#c5c8c9"
                font.pixelSize: 13
                width: Math.min(420, parent.width)
                wrapMode: Text.WordWrap
                lineHeight: 1.25
            }

            Row {
                spacing: 10
                visible: currentGame() !== null

                Rectangle {
                    width: 124
                    height: 40
                    radius: 8
                    color: ember

                    Text {
                        anchors.centerIn: parent
                        text: "Play"
                        color: "#160b07"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: launchGame()
                    }

                }

                Rectangle {
                    width: 40
                    height: 40
                    radius: 8
                    color: "#cc131a22"
                    border.color: "#38434e"

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
            anchors.bottomMargin: 74
            height: 330

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

            ListView {
                id: gameStrip

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 286
                orientation: ListView.Horizontal
                spacing: 14
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

                delegate: Rectangle {
                    id: card

                    width: ListView.isCurrentItem ? Math.min(590, Math.max(390, anvil.width * 0.4)) : 148
                    height: ListView.isCurrentItem ? 248 : 222
                    radius: 8
                    color: panelRaised
                    border.color: ListView.isCurrentItem ? ember : "#32404d"
                    border.width: ListView.isCurrentItem ? 2 : 1
                    clip: true
                    scale: ListView.isCurrentItem ? 1.02 : 0.94
                    opacity: ListView.isCurrentItem ? 1 : 0.7
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        visible: (model.hero || model.grid || "") === ""

                        Text {
                            anchors.centerIn: parent
                            text: initials(model.name)
                            color: "#f6d0be"
                            opacity: 0.68
                            font.pixelSize: ListView.isCurrentItem ? 82 : 54
                            font.bold: true
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.top: parent.top
                            anchors.topMargin: 18
                            width: 42
                            height: 42
                            radius: 8
                            color: "#181f27"
                            border.color: ember

                            Text {
                                anchors.centerIn: parent
                                text: "◆"
                                color: emberLight
                                font.pixelSize: 20
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
                        anchors.fill: parent
                        source: model.dummy ? "" : (ListView.isCurrentItem ? (model.hero || model.grid || "") : (model.grid || model.hero || ""))
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        anchors.fill: parent

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: ListView.isCurrentItem ? "#11000000" : "#22000000"
                            }

                            GradientStop {
                                position: ListView.isCurrentItem ? 0.48 : 0.62
                                color: ListView.isCurrentItem ? "#33000000" : "#55000000"
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
                        text: ListView.isCurrentItem ? ((model.hero || model.grid) ? "FEATURED" : "LOCAL") : ((model.grid || model.hero) ? "BOX ART" : "LOCAL")
                        color: model.steamgriddb_id ? green : muted
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0
                        visible: ListView.isCurrentItem
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 15
                        spacing: 5

                        Text {
                            text: model.name
                            color: fg
                            font.pixelSize: ListView.isCurrentItem ? 20 : 13
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: (model.proton || "Proton Experimental").toUpperCase()
                            color: "#a5aaae"
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                            visible: ListView.isCurrentItem
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedGameIndex = index;
                            gameStrip.currentIndex = index;
                            gameStrip.forceActiveFocus();
                        }
                        onDoubleClicked: launchGame()
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 160
                            easing.type: Easing.OutCubic
                        }

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
        id: libraryPage

        anchors.fill: parent
        visible: activeSection === 1

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
                                    source: model.grid || model.hero || ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: initials(model.name)
                                    color: emberLight
                                    font.pixelSize: 9
                                    font.bold: true
                                    visible: (model.grid || model.hero || "") === ""
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
                            "label": "Artwork",
                            "value": currentGame() && (currentGame().hero || currentGame().grid) ? "Available" : "Missing"
                        }, {
                            "label": "Launch",
                            "value": currentGame() && currentGame().launch_command ? "Ready" : "No command"
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
        id: storePage

        anchors.fill: parent
        visible: activeSection === 2

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
        id: communityPage

        anchors.fill: parent
        visible: activeSection === 3

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
        visible: activeSection === 4

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
        visible: activeSection === 5

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
        id: settingsPage

        anchors.fill: parent
        visible: activeSection === 6

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
                text: "LB / RB  Sections"
                color: muted
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                text: "A / ENTER  Select"
                color: muted
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                text: "B / ESC  Back"
                color: muted
                font.pixelSize: 12
                font.bold: true
            }

        }

    }

    Rectangle {
        id: loadingScreen

        anchors.fill: parent
        color: bg
        opacity: gameIsLoading || libraryScanRunning ? 1 : 0
        visible: opacity > 0
        z: 100

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

}
