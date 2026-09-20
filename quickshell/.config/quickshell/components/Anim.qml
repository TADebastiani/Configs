import QtQuick
import qs

NumberAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: Anim.DefaultSpatial

    duration: {
        if (type < Anim.StandardSmall || type > Anim.SlowEffects)
            return Config.anim.durations.normal;

        if (type === Anim.FastSpatial)
            return Config.anim.durations.expressiveFastSpatial;
        if (type === Anim.DefaultSpatial)
            return Config.anim.durations.expressiveDefaultSpatial;
        if (type === Anim.SlowSpatial)
            return Config.anim.durations.expressiveSlowSpatial;
        if (type === Anim.FastEffects)
            return Config.anim.durations.expressiveFastEffects;
        if (type === Anim.DefaultEffects)
            return Config.anim.durations.expressiveDefaultEffects;
        if (type === Anim.SlowEffects)
            return Config.anim.durations.expressiveSlowEffects;

        const types = ["small", "normal", "large", "extraLarge"];
        const idx = type % 4; // 0-7 are the 4 standard types
        return Config.anim.durations[types[idx]];
    }

    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        if (type === Anim.FastSpatial)
            return Config.anim.expressiveFastSpatial;
        if (type === Anim.DefaultSpatial)
            return Config.anim.expressiveDefaultSpatial;
        if (type === Anim.SlowSpatial)
            return Config.anim.expressiveSlowSpatial;
        if (type === Anim.FastEffects)
            return Config.anim.expressiveFastEffects;
        if (type === Anim.DefaultEffects)
            return Config.anim.expressiveDefaultEffects;
        if (type === Anim.SlowEffects)
            return Config.anim.expressiveSlowEffects;

        if (type >= Anim.EmphasizedSmall && type <= Anim.EmphasizedExtraLarge)
            return Config.anim.emphasized;
        return Config.anim.standard;
    }
}
