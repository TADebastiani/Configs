import QtQuick

// Material 3 easing curves, as QEasingCurve::BezierSpline control points
// (groups of 6 = 2 control points + 1 endpoint per segment).
// Use them as:
//   easing.type: Easing.BezierSpline
//   easing.bezierCurve: Config.anim.standard
QtObject {
    readonly property AnimDurations durations: AnimDurations {}

    readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
    readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
    readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
    readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
    readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property list<real> expressiveSlowSpatial: [0.39, 1.29, 0.35, 0.98, 1, 1]
    readonly property list<real> expressiveFastEffects: [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property list<real> expressiveDefaultEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property list<real> expressiveSlowEffects: [0.34, 0.88, 0.34, 1, 1, 1]
}
