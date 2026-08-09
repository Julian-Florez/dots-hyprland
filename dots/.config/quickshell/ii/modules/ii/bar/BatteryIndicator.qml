import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isChargingFiltered: isCharging && Math.round(percentage * 100) < 100
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100
    readonly property bool isSaver: PowerProfiles.profile === PowerProfile.PowerSaver

    implicitWidth: batteryWidget.width
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    Item {
        id: batteryWidget
        anchors.centerIn: parent
        width: {
            if (boltIconContainer.visible) {
                return boltIconContainer.x + boltIconContainer.width;
            } else if (plusIconContainer.visible) {
                return plusIconContainer.x + plusIconContainer.width;
            } else if (nipple.visible) {
                return nipple.x + nipple.width;
            } else {
                return capsule.width;
            }
        }
        height: 18

        readonly property color highlightColor: {
            if (isChargingFiltered) {
                return "#00C853"; // Vibrant Green
            } else if (isSaver) {
                return "#FFD600"; // Vibrant Yellow
            } else if (isLow) {
                return "#FF1744"; // Vibrant Red
            } else {
                return Appearance.colors.colOnLayer0; // Matches adjacent icons!
            }
        }
        readonly property color trackColor: "#33FFFFFF"

        // Capsule (main battery body)
        Item {
            id: capsule
            width: 38
            height: 18
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            // Masked content (track + progress fill)
            Item {
                id: capsuleContent
                anchors.fill: parent
                visible: false

                // Track
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: batteryWidget.trackColor
                }

                // Fill
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * percentage
                    color: batteryWidget.highlightColor
                }
            }

            // Mask shape
            Rectangle {
                id: capsuleMask
                anchors.fill: parent
                radius: 6
                visible: false
            }

            OpacityMask {
                id: maskedCapsule
                anchors.fill: parent
                source: capsuleContent
                maskSource: capsuleMask
            }

            // Percentage text inside the capsule
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1 // Adjust down to correct font baseline offset
                text: Math.round(percentage * 100)
                font {
                    pixelSize: 14
                    family: Appearance.font.family.numbers
                    weight: Font.Bold
                }
                color: isChargingFiltered ? "#004D40" : "#1A1A1A"
            }
        }

        // Accessory 1: Battery Nipple (only shown when not charging and not in saver mode)
        Rectangle {
            id: nipple
            width: 3
            height: 6
            radius: 1
            anchors.left: capsule.right
            anchors.leftMargin: -0.5 // overlap slightly to avoid lines showing gap
            anchors.verticalCenter: capsule.verticalCenter
            color: percentage >= 0.98 ? batteryWidget.highlightColor : batteryWidget.trackColor
            visible: !isChargingFiltered && !isSaver
        }

        // Accessory 2: Plus sign for battery saver (only shown when saver mode is active and not charging)
        Item {
            id: plusIconContainer
            width: 16
            height: 16
            anchors.left: capsule.right
            anchors.leftMargin: -6
            anchors.verticalCenter: capsule.verticalCenter
            visible: isSaver && !isChargingFiltered

            // Background outlines for overlapping cutout effect (centered relative to main icon)
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: -1.8; anchors.verticalCenterOffset: -1.8 }
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: 1.8; anchors.verticalCenterOffset: -1.8 }
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: -1.8; anchors.verticalCenterOffset: 1.8 }
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: 1.8; anchors.verticalCenterOffset: 1.8 }
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: -1.8 }
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: 1.8 }
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: -1.8; anchors.verticalCenterOffset: 0 }
            MaterialSymbol { text: "add"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: plusIcon; anchors.horizontalCenterOffset: 1.8; anchors.verticalCenterOffset: 0 }

            // Main icon
            MaterialSymbol {
                id: plusIcon
                text: "add"
                fill: 1
                iconSize: 16
                color: Appearance.colors.colOnLayer0
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0.5 // Adjust down for visual centering
            }
        }

        // Accessory 3: Lightning bolt for charging (only shown when charging)
        Item {
            id: boltIconContainer
            width: 16
            height: 16
            anchors.left: capsule.right
            anchors.leftMargin: -6
            anchors.verticalCenter: capsule.verticalCenter
            visible: isChargingFiltered

            // Background outlines for overlapping cutout effect (centered relative to main icon)
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: -1.8; anchors.verticalCenterOffset: -1.8 }
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: 1.8; anchors.verticalCenterOffset: -1.8 }
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: -1.8; anchors.verticalCenterOffset: 1.8 }
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: 1.8; anchors.verticalCenterOffset: 1.8 }
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: -1.8 }
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: 0; anchors.verticalCenterOffset: 1.8 }
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: -1.8; anchors.verticalCenterOffset: 0 }
            MaterialSymbol { text: "bolt"; fill: 1; iconSize: 16; color: Appearance.colors.colLayer0; anchors.centerIn: boltIcon; anchors.horizontalCenterOffset: 1.8; anchors.verticalCenterOffset: 0 }

            // Main icon
            MaterialSymbol {
                id: boltIcon
                text: "bolt"
                fill: 1
                iconSize: 16
                color: Appearance.colors.colOnLayer0
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 0.5 // Adjust down for visual centering
            }
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}




