pragma Singleton
pragma ComponentBehavior: Bound

import "../"
import qs.modules.common
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string filePath: Directories.alarmsPath
    property var list: []
    property bool isRinging: false
    property string ringingLabel: ""
    property string ringingAlarmId: ""
    property bool triggerOpenAlarms: false

    function saveAlarms() {
        alarmsFileView.setText(JSON.stringify(root.list));
    }

    function addAlarm(timeStr, labelStr, daysArray) {
        let idStr = Date.now().toString();
        root.list.push({
            "id": idStr,
            "time": timeStr, // "HH:MM"
            "label": labelStr,
            "enabled": true,
            "days": daysArray // [0,1,2,3,4,5,6] (0 = Sunday, 1 = Monday...)
        });
        root.list = root.list.slice(0); // Trigger binding update
        saveAlarms();
    }

    function toggleAlarm(id) {
        for (let i = 0; i < root.list.length; i++) {
            if (root.list[i].id === id) {
                root.list[i].enabled = !root.list[i].enabled;
                break;
            }
        }
        root.list = root.list.slice(0);
        saveAlarms();
    }

    function deleteAlarm(id) {
        for (let i = 0; i < root.list.length; i++) {
            if (root.list[i].id === id) {
                root.list.splice(i, 1);
                break;
            }
        }
        root.list = root.list.slice(0);
        saveAlarms();
    }

    function dismissAlarm() {
        // Auto-disable one-time alarms (no repeat days)
        if (root.ringingAlarmId !== "") {
            for (let i = 0; i < root.list.length; i++) {
                if (root.list[i].id === root.ringingAlarmId && root.list[i].days.length === 0) {
                    root.list[i].enabled = false;
                    root.list = root.list.slice(0);
                    saveAlarms();
                    break;
                }
            }
        }
        root.isRinging = false;
        root.ringingLabel = "";
        root.ringingAlarmId = "";
        ringingTimer.running = false;
    }

    function snoozeAlarm() {
        let now = new Date();
        now.setMinutes(now.getMinutes() + 5);
        let snoozeTimeStr = now.getHours().toString().padStart(2, '0') + ":" + now.getMinutes().toString().padStart(2, '0');
        addAlarm(snoozeTimeStr, root.ringingLabel + " (Snoozed)", [now.getDay()]);
        dismissAlarm();
    }

    property var lastCheckedMinute: -1

    Timer {
        id: alarmCheckTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            let now = new Date();
            let currentMinute = now.getMinutes();
            if (currentMinute === lastCheckedMinute) return;
            
            let currentHourStr = now.getHours().toString().padStart(2, '0');
            let currentMinStr = currentMinute.toString().padStart(2, '0');
            let currentTimeStr = `${currentHourStr}:${currentMinStr}`;
            let currentDay = now.getDay();

            for (let i = 0; i < root.list.length; i++) {
                let alarm = root.list[i];
                if (alarm.enabled && alarm.time === currentTimeStr) {
                    if (alarm.days.length === 0 || alarm.days.indexOf(currentDay) !== -1) {
                        triggerAlarm(alarm);
                    }
                }
            }
            lastCheckedMinute = currentMinute;
        }
    }

    function triggerAlarm(alarm) {
        root.isRinging = true;
        root.ringingLabel = alarm.label || "Alarm";
        root.ringingAlarmId = alarm.id;
        ringingTimer.running = true;
        root.triggerOpenAlarms = true;
        
        Quickshell.execDetached(["notify-send", "⏰ ALARMA", root.ringingLabel, "-a", "Shell", "-u", "critical"]);
    }

    Timer {
        id: ringingTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: {
            if (Config.options.sounds.pomodoro) {
                Audio.playSystemSound("alarm-clock-elapsed");
            }
        }
    }

    FileView {
        id: alarmsFileView
        path: Qt.resolvedUrl(root.filePath)
        onLoaded: {
            try {
                root.list = JSON.parse(alarmsFileView.text());
            } catch(e) {
                root.list = [];
            }
        }
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                root.list = [];
                alarmsFileView.setText(JSON.stringify(root.list));
            }
        }
    }
}
