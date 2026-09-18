pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.services

Item {
    id: root

    property real volume
    property bool muted
    property real sourceVolume
    property bool sourceMuted

    function show(): void {
        timer.restart();
    }

    Component.onCompleted: {
        volume = Audio.volume;
        muted = Audio.muted;
        sourceVolume = Audio.sourceVolume;
        sourceMuted = Audio.sourceMuted;
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.show()
            root.volume = Audio.volume
        }
    }

    Timer {
        id: timer
        interval: 1000
        onTriggered: {
            root.visible = false
        }
    }

    Loader {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        asynchronous: true
        active: root.visible

        sourceComponent: Text {
            text: "Volume: " + root.volume
        }
    }
}
