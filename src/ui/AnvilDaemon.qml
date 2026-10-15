import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool overlayActive: Quickshell.env("ANVIL_OVERLAY_TEST") === "1"
    property bool gamerActive: Quickshell.env("ANVIL_OVERLAY_TEST") !== "1"
    property bool waitingForGameWindow: false
    property string controllerAction: ""
    property int controllerActionSerial: 0
    property string controllerFamily: "xbox"
    property string controllerName: "Controller"
    readonly property string anvilRoot: Quickshell.env("ANVIL_ROOT") || "/usr/local/share/anvil"
    readonly property string gameSessionScript: anvilRoot + "/scripts/anvil-game-session"
    readonly property string controllerNavScript: anvilRoot + "/scripts/anvil-controller-nav-watch"
    readonly property string achievementsUrl: Quickshell.env("ANVIL_ACHIEVEMENTS_URL") || Quickshell.env("FORGEWORKS_ACHIEVEMENTS_URL") || ""

    function startGame(command, gameName, gameId, inputProfile, inputMap, inputActions, controllerLayout, achievementSet) {
        console.log("Root starting game: " + command);
        root.waitingForGameWindow = true;
        root.gamerActive = true;
        gameWindowTimeoutTimer.restart();
        gameProcess.command = [gameSessionScript, "run", "--name", gameName || "", "--game-id", gameId || "", "--input-profile", inputProfile || "", "--input-map", inputMap || "", "--input-actions", inputActions || "", "--controller-layout", controllerLayout || "", "--achievement-set", achievementSet || "", "--achievements-url", achievementsUrl, "--", command];
        gameProcess.running = true;
    }

    function killGame() {
        root.waitingForGameWindow = false;
        gameWindowTimeoutTimer.stop();
        hideAnvilDelayTimer.stop();
        root.gamerActive = true;
        killProcess.command = [gameSessionScript, "stop"];
        killProcess.running = true;
        root.overlayActive = false;
    }

    function navigate(action, family, name) {
        if (family && family.length > 0)
            root.controllerFamily = family;
        if (name && name.length > 0)
            root.controllerName = name;
        if (!action || action.length === 0)
            return ;
        if (action === "guide") {
            root.overlayActive = !root.overlayActive;
            return ;
        }
        if (action === "quickaccess") {
            root.quickAccessActive = !root.quickAccessActive;
            return ;
        }
        if (action === "keyboard") {
            root.keyboardActive = !root.keyboardActive;
            return ;
        }
        root.controllerAction = action;
        root.controllerActionSerial += 1;
    }

    PanelWindow {
        implicitWidth: 1
        implicitHeight: 1
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "keepalive"
    }

    Process {
        id: clientCheckProcess
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.waitingForGameWindow || !text || text.trim().length === 0)
                    return;
                try {
                    let clients = JSON.parse(text);
                    if (Array.isArray(clients)) {
                        for (let i = 0; i < clients.length; i++) {
                            let c = clients[i];
                            if (c && c.mapped && !c.hidden && c.visible && c.initialClass !== "keepalive") {
                                console.log("[Anvil] Detected mapped game client window: " + (c.title || c.class));
                                root.waitingForGameWindow = false;
                                gameWindowTimeoutTimer.stop();
                                hideAnvilDelayTimer.restart();
                                return;
                            }
                        }
                    }
                } catch (e) {
                    console.log("[Anvil] Error checking clients: " + e);
                }
            }
        }
    }

    Timer {
        id: gameWindowPollTimer
        interval: 350
        repeat: true
        running: root.waitingForGameWindow
        onTriggered: {
            if (!clientCheckProcess.running) {
                clientCheckProcess.running = true;
            }
        }
    }

    Timer {
        id: hideAnvilDelayTimer
        interval: 600
        repeat: false
        onTriggered: {
            root.gamerActive = false;
        }
    }

    Timer {
        id: gameWindowTimeoutTimer
        interval: 45000
        repeat: false
        onTriggered: {
            if (root.waitingForGameWindow) {
                console.log("[Anvil] Game window detection timed out, hiding launcher");
                root.waitingForGameWindow = false;
                root.gamerActive = false;
            }
        }
    }

    Component {
        id: gamerComponent

        Variants {
            model: Quickshell.screens

            AnvilLauncher {
                controllerAction: root.controllerAction
                controllerActionSerial: root.controllerActionSerial
                controllerFamily: root.controllerFamily
                controllerName: root.controllerName
                launchHandler: function(command, game) {
                    root.startGame(command, game ? game.name : "", game ? game.forgeworks_app_id : "", game ? game.input_profile : "", game ? game.input_map : "", game ? game.input_actions : "", game ? game.controller_layout : "", game ? game.achievement_set : "");
                }
                cancelLaunchHandler: function() {
                    root.killGame();
                }
            }

        }

    }

    Loader {
        active: root.gamerActive
        sourceComponent: gamerComponent
    }

    Component {
        id: overlayComponent

        Variants {
            model: Quickshell.screens

            AnvilOverlay {
                controllerAction: root.controllerAction
                controllerActionSerial: root.controllerActionSerial
                controllerFamily: root.controllerFamily
                controllerName: root.controllerName
                closeHandler: function() {
                    root.overlayActive = false;
                }
                killHandler: function() {
                    root.killGame();
                }
            }

        }

    }

    Loader {
        active: root.overlayActive
        sourceComponent: overlayComponent
    }

    property bool quickAccessActive: false
    property bool keyboardActive: false

    Component {
        id: volumeOsdComponent

        Variants {
            model: Quickshell.screens

            AnvilVolumeOSD {
                modelData: screen
            }
        }
    }

    Loader {
        active: true
        sourceComponent: volumeOsdComponent
    }

    Component {
        id: quickAccessComponent

        Variants {
            model: Quickshell.screens

            AnvilQuickAccess {
                modelData: screen
                isVisible: root.quickAccessActive
                onRequestKeyboardToggle: {
                    root.keyboardActive = !root.keyboardActive;
                }
                onRequestClose: {
                    root.quickAccessActive = false;
                }
            }
        }
    }

    Loader {
        active: root.quickAccessActive
        sourceComponent: quickAccessComponent
    }

    Component {
        id: keyboardComponent

        Variants {
            model: Quickshell.screens

            AnvilKeyboard {
                modelData: screen
                isVisible: root.keyboardActive
                onDismissed: {
                    root.keyboardActive = false;
                }
            }
        }
    }

    Loader {
        active: root.keyboardActive
        sourceComponent: keyboardComponent
    }

    IpcHandler {
        function toggle() {
            root.overlayActive = !root.overlayActive;
        }

        function toggleQuickAccess() {
            root.quickAccessActive = !root.quickAccessActive;
        }

        function toggleKeyboard() {
            root.keyboardActive = !root.keyboardActive;
        }

        function launch(command: string) {
            root.startGame(command, "", "", "", "", "", "", "");
        }

        function kill() {
            root.killGame();
        }

        function navigate(action: string, family: string, name: string) {
            root.navigate(action, family, name);
        }

        target: "anvil"
    }

    Process {
        id: controllerNavProcess

        command: ["env", "ANVIL_ROOT=" + anvilRoot, "python3", controllerNavScript]
        running: true
    }

    Process {
        id: gameProcess

        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0)
                    console.log("[Anvil Game stdout]: " + text);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length > 0)
                    console.log("[Anvil Game stderr]: " + text);
            }
        }

        onExited: function(exitCode) {
            console.log("[Anvil Game Process exited with code]: " + exitCode);
        }

        onRunningChanged: {
            if (!running) {
                root.waitingForGameWindow = false;
                gameWindowTimeoutTimer.stop();
                hideAnvilDelayTimer.stop();
                root.gamerActive = true;
                root.overlayActive = false;
            }
        }
    }

    Process {
        id: killProcess
    }

}
