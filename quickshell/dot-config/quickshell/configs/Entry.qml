import QtQuick

QtObject {
    required property string entryId;
    readonly property string id: entryId;
    property bool enabled: true
}
