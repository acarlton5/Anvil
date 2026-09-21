import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: overlayWindow

    property var modelData: null
    readonly property color ink: "#f4f8ff"
    readonly property color muted: "#a7b0bd"
    readonly property color panel: "#20242c"
    readonly property color stroke: "#384350"
    readonly property color accent: "#24a7ff"
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
    Component.onCompleted: friendsPanel.forceActiveFocus()

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
            title: "SESSION INFO"
            hint: "Runtime, network, and active game state."
            line1: "Anvil Session / overlay test"
            line2: "Current game: local cartridge preview"
            line3: "Network: Constellation relay mock"
        }

        ListElement {
            icon: "⚙"
            label: "Settings"
            title: "QUICK SETTINGS"
            hint: "Audio, display, notifications, and overlay behavior."
            line1: "Performance mode: on"
            line2: "Overlay opacity: 82%"
            line3: "Notifications: friends and invites"
        }

        ListElement {
            icon: "✎"
            label: "Notes"
            title: "NOTES"
            hint: "Scratchpad, guide notes, and per-game reminders."
            line1: "Pin build notes beside the game"
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
            title: "NEWS"
            hint: "Patch notes, events, updates, and developer posts."
            line1: "Anvil overlay mock updated"
            line2: "Forgeworks naming pass complete"
            line3: "Cartridge scan detects 49 games"
        }

        ListElement {
            icon: "▣"
            label: "Chat"
            title: "CHAT"
            hint: "Messages, party voice, invites, and group chats."
            line1: "SALVATION / group chat"
            line2: "Mira: browsing Forge Front"
            line3: "Jordan: in Anvil Session"
        }

        ListElement {
            icon: "↓"
            label: "Download"
            title: "DOWNLOADS"
            hint: "Installs, updates, verification, repair, and rollback."
            line1: "Cartridge scan: live"
            line2: "Client update: mock queue"
            line3: "Forgepipe install: design"
        }

        ListElement {
            icon: "🔧"
            label: "Tools"
            title: "TOOLS"
            hint: "Logs, compatibility, repair, and developer test helpers."
            line1: "Open game logs"
            line2: "Verify cartridge manifest"
            line3: "Restart Anvil Runtime"
        }

        ListElement {
            icon: "▧"
            label: "Pictures"
            title: "MEDIA"
            hint: "Screenshots, clips, capture gallery, and sharing."
            line1: "Screenshots: 0 this session"
            line2: "Last clip: none"
            line3: "Storage: local preview"
        }

        ListElement {
            icon: "👥"
            label: "Friends"
            title: "FRIENDS"
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
            title: "CONTROLLER"
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
            title: "SYSTEM"
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
        color: "#b805070b"
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#d006080d"
            }

            GradientStop {
                position: 0.48
                color: "#99080c12"
            }

            GradientStop {
                position: 1
                color: "#e005070b"
            }

        }

    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 250
        color: "#55070a0f"
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
            color: "#27313d"
            border.color: "#3b4653"

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
            color: "#303642"
            border.color: "#46515f"

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

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 38
        text: "ANVIL"
        color: "#dde8f5"
        opacity: 0.9
        font.pixelSize: 32
        font.bold: true
        z: 8
    }

    Rectangle {
        id: friendsPanel

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Math.max(118, parent.height * 0.12)
        width: 306
        height: Math.min(635, parent.height - 220)
        radius: 2
        color: panel
        border.color: "#11151b"
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
                height: 76
                color: "#303843"

                Row {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 10

                    Rectangle {
                        width: 54
                        height: 54
                        radius: 3
                        color: "#48535f"
                        border.color: "#6b7785"

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 2
                            color: "#6d8e77"
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
                            color: "#83d48a"
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

                }

            }

            Rectangle {
                width: parent.width
                height: 43
                color: "#252b34"

                Column {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 3

                    Text {
                        text: activeDock().hint
                        color: "#20bfea"
                        font.pixelSize: 10
                        width: parent.width - 62
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        anchors.right: parent.right
                        width: 54
                        height: 16
                        radius: 2
                        color: "#179bc0"

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
                color: "#616a75"

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
                color: "#1d2028"

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
                color: "#5b6570"

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
                color: "#252d37"

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 9

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        color: "#202b38"
                        border.color: "#7c49ff"

                        Text {
                            anchors.centerIn: parent
                            text: activeDock().icon
                            color: "#9e75ff"
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
        color: "#dce8f5"
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
                color: selectedDockIndex === index ? accent : "#27313d"
                border.color: selectedDockIndex === index ? "#45bdff" : "#3c4652"
                scale: selectedDockIndex === index ? 1.08 : 1

                Text {
                    anchors.centerIn: parent
                    text: model.icon
                    color: selectedDockIndex === index ? "#eef8ff" : "#d4dbe4"
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
