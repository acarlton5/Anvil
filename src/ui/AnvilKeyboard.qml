import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: oskWindow

    property var modelData: null
    screen: modelData
    property bool isVisible: false
    property bool shift: false
    property bool symbols: false

    signal dismissed

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "anvil-keyboard"

    anchors {
        left: true
        right: true
        bottom: true
    }

    implicitHeight: 310

    visible: isVisible

    function sendKey(keyText) {
        if (keyText === "Enter") {
            Quickshell.execDetached(["wtype", "-k", "Return"]);
        } else if (keyText === "Backspace") {
            Quickshell.execDetached(["wtype", "-k", "BackSpace"]);
        } else if (keyText === "Space") {
            Quickshell.execDetached(["wtype", "-k", "space"]);
        } else if (keyText === "Tab") {
            Quickshell.execDetached(["wtype", "-k", "Tab"]);
        } else if (keyText === "Escape") {
            Quickshell.execDetached(["wtype", "-k", "Escape"]);
        } else {
            Quickshell.execDetached(["wtype", keyText]);
        }
    }

    readonly property var row1: [
        { "text": "q", "symbol": "1", "weight": 1.0 },
        { "text": "w", "symbol": "2", "weight": 1.0 },
        { "text": "e", "symbol": "3", "weight": 1.0 },
        { "text": "r", "symbol": "4", "weight": 1.0 },
        { "text": "t", "symbol": "5", "weight": 1.0 },
        { "text": "y", "symbol": "6", "weight": 1.0 },
        { "text": "u", "symbol": "7", "weight": 1.0 },
        { "text": "i", "symbol": "8", "weight": 1.0 },
        { "text": "o", "symbol": "9", "weight": 1.0 },
        { "text": "p", "symbol": "0", "weight": 1.0 }
    ]

    readonly property var row2: [
        { "text": "a", "symbol": "-", "weight": 1.0 },
        { "text": "s", "symbol": "/", "weight": 1.0 },
        { "text": "d", "symbol": ":", "weight": 1.0 },
        { "text": "f", "symbol": ";", "weight": 1.0 },
        { "text": "g", "symbol": "(", "weight": 1.0 },
        { "text": "h", "symbol": ")", "weight": 1.0 },
        { "text": "j", "symbol": "$", "weight": 1.0 },
        { "text": "k", "symbol": "&", "weight": 1.0 },
        { "text": "l", "symbol": "@", "weight": 1.0 }
    ]

    readonly property var row3: [
        { "text": "z", "symbol": ".", "weight": 1.0 },
        { "text": "x", "symbol": ",", "weight": 1.0 },
        { "text": "c", "symbol": "?", "weight": 1.0 },
        { "text": "v", "symbol": "!", "weight": 1.0 },
        { "text": "b", "symbol": "'", "weight": 1.0 },
        { "text": "n", "symbol": "%", "weight": 1.0 },
        { "text": "m", "symbol": "\"", "weight": 1.0 }
    ]

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#f610161f"
        border.color: "#283444"
        border.width: 1

        // Header bar with Title, Status & Close
        Rectangle {
            id: topBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 38
            color: "#161e29"
            border.color: "#222c38"

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: "ON-SCREEN KEYBOARD"
                    color: "#ff6537"
                    font.pixelSize: 12
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Text {
                    text: oskWindow.symbols ? "• Numbers & Symbols" : (oskWindow.shift ? "• Shift Active" : "")
                    color: "#a0afbf"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: closeMouse.containsMouse ? "#3b1e22" : "#212b37"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeMouse.containsMouse ? "#ff7070" : "#a0afbf"
                    font.pixelSize: 13
                    font.bold: true
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        oskWindow.dismissed();
                        oskWindow.isVisible = false;
                    }
                }
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: topBar.bottom
            anchors.bottom: parent.bottom
            anchors.margins: 12
            spacing: 8

            // Row 1: 10 keys (Q-P)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Repeater {
                    model: oskWindow.row1
                    delegate: Rectangle {
                        width: Math.floor((oskWindow.width - 24 - 54) / 10)
                        height: 52
                        radius: 8
                        color: keyMouse.pressed ? "#ff6537" : (keyMouse.containsMouse ? "#273344" : "#1b232f")
                        border.color: keyMouse.pressed ? "#ff6537" : "#2e3b4d"

                        Text {
                            anchors.centerIn: parent
                            text: oskWindow.symbols ? modelData.symbol : (oskWindow.shift ? modelData.text.toUpperCase() : modelData.text)
                            color: keyMouse.pressed ? "#0b0f14" : "#f5f5f2"
                            font.pixelSize: 19
                            font.bold: true
                        }

                        MouseArea {
                            id: keyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                let ch = oskWindow.symbols ? modelData.symbol : (oskWindow.shift ? modelData.text.toUpperCase() : modelData.text);
                                oskWindow.sendKey(ch);
                                if (oskWindow.shift) oskWindow.shift = false;
                            }
                        }
                    }
                }
            }

            // Row 2: 9 keys (A-L)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Repeater {
                    model: oskWindow.row2
                    delegate: Rectangle {
                        width: Math.floor((oskWindow.width - 24 - 54) / 10)
                        height: 52
                        radius: 8
                        color: keyMouse2.pressed ? "#ff6537" : (keyMouse2.containsMouse ? "#273344" : "#1b232f")
                        border.color: keyMouse2.pressed ? "#ff6537" : "#2e3b4d"

                        Text {
                            anchors.centerIn: parent
                            text: oskWindow.symbols ? modelData.symbol : (oskWindow.shift ? modelData.text.toUpperCase() : modelData.text)
                            color: keyMouse2.pressed ? "#0b0f14" : "#f5f5f2"
                            font.pixelSize: 19
                            font.bold: true
                        }

                        MouseArea {
                            id: keyMouse2
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                let ch = oskWindow.symbols ? modelData.symbol : (oskWindow.shift ? modelData.text.toUpperCase() : modelData.text);
                                oskWindow.sendKey(ch);
                                if (oskWindow.shift) oskWindow.shift = false;
                            }
                        }
                    }
                }
            }

            // Row 3: Shift (1.5x), Z-M (7 keys), Backspace (1.5x)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                // Shift Key
                Rectangle {
                    width: Math.floor(((oskWindow.width - 24 - 54) / 10) * 1.48)
                    height: 52
                    radius: 8
                    color: oskWindow.shift ? "#ff6537" : (shiftMouse.containsMouse ? "#273344" : "#222c3b")
                    border.color: oskWindow.shift ? "#ff6537" : "#364559"

                    Text {
                        anchors.centerIn: parent
                        text: "⇧"
                        color: oskWindow.shift ? "#0b0f14" : "#f5f5f2"
                        font.pixelSize: 22
                        font.bold: true
                    }

                    MouseArea {
                        id: shiftMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: oskWindow.shift = !oskWindow.shift
                    }
                }

                // Middle 7 keys
                Repeater {
                    model: oskWindow.row3
                    delegate: Rectangle {
                        width: Math.floor((oskWindow.width - 24 - 54) / 10)
                        height: 52
                        radius: 8
                        color: keyMouse3.pressed ? "#ff6537" : (keyMouse3.containsMouse ? "#273344" : "#1b232f")
                        border.color: keyMouse3.pressed ? "#ff6537" : "#2e3b4d"

                        Text {
                            anchors.centerIn: parent
                            text: oskWindow.symbols ? modelData.symbol : (oskWindow.shift ? modelData.text.toUpperCase() : modelData.text)
                            color: keyMouse3.pressed ? "#0b0f14" : "#f5f5f2"
                            font.pixelSize: 19
                            font.bold: true
                        }

                        MouseArea {
                            id: keyMouse3
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                let ch = oskWindow.symbols ? modelData.symbol : (oskWindow.shift ? modelData.text.toUpperCase() : modelData.text);
                                oskWindow.sendKey(ch);
                                if (oskWindow.shift) oskWindow.shift = false;
                            }
                        }
                    }
                }

                // Backspace Key
                Rectangle {
                    width: Math.floor(((oskWindow.width - 24 - 54) / 10) * 1.48)
                    height: 52
                    radius: 8
                    color: bsMouse.pressed ? "#ff6537" : (bsMouse.containsMouse ? "#322329" : "#271e25")
                    border.color: bsMouse.pressed ? "#ff6537" : "#4e2b34"

                    Text {
                        anchors.centerIn: parent
                        text: "⌫"
                        color: bsMouse.pressed ? "#0b0f14" : "#ff7070"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    MouseArea {
                        id: bsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: oskWindow.sendKey("Backspace")
                    }
                }
            }

            // Row 4: Hide (1.25x), 123/ABC (1.35x), Space (4.4x), . (1x), Enter (1.5x)
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                // Dismiss / Hide Key
                Rectangle {
                    width: Math.floor(((oskWindow.width - 24 - 54) / 10) * 1.25)
                    height: 52
                    radius: 8
                    color: hideMouse.containsMouse ? "#2e3948" : "#222c3b"
                    border.color: "#364559"

                    Text {
                        anchors.centerIn: parent
                        text: "⌨ ✕"
                        color: "#a0afbf"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        id: hideMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            oskWindow.dismissed();
                            oskWindow.isVisible = false;
                        }
                    }
                }

                // 123 / ABC Toggle Key
                Rectangle {
                    width: Math.floor(((oskWindow.width - 24 - 54) / 10) * 1.35)
                    height: 52
                    radius: 8
                    color: oskWindow.symbols ? "#ff6537" : (symMouse.containsMouse ? "#2e3948" : "#222c3b")
                    border.color: oskWindow.symbols ? "#ff6537" : "#364559"

                    Text {
                        anchors.centerIn: parent
                        text: oskWindow.symbols ? "ABC" : "123"
                        color: oskWindow.symbols ? "#0b0f14" : "#f5f5f2"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    MouseArea {
                        id: symMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: oskWindow.symbols = !oskWindow.symbols
                    }
                }

                // Spacebar
                Rectangle {
                    width: Math.floor(((oskWindow.width - 24 - 54) / 10) * 4.4)
                    height: 52
                    radius: 8
                    color: spaceMouse.pressed ? "#ff6537" : (spaceMouse.containsMouse ? "#273344" : "#1b232f")
                    border.color: spaceMouse.pressed ? "#ff6537" : "#2e3b4d"

                    Text {
                        anchors.centerIn: parent
                        text: "SPACE"
                        color: spaceMouse.pressed ? "#0b0f14" : "#728394"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.5
                    }

                    MouseArea {
                        id: spaceMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: oskWindow.sendKey("Space")
                    }
                }

                // Period Key
                Rectangle {
                    width: Math.floor((oskWindow.width - 24 - 54) / 10)
                    height: 52
                    radius: 8
                    color: dotMouse.pressed ? "#ff6537" : (dotMouse.containsMouse ? "#273344" : "#1b232f")
                    border.color: dotMouse.pressed ? "#ff6537" : "#2e3b4d"

                    Text {
                        anchors.centerIn: parent
                        text: "."
                        color: dotMouse.pressed ? "#0b0f14" : "#f5f5f2"
                        font.pixelSize: 22
                        font.bold: true
                    }

                    MouseArea {
                        id: dotMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: oskWindow.sendKey(".")
                    }
                }

                // Enter Key
                Rectangle {
                    width: Math.floor(((oskWindow.width - 24 - 54) / 10) * 1.5)
                    height: 52
                    radius: 8
                    color: enterMouse.pressed ? "#e05020" : "#ff6537"

                    Text {
                        anchors.centerIn: parent
                        text: "↵ ENTER"
                        color: "#0b0f14"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        id: enterMouse
                        anchors.fill: parent
                        onClicked: oskWindow.sendKey("Enter")
                    }
                }
            }
        }
    }
}
