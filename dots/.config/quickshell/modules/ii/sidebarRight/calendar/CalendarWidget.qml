import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "calendar_layout.js" as CalendarLayout
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    
    // Width collapses if no events are scheduled for the selected day
    property bool hasEvents: {
        let selectedStr = root.dateToString(root.selectedDate);
        return root.calendarEvents.some(function(ev) {
            return ev.date === selectedStr;
        });
    }
    
    implicitWidth: hasEvents ? 460 : 300
    implicitHeight: 360

    property int monthShift: 0
    property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
    property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
    
    property var selectedDate: new Date()
    property var calendarEvents: []

    function dateToString(d) {
        let yy = d.getFullYear();
        let mm = (d.getMonth() + 1).toString().padStart(2, '0');
        let dd = d.getDate().toString().padStart(2, '0');
        return `${yy}-${mm}-${dd}`;
    }

    // Helper to compute correct date of cell (accounts for previous/next month days)
    function getCellDate(cell, viewingDate) {
        let year = viewingDate.getFullYear();
        let month = viewingDate.getMonth();
        if (cell.today === -1) {
            if (cell.day > 15) {
                month--;
                if (month < 0) { month = 11; year--; }
            } else {
                month++;
                if (month > 11) { month = 0; year++; }
            }
        }
        return new Date(year, month, cell.day);
    }

    // Load events from file
    FileView {
        id: eventsFileView
        path: Qt.resolvedUrl(Directories.calendarEventsPath)
        onLoaded: {
            try {
                root.calendarEvents = JSON.parse(eventsFileView.text());
            } catch(e) {
                root.calendarEvents = [];
            }
        }
        onLoadFailed: {
            root.calendarEvents = [];
        }
    }

    // Connect to synchronization service
    Connections {
        target: GoogleSyncService
        function onCalendarSynced() {
            print("[Calendar] Sync completed. Reloading events...")
            eventsFileView.reload();
        }
    }

    Keys.onPressed: (event) => {
        if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp)
            && event.modifiers === Qt.NoModifier) {
            if (event.key === Qt.Key_PageDown) {
                monthShift++;
            } else if (event.key === Qt.Key_PageUp) {
                monthShift--;
            }
            event.accepted = true;
        }
    }
    MouseArea {
        anchors.fill: parent
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                monthShift--;
            } else if (event.angleDelta.y < 0) {
                monthShift++;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        // LEFT COLUMN: Calendar Grid
        ColumnLayout {
            id: calendarColumn
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 5

            // Calendar header
            RowLayout {
                Layout.fillWidth: true
                spacing: 5
                CalendarHeaderButton {
                    clip: true
                    buttonText: `${monthShift != 0 ? "• " : ""}${viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
                    tooltipText: (monthShift === 0) ? "" : "Ir al mes actual"
                    downAction: () => {
                        monthShift = 0;
                    }
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                }
                CalendarHeaderButton {
                    forceCircle: true
                    downAction: () => {
                        monthShift--;
                    }
                    contentItem: MaterialSymbol {
                        text: "chevron_left"
                        iconSize: Appearance.font.pixelSize.larger
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.colors.colOnLayer1
                    }
                }
                CalendarHeaderButton {
                    forceCircle: true
                    downAction: () => {
                        monthShift++;
                    }
                    contentItem: MaterialSymbol {
                        text: "chevron_right"
                        iconSize: Appearance.font.pixelSize.larger
                        horizontalAlignment: Text.AlignHCenter
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            // Week days row
            RowLayout {
                id: weekDaysRow
                Layout.alignment: Qt.AlignHCenter
                Layout.fillHeight: false
                spacing: 5
                Repeater {
                    model: CalendarLayout.weekDays
                    delegate: CalendarDayButton {
                        day: Translation.tr(modelData.day)
                        isToday: modelData.today
                        bold: true
                        enabled: false
                    }
                }
            }

            // Real week rows
            Repeater {
                id: calendarRows
                model: 6
                delegate: RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillHeight: false
                    spacing: 5
                    Repeater {
                        model: Array(7).fill(modelData)
                        delegate: CalendarDayButton {
                            property var cell: calendarLayout[modelData][index]
                            property string cellDateStr: root.dateToString(root.getCellDate(cell, root.viewingDate))
                            day: cell.day
                            isToday: cell.today
                            selected: root.dateToString(root.selectedDate) === cellDateStr
                            hasEvents: root.calendarEvents.some(function(ev) { return ev.date === cellDateStr; })

                            downAction: () => {
                                root.selectedDate = root.getCellDate(cell, root.viewingDate);
                            }
                        }
                    }
                }
            }
        }

        // VERTICAL SEPARATOR
        Rectangle {
            Layout.fillHeight: true
            width: 1
            color: Appearance.m3colors.m3outlineVariant
            opacity: 0.5
            visible: root.hasEvents
        }

        // RIGHT COLUMN: Events List
        ColumnLayout {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            spacing: 8
            visible: root.hasEvents

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 8
                text: {
                    let d = root.selectedDate;
                    let localeStr = d.toLocaleDateString(Qt.locale(), "d 'de' MMM");
                    return "Eventos (" + localeStr + ")";
                }
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Bold
                color: Appearance.colors.colOnLayer1
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: eventsListColumn.implicitHeight + 10
                clip: true

                ColumnLayout {
                    id: eventsListColumn
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.calendarEvents.filter(function(ev) {
                            return ev.date === root.dateToString(root.selectedDate);
                        })

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: eventCol.implicitHeight + 12
                            color: Appearance.colors.colLayer2
                            radius: Appearance.rounding.verysmall

                            Rectangle {
                                width: 4
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                color: Appearance.colors.colPrimary
                                radius: 2
                            }

                            ColumnLayout {
                                id: eventCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer1
                                    wrapMode: Text.Wrap
                                }

                                StyledText {
                                    text: modelData.allDay ? "Todo el día" : `${modelData.startTime} - ${modelData.endTime}`
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        Layout.topMargin: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: "Sin eventos"
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        visible: eventsListColumn.children.length <= 1
                    }
                }
            }
        }
    }
}
