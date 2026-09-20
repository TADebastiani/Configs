import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs

Rectangle {
    id: volPill
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted
    property bool showOSD: false

    // Keeps defaultAudioSink's `audio` sub-object bindings live.
    PwObjectTracker {
        objects: volPill.sink ? [volPill.sink] : []
    }

    Connections {
        target: volPill.vol

        function onVolChanged() {
            volPill.showOSD = true;
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: volPill.showOSD = false
    }

    LazyLoader {
        active: volPill.showOSD

        PanelWindow {
            anchors {
                bottom: true
            }
            margins.bottom: Theme.barHeight / 5

            exclusiveZone: 0

            implicitHeight: 50
            implicitWidth: 400
            color: "transparent"

            mask: Region {}

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#1e1e2e"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 15
                    }

                    IconImage {
                        implicitSize: 30
                        source: Quickshell.iconPath("audio-volume-high")
                    }

                    Rectangle {
                        // Stretches to fill all left-over space
                        Layout.fillWidth: true

                        implicitHeight: 10
                        radius: 20
                        color: "#50cdd6f4"

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            color: "#cdd6f4"
                            implicitWidth: parent.width * (volPill.vol ?? 0)
                            radius: parent.radius
                        }
                    }
                }
            }
        }
    }

    implicitWidth: volRow.implicitWidth + 16
    implicitHeight: 22
    radius: Theme.pillRadius
    color: volMa.containsMouse ? Theme.surface1 : Theme.surface0

    RowLayout {
        id: volRow
        anchors.centerIn: parent
        spacing: 4

        IconImage {
            readonly property var volume: Math.round(volPill.vol * 100)

            implicitSize: 18
            source: volPill.muted ? Quickshell.iconPath("audio-volume-muted") : volume < 33 ? Quickshell.iconPath("audio-volume-low") : volume < 66 ? Quickshell.iconPath("audio-volume-medium") : Quickshell.iconPath("audio-volume-high")
        }
    }

    MouseArea {
        id: volMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: volPopup.visible = !volPopup.visible
    }

    // --- Volume popup -------------------------------------------
    PopupWindow {
        id: volPopup
        visible: false
        grabFocus: true
        color: "transparent"
        implicitWidth: 200
        implicitHeight: 96

        anchor {
            item: volPill
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
            margins.top: 6
        }

        onClosed: visible = false

        Rectangle {
            anchors.fill: parent
            radius: Theme.pillRadius
            color: Theme.surface0
            border.color: Theme.surface1
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: volPill.muted ? "Muted" : Math.round(volPill.vol * 100) + "%"
                        font.pixelSize: Config.font.size.small
                        color: Theme.text
                    }

                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 6
                        color: muteMa.containsMouse ? Theme.surface2 : Theme.surface1

                        Text {
                            anchors.centerIn: parent
                            text: volPill.muted ? "🔇" : "🔊"
                            font.pixelSize: Config.font.size.small - 2
                        }

                        MouseArea {
                            id: muteMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (volPill.sink && volPill.sink.audio)
                                    volPill.sink.audio.muted = !volPill.sink.audio.muted;
                            }
                        }
                    }
                }

                Rectangle {
                    id: sliderTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Theme.surface1

                    Rectangle {
                        width: sliderTrack.width * Math.max(0, Math.min(1, volPill.vol))
                        height: parent.height
                        radius: 4
                        color: Theme.mauve
                    }

                    MouseArea {
                        id: sliderMa
                        anchors.fill: parent

                        function setVolumeFromX(x) {
                            if (!volPill.sink || !volPill.sink.audio)
                                return;
                            volPill.sink.audio.volume = Math.max(0, Math.min(1, x / width));
                        }

                        onPressed: mouse => setVolumeFromX(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                setVolumeFromX(mouse.x);
                        }
                    }
                }
            }
        }
    }
}
