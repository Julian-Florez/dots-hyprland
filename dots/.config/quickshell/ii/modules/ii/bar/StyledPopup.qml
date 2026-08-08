import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

LazyLoader {
    id: root

    // hoverTarget: if set, popup opens when mouse is over this item
    property Item hoverTarget
    // anchorTarget: item used for positioning the popup (falls back to hoverTarget)
    property Item anchorTarget
    default property Item contentItem
    property real popupBackgroundMargin: 0
    property bool popupOpen: false

    // Opens when explicitly toggled OR when hovering over hoverTarget
    active: popupOpen || (hoverTarget && hoverTarget.containsMouse)

    component: PanelWindow {
        id: popupWindow
        color: "transparent"

        WlrLayershell.keyboardFocus: root.popupOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Local focus grab to close popup when clicking outside
        HyprlandFocusGrab {
            id: focusGrab
            active: root.popupOpen
            windows: {
                let target = root.anchorTarget ?? root.hoverTarget;
                let targetWindow = target?.QsWindow?.window;
                return targetWindow ? [popupWindow, targetWindow] : [popupWindow];
            }
            onCleared: {
                root.popupOpen = false;
            }
        }

        anchors.left: !Config.options.bar.vertical || (Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.right: Config.options.bar.vertical && Config.options.bar.bottom
        anchors.top: Config.options.bar.vertical || (!Config.options.bar.vertical && !Config.options.bar.bottom)
        anchors.bottom: !Config.options.bar.vertical && Config.options.bar.bottom

        implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin
        implicitHeight: popupBackground.implicitHeight + Appearance.sizes.elevationMargin * 2 + root.popupBackgroundMargin

        mask: Region {
            item: popupBackground
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        margins {
            left: {
                if (!Config.options.bar.vertical) {
                    // Use anchorTarget if set, otherwise fall back to hoverTarget
                    let anchor = root.anchorTarget ?? root.hoverTarget;
                    if (!anchor) return 0;
                    // Center popup under the anchor item
                    let rawX = root.QsWindow?.mapFromItem(
                        anchor,
                        (anchor.width - popupBackground.implicitWidth) / 2, 0
                    ).x ?? 0;
                    // Clamp so popup never goes off screen
                    let screenW = root.QsWindow?.window?.screen?.width ?? 1920;
                    let totalPopupW = popupBackground.implicitWidth
                        + Appearance.sizes.elevationMargin * 2
                        + root.popupBackgroundMargin;
                    return Math.max(0, Math.min(rawX, screenW - totalPopupW - 4));
                }
                return Appearance.sizes.verticalBarWidth;
            }
            top: {
                if (!Config.options.bar.vertical) return Appearance.sizes.barHeight;
                let anchor = root.anchorTarget ?? root.hoverTarget;
                if (!anchor) return 0;
                return root.QsWindow?.mapFromItem(
                    anchor,
                    (anchor.height - popupBackground.implicitHeight) / 2, 0
                ).y ?? 0;
            }
            right: Appearance.sizes.verticalBarWidth
            bottom: Appearance.sizes.barHeight
        }

        WlrLayershell.namespace: "quickshell:popup"
        WlrLayershell.layer: WlrLayer.Overlay

        StyledRectangularShadow {
            target: popupBackground
        }

        Rectangle {
            id: popupBackground
            readonly property real margin: 10
            anchors {
                fill: parent
                leftMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.left)
                rightMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.right)
                topMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.top)
                bottomMargin: Appearance.sizes.elevationMargin + root.popupBackgroundMargin * (!popupWindow.anchors.bottom)
            }
            implicitWidth: root.contentItem.implicitWidth + margin * 2
            implicitHeight: root.contentItem.implicitHeight + margin * 2
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.small
            children: [root.contentItem]

            border.width: 1
            border.color: Appearance.colors.colLayer0Border
        }
    }
}
