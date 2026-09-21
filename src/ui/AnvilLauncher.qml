import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: anvil

    property var modelData: null
    readonly property string localRoot: decodeURIComponent(Qt.resolvedUrl("../../").toString()).replace("file://", "").replace(/\/$/, "")
    readonly property string anvilRoot: Quickshell.env("ANVIL_ROOT") || localRoot
    readonly property string bridgePath: anvilRoot + "/src/daemon/constellation-bridge"
    readonly property string daemonPath: anvilRoot + "/src/ui/AnvilDaemon.qml"
    readonly property color bg: "#080b0f"
    readonly property color panel: "#12171d"
    readonly property color panelRaised: "#171e26"
    readonly property color line: "#2a323b"
    readonly property color fg: "#f5f5f2"
    readonly property color muted: "#98a0a9"
    readonly property color ember: "#ff6537"
    readonly property color emberLight: "#ff8a66"
    readonly property color green: "#65d797"
    property int activeSection: Number(Quickshell.env("ANVIL_SECTION") || 0)
    property bool navOpen: false
    property bool powerMenuActive: false
    property bool gameIsLoading: false
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

    function selectSection(index) {
        activeSection = Math.max(0, Math.min(index, navModel.count - 1));
        navOpen = false;
    }

    function launchGame() {
        let game = currentGame();
        if (!game || game.dummy || !game.launch_command)
            return ;

        gameIsLoading = true;
        console.log("Launching: " + game.name);
        launcher.command = ["qs", "-p", daemonPath, "ipc", "call", "anvil", "launch", game.launch_command];
        launcher.running = true;
    }

    color: bg
    screen: modelData
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "anvil-launcher"
    Component.onCompleted: {
        if (gameModel.count === 0) {
            gameModel.append({
                "name": "ASTROBOTANICA",
                "path": "",
                "launch_command": "",
                "proton": "Proton Experimental",
                "tags": ["Adventure"],
                "hero": "",
                "grid": "",
                "logo": "",
                "steamgriddb_id": "",
                "dummy": true
            });
            gameModel.append({
                "name": "Bluey: The Videogame",
                "path": "",
                "launch_command": "",
                "proton": "Proton Experimental",
                "tags": ["Family"],
                "hero": "",
                "grid": "",
                "logo": "",
                "steamgriddb_id": "",
                "dummy": true
            });
            gameModel.append({
                "name": "Card Shop Simulator",
                "path": "",
                "launch_command": "",
                "proton": "Proton Experimental",
                "tags": ["Sim"],
                "hero": "",
                "grid": "",
                "logo": "",
                "steamgriddb_id": "",
                "dummy": true
            });
        }
    }

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
        }

        ListElement {
            label: "Library"
        }

        ListElement {
            label: "Store"
        }

        ListElement {
            label: "Community"
        }

    }

    ListModel {
        id: storeModel

        ListElement {
            title: "Fresh From The Forge"
            body: "Playable demos, early builds, and experimental indies staged for Anvil."
        }

        ListElement {
            title: "Creator Terms"
            body: "A store model built around better revenue cuts and transparent launch tooling."
        }

        ListElement {
            title: "Cartridge Sync"
            body: "USB and SD libraries today, packaged server manifests tomorrow."
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
                    let games = payload.length > 0 ? JSON.parse(payload) : [];
                    if (games.length > 0) {
                        gameModel.clear();
                        for (let i = 0; i < games.length; i++) gameModel.append(games[i])
                        selectedGameIndex = 0;
                    }
                } catch (e) {
                    console.log("Anvil bridge parse error: " + e);
                }
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
                color: "#24110d"
            }

            GradientStop {
                position: 0.22
                color: "#120d0d"
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
        color: "#cc080b0f"
        border.color: "#26313c"
        z: 20

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            spacing: 11

            Rectangle {
                width: 34
                height: 34
                radius: 8
                color: "#1a1412"
                border.color: ember
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "A"
                    color: emberLight
                    font.pixelSize: 21
                    font.bold: true
                }

            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ANVIL"
                color: fg
                font.pixelSize: 15
                font.bold: true
                font.letterSpacing: 2
            }

        }

        Row {
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: navModel

                Rectangle {
                    width: 112
                    height: 42
                    radius: 9
                    color: activeSection === index ? "#22ffffff" : "transparent"
                    border.color: activeSection === index ? "#33ffffff" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: model.label
                        color: activeSection === index ? fg : muted
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        width: 52
                        height: 2
                        color: ember
                        visible: activeSection === index
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
            anchors.rightMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 92
                height: 36
                radius: 10
                color: "#151b22"
                border.color: "#27323d"

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
                radius: 10
                color: powerMenuActive ? "#30201a" : "#151b22"
                border.color: powerMenuActive ? ember : "#27323d"

                Text {
                    anchors.centerIn: parent
                    text: "IO"
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
            height: Math.max(430, parent.height * 0.55)
            visible: heroImage.source === ""

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 120
                anchors.topMargin: 70
                width: 360
                height: 220
                radius: 14
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
            height: Math.max(430, parent.height * 0.55)

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
            anchors.leftMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 148
            width: Math.min(720, parent.width * 0.44)
            spacing: 16

            Text {
                text: "FEATURED CARTRIDGE"
                color: "#d1d3d4"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2
            }

            Text {
                text: {
                    let game = currentGame();
                    return game ? game.name : "Anvil Library";
                }
                color: fg
                font.pixelSize: Math.min(84, Math.max(48, anvil.width * 0.035))
                font.bold: true
                width: parent.width
                wrapMode: Text.WordWrap
                lineHeight: 0.92
            }

            Text {
                text: "A dedicated game client for local cartridges today and an indie-first store tomorrow."
                color: "#c5c8c9"
                font.pixelSize: 16
                width: Math.min(560, parent.width)
                wrapMode: Text.WordWrap
                lineHeight: 1.35
            }

            Row {
                spacing: 10

                Text {
                    text: tagLine(currentGame())
                    color: muted
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: "/"
                    color: "#55ffffff"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: "PROTON READY"
                    color: green
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: "/"
                    color: "#55ffffff"
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: gameModel.count + " GAMES"
                    color: muted
                    font.pixelSize: 11
                    font.bold: true
                }

            }

            Row {
                spacing: 12

                Rectangle {
                    width: 142
                    height: 48
                    radius: 10
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
                    width: 142
                    height: 48
                    radius: 10
                    color: "#cc141a20"
                    border.color: "#44ffffff"

                    Text {
                        anchors.centerIn: parent
                        text: "Details"
                        color: fg
                        font.pixelSize: 14
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

            Repeater {
                model: [{
                    "label": "Drive",
                    "value": "44E1"
                }, {
                    "label": "Artwork",
                    "value": "Grid API"
                }, {
                    "label": "Mode",
                    "value": "Anvil"
                }]

                Rectangle {
                    width: 132
                    height: 86
                    color: "#bb0f141a"
                    border.color: "#26313c"

                    Column {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: muted
                            font.pixelSize: 9
                            font.bold: true
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.value
                            color: fg
                            font.pixelSize: 15
                            font.bold: true
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
            anchors.bottomMargin: 90
            height: 250

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 72
                anchors.top: parent.top
                text: activeSection === 0 ? "Recently Indexed" : "Store Preview"
                color: fg
                font.pixelSize: 18
                font.bold: true
            }

            ListView {
                id: gameStrip

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 198
                orientation: ListView.Horizontal
                spacing: 14
                leftMargin: 72
                rightMargin: 72
                model: gameModel
                currentIndex: selectedGameIndex
                focus: !navOpen && !powerMenuActive && activeSection === 0
                preferredHighlightBegin: 72
                preferredHighlightEnd: 384
                highlightRangeMode: ListView.StrictlyEnforceRange
                Keys.onLeftPressed: decrementCurrentIndex()
                Keys.onRightPressed: incrementCurrentIndex()
                onCurrentIndexChanged: selectedGameIndex = currentIndex
                Keys.onReturnPressed: launchGame()
                Keys.onTabPressed: navOpen = true
                Keys.onEscapePressed: powerMenuActive = false

                delegate: Rectangle {
                    id: card

                    width: 300
                    height: 176
                    radius: 13
                    color: "#192027"
                    border.color: ListView.isCurrentItem ? ember : "#2a323b"
                    border.width: ListView.isCurrentItem ? 2 : 1
                    clip: true
                    scale: ListView.isCurrentItem ? 1.03 : 0.96
                    opacity: ListView.isCurrentItem ? 1 : 0.78

                    Rectangle {
                        anchors.fill: parent
                        visible: (model.hero || model.grid || "") === ""

                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop {
                                position: 0
                                color: "#192027"
                            }

                            GradientStop {
                                position: 0.55
                                color: "#27323b"
                            }

                            GradientStop {
                                position: 1
                                color: "#513322"
                            }

                        }

                    }

                    Image {
                        anchors.fill: parent
                        source: model.dummy ? "" : (model.hero || model.grid || "")
                        fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                        anchors.fill: parent

                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: "#22000000"
                            }

                            GradientStop {
                                position: 0.62
                                color: "#55000000"
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
                        text: model.steamgriddb_id ? "GRID READY" : "LOCAL"
                        color: model.steamgriddb_id ? green : muted
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 1
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
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            text: model.proton || "Proton Experimental"
                            color: "#a5aaae"
                            font.pixelSize: 10
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
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
            anchors.leftMargin: 54
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
                radius: 12
                color: "#ee0d1118"
                border.color: line
                clip: true

                Column {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        width: parent.width
                        height: 74
                        color: "#12171d"
                        border.color: line

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            Text {
                                text: "Library"
                                color: fg
                                font.pixelSize: 20
                                font.bold: true
                            }

                            Text {
                                text: gameModel.count + " cartridge entries"
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
                        focus: activeSection === 1 && !navOpen && !powerMenuActive
                        Keys.onUpPressed: {
                            decrementCurrentIndex();
                            selectedGameIndex = currentIndex;
                        }
                        Keys.onDownPressed: {
                            incrementCurrentIndex();
                            selectedGameIndex = currentIndex;
                        }
                        Keys.onReturnPressed: launchGame()
                        Keys.onTabPressed: navOpen = true

                        delegate: Rectangle {
                            width: libraryList.width
                            height: 54
                            color: selectedGameIndex === index ? "#242025" : (index % 2 === 0 ? "#0f141a" : "#111820")
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
                radius: 14
                color: "#dd0f141a"
                border.color: line
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

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            position: 0
                            color: "#1a222b"
                        }

                        GradientStop {
                            position: 0.58
                            color: "#2b3034"
                        }

                        GradientStop {
                            position: 1
                            color: "#523421"
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
                        font.letterSpacing: 2
                    }

                    Text {
                        text: currentGame() ? currentGame().name : "Select a Game"
                        color: fg
                        font.pixelSize: 58
                        font.bold: true
                        wrapMode: Text.WordWrap
                        width: parent.width
                        lineHeight: 0.94
                    }

                    Text {
                        text: currentGame() ? (currentGame().proton || "Proton Experimental") + " / " + (currentGame().steamgriddb_id ? "GridDB artwork linked" : "Local cartridge metadata") : ""
                        color: muted
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Row {
                        spacing: 12

                        Rectangle {
                            width: 150
                            height: 48
                            radius: 10
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
                            radius: 10
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
                            "label": "Path",
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
                            color: "#bb12171d"
                            border.color: line

                            Column {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: muted
                                    font.pixelSize: 9
                                    font.bold: true
                                    font.letterSpacing: 1
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

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 72
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 134
            spacing: 22

            Text {
                text: "Anvil Store"
                color: fg
                font.pixelSize: 56
                font.bold: true
            }

            Text {
                text: "A client surface for better indie publishing: demos, updates, storefronts, and cartridge packaging in one place."
                color: "#bdc1c4"
                font.pixelSize: 15
                width: Math.min(720, parent.width)
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: 14

                Repeater {
                    model: storeModel

                    Rectangle {
                        width: Math.max(300, (storePage.width - 186) / 3)
                        height: 260
                        radius: 14
                        color: selectedStoreTile === index ? "#1e252c" : panel
                        border.color: selectedStoreTile === index ? ember : line

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: 4
                            color: ember
                            radius: 2
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 22
                            spacing: 10

                            Text {
                                text: model.title
                                color: fg
                                font.pixelSize: 25
                                font.bold: true
                                wrapMode: Text.WordWrap
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
            anchors.leftMargin: 72
            anchors.right: parent.right
            anchors.rightMargin: 72
            anchors.top: parent.top
            anchors.topMargin: 134
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 90
            spacing: 20

            Rectangle {
                width: parent.width * 0.62
                height: parent.height
                radius: 14
                color: "#dd12171d"
                border.color: line

                Column {
                    anchors.fill: parent
                    anchors.margins: 26
                    spacing: 16

                    Text {
                        text: "Community"
                        color: fg
                        font.pixelSize: 42
                        font.bold: true
                    }

                    Text {
                        text: "Friends, patch notes, screenshots, developer posts, and discussions will live here as Anvil grows into a full client."
                        color: muted
                        font.pixelSize: 15
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Repeater {
                        model: ["49 local games indexed by Constellation", "SteamGridDB artwork fetcher ready for an API key", "Server-packaged cartridges are the next backend step"]

                        Rectangle {
                            width: parent.width
                            height: 76
                            radius: 10
                            color: "#151b22"
                            border.color: line

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 18
                                text: modelData
                                color: fg
                                font.pixelSize: 14
                                font.bold: true
                            }

                        }

                    }

                }

            }

            Rectangle {
                width: parent.width * 0.34
                height: parent.height
                radius: 14
                color: "#dd12171d"
                border.color: line

                Column {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 14

                    Text {
                        text: "Friends Online"
                        color: fg
                        font.pixelSize: 23
                        font.bold: true
                    }

                    Repeater {
                        model: ["Alex / In Game", "Mira / Browsing Store", "Jordan / Away"]

                        Rectangle {
                            width: parent.width
                            height: 58
                            radius: 9
                            color: "#171e26"

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

    Rectangle {
        anchors.fill: parent
        color: "#dd05070b"
        opacity: navOpen || powerMenuActive ? 1 : 0
        visible: opacity > 0
        z: 30

        MouseArea {
            anchors.fill: parent
            onClicked: {
                navOpen = false;
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
        id: navRail

        width: 320
        anchors.top: topbar.bottom
        anchors.bottom: bottomHints.top
        x: navOpen ? 0 : -width
        color: "#f00d1118"
        border.color: line
        z: 40

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            Text {
                text: "Anvil"
                color: fg
                font.pixelSize: 30
                font.bold: true
            }

            Repeater {
                model: navModel

                Rectangle {
                    width: parent.width
                    height: 54
                    radius: 9
                    color: activeSection === index ? "#22ffffff" : "transparent"
                    border.color: activeSection === index ? ember : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        text: model.label
                        color: activeSection === index ? fg : muted
                        font.pixelSize: 18
                        font.bold: activeSection === index
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: selectSection(index)
                    }

                }

            }

        }

        Behavior on x {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }

        }

    }

    Rectangle {
        id: powerMenu

        width: 430
        height: 318
        anchors.centerIn: parent
        radius: 14
        color: "#f0141a20"
        border.color: line
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
                    radius: 9
                    color: index === 3 ? "#241914" : "#151b22"
                    border.color: index === 3 ? ember : line

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
        color: "#e0080b0f"
        border.color: "#26313c"
        z: 20

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 54
            anchors.verticalCenter: parent.verticalCenter
            spacing: 24

            Text {
                text: "TAB  Menu"
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
        opacity: gameIsLoading ? 1 : 0
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
                text: "Starting"
                color: muted
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: {
                    let game = currentGame();
                    return game ? game.name : "Game";
                }
                color: fg
                font.pixelSize: 40
                font.bold: true
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
