import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.sidebarRight
import QtQuick
import QtQuick.Layouts
import Quickshell

StyledPopup {
    id: root

    BottomWidgetGroup {
        implicitWidth: (selectedTab === 0 && loadedItem && loadedItem.hasEvents) ? 630 : 450
        implicitHeight: 420
        collapsed: false

        Connections {
            target: AlarmService
            function onTriggerOpenAlarmsChanged() {
                if (AlarmService.triggerOpenAlarms) {
                    root.popupOpen = true
                    Persistent.states.sidebar.bottomGroup.tab = 4
                    AlarmService.triggerOpenAlarms = false
                }
            }
        }
    }
}
