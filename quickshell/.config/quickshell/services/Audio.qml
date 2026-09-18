pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    function refreshNodes(): void{
        const newSinks = [];
        const newSources = [];
        const newStreams = [];

        for (const node of Pipewire.nodes.values) {
            if (node.isStream && node.audio) {
                newStreams.push(node);
                continue;
            }

            if (!node.isStream) {
                if (node.isSink) {
                    newSinks.push(node);
                    continue;
                }
                if (node.audio) {
                    newSources.push(node);
                    continue;
                }
                continue;
            }
        }

        root.sinks = newSinks;
        root.sources = newSources;
        root.streams = newStreams;
    }

    Component.onCompleted: {
        refreshNodes();
        previousSinkName = sink?.description || sink?.name || qsTr("Dispositivo desconhecido");
        previousSourceName = source?.description || source?.name || qsTr("Dispositivo desconhecido");
    }

    Connections {
        target: Pipewire.nodes
        onTargetChanged: {
            root.refreshNodes();
        }
    }

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources, ...root.streams].filter(n => n)
    }

}
