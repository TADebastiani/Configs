import QtQuick

QtObject {
    readonly property int minThickness: 2
    readonly property int thickness: 10
    readonly property int rounding: 25
    readonly property int smoothing: 20

    function clampedThickness(): int {
        return Math.max(minThickness, thickness);
    }
}
