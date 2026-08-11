import qs
import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    // Reactively watch and load Matugen colors
    QtObject {
        id: m3Colors
        property color background: "#1c110b"
        property color surface_container: "#291d16"
        property color on_surface: "#f5ded3"
        property color primary_container: "#fd791a"
        property color on_primary_container: "#250b00"
    }

    FileView {
        id: colorsLoader
        path: "file:///home/julian/.local/state/quickshell/user/generated/colors.json"
        watchChanges: true

        function parseColors(fileContent) {
            try {
                const json = JSON.parse(fileContent);
                m3Colors.background = json["background"] || m3Colors.background;
                m3Colors.surface_container = json["surface_container"] || m3Colors.surface_container;
                m3Colors.on_surface = json["on_surface"] || m3Colors.on_surface;
                m3Colors.primary_container = json["primary_container"] || m3Colors.primary_container;
                m3Colors.on_primary_container = json["on_primary_container"] || m3Colors.on_primary_container;
            } catch (e) {
                console.error("[KeyIndicator] Failed to parse colors.json:", e);
            }
        }

        onLoadedChanged: {
            if (loaded) {
                parseColors(text());
            }
        }

        onFileChanged: {
            this.reload();
        }
    }

    // List of active indicators to display
    ListModel {
        id: indicatorList
    }

    // Timers mapped by indicator name to trigger fading out
    property var activeTimers: ({})

    function showIndicator(name, state) {
        const active = (state === "true" || state === true || state === 1 || state === "1");
        let icon = "";
        let label = "";

        switch (name) {
        case "capslock":
            icon = "keyboard_capslock";
            label = "Caps Lock";
            break;
        case "numlock":
            icon = "dialpad";
            label = "Num Lock";
            break;
        case "scrolllock":
            icon = "keyboard_tab";
            label = "Scroll Lock";
            break;
        case "touchpad":
            icon = active ? "touchpad" : "touchpad_off";
            label = "Touchpad";
            break;
        case "micmute":
            icon = active ? "mic_off" : "mic"; // active means muted
            label = "Microphone";
            break;
        case "dnd":
            icon = active ? "notifications_paused" : "notifications";
            label = "Do Not Disturb";
            break;
        case "hotspot":
            icon = active ? "wifi_tethering" : "wifi_tethering_off";
            label = "Hotspot";
            break;
        }

        // Find existing indicator or add new one
        let found = false;
        for (let i = 0; i < indicatorList.count; i++) {
            let item = indicatorList.get(i);
            if (item.name === name) {
                indicatorList.setProperty(i, "active", active);
                indicatorList.setProperty(i, "icon", icon);
                indicatorList.setProperty(i, "label", label);
                indicatorList.setProperty(i, "visible", true);
                found = true;
                break;
            }
        }

        if (!found) {
            indicatorList.append({
                                     "name": name,
                                     "icon": icon,
                                     "label": label,
                                     "active": active,
                                     "visible": true
                                 });
        }

        // Auto-dismiss after 2 seconds
        if (activeTimers[name]) {
            activeTimers[name].restart();
        } else {
            let timer = Qt.createQmlObject("import QtQuick; Timer { interval: 2000; repeat: false }", root);
            timer.triggered.connect(function () {
                for (let i = 0; i < indicatorList.count; i++) {
                    if (indicatorList.get(i).name === name) {
                        indicatorList.setProperty(i, "visible", false);
                        break;
                    }
                }
            });
            activeTimers[name] = timer;
            timer.start();
        }
    }

    // IPC Interface so external key hooks can send updates
    IpcHandler {
        target: "keyIndicator"

        function showIndicator(name, state) {
            root.showIndicator(name, state);
        }
    }

    // Listen directly to internal Notifications DND (silent) state changes
    Connections {
        target: Notifications
        function onSilentChanged() {
            root.showIndicator("dnd", Notifications.silent);
        }
    }

    PanelWindow {
        id: indicatorWindow

        // Show window if any indicator is currently visible
        visible: {
            for (let i = 0; i < indicatorList.count; i++) {
                if (indicatorList.get(i).visible)
                    return true;
            }
            return false;
        }

        anchors {
            right: true
            verticalCenter: true
        }

        margins {
            right: 24
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: 80
        implicitHeight: mainColumn.implicitHeight

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.namespace: "quickshell:keyIndicator"
        WlrLayershell.layer: WlrLayer.Overlay

        ColumnLayout {
            id: mainColumn
            spacing: 8
            anchors.fill: parent

            Repeater {
                model: indicatorList
                delegate: Rectangle {
                    id: indicatorCard
                    required property string name
                    required property string icon
                    required property string label
                    required property bool active
                    required property bool visible

                    implicitWidth: 56
                    implicitHeight: 56
                    radius: 28 // Circle

                    color: active ? m3Colors.primary_container : m3Colors.surface_container
                    border.color: m3Colors.background
                    border.width: 3

                    // Entry/exit animations
                    opacity: visible ? 1.0 : 0.0
                    scale: visible ? 1.0 : 0.8

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                    }

                    Layout.preferredWidth: visible ? 56 : 0
                    Layout.preferredHeight: visible ? 56 : 0
                    Layout.alignment: Qt.AlignHCenter
                    visible: opacity > 0.01

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: indicatorCard.icon
                        iconSize: 24
                        color: indicatorCard.active ? m3Colors.on_primary_container : m3Colors.on_surface
                    }
                }
            }
        }
    }
}
