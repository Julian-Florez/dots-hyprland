import "../../../../"
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property bool showAddDialog: false
    property var selectedDays: [] // 0-6 (Sunday is 0, Monday is 1, etc.)
    property string newLabel: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        visible: !AlarmService.isRinging


        // List
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: alarmsListColumn.implicitHeight + 80
            clip: true

            Column {
                id: alarmsListColumn
                width: parent.width
                spacing: 12
                padding: 10

                Repeater {
                    model: AlarmService.list
                    delegate: Rectangle {
                        id: alarmCard
                        width: parent.width - 20
                        height: cardLayout.implicitHeight + 24
                        color: modelData.enabled ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                        radius: Appearance.rounding.normal

                        RowLayout {
                            id: cardRow
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            ColumnLayout {
                                id: cardLayout
                                Layout.fillWidth: true
                                spacing: 4

                                // Days and optional label
                                RowLayout {
                                    spacing: 8
                                    StyledText {
                                        text: {
                                            if (modelData.days.length === 0) return "Una vez";
                                            if (modelData.days.length === 7) return "Todos los días";
                                            let monToFri = [1, 2, 3, 4, 5];
                                            let isMonToFri = modelData.days.length === 5 && modelData.days.every(d => monToFri.indexOf(d) !== -1);
                                            if (isMonToFri) return "Lun-vie";
                                            let dayNames = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"];
                                            return modelData.days.map(d => dayNames[d]).join(", ");
                                        }
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        color: modelData.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                                    }

                                    StyledText {
                                        text: modelData.label || ""
                                        font.pixelSize: 12
                                        color: modelData.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colSubtext
                                        opacity: 0.8
                                        visible: text.length > 0
                                    }
                                }

                                // Huge Time with AM/PM
                                StyledText {
                                    text: {
                                        let parts = modelData.time.split(":");
                                        let hh = parseInt(parts[0]);
                                        let mm = parts[1];
                                        let ampm = hh >= 12 ? "p. m." : "a. m.";
                                        let hh12 = hh % 12;
                                        if (hh12 === 0) hh12 = 12;
                                        return `${hh12}:${mm} ${ampm}`;
                                    }
                                    font.pixelSize: 32
                                    font.weight: Font.DemiBold
                                    color: modelData.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                                }
                            }

                            // Custom switch replicating the M3/Google Clock style
                            Switch {
                                id: alarmSwitch
                                checked: modelData.enabled
                                onCheckedChanged: {
                                    if (modelData.enabled !== checked) {
                                        AlarmService.toggleAlarm(modelData.id);
                                    }
                                }
                                Layout.alignment: Qt.AlignVCenter
                                implicitWidth: 56
                                implicitHeight: 30
                                padding: 0
                                topPadding: 0
                                bottomPadding: 0
                                leftPadding: 0
                                rightPadding: 0

                                indicator: Rectangle {
                                    implicitWidth: 56
                                    implicitHeight: 30
                                    radius: 15
                                    color: alarmSwitch.checked ? 
                                           (modelData.enabled ? "#2c1e13" : Appearance.colors.colPrimary) : 
                                           "#3c3024"
                                    
                                    border.width: alarmSwitch.checked ? 0 : 2
                                    border.color: "#4a3e32"

                                    Rectangle {
                                        x: alarmSwitch.checked ? 30 : 4
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: alarmSwitch.checked ? 
                                               (modelData.enabled ? Appearance.colors.colPrimary : Appearance.m3colors.m3onPrimary) : 
                                               "#4a3e32"
                                        
                                        Behavior on x {
                                            NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                                        }
                                    }
                                }
                            }

                            // Small Delete Trash Button on the side
                            RippleButton {
                                implicitWidth: 32
                                implicitHeight: 32
                                Layout.alignment: Qt.AlignVCenter
                                buttonRadius: Appearance.rounding.full
                                colBackground: "transparent"
                                onClicked: AlarmService.deleteAlarm(modelData.id)
                                
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    iconSize: 18
                                    color: modelData.enabled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Shadow & Google clock styled FAB identical to tasks
    StyledRectangularShadow {
        target: fabButton
        radius: fabButton.buttonRadius
        blur: 0.6 * Appearance.sizes.elevationMargin
        z: 99
    }

    FloatingActionButton {
        id: fabButton
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        z: 100

        onClicked: {
            root.showAddDialog = true;
            root.selectedDays = [];
            root.newLabel = "";
            hoursInput.text = new Date().getHours().toString().padStart(2, '0');
            minutesInput.text = new Date().getMinutes().toString().padStart(2, '0');
        }
        iconText: "add"
    }

    // Add Alarm Dialog overlay
    Item {
        anchors.fill: parent
        z: 9999
        visible: root.showAddDialog

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colScrim
            MouseArea { anchors.fill: parent; preventStealing: true }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 40
            implicitHeight: dialogLayout.implicitHeight + 30
            color: Appearance.m3colors.m3surfaceContainerHigh
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: dialogLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                StyledText {
                    text: "Nueva Alarma"
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Bold
                    color: Appearance.m3colors.m3onSurface
                }

                // Time selector
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8

                    TextField {
                        id: hoursInput
                        implicitWidth: 60
                        horizontalAlignment: TextInput.AlignHCenter
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        validator: IntValidator { bottom: 0; top: 23 }
                        color: Appearance.m3colors.m3onSurface
                        background: Rectangle {
                            color: Appearance.colors.colLayer2
                            radius: Appearance.rounding.verysmall
                        }
                    }

                    StyledText {
                        text: ":"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: Appearance.m3colors.m3onSurface
                    }

                    TextField {
                        id: minutesInput
                        implicitWidth: 60
                        horizontalAlignment: TextInput.AlignHCenter
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        validator: IntValidator { bottom: 0; top: 59 }
                        color: Appearance.m3colors.m3onSurface
                        background: Rectangle {
                            color: Appearance.colors.colLayer2
                            radius: Appearance.rounding.verysmall
                        }
                    }
                }

                // Label field
                TextField {
                    id: labelInput
                    Layout.fillWidth: true
                    placeholderText: "Etiqueta (ej. Despertar)"
                    placeholderTextColor: Appearance.m3colors.m3outline
                    color: Appearance.m3colors.m3onSurface
                    background: Rectangle {
                        color: Appearance.colors.colLayer2
                        radius: Appearance.rounding.verysmall
                    }
                }

                // Repeat Days Selection Row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    Repeater {
                        model: [
                            {"val": 1, "lbl": "L"},
                            {"val": 2, "lbl": "M"},
                            {"val": 3, "lbl": "X"},
                            {"val": 4, "lbl": "J"},
                            {"val": 5, "lbl": "V"},
                            {"val": 6, "lbl": "S"},
                            {"val": 0, "lbl": "D"}
                        ]

                        delegate: Rectangle {
                            implicitWidth: 26
                            implicitHeight: 26
                            radius: width / 2
                            color: root.selectedDays.indexOf(modelData.val) !== -1 ? Appearance.colors.colPrimary : Appearance.colors.colLayer2
                            border.width: 1
                            border.color: root.selectedDays.indexOf(modelData.val) !== -1 ? "transparent" : Appearance.m3colors.m3outline

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.lbl
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                color: root.selectedDays.indexOf(modelData.val) !== -1 ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    let idx = root.selectedDays.indexOf(modelData.val);
                                    if (idx === -1) {
                                        root.selectedDays.push(modelData.val);
                                    } else {
                                        root.selectedDays.splice(idx, 1);
                                    }
                                    root.selectedDays = root.selectedDays.slice(0); // Trigger binding update
                                }
                            }
                        }
                    }
                }

                // Dialog Buttons
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    DialogButton {
                        buttonText: "Cancelar"
                        onClicked: root.showAddDialog = false
                    }

                    DialogButton {
                        buttonText: "Guardar"
                        enabled: hoursInput.text.length > 0 && minutesInput.text.length > 0
                        onClicked: {
                            let hh = hoursInput.text.padStart(2, '0');
                            let mm = minutesInput.text.padStart(2, '0');
                            AlarmService.addAlarm(`${hh}:${mm}`, labelInput.text, root.selectedDays);
                            root.showAddDialog = false;
                        }
                    }
                }
            }
        }
    }

    // Ringing Overlay Screen
    Rectangle {
        anchors.fill: parent
        z: 10000
        visible: AlarmService.isRinging
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.normal

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 24

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                text: "alarm"
                iconSize: 64
                color: Appearance.colors.colPrimary
                
                SequentialAnimation on rotation {
                    loops: Animation.Infinite
                    running: AlarmService.isRinging
                    NumberAnimation { from: -10; to: 10; duration: 100 }
                    NumberAnimation { from: 10; to: -10; duration: 100 }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 4

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Sonando..."
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: AlarmService.ringingLabel
                    font.pixelSize: 24
                    font.weight: Font.Bold
                    color: Appearance.m3colors.m3onSurface
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 16

                RippleButton {
                    implicitWidth: 100
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colSecondaryContainer
                    colBackgroundHover: Appearance.colors.colSecondaryContainer
                    onClicked: AlarmService.snoozeAlarm()
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: "Posponer"
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSecondaryContainer
                    }
                }

                RippleButton {
                    implicitWidth: 100
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: Appearance.colors.colErrorContainer
                    onClicked: AlarmService.dismissAlarm()
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: "Descartar"
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnErrorContainer
                    }
                }
            }
        }
    }
}
