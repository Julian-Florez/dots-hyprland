pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    anchors.fill: parent

    required property int clockSecond
    readonly property real scaleFactor: parent ? parent.width / 230 : 1
    property real handWidth: 2 * scaleFactor
    property real handLength: 95 * scaleFactor
    property real dotSize: 20 * scaleFactor
    property string style: "hide"
    property color color: Appearance.colors.colSecondary
    
    rotation: (360 / 60 * clockSecond) + 90

    Behavior on rotation {
        enabled: Config.options.background.widgets.clock.cookie.constantlyRotate // Animating every second is expensive...
        animation: RotationAnimation {
            direction: RotationAnimation.Clockwise
            duration: 1000 // 1 second
            easing.type: Easing.InOutQuad
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: (10 * root.scaleFactor) + (root.style === "dot" ? root.dotSize : 0)
        }
        implicitWidth: root.style === "dot" ? root.dotSize : root.handLength
        implicitHeight: root.style === "dot" ? root.dotSize : root.handWidth
        radius: Math.min(width, height) / 2
        color: root.color
        Behavior on implicitHeight {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
    }

    // Classic style dot in the middle of the hand
    FadeLoader {
        id: classicDotLoader
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        shown: root.style === "classic"
        Rectangle {
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                leftMargin: 40 * root.scaleFactor
            }
            implicitWidth: (root.style === "classic" ? 14 : 0) * root.scaleFactor
            implicitHeight: implicitWidth
            color: root.color
            radius: Appearance.rounding.small

            Behavior on implicitWidth {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }
        }
    }
}
