import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

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
        } else if (keyText === "Escape" || keyText === "keyboard_hide") {
            oskWindow.dismissed();
        } else {
            Quickshell.execDetached(["wtype", keyText]);
        }
    }

    readonly property var keyboardModel: [
        // Row 1
        [
            {"t": "q", "s": "1", "w": 1.0},
            {"t": "w", "s": "2", "w": 1.0},
            {"t": "e", "s": "3", "w": 1.0},
            {"t": "r", "s": "4", "w": 1.0},
            {"t": "t", "s": "5", "w": 1.0},
            {"t": "y", "s": "6", "w": 1.0},
            {"t": "u", "s": "7", "w": 1.0},
            {"t": "i", "s": "8", "w": 1.0},
            {"t": "o", "s": "9", "w": 1.0},
            {"t": "p", "s": "0", "w": 1.0}
        ],
        // Row 2
        [
            {"t": "a", "s": "-", "w": 1.0},
            {"t": "s", "s": "/", "w": 1.0},
            {"t": "d", "s": ":", "w": 1.0},
            {"t": "f", "s": ";", "w": 1.0},
            {"t": "g", "s": "(", "w": 1.0},
            {"t": "h", "s": ")", "w": 1.0},
            {"t": "j", "s": "$", "w": 1.0},
            {"t": "k", "s": "&", "w": 1.0},
            {"t": "l", "s": "@", "w": 1.0}
        ],
        // Row 3
        [
            {"t": "⇧", "s": "⇧", "w": 1.5, "action": "shift"},
            {"t": "z", "s": ".", "w": 1.0},
            {"t": "x", "s": ",", "w": 1.0},
            {"t": "c", "s": "?", "w": 1.0},
            {"t": "v", "s": "!", "w": 1.0},
            {"t": "b", "s": "'", "w": 1.0},
            {"t": "n", "s": "%", "w": 1.0},
            {"t": "m", "s": "\"", "w": 1.0},
            {"t": "⌫", "s": "⌫", "w": 1.5, "action": "backspace"}
        ],
        // Row 4
        [
            {"t": "⌨", "s": "⌨", "w": 1.5, "action": "hide"},
            {"t": "?123", "s": "ABC", "w": 1.5, "action": "symbol"},
            {"t": " ", "s": " ", "w": 4.5, "action": "space"},
            {"t": ".", "s": ".", "w": 1.0},
            {"t": "↵", "s": "↵", "w": 1.5, "action": "enter"}
        ]
    ]

    Rectangle {
        id: keyboardContainer
        anchors.fill: parent
        color: AnvilTheme.surfaceContainerHigh
        border.color: AnvilTheme.outline
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Repeater {
                model: keyboardModel

                Row {
                    id: rowItem
                    property var rowData: modelData
                    spacing: 6
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: rowData

                        Rectangle {
                            id: keyButton
                            property var keyItem: modelData
                            property bool isSpecial: !!keyItem.action
                            property bool isShiftActive: keyItem.action === "shift" && oskWindow.shift
                            
                            // 10 key slots per standard row
                            width: Math.floor(keyItem.w * ((oskWindow.width - 24 - (9 * 6)) / 10.0))
                            height: (keyboardContainer.height - 16 - (3 * 8)) / 4.0
                            radius: 10

                            color: isShiftActive ? AnvilTheme.primary : (keyMouse.pressed ? AnvilTheme.primary : (isSpecial ? AnvilTheme.surfaceVariant : AnvilTheme.surface))
                            border.color: isShiftActive ? AnvilTheme.primary : (keyMouse.containsMouse ? AnvilTheme.outline : "transparent")
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    if (keyItem.action === "symbol") return oskWindow.symbols ? "ABC" : "?123";
                                    if (keyItem.action === "space") return " ";
                                    let raw = oskWindow.symbols ? keyItem.s : keyItem.t;
                                    return oskWindow.shift ? raw.toUpperCase() : raw;
                                }
                                color: (isShiftActive || keyMouse.pressed) ? AnvilTheme.primaryText : AnvilTheme.surfaceText
                                font.pixelSize: keyItem.action === "symbol" ? 14 : 18
                                font.bold: isSpecial || oskWindow.shift
                            }

                            MouseArea {
                                id: keyMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    let act = keyItem.action;
                                    if (act === "shift") {
                                        oskWindow.shift = !oskWindow.shift;
                                    } else if (act === "symbol") {
                                        oskWindow.symbols = !oskWindow.symbols;
                                    } else if (act === "hide") {
                                        oskWindow.dismissed();
                                    } else if (act === "backspace") {
                                        oskWindow.sendKey("Backspace");
                                    } else if (act === "enter") {
                                        oskWindow.sendKey("Enter");
                                    } else if (act === "space") {
                                        oskWindow.sendKey("Space");
                                    } else {
                                        let char = oskWindow.symbols ? keyItem.s : (oskWindow.shift ? keyItem.t.toUpperCase() : keyItem.t);
                                        oskWindow.sendKey(char);
                                        if (oskWindow.shift) oskWindow.shift = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
