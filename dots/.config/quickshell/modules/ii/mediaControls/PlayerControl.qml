pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.services
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item { // Player instance
    id: root
    required property MprisPlayer player
    property var artUrl: player?.trackArtUrl
    property string artDownloadLocation: Directories.coverArt
    property string artFileName: Qt.md5(artUrl)
    property string artFilePath: `${artDownloadLocation}/${artFileName}`
    // Keep the palette tied to the cover art; use a neutral fallback while
    // the downloaded image is being quantized.
    property color artDominantColor: "#202020"
    property bool downloaded: false
    property list<real> visualizerPoints: []
    property real maxVisualizerValue: 1000 // Max value in the data points
    property int visualizerSmoothing: 2 // Number of points to average for smoothing
    property real radius
    property bool pinned: true
    signal closeRequested()
    signal dragRequested(real dx, real dy)

    property string displayedArtFilePath: root.downloaded ? Qt.resolvedUrl(artFilePath) : ""

    component TrackChangeButton: RippleButton {
        implicitWidth: 24
        implicitHeight: 24

        property var iconName
        colBackground: ColorUtils.transparentize(blendedColors.colSecondaryContainer, 1)
        colBackgroundHover: blendedColors.colSecondaryContainerHover
        colRipple: blendedColors.colSecondaryContainerActive

        contentItem: MaterialSymbol {
            iconSize: Appearance.font.pixelSize.huge
            fill: 1
            horizontalAlignment: Text.AlignHCenter
            color: blendedColors.colOnSecondaryContainer
            text: iconName

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    Timer { // Force update for revision
        running: root.player?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: {
            root.player.positionChanged()
        }
    }

    onArtFilePathChanged: {
        if (root.artUrl.length == 0) {
            root.artDominantColor = "#202020"
            return;
        }

        // Binding does not work in Process
        coverArtDownloader.targetFile = root.artUrl 
        coverArtDownloader.artFilePath = root.artFilePath
        // Download
        root.artDominantColor = "#202020"
        root.downloaded = false
        coverArtDownloader.running = true
    }

    Process { // Cover art downloader
        id: coverArtDownloader
        property string targetFile: root.artUrl
        property string artFilePath: root.artFilePath
        command: [ "bash", "-c", `[ -f ${artFilePath} ] || curl -4 -sSL '${targetFile}' -o '${artFilePath}'` ]
        onExited: (exitCode, exitStatus) => {
            root.downloaded = true
        }
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 3 // Keep several representative colors from the cover.
        rescaleSize: 32
        onColorsChanged: root.updateArtPalette()
    }

    function updateArtPalette() {
        if (colorQuantizer.colors.length > 0) {
            const sampled = Qt.color(colorQuantizer.colors[0]);
            const hue = sampled.hslHue >= 0 ? sampled.hslHue : 0;
            const saturation = Math.min(1, Math.max(0.55, sampled.hslSaturation * 1.35));
            const lightness = Math.min(0.68, Math.max(0.42, sampled.hslLightness + 0.08));
            root.artDominantColor = Qt.hsla(hue, saturation, lightness, sampled.a);
        }
    }

    Component.onCompleted: root.updateArtPalette()

    // A small palette derived directly from the cover art. This intentionally
    // avoids the global Material You palette for this player.
    property QtObject blendedColors: QtObject {
        readonly property color colLayer0: ColorUtils.colorWithLightness(root.artDominantColor, 0.14)
        readonly property color colOnLayer0: ColorUtils.colorWithLightness(root.artDominantColor, 0.92)
        readonly property color colSubtext: ColorUtils.colorWithLightness(root.artDominantColor, 0.72)
        readonly property color colPrimary: ColorUtils.colorWithLightness(root.artDominantColor, 0.78)
        readonly property color colPrimaryHover: ColorUtils.colorWithLightness(root.artDominantColor, 0.86)
        readonly property color colPrimaryActive: ColorUtils.colorWithLightness(root.artDominantColor, 0.68)
        readonly property color colSecondaryContainer: ColorUtils.colorWithLightness(root.artDominantColor, 0.28)
        readonly property color colSecondaryContainerHover: ColorUtils.colorWithLightness(root.artDominantColor, 0.36)
        readonly property color colSecondaryContainerActive: ColorUtils.colorWithLightness(root.artDominantColor, 0.22)
        readonly property color colOnPrimary: ColorUtils.colorWithLightness(root.artDominantColor, 0.08)
        readonly property color colOnSecondaryContainer: ColorUtils.colorWithLightness(root.artDominantColor, 0.88)
    }

    StyledRectangularShadow {
        target: background
    }
    Rectangle { // Background
        id: background
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: ColorUtils.applyAlpha(blendedColors.colLayer0, 1)
        radius: root.radius

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: background.width
                height: background.height
                radius: background.radius
            }
        }

        StyledImage {
            id: blurredArt
            anchors.fill: parent
            source: root.displayedArtFilePath
            fillMode: Image.PreserveAspectCrop
            cache: false
            antialiasing: true
            asynchronous: true

            layer.enabled: true
            layer.effect: StyledBlurEffect {
                source: blurredArt
            }

            Rectangle {
                anchors.fill: parent
                // Keep the cover visible across the whole card while darkening
                // it enough for the controls to remain readable.
                color: Qt.rgba(0, 0, 0, 0.5)
                radius: root.radius
            }
        }

        Item {
            id: dragHandle
            z: 10
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 42
            DragHandler {
                id: dragHandler
                target: null
                acceptedButtons: Qt.LeftButton
                property real lastX: 0
                property real lastY: 0

                function globalPointerPosition() {
                    // Convert the pointer to screen coordinates before asking
                    // the window to move.  Local coordinates shift whenever
                    // the panel moves, which makes the drag lag behind.
                    return dragHandle.mapToGlobal(centroid.position);
                }

                onActiveChanged: {
                    if (active) {
                        const point = globalPointerPosition();
                        lastX = point.x;
                        lastY = point.y;
                    }
                }

                onCentroidChanged: {
                    if (!active)
                        return;
                    const point = globalPointerPosition();
                    const dx = point.x - lastX;
                    const dy = point.y - lastY;
                    lastX = point.x;
                    lastY = point.y;
                    if (dx !== 0 || dy !== 0)
                        root.dragRequested(dx, dy);
                }
            }

            RippleButton {
                id: closeButton
                anchors {
                    top: parent.top
                    right: parent.right
                    topMargin: 5
                    rightMargin: 5
                }
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: blendedColors.colPrimary
                colBackgroundHover: blendedColors.colPrimaryHover
                colRipple: blendedColors.colPrimaryActive
                onClicked: root.closeRequested()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: Appearance.font.pixelSize.large
                    fill: 1
                    text: "close"
                    color: blendedColors.colOnPrimary
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.topMargin: 13
            anchors.bottomMargin: 13
            anchors.leftMargin: 13
            anchors.rightMargin: 13
            spacing: 15

            ColumnLayout { // Info & controls
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                Item { Layout.fillHeight: true }

                StyledText {
                    id: trackTitle
                    Layout.fillWidth: true
                    Layout.leftMargin: 0
                    Layout.rightMargin: 76
                    transform: Translate {
                        y: 14
                    }
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Bold
                    color: blendedColors.colOnLayer0
                    elide: Text.ElideRight
                    text: StringUtils.cleanMusicTitle(root.player?.trackTitle) || "Untitled"
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }
                StyledText {
                    id: trackArtist
                    Layout.fillWidth: true
                    Layout.leftMargin: 0
                    Layout.rightMargin: 76
                    transform: Translate {
                        y: 14
                    }
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: blendedColors.colSubtext
                    elide: Text.ElideRight
                    text: root.player?.trackArtist
                    animateChange: true
                    animationDistanceX: 6
                    animationDistanceY: 0
                }
                Item { Layout.fillHeight: true }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: sliderRow.implicitHeight
                    RowLayout {
                        id: sliderRow
                        anchors {
                            bottom: parent.bottom
                            left: parent.left
                            right: parent.right
                        }
                        TrackChangeButton {
                            iconName: "skip_previous"
                            downAction: () => root.player?.previous()
                        }
                        Item {
                            id: progressBarContainer
                            Layout.fillWidth: true
                            implicitHeight: Math.max(sliderLoader.implicitHeight, progressBarLoader.implicitHeight)

                            Loader {
                                id: sliderLoader
                                anchors.fill: parent
                                active: root.player?.canSeek ?? false
                                sourceComponent: StyledSlider { 
                                    configuration: StyledSlider.Configuration.Wavy
                                    wavy: true
                                    waveAmplitudeMultiplier: root.player?.isPlaying ? 0.5 : 0
                                    Behavior on waveAmplitudeMultiplier {
                                        NumberAnimation {
                                            duration: Appearance.animation.elementMoveFast.duration
                                            easing.type: Appearance.animation.elementMoveFast.type
                                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                        }
                                    }
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    handleColor: blendedColors.colPrimary
                                    value: root.player?.position / root.player?.length
                                    onMoved: {
                                        root.player.position = value * root.player.length;
                                    }
                                }
                            }

                            Loader {
                                id: progressBarLoader
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    left: parent.left
                                    right: parent.right
                                }
                                active: !(root.player?.canSeek ?? false)
                                sourceComponent: StyledProgressBar { 
                                    wavy: true
                                    waveAmplitudeMultiplier: root.player?.isPlaying ? 0.5 : 0
                                    highlightColor: blendedColors.colPrimary
                                    trackColor: blendedColors.colSecondaryContainer
                                    value: root.player?.position / root.player?.length
                                }
                            }

                            
                        }
                        TrackChangeButton {
                            iconName: "skip_next"
                            downAction: () => root.player?.next()
                        }
                    }

                }

            }
        }
        RippleButton {
            id: playPauseButton
            anchors.right: parent.right
            anchors.rightMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            property real size: 64
            implicitWidth: size
            implicitHeight: size
            downAction: () => root.player.togglePlaying();

            buttonRadius: root.player?.isPlaying ? Appearance?.rounding.normal : size / 2
            colBackground: root.player?.isPlaying ? blendedColors.colPrimary : blendedColors.colSecondaryContainer
            colBackgroundHover: root.player?.isPlaying ? blendedColors.colPrimaryHover : blendedColors.colSecondaryContainerHover
            colRipple: root.player?.isPlaying ? blendedColors.colPrimaryActive : blendedColors.colSecondaryContainerActive

            contentItem: MaterialSymbol {
                iconSize: Appearance.font.pixelSize.huge
                fill: 1
                horizontalAlignment: Text.AlignHCenter
                color: root.player?.isPlaying ? blendedColors.colOnPrimary : blendedColors.colOnSecondaryContainer
                text: root.player?.isPlaying ? "pause" : "play_arrow"

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }
    }
}
