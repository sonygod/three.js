class Interpolations {
    public static function bezierCatmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
        var v0:Float = (p2 - p0) * 0.5;
        var v1:Float = (p3 - p1) * 0.5;
        var t2:Float = t * t;
        var t3:Float = t * t2;
        return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
    }
    
    public static function bezierQuadraticP0(t:Float, p:Float):Float {
        var k:Float = 1 - t;
        return k * k * p;
    }
    
    public static function bezierQuadraticP1(t:Float, p:Float):Float {
        return 2 * (1 - t) * t * p;
    }
    
    public static function bezierQuadraticP2(t:Float, p:Float):Float {
        return t * t * p;
    }
    
    public static function bezierQuadratic(t:Float, p0:Float, p1:Float, p2:Float):Float {
        return bezierQuadraticP0(t, p0) + bezierQuadraticP1(t, p1) + bezierQuadraticP2(t, p2);
    }
    
    public static function bezierCubicP0(t:Float, p:Float):Float {
        var k:Float = 1 - t;
        return k * k * k * p;
    }
    
    public static function bezierCubicP1(t:Float, p:Float):Float {
        var k:Float = 1 - t;
        return 3 * k * k * t * p;
    }
    
    public static function bezierCubicP2(t:Float, p:Float):Float {
        return 3 * (1 - t) * t * t * p;
    }
    
    public static function bezierCubicP3(t:Float, p:Float):Float {
        return t * t * t * p;
    }
    
    public static function bezierCubic(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
        return bezierCubicP0(t, p0) + bezierCubicP1(t, p1) + bezierCubicP2(t, p2) + bezierCubicP3(t, p3);
    }
}

typedef Interpolations = {
    static function catmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float;
    static function quadraticBezier(t:Float, p0:Float, p1:Float, p2:Float):Float;
    static function cubicBezier(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float;
}