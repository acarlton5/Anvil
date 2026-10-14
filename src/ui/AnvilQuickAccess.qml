import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire

PanelWindow {
    id: qamWindow

    property bool isVisible: false
    signal requestKeyboardToggle
    signal requestClose

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "anvil-quick-access"

    anchors {
        top: true
        bottom: true
        right: true
    }

    implicitWidth: 360

    visible: isVisible

    readonly property PwNode audioSink: Pipewire.defaultAudioSink

    property int batteryPercent: 100
    property bool isCharging: false
    property string currentTime: ""
    property real brightnessLevel: 0.8

    Timer {
        interval: 3000
        running: qamWindow.isVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            updateSystemInfo();
        }
    }

    function updateSystemInfo() {
        // Time
        let d = new Date();
        currentTime = Qt.formatTime(d, "h:mm AP");

        // Battery
        batteryReader.command = ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1"];
        batteryReader.running = true;

        // Brightness
        brightnessReader.command = ["brightnessctl", "get"];
        brightnessReader.running = true;
    }

    Process {
        id: batteryReader
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = text.trim().split("\n");
                if (lines.length >= 1 && lines[0]) {
                    batteryPercent = parseInt(lines[0]) || 100;
                }
                if (lines.length >= 2) {
                    isCharging = lines[1].toLowerCase().includes("charging");
                }
            }
        }
    }

    Process {
        id: brightnessReader
        stdout: StdioCollector {
            onStreamFinished: {
                let current = parseInt(text.trim()) || 0;
                if (current > 0) {
                    brightnessLevel = Math.min(1.0, current / 255.0);
                }
            }
        }
    }

    function setBrightness(val) {
        let percent = Math.round(val * 100);
        Quickshell.execDetached(["brightnessctl", "set", percent + "%"]);
        brightnessLevel = val;
    }

    function setVolume(val) {
        if (audioSink && audioSink.audio) {
            audioSink.audio.volume = val;
        }
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        color: "#f60d1319"
        border.color: "#283442"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            // Header: Title, Clock, Battery
            Row {
                width: parent.width
                height: 36
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "QUICK ACCESS"
                    color: "#ff6537"
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Item { Layout.fillWidth: true; width: parent.width - 240 }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: currentTime
                    color: "#a0afbf"
                    font.pixelSize: 13
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 22
                    radius: 4
                    color: "#1c2633"
                    border.color: isCharging ? "#4cd964" : (batteryPercent <= 20 ? "#ff3b30" : "#ff6537")

                    Text {
                        anchors.centerIn: parent
                        text: batteryPercent + "%"
                        color: "#f5f5f2"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: "#1f2a36"

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#a0afbf"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: qamWindow.isVisible = false
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#263240"
            }

            // Keyboard Toggle Action Button (Prominent)
            Rectangle {
                width: parent.width
                height: 52
                radius: 8
                color: "#1c2734"
                border.color: "#ff6537"
                border.width: 1.5

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌨"
                        color: "#ff6537"
                        font.pixelSize: 22
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "TOGGLE VIRTUAL KEYBOARD"
                        color: "#f5f5f2"
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 1.0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        qamWindow.requestKeyboardToggle();
                    }
                }
            }

            // Volume Control Section
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    Text {
                        text: "VOLUME"
                        color: "#a0afbf"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                    }
                    Item { width: parent.width - 120; height: 1 }
                    Text {
                        text: audioSink && audioSink.audio ? Math.round(audioSink.audio.volume * 100) + "%" : "0%"
                        color: "#ff6537"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 6
                    color: "#161e27"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: audioSink && audioSink.audio ? Math.max(0, Math.min(parent.width, parent.width * audioSink.audio.volume)) : 0
                        radius: 6
                        color: "#ff6537"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: (mouse) => {
                            let frac = Math.max(0.0, Math.min(1.0, mouse.x / width));
                            setVolume(frac);
                        }
                    }
                }
            }

            // Brightness Control Section
            Column {
                width: parent.width
                spacing: 8

                Row {
                    width: parent.width
                    Text {
                        text: "BRIGHTNESS"
                        color: "#a0afbf"
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1.0
                    }
                    Item { width: parent.width - 140; height: 1 }
                    Text {
                        text: Math.round(brightnessLevel * 100) + "%"
                        color: "#ffb037"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 6
                    color: "#161e27"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.max(0, Math.min(parent.width, parent.width * brightnessLevel))
                        radius: 6
                        color: "#ffb037"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: (mouse) => {
                            let frac = Math.max(0.05, Math.min(1.0, mouse.x / width));
                            setBrightness(frac);
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#263240"
            }

            // Session / Power Management
            Text {
                text: "POWER & SESSION"
                color: "#a0afbf"
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 1.0
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                // Switch to Desktop
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 42
                    radius: 6
                    color: "#212d3b"
                    border.color: "#3d4e61"

                    Text {
                        anchors.centerIn: parent
                        text: "Desktop Mode"
                        color: "#f5f5f2"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
                            Qt.quit();
                        }
                    }
                }

                // Sleep
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 42
                    radius: 6
                    color: "#161e27"
                    border.color: "#283442"

                    Text {
                        anchors.centerIn: parent
                        text: "Sleep"
                        color: "#a0afbf"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "loginctl suspend 2>/dev/null || systemctl suspend"]);
                        }
                    }
                }

                // Restart System
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 42
                    radius: 6
                    color: "#161e27"
                    border.color: "#283442"

                    Text {
                        anchors.centerIn: parent
                        text: "Restart System"
                        color: "#a0afbf"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "loginctl reboot 2>/dev/null || systemctl reboot"]);
                        }
                    }
                }

                // Shut Down
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 42
                    radius: 6
                    color: "#281519"
                    border.color: "#522228"

                    Text {
                        anchors.centerIn: parent
                        text: "Shut Down"
                        color: "#ff7070"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "loginctl poweroff 2>/dev/null || systemctl poweroff"]);
                        }
                    }
                }
            }
        }
    }
}
