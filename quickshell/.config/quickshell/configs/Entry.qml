import QtQuick

QtObject {
    required property string entryId;
    readonly property string id: entryId;
    readonly property bool enabled: true
}
