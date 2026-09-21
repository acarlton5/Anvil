import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property bool overlayActive: Quickshell.env("ANVIL_OVERLAY_TEST") === "1"
    property bool gamerActive: Quickshell.env("ANVIL_OVERLAY_TEST") !== "1"

    function startGame(command) {
        console.log("Root starting game: " + command);
        gameProcess.command = ["bash", "-c", command];
        gameProcess.running = true;
        // Hide Anvil AFTER 4 seconds to show the loading screen transition!
        hideAnvilTimer.start();
    }

    function killGame() {
        killProcess.running = true;
        root.overlayActive = false;
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
            root.startGame(command);
        }

        target: "anvil"
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

        command: ["killall", "anvil-proton-run"]
    }

}
