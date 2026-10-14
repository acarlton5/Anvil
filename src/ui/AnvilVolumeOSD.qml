import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: osdWindow

    property bool isVisible: false
    property real currentVolume: 0.0
    property bool isMuted: false

    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "anvil-volume-osd"

    anchors {
        top: true
    }

    visible: isVisible

    implicitWidth: 320
    implicitHeight: 70

    readonly property PwNode audioSink: Pipewire.defaultAudioSink

    Connections {
        target: audioSink ? audioSink.audio : null

        function onVolumeChanged() {
            if (!audioSink || !audioSink.audio) return;
            currentVolume = audioSink.audio.volume;
            isMuted = audioSink.audio.muted;
            showOSD();
        }

        function onMutedChanged() {
            if (!audioSink || !audioSink.audio) return;
            isMuted = audioSink.audio.muted;
            showOSD();
        }
    }

    Timer {
        id: hideTimer
        interval: 2200
        repeat: false
        onTriggered: {
            osdWindow.isVisible = false;
        }
    }

    function showOSD() {
        isVisible = true;
        hideTimer.restart();
    }

    Rectangle {
        id: osdContainer
        anchors.centerIn: parent
        width: 280
        height: 52
        radius: 26
        color: "#ee10141a"
        border.color: isMuted ? "#ff5555" : "#ff6537"
        border.width: 1.5

        opacity: osdWindow.isVisible ? 1.0 : 0.0
        scale: osdWindow.isVisible ? 1.0 : 0.92

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        Row {
            anchors.centerIn: parent
            spacing: 14
            width: parent.width - 32

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: isMuted ? "🔇" : (currentVolume > 0.5 ? "🔊" : "🔉")
                color: isMuted ? "#ff5555" : "#ff6537"
                font.pixelSize: 20
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 80
                height: 8
                radius: 4
                color: "#2a3440"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, Math.min(parent.width, parent.width * osdWindow.currentVolume))
                    radius: 4
                    color: isMuted ? "#888888" : "#ff6537"

                    Behavior on width {
                        NumberAnimation { duration: 80 }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: isMuted ? "MUTE" : Math.round(osdWindow.currentVolume * 100) + "%"
                color: "#f5f5f2"
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
