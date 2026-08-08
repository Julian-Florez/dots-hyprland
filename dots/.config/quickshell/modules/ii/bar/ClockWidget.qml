import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool showDate: true
    implicitWidth: rowLayout.implicitWidth + 8
    implicitHeight: Appearance.sizes.barHeight

    // 12h time without AM/PM
    property string customTimeVal: {
        let d = new Date();
        let h = d.getHours() % 12 || 12;
        let m = d.getMinutes().toString().padStart(2, "0");
        return h + ":" + m;
    }
    // Date: "Mar, 28 de jul"
    property string customDateVal: {
        let d = new Date();
        let day = Qt.locale("es_MX").dayName(d.getDay(), Locale.ShortFormat).replace(/\.$/, "");
        day = day.charAt(0).toUpperCase() + day.slice(1);
        let dd = d.getDate().toString().padStart(2, "0");
        let month = Qt.locale("es_MX").monthName(d.getMonth(), Locale.ShortFormat).replace(/\.$/, "");
        return day + ", " + dd + " de " + month;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let d = new Date();
            let h = d.getHours() % 12 || 12;
            let m = d.getMinutes().toString().padStart(2, "0");
            root.customTimeVal = h + ":" + m;
            let day = Qt.locale("es_MX").dayName(d.getDay(), Locale.ShortFormat).replace(/\.$/, "");
            day = day.charAt(0).toUpperCase() + day.slice(1);
            let dd = d.getDate().toString().padStart(2, "0");
            let month = Qt.locale("es_MX").monthName(d.getMonth(), Locale.ShortFormat).replace(/\.$/, "");
            root.customDateVal = day + ", " + dd + " de " + month;
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: false
        onClicked: {
            clockPopup.popupOpen = !clockPopup.popupOpen;
        }
    }

    RowLayout {
        id: rowLayout
        anchors {
            left: parent.left
            leftMargin: 4
            verticalCenter: parent.verticalCenter
        }
        spacing: 12

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: root.customTimeVal
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            text: root.customDateVal
        }
    }

    ClockWidgetPopup {
        id: clockPopup
        hoverTarget: null       // no hover-to-open
        anchorTarget: mouseArea // position relative to clock

        onPopupOpenChanged: {
            GlobalStates.todoPopupOpen = popupOpen;
        }
    }
}
