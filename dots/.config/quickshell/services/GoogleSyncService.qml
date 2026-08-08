pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services

Singleton {
    id: root

    signal calendarSynced()
    signal tasksSynced()

    property bool isSyncing: tasksSyncProc.running || calSyncProc.running

    function sync() {
        if (isSyncing) return;
        print("[GoogleSync] Triggering sync...")
        tasksSyncProc.running = true
    }

    Timer {
        id: syncTimer
        interval: 300000 // 5 minutes by default
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            root.sync()
        }
    }

    // Speed up sync interval when the clock popup is open, restore when closed
    Connections {
        target: GlobalStates
        function onTodoPopupOpenChanged() {
            if (GlobalStates.todoPopupOpen) {
                print("[GoogleSync] Todo popup opened. Speeding up sync interval to 15s...")
                syncTimer.interval = 15000
                root.sync() // sync immediately on open
            } else {
                print("[GoogleSync] Todo popup closed. Restoring sync interval to 5m...")
                syncTimer.interval = 300000
            }
        }
    }

    // Trigger sync immediately on local task modifications (add, delete, mark done)
    Connections {
        target: Todo
        function onListChanged() {
            if (Todo.localChange) {
                print("[GoogleSync] Local Todo modification detected. Syncing immediately...")
                Todo.localChange = false // Reset flag immediately
                root.sync()
            }
        }
    }

    Process {
        id: tasksSyncProc
        command: ["/run/current-system/sw/bin/python3", "/home/julian/.config/quickshell/ii/scripts/google_tasks_sync.py"]
        onExited: (exitCode, exitStatus) => {
            print("[GoogleSync] Tasks sync finished with code: " + exitCode)
            root.tasksSynced()
            
            // Reload local todo list
            try {
                Todo.refresh();
            } catch(e) {
                print("[GoogleSync] Error reloading Todo service: " + e)
            }
            
            // Trigger calendar sync next
            calSyncProc.running = true
        }
    }

    Process {
        id: calSyncProc
        command: ["/run/current-system/sw/bin/python3", "/home/julian/.config/quickshell/ii/scripts/google_calendar_sync.py"]
        onExited: (exitCode, exitStatus) => {
            print("[GoogleSync] Calendar sync finished with code: " + exitCode)
            root.calendarSynced()
        }
    }

    Component.onCompleted: {
        // Run initial sync shortly after startup
        startupTimer.start()
    }

    Timer {
        id: startupTimer
        interval: 3000
        repeat: false
        onTriggered: root.sync()
    }
}
