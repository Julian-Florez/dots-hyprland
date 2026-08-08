import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

RippleButton {
    id: button
    property string day
    property int isToday
    property bool bold
    property bool hasEvents: false
    property bool selected: false

    Layout.fillWidth: false
    Layout.fillHeight: false
    implicitWidth: 38; 
    implicitHeight: 38;

    toggled: (isToday === 1) || selected
    buttonRadius: Appearance.rounding.small
    
    contentItem: StyledText {
        anchors.fill: parent
        text: day
        horizontalAlignment: Text.AlignHCenter
        font.weight: bold ? Font.DemiBold : Font.Normal
        color: button.toggled ? Appearance.m3colors.m3onPrimary : 
            (isToday === -1) ? Appearance.colors.colOutlineVariant : 
            Appearance.colors.colOnLayer1

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    Rectangle {
        width: 4
        height: 4
        radius: 2
        color: button.toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colPrimary
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        visible: button.hasEvents
    }
}
