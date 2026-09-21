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

    function runMenuAction(action) {
        if (action === "Back to Game" || action === "Resume Game")
            root.overlayActive = false;
        else if (action === "Exit Game")
            root.killGame();
    }

    color: "transparent"
    screen: modelData
    implicitWidth: 1920
    implicitHeight: 1080
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "anvil-overlay"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    ListModel {
        id: dockModel

        ListElement {
            icon: "i"
            label: "Info"
            active: false
        }

        ListElement {
            icon: "*"
            label: "Settings"
            active: false
        }

        ListElement {
            icon: "/"
            label: "Notes"
            active: false
        }

        ListElement {
            icon: "T"
            label: "Timer"
            active: false
        }

        ListElement {
            icon: "N"
            label: "News"
            active: false
        }

        ListElement {
            icon: "C"
            label: "Chat"
            active: false
        }

        ListElement {
            icon: "D"
            label: "Download"
            active: false
        }

        ListElement {
            icon: "W"
            label: "Tools"
            active: false
        }

        ListElement {
            icon: "P"
            label: "Pictures"
            active: false
        }

        ListElement {
            icon: "F"
            label: "Friends"
            active: true
        }

        ListElement {
            icon: "A"
            label: "Anvil"
            active: true
        }

        ListElement {
            icon: "G"
            label: "Controller"
            active: false
        }

        ListElement {
            icon: "O"
            label: "Web"
            active: false
        }

        ListElement {
            icon: "REC"
            label: "Capture"
            active: false
        }

        ListElement {
            icon: "S"
            label: "System"
            active: false
        }

        ListElement {
            icon: "v"
            label: "More"
            active: false
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
                            color: "#6e7b72"
                            opacity: 0.45
                        }

                        Text {
                            text: "Online"
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
                        text: "Drag Friends & Chats here for easy access"
                        color: "#20bfea"
                        font.pixelSize: 10
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
                        text: "FRIENDS"
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
                    text: "+Offline [5]"
                    color: "#c4cad2"
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
                        text: "v GROUP CHATS"
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
                            text: "A"
                            color: "#9e75ff"
                            font.pixelSize: 16
                            font.bold: true
                        }

                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SALVATION"
                        color: "#d8dee7"
                        font.pixelSize: 13
                    }

                }

            }

        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            focus: true
            Keys.onEscapePressed: runMenuAction("Back to Game")
            Keys.onReturnPressed: runMenuAction("Back to Game")
        }

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
                width: model.icon === "REC" ? 44 : 36
                height: 36
                radius: 2
                color: model.active ? accent : "#27313d"
                border.color: model.active ? "#45bdff" : "#3c4652"

                Text {
                    anchors.centerIn: parent
                    text: model.icon
                    color: model.active ? "#eef8ff" : "#d4dbe4"
                    font.pixelSize: model.icon === "REC" ? 10 : 14
                    font.bold: true
                }

            }

        }

    }

}
