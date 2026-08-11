import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import Quickshell
import Quickshell.Io

QuickToggleModel {
    id: rootToggle
    name: Translation.tr("Hotspot")
    statusText: toggled ? Translation.tr("On") : Translation.tr("Off")
    tooltipText: Translation.tr("Wifi Hotspot")
    icon: "wifi_tethering"

    property bool activeState: false
    toggled: activeState

    // Every 3 seconds, poll the status of the connection
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: checkStatusProc.running = true
    }

    Process {
        id: checkStatusProc
        command: ["sh", "-c", "nmcli -t -f NAME,DEVICE connection show --active | grep -q '^Hotspot:'"]
        onExited: exitCode => {
            const newState = (exitCode === 0);
            if (rootToggle.activeState !== newState) {
                rootToggle.activeState = newState;
            }
        }
    }

    Process {
        id: toggleActionProc
        command: rootToggle.activeState ? ["nmcli", "connection", "down", "Hotspot"] : ["nmcli", "connection",
                                                                                        "up", "Hotspot"]
        onExited: exitCode => {
            checkStatusProc.running = true;
        }
    }

    mainAction: () => {
        toggleActionProc.running = true;
    }
}
