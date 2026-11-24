import QtQuick
import qs

ColorAnimation {
    duration: Config.anim.durations.expressiveSlowEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Config.anim.expressiveSlowEffects
}
