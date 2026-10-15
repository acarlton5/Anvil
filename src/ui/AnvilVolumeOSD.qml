import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: osdWindow

    property var modelData: null
    screen: modelData

    property bool isVisible: false
    property int currentVolume: 70
    property bool isMuted: false

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "anvil-volume-osd"

    anchors {
        top: true
    }

    margins {
        top: 24
    }

    visible: isVisible

    implicitWidth: 320
    implicitHeight: 70

    readonly property string anvilRoot: Quickshell.env("ANVIL_ROOT") || "/usr/local/share/anvil"

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: {
            osdWindow.isVisible = false;
        }
    }

    Process {
        id: audioPoller
        command: ["sh", "-c", anvilRoot + "/scripts/anvil-audio-control status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text);
                    if (d.current_sink) {
                        let newVol = Math.min(100, d.current_sink.volume || 0);
                        let newMuted = !!d.current_sink.muted;
                        if (newVol !== currentVolume || newMuted !== isMuted) {
                            currentVolume = newVol;
                            isMuted = newMuted;
                            osdWindow.isVisible = true;
                            hideTimer.restart();
                        }
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        interval: 150
        repeat: true
        running: true
        onTriggered: {
            if (!audioPoller.running) audioPoller.running = true;
        }
    }

    Rectangle {
        id: osdContainer
        anchors.centerIn: parent
        width: 280
        height: 52
        radius: 12
        color: AnvilTheme.panelBg
        border.color: isMuted ? AnvilTheme.error : AnvilTheme.primary
        border.width: 1.5

        opacity: osdWindow.isVisible ? 1.0 : 0.0
        scale: osdWindow.isVisible ? 1.0 : 0.95

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Row {
            anchors.centerIn: parent
            spacing: 14
            width: parent.width - 32

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: isMuted ? "󰝟" : (currentVolume > 50 ? "󰕾" : (currentVolume > 0 ? "󰖀" : "󰕿"))
                font.family: "Symbols Nerd Font, monospace"
                font.pixelSize: 20
                color: isMuted ? AnvilTheme.error : AnvilTheme.primary
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 92
                height: 10
                radius: 5
                color: AnvilTheme.panelDeep

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, Math.min(parent.width, parent.width * (osdWindow.currentVolume / 100.0)))
                    radius: 5
                    color: isMuted ? "#888888" : AnvilTheme.primary

                    Behavior on width {
                        NumberAnimation { duration: 70 }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: isMuted ? "MUTE" : osdWindow.currentVolume + "%"
                color: AnvilTheme.surfaceText
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
