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

    implicitHeight: 280

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

    Rectangle {
        id: bg
        anchors.fill: parent
        color: "#f20d1218"
        border.color: "#2a3644"
        border.width: 1

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 38
            color: "#18222d"

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "ANVIL VIRTUAL KEYBOARD"
                color: "#ff6537"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.2
            }

            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 70
                height: 26
                radius: 4
                color: "#ff3b30"

                Text {
                    anchors.centerIn: parent
                    text: "CLOSE"
                    color: "white"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: oskWindow.isVisible = false
                }
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.topMargin: 44
            anchors.margins: 8
            spacing: 6

            // Row 1: Numbers
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Repeater {
                    model: oskWindow.symbols ? ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")"] : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                    delegate: Rectangle {
                        width: (oskWindow.width - 80) / 10
                        height: 48
                        radius: 6
                        color: "#1f2a36"
                        border.color: "#384756"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "#f5f5f2"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: oskWindow.sendKey(modelData)
                        }
                    }
                }
            }

            // Row 2: QWERTY
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Repeater {
                    model: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
                    delegate: Rectangle {
                        width: (oskWindow.width - 80) / 10
                        height: 48
                        radius: 6
                        color: "#1f2a36"
                        border.color: "#384756"
                        Text {
                            anchors.centerIn: parent
                            text: oskWindow.shift ? modelData.toUpperCase() : modelData
                            color: "#f5f5f2"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                let ch = oskWindow.shift ? modelData.toUpperCase() : modelData;
                                oskWindow.sendKey(ch);
                                if (oskWindow.shift) oskWindow.shift = false;
                            }
                        }
                    }
                }
            }

            // Row 3: ASDFGHJKL + Backspace
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Repeater {
                    model: ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
                    delegate: Rectangle {
                        width: (oskWindow.width - 100) / 10.5
                        height: 48
                        radius: 6
                        color: "#1f2a36"
                        border.color: "#384756"
                        Text {
                            anchors.centerIn: parent
                            text: oskWindow.shift ? modelData.toUpperCase() : modelData
                            color: "#f5f5f2"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                let ch = oskWindow.shift ? modelData.toUpperCase() : modelData;
                                oskWindow.sendKey(ch);
                                if (oskWindow.shift) oskWindow.shift = false;
                            }
                        }
                    }
                }

                Rectangle {
                    width: ((oskWindow.width - 100) / 10.5) * 1.5
                    height: 48
                    radius: 6
                    color: "#2a3644"
                    border.color: "#ff6537"
                    Text {
                        anchors.centerIn: parent
                        text: "⌫"
                        color: "#ff6537"
                        font.pixelSize: 20
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: oskWindow.sendKey("Backspace")
                    }
                }
            }

            // Row 4: Shift, ZXCVBNM, Enter
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Rectangle {
                    width: ((oskWindow.width - 100) / 10.5) * 1.3
                    height: 48
                    radius: 6
                    color: oskWindow.shift ? "#ff6537" : "#2a3644"
                    border.color: "#384756"
                    Text {
                        anchors.centerIn: parent
                        text: "⇧"
                        color: oskWindow.shift ? "black" : "#f5f5f2"
                        font.pixelSize: 20
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: oskWindow.shift = !oskWindow.shift
                    }
                }

                Repeater {
                    model: ["z", "x", "c", "v", "b", "n", "m", ",", "."]
                    delegate: Rectangle {
                        width: (oskWindow.width - 120) / 11
                        height: 48
                        radius: 6
                        color: "#1f2a36"
                        border.color: "#384756"
                        Text {
                            anchors.centerIn: parent
                            text: oskWindow.shift ? modelData.toUpperCase() : modelData
                            color: "#f5f5f2"
                            font.pixelSize: 18
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                let ch = oskWindow.shift ? modelData.toUpperCase() : modelData;
                                oskWindow.sendKey(ch);
                                if (oskWindow.shift) oskWindow.shift = false;
                            }
                        }
                    }
                }

                Rectangle {
                    width: ((oskWindow.width - 100) / 10.5) * 1.5
                    height: 48
                    radius: 6
                    color: "#ff6537"
                    Text {
                        anchors.centerIn: parent
                        text: "↵ ENTER"
                        color: "#0d1218"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: oskWindow.sendKey("Enter")
                    }
                }
            }

            // Row 5: Space and symbol toggle
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    width: 100
                    height: 44
                    radius: 6
                    color: oskWindow.symbols ? "#ff6537" : "#2a3644"
                    Text {
                        anchors.centerIn: parent
                        text: oskWindow.symbols ? "ABC" : "123 #+="
                        color: oskWindow.symbols ? "black" : "#f5f5f2"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: oskWindow.symbols = !oskWindow.symbols
                    }
                }

                Rectangle {
                    width: oskWindow.width * 0.45
                    height: 44
                    radius: 6
                    color: "#1f2a36"
                    border.color: "#384756"
                    Text {
                        anchors.centerIn: parent
                        text: "SPACE"
                        color: "#8895a5"
                        font.pixelSize: 12
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: oskWindow.sendKey("Space")
                    }
                }

                Rectangle {
                    width: 100
                    height: 44
                    radius: 6
                    color: "#2a3644"
                    Text {
                        anchors.centerIn: parent
                        text: "ESC"
                        color: "#f5f5f2"
                        font.pixelSize: 13
                        font.bold: true
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: oskWindow.sendKey("Escape")
                    }
                }
            }
        }
    }
}
