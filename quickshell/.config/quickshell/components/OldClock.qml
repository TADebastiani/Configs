import QtQuick
import QtQuick.Layouts
import qs

Text {
    id: clock
    Layout.leftMargin: 4
    text: new Date().toLocaleString(Qt.locale("pt_BR"), "ddd dd MMM  HH:mm")
    font.pixelSize: Theme.fontSize
    font.bold: true
    color: Theme.lavender

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.text = new Date().toLocaleString(Qt.locale("pt_BR"), "ddd dd MMM  HH:mm")
    }
}
