import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool showToast: false
    property string clipboardType: "" // "text" or "image"
    property string clipboardText: ""
    property string imageSource: ""

    // Prevent toast from popping up immediately upon startup
    property bool isReady: false

    Timer {
        id: startupTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: root.isReady = true
    }

    // Reactively watch and load Matugen colors from generated colors.json
    QtObject {
        id: m3Colors
        property color background: "#1c110b"
        property color surface_container: "#291d16"
        property color on_surface: "#f5ded3"
        property color primary_container: "#fd791a"
        property color on_primary_container: "#250b00"
        property color outline_variant: "#584236"
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
                m3Colors.outline_variant = json["outline_variant"] || m3Colors.outline_variant;
            } catch (e) {
                console.error("[ClipboardToast] Failed to parse colors.json:", e);
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

    // Persistent clipboard change detector
    Process {
        id: clipboardWatcher
        running: true
        command: ["wl-paste", "--watch", "sh", "-c",
            "wl-paste -l | grep -qE 'image/png|image/jpeg' && echo IMAGE || echo TEXT"]

        stdout: SplitParser {
            onRead: line => {
                if (!root.isReady)
                    return;
                const type = line.trim();
                if (type === "IMAGE") {
                    saveImageProcess.running = true;
                } else if (type === "TEXT") {
                    readTextProcess.running = true;
                }
            }
        }
    }

    // Image preview extractor (one-shot, query MIME types to grab browser images correctly)
    Process {
        id: saveImageProcess
        command: ["bash", "-c", "
            types=$(wl-paste -l 2>/dev/null)
            if echo \"$types\" | grep -q 'image/png'; then
                wl-paste -t image/png > /tmp/qs_clipboard_preview.png 2>/dev/null
            elif echo \"$types\" | grep -q 'image/jpeg'; then
                wl-paste -t image/jpeg > /tmp/qs_clipboard_preview.png 2>/dev/null
            else
                img_type=$(echo \"$types\" | grep 'image/' | head -n 1)
                if [ ! -z \"$img_type\" ]; then
                    wl-paste -t \"$img_type\" > /tmp/qs_clipboard_preview.png 2>/dev/null
                else
                    exit 1
                fi
            fi
        "]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.clipboardType = "image";
                root.imageSource = "file:///tmp/qs_clipboard_preview.png?t=" + Date.now();
                root.showToast = true;
                dismissTimer.restart();
            } else {
                console.error("[ClipboardToast] Failed to save image from clipboard.");
            }
        }
    }

    // Text content extractor (one-shot, safely capped to avoid freezes)
    Process {
        id: readTextProcess
        command: ["bash", "-c", "wl-paste -n | head -c 1000"]
        stdout: StdioCollector {
            id: textCollector
            onStreamFinished: {
                root.clipboardType = "text";
                root.clipboardText = textCollector.text;
                root.showToast = true;
                dismissTimer.restart();
            }
        }
    }

    // 5-second automatic dismiss timer
    Timer {
        id: dismissTimer
        interval: 5000
        repeat: false
        onTriggered: {
            root.showToast = false;
        }
    }

    PanelWindow {
        id: toastWindow
        visible: root.showToast || contentCard.opacity > 0.01

        anchors {
            bottom: true
            left: true
        }

        margins {
            bottom: 24
            left: 24
        }

        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        color: "transparent"

        implicitWidth: contentCard.implicitWidth + 32
        implicitHeight: contentCard.implicitHeight + 32

        // Define bounding region covering both the pill card and the 8px top protrusion
        mask: Region {
            item: maskItem
        }

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

        WlrLayershell.namespace: "quickshell:clipboardToast"
        WlrLayershell.layer: WlrLayer.Overlay

        // Bounding helper for window click mask
        Item {
            id: maskItem
            x: contentCard.x
            y: contentCard.y - 8
            width: contentCard.width
            height: contentCard.height + 8
        }

        // Subtle rectangular shadow following the card animation
        StyledRectangularShadow {
            target: contentCard
        }

        Rectangle {
            id: contentCard
            implicitWidth: (root.clipboardType === "image" ? 80 : 180)
                           + 112 // Dynamic layout width calculation

            implicitHeight: 48 // Lowered outer pill height (borderless)
            radius: 20 // Lowered outer capsule rounded corners
            color: m3Colors.surface_container
            border.width: 0 // Removed outer border
            clip: false // Crucial to let child preview box protrude above top

            // Vertical slide and fade-in animations on entry/exit
            opacity: root.showToast ? 1 : 0
            y: root.showToast ? 16 : 56

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutBack
                }
            }

            // Pause auto-dismiss timer on hover, restart on exit
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    dismissTimer.stop();
                }
                onExited: {
                    dismissTimer.restart();
                }
            }

            // LEFT SIDE: Text preview container (solid orange accent, 12px rounded corners, protrudes 8px at the top)
            Rectangle {
                id: textPreviewBox
                visible: root.clipboardType === "text"
                width: 180
                height: 56
                radius: 12 // Lowered rounded corners
                color: m3Colors.primary_container // Accent orange background
                border.color: m3Colors.surface_container
                border.width: 3 // Thicker border (3px)
                clip: true

                anchors {
                    left: parent.left
                    leftMargin: 8
                    bottom: parent.bottom
                    bottomMargin: 0
                }

                StyledText {
                    anchors.fill: parent
                    anchors.margins: 8
                    text: root.clipboardText
                    color: m3Colors.on_primary_container // Accent text color
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    font.family: Appearance.font.family.main
                    font.weight: Font.Medium
                    wrapMode: Text.WrapAnywhere
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // LEFT SIDE: Image preview container (12px rounded corners, protrudes 8px at the top)
            Rectangle {
                id: imagePreviewBox
                visible: root.clipboardType === "image"
                width: 80
                height: 56
                radius: 12 // Lowered rounded corners
                color: m3Colors.background
                border.color: m3Colors.surface_container
                border.width: 3 // Thicker border (3px)

                anchors {
                    left: parent.left
                    leftMargin: 8
                    bottom: parent.bottom
                    bottomMargin: 0
                }

                // Inner container to cleanly clip the image to the border boundary using OpacityMask
                Rectangle {
                    id: imageInnerContainer
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    radius: parent.radius - parent.border.width
                    clip: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageInnerContainer.width
                            height: imageInnerContainer.height
                            radius: imageInnerContainer.radius
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: root.imageSource
                        fillMode: Image.PreserveAspectCrop // Aspect crop for beautiful thumbnail look
                        cache: false
                        asynchronous: true
                    }
                }
            }

            // RIGHT SIDE: Action Buttons (centered vertically inside capsule)
            RowLayout {
                id: buttonsRow
                spacing: 8

                anchors {
                    right: parent.right
                    rightMargin: 8
                    verticalCenter: parent.verticalCenter
                }

                // History Popover Button (triggers native Quickshell overlay)
                Rectangle {
                    id: historyBtn
                    width: 38
                    height: 38
                    radius: 19
                    color: m3Colors.primary_container // Accent orange background

                    scale: historyMouse.containsMouse ? 1.08 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                    }

                    opacity: historyMouse.pressed ? 0.8 : 1.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "history"
                        iconSize: 20
                        color: m3Colors.on_primary_container
                    }

                    MouseArea {
                        id: historyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["quickshell", "-c", "ii", "ipc", "call", "search",
                                                     "clipboardToggle"]);
                            root.showToast = false;
                        }
                    }
                }

                // Close Button
                Rectangle {
                    id: closeBtn
                    width: 38
                    height: 38
                    radius: 19
                    color: m3Colors.primary_container // Accent orange background

                    scale: closeMouse.containsMouse ? 1.08 : 1.0
                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                    }

                    opacity: closeMouse.pressed ? 0.8 : 1.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 20
                        color: m3Colors.on_primary_container
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showToast = false;
                        }
                    }
                }
            }
        }
    }
}
