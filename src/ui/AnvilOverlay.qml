import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: overlayWindow

    property var modelData: null
    property var closeHandler: null
    property var killHandler: null
    readonly property color ink: "#f4f8ff"
    readonly property color muted: "#aeb6bd"
    readonly property color panel: "#111820"
    readonly property color panelDeep: "#080c11"
    readonly property color stroke: "#2f3a45"
    readonly property color ember: "#ff6537"
    readonly property color emberLight: "#ff9a73"
    readonly property color forgeGold: "#d9ad5f"
    property int selectedDockIndex: 9
    property var openModules: ({
        "Friends": true,
        "Anvil": true,
        "Capture": false,
        "Controller": false
    })

    function activeDock() {
        return dockModel.get(Math.max(0, Math.min(selectedDockIndex, dockModel.count - 1)));
    }

    function moduleVisible(label) {
        return !!openModules[label];
    }

    function setModuleVisible(label, visible) {
        let next = Object.assign({
        }, openModules);
        next[label] = visible;
        openModules = next;
    }

    function toggleModule(index) {
        let item = dockModel.get(index);
        selectedDockIndex = index;
        setModuleVisible(item.label, !moduleVisible(item.label));
    }

    function runMenuAction(action) {
        if (action === "Back to Game" || action === "Resume Game") {
            if (closeHandler)
                closeHandler();

        } else if (action === "Exit Game") {
            if (killHandler)
                killHandler();

        }
    }

    color: "transparent"
    screen: modelData
    implicitWidth: 1920
    implicitHeight: 1080
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "anvil-overlay"
    Component.onCompleted: keyCatcher.forceActiveFocus()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    ListModel {
        id: dockModel

        ListElement {
            icon: "ⓘ"
            label: "Info"
            title: "ANVIL SESSION"
            hint: "Session, runtime, network, and cartridge state."
            line1: "Anvil Session / overlay test"
            line2: "Current game: local cartridge preview"
            line3: "Relay: Constellation path mock"
            x0: 330
            y0: 120
            wide: false
        }

        ListElement {
            icon: "⚙"
            label: "Settings"
            title: "FORGE SETTINGS"
            hint: "Audio, display, notifications, and overlay temper."
            line1: "Performance mode: on"
            line2: "Overlay heat: 82%"
            line3: "Alerts: friends and invites"
            x0: 1100
            y0: 146
            wide: false
        }

        ListElement {
            icon: "✎"
            label: "Notes"
            title: "FORGE NOTES"
            hint: "Scratchpad, guide notes, and per-cartridge reminders."
            line1: "Pin runtime notes beside the game"
            line2: "Add launch options and Proton notes"
            line3: "Sync notes through Anvil Cloud later"
            x0: 420
            y0: 470
            wide: false
        }

        ListElement {
            icon: "◷"
            label: "Timer"
            title: "SESSION TIMER"
            hint: "Playtime, break reminders, and family limits."
            line1: "This session: 6 minutes"
            line2: "Today: 42 minutes"
            line3: "Break reminder: disabled"
            x0: 46
            y0: 426
            wide: false
        }

        ListElement {
            icon: "▤"
            label: "News"
            title: "ANVIL NEWS"
            hint: "Patch notes, events, updates, and Forge posts."
            line1: "Anvil overlay mock updated"
            line2: "Forgeworks naming pass complete"
            line3: "Cartridge scan detects 49 games"
            x0: 708
            y0: 430
            wide: true
        }

        ListElement {
            icon: "▣"
            label: "Chat"
            title: "ANVIL CHAT"
            hint: "Messages, party voice, invites, and group chats."
            line1: "SALVATION / group chat"
            line2: "Mira: browsing Forge Front"
            line3: "Jordan: in Anvil Session"
            x0: 1220
            y0: 366
            wide: false
        }

        ListElement {
            icon: "↓"
            label: "Download"
            title: "FORGEPIPE"
            hint: "Installs, updates, verification, repair, and rollback."
            line1: "Cartridge scan: live"
            line2: "Client update: mock queue"
            line3: "Forgepipe install: design"
            x0: 44
            y0: 160
            wide: false
        }

        ListElement {
            icon: "⌘"
            label: "Tools"
            title: "RUNTIME TOOLS"
            hint: "Logs, compatibility, repair, and developer test helpers."
            line1: "Open game logs"
            line2: "Verify cartridge manifest"
            line3: "Restart Anvil Runtime"
            x0: 1130
            y0: 520
            wide: false
        }

        ListElement {
            icon: "▧"
            label: "Pictures"
            title: "ANVIL MEDIA"
            hint: "Screenshots, clips, capture gallery, and sharing."
            line1: "Screenshots: 0 this session"
            line2: "Last clip: none"
            line3: "Storage: local preview"
            x0: 790
            y0: 118
            wide: false
        }

        ListElement {
            icon: "◉"
            label: "Friends"
            title: "ANVIL FRIENDS"
            hint: "Friends, chats, parties, invites, and pinned groups."
            line1: "+Offline [5]"
            line2: "SALVATION / group chat"
            line3: "No active party"
            x0: 548
            y0: 128
            wide: false
        }

        ListElement {
            icon: "◆"
            label: "Anvil"
            title: "ANVIL QUICK BAR"
            hint: "Launcher, store, library, session, and overlay controls."
            line1: "Return to library"
            line2: "Open Forge Front"
            line3: "Switch to desktop"
            x0: 646
            y0: 312
            wide: true
        }

        ListElement {
            icon: "◇"
            label: "Controller"
            title: "ANVIL INPUT"
            hint: "Input profiles, glyphs, rumble, and layout switching."
            line1: "Profile: Gamepad default"
            line2: "Rumble: enabled"
            line3: "Gyro: not configured"
            x0: 1010
            y0: 300
            wide: false
        }

        ListElement {
            icon: "◎"
            label: "Web"
            title: "WEB"
            hint: "Guides, store pages, patch notes, and browser tabs."
            line1: "Guide overlay: mock"
            line2: "Store page: available"
            line3: "External browser: disabled"
            x0: 410
            y0: 250
            wide: false
        }

        ListElement {
            icon: "●"
            label: "Capture"
            title: "ANVIL CAPTURE"
            hint: "Screenshot, replay buffer, recording, and timeline markers."
            line1: "Replay buffer: off"
            line2: "Screenshot hotkey: ready"
            line3: "Recording: stopped"
            x0: 1260
            y0: 166
            wide: false
        }

        ListElement {
            icon: "⚙"
            label: "System"
            title: "SESSION SYSTEM"
            hint: "Power, network, display, Bluetooth, and session status."
            line1: "Mode: Anvil Session"
            line2: "Network: Tailscale online"
            line3: "Power profile: performance"
            x0: 68
            y0: 300
            wide: false
        }

        ListElement {
            icon: "⌄"
            label: "More"
            title: "MORE"
            hint: "Additional modules and future overlay extensions."
            line1: "Workshop"
            line2: "Broadcast"
            line3: "Forgeworks diagnostics"
            x0: 780
            y0: 548
            wide: false
        }

    }

    Rectangle {
        anchors.fill: parent
        color: "#c5050609"
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#d60b1016"
            }

            GradientStop {
                position: 0.48
                color: "#90111720"
            }

            GradientStop {
                position: 1
                color: "#ea050609"
            }

        }

    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: true
        Keys.onLeftPressed: selectedDockIndex = Math.max(0, selectedDockIndex - 1)
        Keys.onRightPressed: selectedDockIndex = Math.min(dockModel.count - 1, selectedDockIndex + 1)
        Keys.onReturnPressed: toggleModule(selectedDockIndex)
        Keys.onEscapePressed: runMenuAction("Back to Game")
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.top: parent.top
        anchors.topMargin: 14
        spacing: 6
        z: 30

        Text {
            text: Qt.formatTime(new Date(), "h:mm AP")
            color: ink
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            text: Qt.formatDate(new Date(), "ddd, MMM d")
            color: muted
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            text: "6 minutes - this session"
            color: muted
            font.pixelSize: 11
        }

        Rectangle {
            width: 86
            height: 26
            radius: 2
            color: "#17212a"
            border.color: stroke

            Text {
                anchors.centerIn: parent
                text: "EXIT GAME"
                color: "#d8dee7"
                font.pixelSize: 10
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: runMenuAction("Exit Game")
            }

        }

    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 14
        spacing: 10
        z: 30

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                anchors.right: parent.right
                text: "Back to Game"
                color: ink
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                text: "(Shift+Tab)"
                color: muted
                font.pixelSize: 10
                font.bold: true
            }

        }

        Rectangle {
            width: 38
            height: 38
            radius: 2
            color: "#17212a"
            border.color: stroke

            Text {
                anchors.centerIn: parent
                text: "X"
                color: ink
                font.pixelSize: 18
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: runMenuAction("Back to Game")
            }

        }

    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 34
        width: 148
        height: 50
        radius: 6
        color: "#121820"
        border.color: ember
        z: 22

        Row {
            anchors.centerIn: parent
            spacing: 9

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "◆"
                color: emberLight
                font.pixelSize: 24
                font.bold: true
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "ANVIL"
                color: ink
                font.pixelSize: 22
                font.bold: true
            }

        }

    }

    Repeater {
        id: moduleRepeater

        model: dockModel

        Rectangle {
            id: moduleWidget

            x: Math.min(model.x0, overlayWindow.width - width - 28)
            y: Math.min(model.y0, overlayWindow.height - height - 86)
            width: model.wide ? 430 : 306
            height: model.wide ? 178 : 252
            radius: 4
            color: panel
            border.color: selectedDockIndex === index ? ember : stroke
            visible: moduleVisible(model.label)
            z: selectedDockIndex === index ? 18 : 12
            clip: true

            Rectangle {
                width: parent.width
                height: 3
                color: ember
            }

            Rectangle {
                id: moduleHeader

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 3
                height: 48
                color: "#18212a"

                MouseArea {
                    anchors.fill: parent
                    drag.target: moduleWidget
                    onPressed: {
                        selectedDockIndex = index;
                        moduleWidget.z = 24;
                        keyCatcher.forceActiveFocus();
                    }
                    onReleased: moduleWidget.z = selectedDockIndex === index ? 18 : 12
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        radius: 3
                        color: "#0d131a"
                        border.color: ember

                        Text {
                            anchors.centerIn: parent
                            text: model.icon
                            color: emberLight
                            font.pixelSize: model.icon.length > 1 ? 10 : 15
                            font.bold: true
                        }

                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.title
                        color: ink
                        font.pixelSize: 12
                        font.bold: true
                        width: parent.width - 88
                        elide: Text.ElideRight
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "X"
                        color: muted
                        font.pixelSize: 13
                        font.bold: true

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            onClicked: setModuleVisible(model.label, false)
                        }

                    }

                }

            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: moduleHeader.bottom
                height: 38
                color: "#101820"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    color: forgeGold
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.hint
                    color: emberLight
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: moduleHeader.bottom
                anchors.topMargin: 50
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: model.line1
                    color: "#d8dee7"
                    font.pixelSize: 12
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: model.line2
                    color: ink
                    font.pixelSize: model.wide ? 18 : 15
                    font.bold: true
                    width: parent.width
                    elide: Text.ElideRight
                }

                Text {
                    text: model.line3
                    color: muted
                    font.pixelSize: 12
                    width: parent.width
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: "#27313a"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (0.34 + ((index % 6) * 0.1))
                        radius: 3
                        color: index === selectedDockIndex ? ember : forgeGold
                    }

                }

            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onPressed: selectedDockIndex = index
            }

        }

    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: dock.top
        anchors.bottomMargin: 10
        text: activeDock().label + (moduleVisible(activeDock().label) ? " shown" : " hidden")
        color: forgeGold
        opacity: 0.86
        font.pixelSize: 12
        font.bold: true
        z: 24
    }

    Row {
        id: dock

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        spacing: 6
        z: 24

        Repeater {
            model: dockModel

            Rectangle {
                width: model.icon.length > 1 ? 44 : 38
                height: 38
                radius: 2
                color: moduleVisible(model.label) ? ember : "#17212a"
                border.color: selectedDockIndex === index ? emberLight : stroke
                border.width: selectedDockIndex === index ? 2 : 1
                scale: selectedDockIndex === index ? 1.08 : 1

                Text {
                    anchors.centerIn: parent
                    text: model.icon
                    color: moduleVisible(model.label) ? "#1b0903" : "#dccbc1"
                    font.pixelSize: model.icon.length > 1 ? 10 : 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        toggleModule(index);
                        keyCatcher.forceActiveFocus();
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 120
                    }

                }

            }

        }

    }

}
