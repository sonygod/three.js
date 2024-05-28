/**
 * Bezier Curves formulas obtained from
 * https://en.wikipedia.org/wiki/B%C3%A9zier_curve
 */

function catmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
    var v0 = (p2 - p0) / 2.;
    var v1 = (p3 - p1) / 2.;
    var t2 = t * t;
    var t3 = t * t2;
    return (2. * p1 - 2. * p2 + v0 + v1) * t3 + (-3. * p1 + 3. * p2 - 2. * v0 - v1) * t2 + v0 * t + p1;
}

function quadraticBezierP0(t:Float, p:Float):Float {
    var k = 1. - t;
    return k * k * p;
}

function quadraticBezierP1(t:Float, p:Float):Float {
    return 2. * (1. - t) * t * p;
}

function quadraticBezierP2(t:Float, p:Float):Float {
    return t * t * p;
}

function quadraticBezier(t:Float, p0:Float, p1:Float, p2:Float):Float {
    return quadraticBezierP0(t, p0) + quadraticBezierP1(t, p1) + quadraticBezierP2(t, p2);
}

function cubicBezierP0(t:Float, p:Float):Float {
    var k = 1. - t;
    return k * k * k * p;
}

function cubicBezierP1(t:Float, p:Float):Float {
    var k = 1. - t;
    return 3. * k * k * t * p;
}

function cubicBezierP2(t:Float, p:Float):Float {
    return 3. * (1. - t) * t * t * p;
}

function cubicBezierP3(t:Float, p:Float):Float {
    return t * t * t * p;
}

function cubicBezier(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
    return cubicBezierP0(t, p0) + cubicBezierP1(t, p1) + cubicBezierP2(t, p2) + cubicBezierP3(t, p3);
}

class BezierFormulas {
    public static function catmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
        return catmullRom(t, p0, p1, p2, p3);
    }

    public static function quadraticBezier(t:Float, p0:Float, p1:Float, p2:Float):Float {
        return quadraticBezier(t, p0, p1, p2);
    }

    public static function cubicBezier(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
        return cubicBezier(t, p0, p1, p2, p3);
    }
}