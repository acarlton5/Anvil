import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool overlayActive: Quickshell.env("ANVIL_OVERLAY_TEST") === "1"
    property bool gamerActive: Quickshell.env("ANVIL_OVERLAY_TEST") !== "1"
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
        gameProcess.command = [gameSessionScript, "run", "--name", gameName || "", "--game-id", gameId || "", "--input-profile", inputProfile || "", "--input-map", inputMap || "", "--input-actions", inputActions || "", "--controller-layout", controllerLayout || "", "--achievement-set", achievementSet || "", "--achievements-url", achievementsUrl, "--", command];
        gameProcess.running = true;
        // Hide Anvil AFTER 4 seconds to show the loading screen transition!
        hideAnvilTimer.start();
    }

    function killGame() {
        hideAnvilTimer.stop();
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
        if (action === "guide") {
            root.overlayActive = !root.overlayActive;
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

    Timer {
        id: hideAnvilTimer

        interval: 4000
        onTriggered: root.gamerActive = false
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

    IpcHandler {
        function toggle() {
            root.overlayActive = !root.overlayActive;
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

        onRunningChanged: {
            if (!running) {
                hideAnvilTimer.stop();
                root.gamerActive = true;
                root.overlayActive = false;
            }
        }
    }

    Process {
        id: killProcess
    }

}
