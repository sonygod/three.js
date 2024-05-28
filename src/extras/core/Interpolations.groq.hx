Here is the equivalent Haxe code:
```
package three.js.src.extras.core;

/**
 * Bezier Curves formulas obtained from
 * https://en.wikipedia.org/wiki/B%C3%A9zier_curve
 */

class Interpolations {
  public static function CatmullRom(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
    var v0:Float = (p2 - p0) * 0.5;
    var v1:Float = (p3 - p1) * 0.5;
    var t2:Float = t * t;
    var t3:Float = t * t2;
    return (2 * p1 - 2 * p2 + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - 2 * v0 - v1) * t2 + v0 * t + p1;
  }

  public static function QuadraticBezierP0(t:Float, p:Float):Float {
    var k:Float = 1 - t;
    return k * k * p;
  }

  public static function QuadraticBezierP1(t:Float, p:Float):Float {
    return 2 * (1 - t) * t * p;
  }

  public static function QuadraticBezierP2(t:Float, p:Float):Float {
    return t * t * p;
  }

  public static function QuadraticBezier(t:Float, p0:Float, p1:Float, p2:Float):Float {
    return QuadraticBezierP0(t, p0) + QuadraticBezierP1(t, p1) + QuadraticBezierP2(t, p2);
  }

  public static function CubicBezierP0(t:Float, p:Float):Float {
    var k:Float = 1 - t;
    return k * k * k * p;
  }

  public static function CubicBezierP1(t:Float, p:Float):Float {
    var k:Float = 1 - t;
    return 3 * k * k * t * p;
  }

  public static function CubicBezierP2(t:Float, p:Float):Float {
    return 3 * (1 - t) * t * t * p;
  }

  public static function CubicBezierP3(t:Float, p:Float):Float {
    return t * t * t * p;
  }

  public static function CubicBezier(t:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float {
    return CubicBezierP0(t, p0) + CubicBezierP1(t, p1) + CubicBezierP2(t, p2) + CubicBezierP3(t, p3);
  }
}
```
Note that I've kept the same naming conventions and organization as the original JavaScript code. I've also used Haxe's syntax for static functions and variables. Let me know if you have any questions or need further modifications!