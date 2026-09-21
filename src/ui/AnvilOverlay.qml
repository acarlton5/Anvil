import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: overlayWindow

    property var modelData: null
    readonly property color ink: "#f4f8ff"
    readonly property color muted: "#b4aaa3"
    readonly property color panel: "#201b18"
    readonly property color stroke: "#4a3329"
    readonly property color accent: "#ff6537"
    readonly property color ember: "#ff6537"
    readonly property color emberLight: "#ff9a73"
    readonly property color forgeGold: "#d9ad5f"
    property int selectedDockIndex: 9

    function runMenuAction(action) {
        if (action === "Back to Game" || action === "Resume Game")
            root.overlayActive = false;
        else if (action === "Exit Game")
            root.killGame();
    }

    function activeDock() {
        return dockModel.get(Math.max(0, Math.min(selectedDockIndex, dockModel.count - 1)));
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
        friendsPanel.x = (overlayWindow.width - friendsPanel.width) / 2;
        friendsPanel.y = Math.max(118, overlayWindow.height * 0.12);
        forgePulse.x = overlayWindow.width - forgePulse.width - 76;
        forgePulse.y = Math.max(132, overlayWindow.height * 0.18);
        cartridgeWidget.x = 36;
        cartridgeWidget.y = Math.max(154, overlayWindow.height * 0.22);
        sessionWidget.x = overlayWindow.width - sessionWidget.width - 90;
        sessionWidget.y = Math.max(368, overlayWindow.height * 0.48);
        friendsPanel.forceActiveFocus();
    }

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
        }

        ListElement {
            icon: "⚙"
            label: "Settings"
            title: "FORGE SETTINGS"
            hint: "Audio, display, notifications, and overlay temper."
            line1: "Performance mode: on"
            line2: "Overlay heat: 82%"
            line3: "Alerts: friends and invites"
        }

        ListElement {
            icon: "✎"
            label: "Notes"
            title: "FORGE NOTES"
            hint: "Scratchpad, guide notes, and per-cartridge reminders."
            line1: "Pin runtime notes beside the game"
            line2: "Add launch options and Proton notes"
            line3: "Sync notes through Anvil Cloud later"
        }

        ListElement {
            icon: "◷"
            label: "Timer"
            title: "SESSION TIMER"
            hint: "Playtime, break reminders, and family limits."
            line1: "This session: 6 minutes"
            line2: "Today: 42 minutes"
            line3: "Break reminder: disabled"
        }

        ListElement {
            icon: "▤"
            label: "News"
            title: "ANVIL NEWS"
            hint: "Patch notes, events, updates, and Forge posts."
            line1: "Anvil overlay mock updated"
            line2: "Forgeworks naming pass complete"
            line3: "Cartridge scan detects 49 games"
        }

        ListElement {
            icon: "▣"
            label: "Chat"
            title: "ANVIL CHAT"
            hint: "Messages, party voice, invites, and group chats."
            line1: "SALVATION / group chat"
            line2: "Mira: browsing Forge Front"
            line3: "Jordan: in Anvil Session"
        }

        ListElement {
            icon: "↓"
            label: "Download"
            title: "FORGEPIPE"
            hint: "Installs, updates, verification, repair, and rollback."
            line1: "Cartridge scan: live"
            line2: "Client update: mock queue"
            line3: "Forgepipe install: design"
        }

        ListElement {
            icon: "🔧"
            label: "Tools"
            title: "RUNTIME TOOLS"
            hint: "Logs, compatibility, repair, and developer test helpers."
            line1: "Open game logs"
            line2: "Verify cartridge manifest"
            line3: "Restart Anvil Runtime"
        }

        ListElement {
            icon: "▧"
            label: "Pictures"
            title: "ANVIL CAPTURE"
            hint: "Screenshots, clips, capture gallery, and sharing."
            line1: "Screenshots: 0 this session"
            line2: "Last clip: none"
            line3: "Storage: local preview"
        }

        ListElement {
            icon: "👥"
            label: "Friends"
            title: "ANVIL FRIENDS"
            hint: "Friends, chats, parties, invites, and pinned groups."
            line1: "+Offline [5]"
            line2: "SALVATION / group chat"
            line3: "No active party"
        }

        ListElement {
            icon: "◆"
            label: "Anvil"
            title: "ANVIL"
            hint: "Launcher, store, library, session, and overlay controls."
            line1: "Return to library"
            line2: "Open Forge Front"
            line3: "Switch to desktop"
        }

        ListElement {
            icon: "🎮"
            label: "Controller"
            title: "ANVIL INPUT"
            hint: "Input profiles, glyphs, rumble, and layout switching."
            line1: "Profile: Gamepad default"
            line2: "Rumble: enabled"
            line3: "Gyro: not configured"
        }

        ListElement {
            icon: "◎"
            label: "Web"
            title: "WEB"
            hint: "Guides, store pages, patch notes, and browser tabs."
            line1: "Guide overlay: mock"
            line2: "Store page: available"
            line3: "External browser: disabled"
        }

        ListElement {
            icon: "●"
            label: "Capture"
            title: "CAPTURE"
            hint: "Screenshot, replay buffer, recording, and timeline markers."
            line1: "Replay buffer: off"
            line2: "Screenshot hotkey: ready"
            line3: "Recording: stopped"
        }

        ListElement {
            icon: "⚙"
            label: "System"
            title: "SESSION SYSTEM"
            hint: "Power, network, display, Bluetooth, and session status."
            line1: "Mode: Anvil Session"
            line2: "Network: Tailscale online"
            line3: "Power profile: performance"
        }

        ListElement {
            icon: "⌄"
            label: "More"
            title: "MORE"
            hint: "Additional modules and future overlay extensions."
            line1: "Workshop"
            line2: "Broadcast"
            line3: "Forgeworks diagnostics"
        }

    }

    Rectangle {
        anchors.fill: parent
        color: "#bc050403"
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#da130806"
            }

            GradientStop {
                position: 0.48
                color: "#8f130d0a"
            }

            GradientStop {
                position: 1
                color: "#e0040303"
            }

        }

    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 250
        color: "#55110806"
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.top: parent.top
        anchors.topMargin: 14
        spacing: 6
        z: 10

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
            color: "#332119"
            border.color: "#6b3b27"

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
        z: 10

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
            color: "#332119"
            border.color: "#6b3b27"

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
        color: "#22140e"
        border.color: ember
        z: 8

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

    Rectangle {
        id: cartridgeWidget

        width: 238
        height: 126
        radius: 4
        color: "#d016100d"
        border.color: "#583324"
        z: 11

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            color: ember
        }

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 7

            Text {
                text: "CARTRIDGE"
                color: forgeGold
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                text: "Local Library"
                color: ink
                font.pixelSize: 20
                font.bold: true
            }

            Text {
                text: "49 games indexed / removable media ready"
                color: muted
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                width: parent.width
            }

        }

        MouseArea {
            anchors.fill: parent
            drag.target: cartridgeWidget
            onPressed: cartridgeWidget.z = 20
            onReleased: cartridgeWidget.z = 11
        }

    }

    Rectangle {
        id: forgePulse

        width: 258
        height: 148
        radius: 4
        color: "#d018120f"
        border.color: "#68402d"
        z: 11

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 9

            Text {
                text: "FORGE PULSE"
                color: forgeGold
                font.pixelSize: 11
                font.bold: true
            }

            Row {
                spacing: 8

                Repeater {
                    model: [0.86, 0.68, 0.74, 0.52, 0.91, 0.61]

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: 18
                        height: 74 * modelData
                        radius: 2
                        color: index === 4 ? ember : "#7a4934"
                    }

                }

            }

            Text {
                text: "Runtime stable / overlay widgets unlocked"
                color: muted
                font.pixelSize: 12
                width: parent.width
                elide: Text.ElideRight
            }

        }

        MouseArea {
            anchors.fill: parent
            drag.target: forgePulse
            onPressed: forgePulse.z = 20
            onReleased: forgePulse.z = 11
        }

    }

    Rectangle {
        id: sessionWidget

        width: 260
        height: 132
        radius: 4
        color: "#d015100c"
        border.color: "#5d3929"
        z: 11

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8

            Text {
                text: "SESSION"
                color: forgeGold
                font.pixelSize: 11
                font.bold: true
            }

            Text {
                text: "Anvil Runtime"
                color: ink
                font.pixelSize: 20
                font.bold: true
            }

            Text {
                text: "Proton Experimental / overlay test mode / Shift+Tab ready"
                color: muted
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                width: parent.width
            }

        }

        MouseArea {
            anchors.fill: parent
            drag.target: sessionWidget
            onPressed: sessionWidget.z = 20
            onReleased: sessionWidget.z = 11
        }

    }

    Rectangle {
        id: friendsPanel

        width: 306
        height: Math.min(635, parent.height - 220)
        radius: 2
        color: panel
        border.color: "#1a0e0a"
        z: 12
        clip: true
        focus: true
        Keys.onLeftPressed: selectedDockIndex = Math.max(0, selectedDockIndex - 1)
        Keys.onRightPressed: selectedDockIndex = Math.min(dockModel.count - 1, selectedDockIndex + 1)
        Keys.onEscapePressed: runMenuAction("Back to Game")
        Keys.onReturnPressed: runMenuAction("Back to Game")

        Column {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                width: parent.width
                height: 3
                color: ember
            }

            Rectangle {
                width: parent.width
                height: 73
                color: "#34241c"

                MouseArea {
                    anchors.fill: parent
                    drag.target: friendsPanel
                    onPressed: friendsPanel.z = 20
                    onReleased: {
                        friendsPanel.z = 12;
                        friendsPanel.forceActiveFocus();
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 10

                    Rectangle {
                        width: 54
                        height: 54
                        radius: 3
                        color: "#4a3124"
                        border.color: "#8f5134"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 2
                            color: ember
                            opacity: 0.55
                        }

                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 96
                        spacing: 5

                        Rectangle {
                            width: parent.width
                            height: 16
                            radius: 2
                            color: accent
                            opacity: 0.32
                        }

                        Text {
                            text: activeDock().label
                            color: forgeGold
                            font.pixelSize: 11
                            font.bold: true
                        }

                    }

                    Text {
                        text: "v  X"
                        color: "#c4ccd5"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: "DRAG"
                        color: "#8a776b"
                        font.pixelSize: 9
                        font.bold: true
                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 43
                color: "#251b16"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 3
                    color: forgeGold
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 3

                    Text {
                        text: activeDock().hint
                        color: emberLight
                        font.pixelSize: 10
                        width: parent.width - 62
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 54
                        height: 16
                        radius: 2
                        color: "#7d3d25"

                        Text {
                            anchors.centerIn: parent
                            text: "GOT IT!"
                            color: ink
                            font.pixelSize: 9
                            font.bold: true
                        }

                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 27
                color: "#6b4a38"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: activeDock().title
                        color: ink
                        font.pixelSize: 11
                        font.bold: true
                        width: parent.width - 88
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Q"
                        color: "#d8e0ea"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                        color: "#d8e0ea"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "*"
                        color: "#d8e0ea"
                        font.pixelSize: 14
                        font.bold: true
                    }

                }

            }

            Rectangle {
                width: parent.width
                height: friendsPanel.height - 238
                color: "#191411"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.top: parent.top
                    anchors.topMargin: 14
                    text: activeDock().line1
                    color: "#c4cad2"
                    font.pixelSize: 11
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.top: parent.top
                    anchors.topMargin: 42
                    text: activeDock().line2
                    color: "#d6dbe2"
                    font.pixelSize: 12
                    font.bold: selectedDockIndex === 9
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.top: parent.top
                    anchors.topMargin: 70
                    text: activeDock().line3
                    color: muted
                    font.pixelSize: 11
                }

            }

            Rectangle {
                width: parent.width
                height: 34
                color: "#5a3e30"

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "v " + activeDock().label.toUpperCase()
                        color: "#dbe2ea"
                        font.pixelSize: 11
                        font.bold: true
                        width: parent.width - 28
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+"
                        color: "#dbe2ea"
                        font.pixelSize: 18
                        font.bold: true
                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 58
                color: "#241a15"

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 9

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: "#1a100d"
                        border.color: ember

                        Text {
                            anchors.centerIn: parent
                            text: activeDock().icon
                            color: emberLight
                            font.pixelSize: activeDock().icon.length > 1 ? 11 : 16
                            font.bold: true
                        }

                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: activeDock().line2
                        color: "#d8dee7"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: parent.width - 48
                    }

                }

            }

        }

    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: dock.top
        anchors.bottomMargin: 10
        text: activeDock().label
        color: forgeGold
        opacity: 0.86
        font.pixelSize: 12
        font.bold: true
        z: 12
    }

    Row {
        id: dock

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30
        spacing: 6
        z: 12

        Repeater {
            model: dockModel

            Rectangle {
                width: model.icon.length > 1 ? 44 : 38
                height: 38
                radius: 2
                color: selectedDockIndex === index ? ember : "#2a211d"
                border.color: selectedDockIndex === index ? emberLight : "#5b392a"
                scale: selectedDockIndex === index ? 1.08 : 1

                Text {
                    anchors.centerIn: parent
                    text: model.icon
                    color: selectedDockIndex === index ? "#1b0903" : "#dccbc1"
                    font.pixelSize: model.icon.length > 1 ? 10 : 16
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selectedDockIndex = index;
                        friendsPanel.forceActiveFocus();
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
