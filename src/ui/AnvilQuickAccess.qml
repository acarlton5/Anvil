import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire

PanelWindow {
    id: qamWindow

    property var modelData: null
    screen: modelData
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
            updateSystemInfo(); refreshAudioStatus();
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

        readonly property string anvilRoot: Quickshell.env("ANVIL_ROOT") || "/usr/local/share/anvil"
    property string currentOutputDevice: "Default Output"
    property int currentOutputVol: 70
    property bool isOutputMuted: false

    property string currentInputDevice: "Default Mic"
    property int currentInputVol: 100
    property bool isInputMuted: false

    Process {
        id: audioStatusProc
        command: ["sh", "-c", anvilRoot + "/scripts/anvil-audio-control status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let d = JSON.parse(text);
                    if (d.current_sink) {
                        currentOutputDevice = d.current_sink.name || "Output";
                        currentOutputVol = d.current_sink.volume || 0;
                        isOutputMuted = !!d.current_sink.muted;
                    }
                    if (d.current_source) {
                        currentInputDevice = d.current_source.name || "Input";
                        currentInputVol = d.current_source.volume || 0;
                        isInputMuted = !!d.current_source.muted;
                    }
                } catch(e) {}
            }
        }
    }

    function refreshAudioStatus() {
        if (!audioStatusProc.running) {
            audioStatusProc.running = true;
        }
    }

    function cycleAudioOutput() {
        Quickshell.execDetached([anvilRoot + "/scripts/anvil-audio-control", "cycle-sink"]);
        refreshAudioTimer.start();
    }

    function cycleAudioInput() {
        Quickshell.execDetached([anvilRoot + "/scripts/anvil-audio-control", "cycle-source"]);
        refreshAudioTimer.start();
    }

    function setOutputVolume(frac) {
        currentOutputVol = Math.max(0, Math.min(100, Math.round(frac * 100)));
        Quickshell.execDetached([anvilRoot + "/scripts/anvil-audio-control", "set-volume", currentOutputVol.toString()]);
    }

    function setInputVolume(frac) {
        currentInputVol = Math.max(0, Math.min(100, Math.round(frac * 100)));
        Quickshell.execDetached([anvilRoot + "/scripts/anvil-audio-control", "set-mic-volume", currentInputVol.toString()]);
    }

    Timer {
        id: refreshAudioTimer
        interval: 350
        repeat: false
        onTriggered: refreshAudioStatus()
    }

    function setBrightness(val) {
        let percent = Math.round(val * 100);
        Quickshell.execDetached(["brightnessctl", "set", percent + "%"]);
        brightnessLevel = val;
    }

    property bool isUpdating: false
    property string updateStatusText: "Check for Updates"

    Process {
        id: updaterProcess
        command: ["sh", "-c", "sudo /usr/local/bin/hype update install 2>&1; git -C ~/.config/HypeShell/plugins/hypeAnvil pull origin main 2>&1 && sudo bash ~/.config/HypeShell/plugins/hypeAnvil/scripts/install-session ~/.config/HypeShell/plugins/hypeAnvil 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                isUpdating = false;
                updateStatusText = "System Up to Date!";
                console.log("[Anvil Update]: " + text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0)
                    console.log("[Anvil Update err]: " + text);
            }
        }
        onExited: function(exitCode) {
            isUpdating = false;
            if (exitCode === 0) {
                updateStatusText = "Update Complete!";
            } else {
                updateStatusText = "Check for Updates";
            }
        }
    }

    function triggerSystemUpdate() {
        if (isUpdating) return;
        isUpdating = true;
        updateStatusText = "Updating System...";
        updaterProcess.running = true;
    }

    function setVolume(val) {
        if (audioSink && audioSink.audio) {
            audioSink.audio.volume = val;
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: qamWindow.isVisible
        Keys.onEscapePressed: qamWindow.requestClose()
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        color: AnvilTheme.background
        opacity: 0.96
        border.color: AnvilTheme.outlineVariant
        border.width: 1
        radius: 16

        // SteamOS / PS5 dark gradient accent
        gradient: Gradient {
            GradientStop { position: 0.0; color: AnvilTheme.panelBg }
            GradientStop { position: 1.0; color: AnvilTheme.background }
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 16
            contentHeight: contentCol.height + 24
            clip: true

            Column {
                id: contentCol
                width: parent.width
                spacing: 14

                // Header: Title, Clock, Battery, Close
                Row {
                    width: parent.width
                    height: 36
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "QUICK ACCESS"
                        color: AnvilTheme.primary
                        font.pixelSize: 15
                        font.bold: true
                        font.letterSpacing: 1.2
                    }

                    Item { width: Math.max(8, parent.width - 250); height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: currentTime
                        color: AnvilTheme.surfaceVariantText
                        font.pixelSize: 13
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 44
                        height: 22
                        radius: 6
                        color: AnvilTheme.panelCard
                        border.color: isCharging ? "#4cd964" : (batteryPercent <= 20 ? "#ff3b30" : AnvilTheme.primary)

                        Text {
                            anchors.centerIn: parent
                            text: batteryPercent + "%"
                            color: AnvilTheme.surfaceText
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: closeMouse.containsMouse ? AnvilTheme.panelCard : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: AnvilTheme.surfaceVariantText
                            font.pixelSize: 14
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: qamWindow.requestClose()
                        }
                    }
                }

                // Keyboard Toggle Button
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 8
                    color: AnvilTheme.panelCard
                    border.color: AnvilTheme.outline

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⌨"
                            font.pixelSize: 14
                            color: AnvilTheme.primary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "On-Screen Keyboard (Steam + X)"
                            color: AnvilTheme.surfaceText
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            qamWindow.requestKeyboardToggle();
                        }
                    }
                }

                // Audio Output Section (SteamOS style card)
                Rectangle {
                    width: parent.width
                    height: 104
                    radius: 10
                    color: AnvilTheme.panelCard
                    border.color: AnvilTheme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Row {
                            width: parent.width
                            Text {
                                text: "AUDIO OUTPUT"
                                color: AnvilTheme.primary
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.0
                            }
                            Item { width: Math.max(10, parent.width - 150); height: 1 }
                            Text {
                                text: currentOutputVol + "%"
                                color: isOutputMuted ? AnvilTheme.error : AnvilTheme.surfaceText
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        // Output Device Selector (Click to cycle)
                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 6
                            color: AnvilTheme.panelDeep

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "🔊"
                                    font.pixelSize: 13
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 70
                                    text: currentOutputDevice
                                    color: AnvilTheme.surfaceText
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 50
                                    height: 20
                                    radius: 4
                                    color: AnvilTheme.surfaceVariant

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cycle"
                                        color: AnvilTheme.primary
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: cycleAudioOutput()
                            }
                        }

                        // Output Volume Slider
                        Rectangle {
                            width: parent.width
                            height: 24
                            radius: 6
                            color: AnvilTheme.panelDeep

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(0, Math.min(parent.width, parent.width * (currentOutputVol / 100.0)))
                                radius: 6
                                color: isOutputMuted ? "#666666" : AnvilTheme.primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    let frac = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                    setOutputVolume(frac);
                                }
                            }
                        }
                    }
                }

                // Microphone Section
                Rectangle {
                    width: parent.width
                    height: 104
                    radius: 10
                    color: AnvilTheme.panelCard
                    border.color: AnvilTheme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Row {
                            width: parent.width
                            Text {
                                text: "MICROPHONE"
                                color: AnvilTheme.secondary
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.0
                            }
                            Item { width: Math.max(10, parent.width - 150); height: 1 }
                            Text {
                                text: currentInputVol + "%"
                                color: isInputMuted ? AnvilTheme.error : AnvilTheme.surfaceText
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        // Input Device Selector (Click to cycle)
                        Rectangle {
                            width: parent.width
                            height: 32
                            radius: 6
                            color: AnvilTheme.panelDeep

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "🎤"
                                    font.pixelSize: 13
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 70
                                    text: currentInputDevice
                                    color: AnvilTheme.surfaceText
                                    font.pixelSize: 11
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 50
                                    height: 20
                                    radius: 4
                                    color: AnvilTheme.surfaceVariant

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Cycle"
                                        color: AnvilTheme.secondary
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: cycleAudioInput()
                            }
                        }

                        // Input Volume Slider
                        Rectangle {
                            width: parent.width
                            height: 24
                            radius: 6
                            color: AnvilTheme.panelDeep

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(0, Math.min(parent.width, parent.width * (currentInputVol / 100.0)))
                                radius: 6
                                color: isInputMuted ? "#666666" : AnvilTheme.secondary
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    let frac = Math.max(0.0, Math.min(1.0, mouse.x / width));
                                    setInputVolume(frac);
                                }
                            }
                        }
                    }
                }

                // Brightness Section
                Rectangle {
                    width: parent.width
                    height: 78
                    radius: 10
                    color: AnvilTheme.panelCard
                    border.color: AnvilTheme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Row {
                            width: parent.width
                            Text {
                                text: "DISPLAY BRIGHTNESS"
                                color: AnvilTheme.surfaceVariantText
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.0
                            }
                            Item { width: Math.max(10, parent.width - 170); height: 1 }
                            Text {
                                text: Math.round(brightnessLevel * 100) + "%"
                                color: AnvilTheme.surfaceText
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 24
                            radius: 6
                            color: AnvilTheme.panelDeep

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(0, Math.min(parent.width, parent.width * brightnessLevel))
                                radius: 6
                                color: AnvilTheme.secondary
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
                }

                // Session / Power Management Card
                Rectangle {
                    width: parent.width
                    height: 140
                    radius: 10
                    color: AnvilTheme.panelCard
                    border.color: AnvilTheme.surfaceContainerHigh

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "POWER & SESSION"
                            color: AnvilTheme.surfaceVariantText
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.0
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 8

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 38
                                radius: 6
                                color: AnvilTheme.panelDeep
                                border.color: AnvilTheme.outline

                                Text {
                                    anchors.centerIn: parent
                                    text: "Desktop Mode"
                                    color: AnvilTheme.surfaceText
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Quickshell.execDetached(["sh", "-c", "command -v anvil-switch-desktop >/dev/null 2>&1 && anvil-switch-desktop || hyprctl dispatch exit"]);
                                        Qt.quit();
                                    }
                                }
                            }

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 38
                                radius: 6
                                color: AnvilTheme.panelDeep
                                border.color: AnvilTheme.outline

                                Text {
                                    anchors.centerIn: parent
                                    text: "Sleep"
                                    color: AnvilTheme.surfaceVariantText
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Quickshell.execDetached(["sh", "-c", "loginctl suspend 2>/dev/null || systemctl suspend"]);
                                    }
                                }
                            }

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 38
                                radius: 6
                                color: AnvilTheme.panelDeep
                                border.color: AnvilTheme.outline

                                Text {
                                    anchors.centerIn: parent
                                    text: "Restart System"
                                    color: AnvilTheme.surfaceVariantText
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Quickshell.execDetached(["sh", "-c", "loginctl reboot 2>/dev/null || systemctl reboot"]);
                                    }
                                }
                            }

                            Rectangle {
                                width: (parent.width - 8) / 2
                                height: 38
                                radius: 6
                                color: "#281519"
                                border.color: "#522228"

                                Text {
                                    anchors.centerIn: parent
                                    text: "Shut Down"
                                    color: "#ff7070"
                                    font.pixelSize: 11
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
        }
    }
}