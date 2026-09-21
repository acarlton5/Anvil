import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: overlayWindow

    property var modelData: null
    readonly property color ink: "#f4f8ff"
    readonly property color muted: "#9aa7b7"
    readonly property color quiet: "#667487"
    readonly property color panel: "#141a23"
    readonly property color panel2: "#1d2531"
    readonly property color stroke: "#2e3948"
    readonly property color accent: "#23d5e8"

    function runMenuAction(action) {
        if (action === "Resume Game") {
            root.overlayActive = false;
        } else if (action === "Exit Game") {
            root.overlayActive = false;
            killGameProcess.running = true;
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

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Rectangle {
        anchors.fill: parent
        color: "#b005070b"
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#ee080b10"
            }

            GradientStop {
                position: 0.5
                color: "#aa080b10"
            }

            GradientStop {
                position: 1
                color: "#f0080b10"
            }

        }

    }

    Rectangle {
        id: leftPanel

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 380
        color: "#f00d1118"
        border.color: stroke

        Column {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 18

            Row {
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    radius: 8
                    color: "#111821"
                    border.color: accent

                    Text {
                        anchors.centerIn: parent
                        text: "A"
                        color: ink
                        font.pixelSize: 24
                        font.bold: true
                    }

                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: "Anvil Overlay"
                        color: ink
                        font.pixelSize: 24
                        font.bold: true
                    }

                    Text {
                        text: "In-game controls"
                        color: muted
                        font.pixelSize: 13
                        font.bold: true
                    }

                }

            }

            ListView {
                id: menuList

                width: parent.width
                height: 350
                spacing: 8
                focus: true
                Keys.onUpPressed: decrementCurrentIndex()
                Keys.onDownPressed: incrementCurrentIndex()
                Keys.onEscapePressed: root.overlayActive = false
                Keys.onReturnPressed: runMenuAction(model.get(currentIndex).name)

                model: ListModel {
                    ListElement {
                        name: "Resume Game"
                        detail: "Return to play"
                    }

                    ListElement {
                        name: "Friends"
                        detail: "Party and messages"
                    }

                    ListElement {
                        name: "Achievements"
                        detail: "Recent unlocks"
                    }

                    ListElement {
                        name: "Controller"
                        detail: "Input and layout"
                    }

                    ListElement {
                        name: "Settings"
                        detail: "Audio, display, system"
                    }

                    ListElement {
                        name: "Exit Game"
                        detail: "Stop current process"
                    }

                }

                delegate: Rectangle {
                    width: menuList.width
                    height: 58
                    radius: 8
                    color: ListView.isCurrentItem ? "#263242" : "transparent"
                    border.color: ListView.isCurrentItem ? accent : "transparent"

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        spacing: 1

                        Text {
                            text: model.name
                            color: ink
                            font.pixelSize: 17
                            font.bold: true
                        }

                        Text {
                            text: model.detail
                            color: ListView.isCurrentItem ? muted : quiet
                            font.pixelSize: 12
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            menuList.currentIndex = index;
                            runMenuAction(model.name);
                        }
                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 122
                radius: 8
                color: panel
                border.color: stroke

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "Session"
                        color: muted
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        text: "Performance Mode"
                        color: ink
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Text {
                        text: "Desktop load trimmed for Anvil. Overlay stays on the dedicated quick path."
                        color: muted
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                }

            }

        }

    }

    Rectangle {
        id: rightPanel

        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 360
        color: "#ed0d1118"
        border.color: stroke

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            Text {
                text: "Achievements"
                color: ink
                font.pixelSize: 24
                font.bold: true
            }

            Repeater {
                model: ["First Boot", "Cartridge Ready", "Overlay Online", "Library Indexed"]

                Rectangle {
                    width: parent.width
                    height: 76
                    radius: 8
                    color: panel
                    border.color: stroke

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 8
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#202b39"
                        border.color: index < 2 ? accent : stroke

                        Text {
                            anchors.centerIn: parent
                            text: index < 2 ? "OK" : "--"
                            color: index < 2 ? accent : quiet
                            font.pixelSize: 12
                            font.bold: true
                        }

                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 70
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: modelData
                            color: ink
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            text: index < 2 ? "Unlocked today" : "In progress"
                            color: muted
                            font.pixelSize: 12
                        }

                    }

                }

            }

            Rectangle {
                width: parent.width
                height: 134
                radius: 8
                color: "#121821"
                border.color: stroke

                Column {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 8

                    Text {
                        text: "Friends"
                        color: ink
                        font.pixelSize: 19
                        font.bold: true
                    }

                    Text {
                        text: "Party, chat, invites, and broadcast controls will dock here."
                        color: muted
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                }

            }

        }

    }

    Rectangle {
        id: centerPanel

        anchors.left: leftPanel.right
        anchors.leftMargin: 22
        anchors.right: rightPanel.left
        anchors.rightMargin: 22
        anchors.top: parent.top
        anchors.topMargin: 54
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 54
        radius: 8
        color: "#d010151d"
        border.color: "#233041"

        Column {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 18

            Row {
                width: parent.width
                height: 86
                spacing: 16

                Rectangle {
                    width: 86
                    height: 86
                    radius: 8
                    color: panel2
                    border.color: stroke

                    Text {
                        anchors.centerIn: parent
                        text: "LIVE"
                        color: accent
                        font.pixelSize: 18
                        font.bold: true
                    }

                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 110
                    spacing: 5

                    Text {
                        text: "Quick Access"
                        color: ink
                        font.pixelSize: 34
                        font.bold: true
                    }

                    Text {
                        text: "A Steam-style overlay, reworked for Anvil's darker HypeShell surface."
                        color: muted
                        font.pixelSize: 15
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                }

            }

            Grid {
                columns: 2
                spacing: 14

                Repeater {
                    model: ["Screenshot", "Record Clip", "Controller Layout", "Store Page", "Patch Notes", "Return to Library"]

                    Rectangle {
                        width: Math.max(220, (centerPanel.width - 82) / 2)
                        height: 96
                        radius: 8
                        color: "#171f2a"
                        border.color: stroke

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 18
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: ink
                            font.pixelSize: 18
                            font.bold: true
                        }

                    }

                }

            }

        }

    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        spacing: 22

        Text {
            text: "B / ESC  Resume"
            color: muted
            font.pixelSize: 14
            font.bold: true
        }

        Text {
            text: "A / ENTER  Select"
            color: muted
            font.pixelSize: 14
            font.bold: true
        }

    }

    Process {
        id: killGameProcess

        command: ["killall", "anvil-proton-run"]
    }

}
