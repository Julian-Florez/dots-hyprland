import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.ii.onScreenDisplay

OsdValueIndicator {
    id: root
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    icon: {
        var val = root.brightnessMonitor?.brightness ?? 0.5;
        if (val < 0.33) {
            return "brightness_low";
        } else if (val < 0.66) {
            return "brightness_medium";
        } else {
            return "brightness_high";
        }
    }
    rotateIcon: false
    scaleIcon: false
    name: Translation.tr("Brightness")
    value: root.brightnessMonitor?.brightness ?? 0.5
}
