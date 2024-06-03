import three.extras.curves.ArcCurve;
import three.extras.curves.CatmullRomCurve3;
import three.extras.curves.CubicBezierCurve;
import three.extras.curves.CubicBezierCurve3;
import three.extras.curves.EllipseCurve;
import three.extras.curves.LineCurve;
import three.extras.curves.LineCurve3;
import three.extras.curves.QuadraticBezierCurve;
import three.extras.curves.QuadraticBezierCurve3;
import three.extras.curves.SplineCurve;

class Curves {
    public static inline function getArcCurve():ArcCurve {
        return new ArcCurve();
    }

    public static inline function getCatmullRomCurve3():CatmullRomCurve3 {
        return new CatmullRomCurve3();
    }

    /* Add similar functions for the rest of the classes */
}