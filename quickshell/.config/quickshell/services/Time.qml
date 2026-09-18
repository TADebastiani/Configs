pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string dateStr: clock.dateStr
    readonly property string timeStr: clock.timeStr
    readonly property list<string> timeComponents: timeStr.split(":")
    readonly property string hourStr: timeComponents[0] ?? ""
    readonly property string minuteStr: timeComponents[1] ?? ""
    readonly property string secondStr: timeComponents[2] ?? ""

    Timer {
        id: clock

        property string dateStr: new Date().toLocaleString(Qt.locale("pt_BR"), "ddd dd MMM")
        property string timeStr: new Date().toLocaleString(Qt.locale("pt_BR"), "HH:mm")

        interval: 1000
        running: true
        repeat: true

        onTriggered: {
            const newDate = new Date();
            dateStr = newDate.toLocaleString(Qt.locale("pt_BR"), "ddd dd MMM");
            timeStr = newDate.toLocaleString(Qt.locale("pt_BR"), "HH:mm");
        }
    }
}
