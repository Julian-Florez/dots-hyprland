import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

Item {
    id: root
    required property real value
    required property string icon
    required property string name
    property bool rotateIcon: false
    property bool scaleIcon: false
    property real from: 0
    property real to: 1
    property bool showMixerButton: false

    // Dynamic reference to focused screen's brightness monitor
    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    // Derived property to check active state (e.g. not muted for volume)
    property bool isActive: {
        if (root.name === Translation.tr("Volume")) {
            return !(Audio.sink?.audio.muted ?? false);
        }
        return true;
    }

    implicitWidth: 56 + 2 * Appearance.sizes.elevationMargin
    implicitHeight: (showMixerButton ? 292 : 244) + 2 * Appearance.sizes.elevationMargin

    StyledRectangularShadow {
        target: valueIndicator
    }

    Rectangle {
        id: valueIndicator
        anchors {
            fill: parent
            margins: Appearance.sizes.elevationMargin
        }
        radius: width / 2
        color: Appearance.m3colors.m3surfaceContainer // Dark brown background

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Top Button (Speaker/Brightness level indicator)
            Rectangle {
                id: topButton
                width: 40
                height: 40
                radius: 20
                color: root.isActive ? Appearance.m3colors.m3primary : Appearance.m3colors.m3surfaceContainerLowest

                MaterialSymbol {
                    anchors.centerIn: parent
                    color: root.isActive ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3primary
                    text: root.icon
                    iconSize: 20
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.name === Translation.tr("Volume")) {
                            if (Audio.sink?.audio) {
                                Audio.sink.audio.muted = !Audio.sink.audio.muted;
                            }
                        }
                    }
                }
            }

            // Middle Slider Track
            Rectangle {
                id: sliderTrack
                width: 40
                height: 180
                radius: 20
                color: Appearance.m3colors.m3surfaceContainerLowest
                clip: true

                // Active Fill
                Rectangle {
                    id: sliderFill
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: parent.height * Math.min(Math.max((root.value - root.from) / (root.to - root.from), 0), 1)
                    color: Appearance.m3colors.m3primary
                }

                // Interactive MouseArea for dragging
                MouseArea {
                    id: sliderMouseArea
                    anchors.fill: parent
                    preventStealing: true

                    function updateValue(mouseY) {
                        var ratio = 1 - (mouseY / height);
                        var clampedRatio = Math.min(Math.max(ratio, 0), 1);
                        var newValue = root.from + clampedRatio * (root.to - root.from);

                        if (root.name === Translation.tr("Volume")) {
                            if (Audio.sink?.audio) {
                                Audio.sink.audio.volume = newValue;
                            }
                        } else if (root.name === Translation.tr("Brightness")) {
                            if (root.brightnessMonitor) {
                                if (typeof root.brightnessMonitor.setBrightness === "function") {
                                    root.brightnessMonitor.setBrightness(newValue);
                                } else {
                                    root.brightnessMonitor.brightness = newValue;
                                }
                            }
                        } else if (root.name === Translation.tr("Gamma")) {
                            Hyprsunset.setGamma(newValue * 100);
                        }
                    }

                    onPressed: (mouse) => updateValue(mouse.y)
                    onPositionChanged: (mouse) => updateValue(mouse.y)
                }
            }

            // Bottom Button (Sound Mixer)
            Rectangle {
                id: bottomButton
                width: 40
                height: 40
                radius: 20
                visible: root.showMixerButton
                color: Appearance.m3colors.m3surfaceContainerLowest

                MaterialSymbol {
                    anchors.centerIn: parent
                    color: Appearance.m3colors.m3primary
                    text: "tune"
                    iconSize: 20
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Quickshell.execDetached(["bash", "-c", Config.options.apps.volumeMixer]);
                        GlobalStates.osdVolumeOpen = false;
                    }
                }
            }
        }
    }
}
