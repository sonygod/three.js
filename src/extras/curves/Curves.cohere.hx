package;

import arc.ArcCurve;
import catmullRom.CatmullRomCurve3;
import cubicBezier.CubicBezierCurve;
import cubicBezier3.CubicBezierCurve3;
import ellipse.EllipseCurve;
import line.LineCurve;
import line3.LineCurve3;
import quadraticBezier.QuadraticBezierCurve;
import quadraticBezier3.QuadraticBezierCurve3;
import spline.SplineCurve;

class Exports {
    public static function init() {
        ArcCurve.init();
        CatmullRomCurve3.init();
        CubicBezierCurve.init();
        CubicBezierCurve3.init();
        EllipseCurve.init();
        LineCurve.init();
        LineCurve3.init();
        QuadraticBezierCurve.init();
        QuadraticBezierCurve3.init();
        SplineCurve.init();
    }
}