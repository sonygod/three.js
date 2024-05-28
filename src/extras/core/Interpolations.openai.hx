package three.js.src.extras.core;

/**
 * Bezier Curves formulas obtained from
 * https://en.wikipedia.org/wiki/B%C3%A9zier_curve
 */

class Interpolations {
    public static function catmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
        var v0:Float = (p2 - p0) * 0.5;
        var v1:Float = (p3 - p1) * 0.5;
        var t2:Float = t * t;
        var t3:Float = t * t2;
        return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
    }

    public static function quadraticBezierP0(t:Float, p:Float):Float {
        var k:Float = 1 - t;
        return k * k * p;
    }

    public static function quadraticBezierP1(t:Float, p:Float):Float {
        return 2 * (1 - t) * t * p;
    }

    public static function quadraticBezierP2(t:Float, p:Float):Float {
        return t * t * p;
    }

    public static function quadraticBezier(t:Float, p0:Float, p1:Float, p2:Float):Float {
        return quadraticBezierP0(t, p0) + quadraticBezierP1(t, p1) + quadraticBezierP2(t, p2);
    }

    public static function cubicBezierP0(t:Float, p:Float):Float {
        var k:Float = 1 - t;
        return k * k * k * p;
    }

    public static function cubicBezierP1(t:Float, p:Float):Float {
        var k:Float = 1 - t;
        return 3 * k * k * t * p;
    }

    public static function cubicBezierP2(t:Float, p:Float):Float {
        return 3 * (1 - t) * t * t * p;
    }

    public static function cubicBezierP3(t:Float, p:Float):Float {
        return t * t * t * p;
    }

    public static function cubicBezier(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
        return cubicBezierP0(t, p0) + cubicBezierP1(t, p1) + cubicBezierP2(t, p2) + cubicBezierP3(t, p3);
    }
}