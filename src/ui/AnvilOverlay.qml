import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: overlayWindow

    property var modelData: null
    property var closeHandler: null
    property var killHandler: null
    property string controllerAction: ""
    property int controllerActionSerial: 0
    property string controllerFamily: "xbox"
    property string controllerName: "Controller"
    readonly property color ink: "#f5f7fb"
    readonly property color muted: "#a8b1ba"
    readonly property color dim: "#68737d"
    readonly property color panel: "#d911171f"
    readonly property color panelSoft: "#aa151d26"
    readonly property color panelDeep: "#ee070a0f"
    readonly property color stroke: "#3a4652"
    readonly property color strokeSoft: "#24303a"
    readonly property color ember: "#ff6841"
    readonly property color gold: "#dbb66d"
    readonly property string anvilRoot: Quickshell.env("ANVIL_ROOT") || "/usr/local/share/anvil"
    readonly property string achievementStatusScript: anvilRoot + "/scripts/anvil-achievement-status"
    property int selectedDockIndex: 2
    property var achievementStatus: ({
        "game_name": "Current game",
        "service_state": "offline",
        "set_name": "Achievements",
        "claimed": 0,
        "total": 0,
        "achievements": []
    })
    property var openModules: ({
        "Home": true,
        "Friends": true,
        "Achievements": true,
        "Controller": false,
        "Capture": false,
        "Settings": false
    })

    function selectedItem() {
        return dockModel.get(Math.max(0, Math.min(selectedDockIndex, dockModel.count - 1)));
    }

    function moduleVisible(label) {
        return !!openModules[label];
    }

    function setModuleVisible(label, visible) {
        let next = Object.assign({}, openModules);
        next[label] = visible;
        openModules = next;
    }

    function toggleModule(index) {
        selectedDockIndex = index;
        let label = dockModel.get(index).label;
        setModuleVisible(label, !moduleVisible(label));
    }

    function runMenuAction(action) {
        if (action === "back") {
            if (closeHandler)
                closeHandler();
        } else if (action === "exit") {
            if (killHandler)
                killHandler();
        }
    }

    function refreshAchievements() {
        achievementStatusProcess.command = ["python3", achievementStatusScript];
        achievementStatusProcess.running = true;
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
            return "Guide";
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
        return ink;
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

    function inputRuntimeLabel(mode) {
        mode = String(mode || "");
        if (mode === "xinput_compat")
            return "XInput";
        if (mode === "forgeworks_input")
            return "Anvil Input";
        if (mode === "native")
            return "Native";
        return "Default";
    }

    function inputGlyphLabel(mode) {
        mode = String(mode || "");
        if (mode === "game_xbox_only")
            return "Xbox glyphs";
        if (mode === "anvil_glyphs")
            return "Anvil glyphs";
        if (mode === "native")
            return "Native glyphs";
        return "Auto";
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

    function handleControllerAction(action) {
        if (action === "left" || action === "lt" || action === "lb")
            selectedDockIndex = Math.max(0, selectedDockIndex - 1);
        else if (action === "right" || action === "rt" || action === "rb")
            selectedDockIndex = Math.min(dockModel.count - 1, selectedDockIndex + 1);
        else if (action === "up")
            selectedDockIndex = Math.max(0, selectedDockIndex - 2);
        else if (action === "down")
            selectedDockIndex = Math.min(dockModel.count - 1, selectedDockIndex + 2);
        else if (action === "south" || action === "start")
            toggleModule(selectedDockIndex);
        else if (action === "north")
            refreshAchievements();
        else if (action === "east" || action === "back")
            runMenuAction("back");
        keyCatcher.forceActiveFocus();
    }

    color: "transparent"
    screen: modelData
    implicitWidth: 1920
    implicitHeight: 1080
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "anvil-overlay"
    Component.onCompleted: {
        keyCatcher.forceActiveFocus();
        refreshAchievements();
    }
    onControllerActionSerialChanged: handleControllerAction(controllerAction)

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    ListModel {
        id: dockModel

        ListElement {
            label: "Home"
            icon: "user-home-symbolic"
            title: "ANVIL"
            eyebrow: "Session"
            summary: "Return to library, session controls, update state, and runtime actions."
        }

        ListElement {
            label: "Friends"
            icon: "system-users-symbolic"
            title: "FRIENDS"
            eyebrow: "Social"
            summary: "Friends, group chats, parties, invites, and presence."
        }

        ListElement {
            label: "Achievements"
            icon: "emblem-favorite-symbolic"
            title: "ACHIEVEMENTS"
            eyebrow: "Forgeworks"
            summary: "Current game progress, claims, and achievement state."
        }

        ListElement {
            label: "Controller"
            icon: "input-gaming-symbolic"
            title: "INPUT"
            eyebrow: "Controller"
            summary: "Controller profile, PlayStation glyphs, rumble, and remaps."
        }

        ListElement {
            label: "Capture"
            icon: "camera-photo-symbolic"
            title: "CAPTURE"
            eyebrow: "Media"
            summary: "Screenshots, recordings, replay buffer, and clip sharing."
        }

        ListElement {
            label: "Downloads"
            icon: "folder-download-symbolic"
            title: "DOWNLOADS"
            eyebrow: "Forgepipe"
            summary: "Installs, updates, verification, and repair jobs."
        }

        ListElement {
            label: "Tools"
            icon: "applications-engineering-symbolic"
            title: "TOOLS"
            eyebrow: "Runtime"
            summary: "Logs, compatibility tools, manifests, and diagnostics."
        }

        ListElement {
            label: "Settings"
            icon: "preferences-system-symbolic"
            title: "SETTINGS"
            eyebrow: "System"
            summary: "Display, audio, network, notifications, and power."
        }
    }

    Process {
        id: achievementStatusProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let payload = text.trim();
                    if (payload.length > 0)
                        achievementStatus = JSON.parse(payload);
                } catch (e) {
                    console.log("Anvil achievement status parse error: " + e);
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#d904070a"
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#ef070b10"
            }
            GradientStop {
                position: 0.48
                color: "#ba111922"
            }
            GradientStop {
                position: 1
                color: "#fa040506"
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: "#291e252d"
        border.width: 1
    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: true
        Keys.onLeftPressed: selectedDockIndex = Math.max(0, selectedDockIndex - 1)
        Keys.onRightPressed: selectedDockIndex = Math.min(dockModel.count - 1, selectedDockIndex + 1)
        Keys.onReturnPressed: toggleModule(selectedDockIndex)
        Keys.onEscapePressed: runMenuAction("back")
    }

    Row {
        id: topBar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 22
        height: 44
        z: 20

        Column {
            width: 260
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: Qt.formatTime(new Date(), "h:mm AP")
                color: ink
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                text: Qt.formatDate(new Date(), "ddd, MMM d") + "  /  session overlay"
                color: muted
                font.pixelSize: 11
                font.bold: true
            }
        }

        Item {
            width: parent.width - 560
            height: parent.height

            Row {
                anchors.centerIn: parent
                spacing: 12

                Rectangle {
                    width: 34
                    height: 34
                    radius: 4
                    color: "#1a111820"
                    border.color: ember

                    Text {
                        anchors.centerIn: parent
                        text: "A"
                        color: ember
                        font.pixelSize: 17
                        font.bold: true
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ANVIL OVERLAY"
                    color: ink
                    font.pixelSize: 17
                    font.bold: true
                }
            }
        }

        Row {
            width: 480
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 226
                height: 34
                radius: 17
                color: "#9810161d"
                border.color: stroke

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 24
                        height: 16
                        source: controllerIcon()
                        sourceSize.width: 48
                        sourceSize.height: 32
                        opacity: source === "" ? 0 : 0.86
                    }

                    ButtonGlyph {
                        anchors.verticalCenter: parent.verticalCenter
                        action: "accept"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Toggle"
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

            OverlayButton {
                label: "Back"
                width: 104
                glyphAction: "back"
                onClicked: runMenuAction("back")
            }

            OverlayButton {
                label: "Exit Game"
                accent: true
                width: 126
                onClicked: runMenuAction("exit")
            }
        }
    }

    Rectangle {
        id: contentShell

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.bottom: dock.top
        anchors.leftMargin: 42
        anchors.rightMargin: 42
        anchors.topMargin: 30
        anchors.bottomMargin: 24
        color: "transparent"

        Row {
            anchors.fill: parent
            spacing: 18

            Rectangle {
                id: sessionCard

                width: Math.max(270, Math.min(330, overlayWindow.width * 0.18))
                height: parent.height
                radius: 8
                color: panel
                border.color: strokeSoft
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 3
                    color: ember
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 16

                    Column {
                        width: parent.width
                        spacing: 5

                        Text {
                            text: "NOW PLAYING"
                            color: gold
                            font.pixelSize: 11
                            font.bold: true
                        }

                        Text {
                            text: achievementStatus.game_name || "Current game"
                            color: ink
                            font.pixelSize: 25
                            font.bold: true
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            text: achievementStatus.service_state === "online" ? "Forgeworks connected" : "Forgeworks offline"
                            color: achievementStatus.service_state === "online" ? gold : muted
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: strokeSoft
                    }

                    Column {
                        width: parent.width
                        spacing: 10

                        StatRow {
                            name: "Achievements"
                            value: achievementStatus.claimed + " / " + achievementStatus.total
                        }

                        StatRow {
                            name: "Input"
                            value: controllerShortName()
                        }

                        StatRow {
                            name: "Runtime"
                            value: inputRuntimeLabel(achievementStatus.input_runtime_mode)
                        }

                        StatRow {
                            name: "Glyphs"
                            value: inputGlyphLabel(achievementStatus.input_glyph_mode)
                        }

                        StatRow {
                            name: "Overlay"
                            value: "Shift+Tab / " + glyph("guide")
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 84
                        radius: 6
                        color: "#85101822"
                        border.color: strokeSoft

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            Text {
                                text: selectedItem().title
                                color: ink
                                font.pixelSize: 15
                                font.bold: true
                            }

                            Text {
                                text: selectedItem().summary
                                color: muted
                                font.pixelSize: 11
                                width: parent.width
                                wrapMode: Text.WordWrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Math.max(1, parent.height - 500)
                    }

                    OverlayButton {
                        width: parent.width
                        label: "Return to Library"
                    }

                    OverlayButton {
                        width: parent.width
                        label: "Exit Game"
                        accent: true
                        onClicked: runMenuAction("exit")
                    }
                }
            }

            Rectangle {
                id: focusPanel

                width: parent.width - sessionCard.width - detailPanel.width - 36
                height: parent.height
                radius: 8
                color: panelDeep
                border.color: stroke
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 3
                    color: ember
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 18

                    Row {
                        width: parent.width
                        height: 66
                        spacing: 14

                        Rectangle {
                            width: 54
                            height: 54
                            radius: 6
                            color: "#161d25"
                            border.color: ember

                            Text {
                                anchors.centerIn: parent
                                text: selectedItem().icon
                                color: ember
                                font.pixelSize: selectedItem().icon.length > 1 ? 15 : 22
                                font.bold: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 180
                            spacing: 4

                            Text {
                                text: selectedItem().eyebrow
                                color: gold
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Text {
                                text: selectedItem().title
                                color: ink
                                font.pixelSize: 30
                                font.bold: true
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        OverlayButton {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 104
                            label: moduleVisible(selectedItem().label) ? "Hide" : "Show"
                            onClicked: toggleModule(selectedDockIndex)
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: strokeSoft
                    }

                    Loader {
                        width: parent.width
                        height: parent.height - 98
                        sourceComponent: selectedItem().label === "Achievements" ? achievementsComponent
                            : selectedItem().label === "Friends" ? friendsComponent
                            : selectedItem().label === "Controller" ? controllerComponent
                            : selectedItem().label === "Capture" ? captureComponent
                            : selectedItem().label === "Downloads" ? downloadsComponent
                            : selectedItem().label === "Tools" ? toolsComponent
                            : selectedItem().label === "Settings" ? settingsComponent
                            : homeComponent
                    }
                }
            }

            Rectangle {
                id: detailPanel

                width: Math.max(292, Math.min(360, overlayWindow.width * 0.2))
                height: parent.height
                radius: 8
                color: panel
                border.color: strokeSoft
                clip: true

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 14

                    Row {
                        width: parent.width
                        height: 34

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "LIVE MODULES"
                            color: ink
                            font.pixelSize: 14
                            font.bold: true
                            width: parent.width - 40
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "ON"
                            color: gold
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Repeater {
                        model: dockModel

                        Rectangle {
                            width: parent.width
                            height: 46
                            radius: 6
                            color: moduleVisible(model.label) ? "#781c2730" : "#5f0d1218"
                            border.color: selectedDockIndex === index ? ember : (moduleVisible(model.label) ? stroke : strokeSoft)

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 10

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 30
                                    height: 30
                                    radius: 4
                                    color: selectedDockIndex === index ? ember : "#151d25"

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.icon
                                        color: selectedDockIndex === index ? "#170805" : ink
                                        font.pixelSize: model.icon.length > 1 ? 10 : 14
                                        font.bold: true
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 92
                                    spacing: 1

                                    Text {
                                        text: model.label
                                        color: ink
                                        font.pixelSize: 12
                                        font.bold: true
                                    }

                                    Text {
                                        text: moduleVisible(model.label) ? "visible" : "hidden"
                                        color: muted
                                        font.pixelSize: 10
                                    }
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 9
                                    height: 9
                                    radius: 5
                                    color: moduleVisible(model.label) ? gold : dim
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    selectedDockIndex = index;
                                    keyCatcher.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        id: dock

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28
        spacing: 8
        z: 24

        Repeater {
            model: dockModel

            Rectangle {
                width: selectedDockIndex === index ? 82 : 48
                height: 46
                radius: 6
                color: selectedDockIndex === index ? ember : (moduleVisible(model.label) ? "#c51a2430" : "#a00d1218")
                border.color: selectedDockIndex === index ? ember : stroke
                border.width: selectedDockIndex === index ? 2 : 1

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        height: 20
                        source: Quickshell.iconPath(model.icon, true)
                        sourceSize.width: 40
                        sourceSize.height: 40
                        opacity: selectedDockIndex === index ? 1 : 0.78
                    }

                    Text {
                        visible: selectedDockIndex === index
                        text: model.label
                        color: "#190804"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selectedDockIndex = index;
                        keyCatcher.forceActiveFocus();
                    }
                    onDoubleClicked: toggleModule(index)
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }
    }

    Component {
        id: homeComponent

        Grid {
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            ModuleTile {
                title: "Library"
                body: "Return to Anvil library without ending the game."
                status: "Ready"
            }

            ModuleTile {
                title: "Forge Front"
                body: "Store, news, updates, and game pages."
                status: "Soon"
            }

            ModuleTile {
                title: "Runtime"
                body: "Supervised process, overlay hooks, and exit recovery."
                status: "Active"
            }

            ModuleTile {
                title: "Session"
                body: "Controller-first Wayland mode with mounted cartridges."
                status: "Anvil"
            }
        }
    }

    Component {
        id: achievementsComponent

        Column {
            spacing: 12

            Row {
                width: parent.width
                height: 70
                spacing: 14

                Rectangle {
                    width: 96
                    height: 64
                    radius: 8
                    color: "#141d24"
                    border.color: achievementStatus.service_state === "online" ? gold : stroke

                    Text {
                        anchors.centerIn: parent
                        text: achievementStatus.claimed + "/" + achievementStatus.total
                        color: achievementStatus.service_state === "online" ? gold : muted
                        font.pixelSize: 24
                        font.bold: true
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 226
                    spacing: 5

                    Text {
                        text: achievementStatus.set_name || "Achievements"
                        color: ink
                        font.pixelSize: 20
                        font.bold: true
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: (achievementStatus.game_name || "Current game") + " / " + (achievementStatus.service_state === "online" ? "Forgeworks online" : "Forgeworks offline")
                        color: muted
                        font.pixelSize: 12
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }

                OverlayButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 108
                    label: "Refresh"
                    onClicked: refreshAchievements()
                }
            }

            Repeater {
                model: (achievementStatus.achievements || []).slice(0, 6)

                Rectangle {
                    width: parent.width
                    height: 58
                    radius: 7
                    color: modelData.claimed ? "#901a2a22" : "#7010161e"
                    border.color: modelData.claimed ? gold : strokeSoft

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 18
                            color: modelData.claimed ? gold : "#151e26"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.claimed ? "A" : "-"
                                color: modelData.claimed ? "#160d04" : muted
                                font.pixelSize: 13
                                font.bold: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 98
                            spacing: 3

                            Text {
                                text: modelData.name || modelData.id
                                color: ink
                                font.pixelSize: 14
                                font.bold: true
                                width: parent.width
                                elide: Text.ElideRight
                            }

                            Text {
                                text: modelData.description || ""
                                color: muted
                                font.pixelSize: 11
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.points ? modelData.points + "P" : ""
                            color: modelData.claimed ? gold : muted
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    Component {
        id: friendsComponent

        Column {
            spacing: 12

            ModuleTile {
                title: "SALVATION"
                body: "Group chat / no active voice party"
                status: "Pinned"
            }

            ModuleTile {
                title: "Friends"
                body: "5 offline, 0 in party, invites ready"
                status: "Quiet"
            }

            ModuleTile {
                title: "Party"
                body: "Voice and lobby hooks belong here once Forgeworks social is live."
                status: "Soon"
            }
        }
    }

    Component {
        id: controllerComponent

        Column {
            spacing: 12

            Rectangle {
                width: parent.width
                height: 112
                radius: 8
                color: panelSoft
                border.color: strokeSoft

                Row {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 84
                        height: 68
                        radius: 8
                        color: "#111820"
                        border.color: stroke

                        Image {
                            anchors.centerIn: parent
                            width: 56
                            height: 36
                            source: controllerIcon()
                            sourceSize.width: 112
                            sourceSize.height: 72
                            opacity: source === "" ? 0 : 0.92
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: controllerIcon() === ""
                            text: "PAD"
                            color: muted
                            font.pixelSize: 14
                            font.bold: true
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 112
                        spacing: 6

                        Text {
                            text: controllerShortName()
                            color: ink
                            font.pixelSize: 22
                            font.bold: true
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Last input: " + inputActionLabel(controllerAction)
                            color: controllerAction === "" ? muted : gold
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Text {
                            text: inputRuntimeLabel(achievementStatus.input_runtime_mode) + " / " + inputGlyphLabel(achievementStatus.input_glyph_mode)
                            color: muted
                            font.pixelSize: 11
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Grid {
                width: parent.width
                columns: 4
                rowSpacing: 9
                columnSpacing: 9

                Repeater {
                    model: ["south", "east", "north", "west", "lt", "rt", "lb", "rb", "back", "start", "guide", "up", "down", "left", "right"]

                    Rectangle {
                        width: (parent.width - parent.columnSpacing * (parent.columns - 1)) / parent.columns
                        height: 46
                        radius: 6
                        color: controllerAction === modelData ? ember : "#121a22"
                        border.color: controllerAction === modelData ? gold : strokeSoft

                        Text {
                            anchors.centerIn: parent
                            text: modelData === "up" || modelData === "down" || modelData === "left" || modelData === "right" ? inputActionLabel(modelData) : ""
                            color: controllerAction === modelData ? "#190804" : ink
                            font.pixelSize: 11
                            font.bold: true
                            width: parent.width - 12
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
        }
    }

    Component {
        id: captureComponent

        Column {
            spacing: 12

            ModuleTile {
                title: "Screenshot"
                body: "Capture hooks are reserved for the Anvil runtime layer."
                status: "Soon"
            }

            ModuleTile {
                title: "Replay Buffer"
                body: "Local timeline markers and clipping can slot into this panel."
                status: "Off"
            }
        }
    }

    Component {
        id: downloadsComponent

        Column {
            spacing: 12

            ModuleTile {
                title: "Cartridge Scan"
                body: "Mounted media and local cartridge manifests feed Anvil Library."
                status: "Live"
            }

            ModuleTile {
                title: "Forgepipe"
                body: "Installs, verification, repair, and rollback move here."
                status: "Design"
            }
        }
    }

    Component {
        id: toolsComponent

        Column {
            spacing: 12

            ModuleTile {
                title: "Runtime Logs"
                body: "Game process, controller watcher, overlay watcher, and launch state."
                status: "Local"
            }

            ModuleTile {
                title: "Manifest"
                body: "Inspect cartridge metadata, Proton selection, input map, and achievements."
                status: "Ready"
            }
        }
    }

    Component {
        id: settingsComponent

        Column {
            spacing: 12

            ModuleTile {
                title: "Display"
                body: "Session compositor, scaling, refresh, HDR, and overscan."
                status: "Soon"
            }

            ModuleTile {
                title: "Network"
                body: "Forgeworks endpoint, Tailscale route, and offline behavior."
                status: achievementStatus.service_state
            }

            ModuleTile {
                title: "Notifications"
                body: "Achievements, friends, updates, and capture alerts."
                status: "Quiet"
            }
        }
    }

    component OverlayButton: Rectangle {
        id: buttonRoot

        signal clicked
        property string label: ""
        property string glyphAction: ""
        property bool accent: false

        height: 34
        radius: 6
        color: accent ? ember : "#b0141c24"
        border.color: accent ? ember : stroke

        Row {
            anchors.centerIn: parent
            spacing: 7

            ButtonGlyph {
                anchors.verticalCenter: parent.verticalCenter
                visible: glyphAction !== ""
                action: glyphAction
                active: accent
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: glyphAction !== "" ? Math.max(1, buttonRoot.width - 56) : Math.max(1, buttonRoot.width - 18)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: label
                color: accent ? "#190804" : ink
                font.pixelSize: 12
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.clicked()
        }
    }

    component ButtonGlyph: Rectangle {
        property string action: ""
        property bool active: false

        width: Math.max(24, glyphLabel.implicitWidth + 12)
        height: 24
        radius: 12
        color: active ? ember : "#151d25"
        border.color: active ? glyphColor(action) : stroke

        Text {
            id: glyphLabel

            anchors.centerIn: parent
            text: glyph(action)
            color: active ? "#190804" : glyphColor(action)
            font.pixelSize: text.length > 2 ? 9 : 14
            font.bold: true
        }
    }

    component StatRow: Row {
        property string name: ""
        property string value: ""

        width: parent.width
        height: 22

        Text {
            text: name
            color: muted
            font.pixelSize: 12
            width: parent.width * 0.48
            elide: Text.ElideRight
        }

        Text {
            text: value
            color: ink
            font.pixelSize: 12
            font.bold: true
            width: parent.width * 0.52
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    component ModuleTile: Rectangle {
        property string title: ""
        property string body: ""
        property string status: ""

        width: parent ? parent.width : 360
        height: 86
        radius: 7
        color: panelSoft
        border.color: strokeSoft

        Row {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 10
                height: parent.height - 10
                radius: 5
                color: ember
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 114
                spacing: 5

                Text {
                    text: title
                    color: ink
                    font.pixelSize: 15
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: body
                    color: muted
                    font.pixelSize: 12
                    width: parent.width
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 72
                height: 28
                radius: 14
                color: "#121a22"
                border.color: stroke

                Text {
                    anchors.centerIn: parent
                    text: status
                    color: gold
                    font.pixelSize: 10
                    font.bold: true
                    elide: Text.ElideRight
                    width: parent.width - 10
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
