import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasMedia: activePlayer !== null && !!activePlayer.trackTitle

    Layout.fillHeight: true
    implicitWidth: mediaPill.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }

    Rectangle {
        id: mediaPill
        anchors.centerIn: parent
        implicitWidth: 112
        implicitHeight: 26
        radius: height / 2
        // Solid shades derived from the current dynamic accent.
        color: Appearance.colors.colOnPrimary

        Rectangle {
            id: artwork
            anchors {
                left: parent.left
                leftMargin: 3
                verticalCenter: parent.verticalCenter
            }
            width: 20
            height: 20
            radius: width / 2
            clip: true
            color: Appearance.colors.colPrimary
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: artwork.width
                    height: artwork.height
                    radius: width / 2
                }
            }

            StyledImage {
                anchors.fill: parent
                source: root.activePlayer?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: !root.activePlayer?.trackArtUrl
                text: "music_note"
                iconSize: 14
                color: Appearance.colors.colOnPrimary
            }
        }

        Rectangle {
            id: progressTrack
            anchors {
                left: artwork.right
                leftMargin: 7
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            height: 6
            radius: 9999
            color: Appearance.colors.colLayer2Hover

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.activePlayer?.length > 0 ? root.activePlayer.position / root.activePlayer.length : 0))
                height: parent.height
                radius: 9999
                color: Appearance.colors.colPrimary
            }
        }
    }

}
