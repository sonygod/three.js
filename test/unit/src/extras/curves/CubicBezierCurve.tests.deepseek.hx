package;

import three.extras.curves.CubicBezierCurve;
import three.extras.core.Curve;
import three.math.Vector2;
import js.Lib;

class CubicBezierCurveTests {
    static function main() {
        var curve:CubicBezierCurve;

        // INHERITANCE
        Lib.assert(curve instanceof Curve, "CubicBezierCurve extends from Curve");

        // INSTANCING
        var object = new CubicBezierCurve();
        Lib.assert(object != null, "Can instantiate a CubicBezierCurve.");

        // PROPERTIES
        Lib.assert(object.type == "CubicBezierCurve", "CubicBezierCurve.type should be CubicBezierCurve");

        // PUBLIC
        Lib.assert(object.isCubicBezierCurve, "CubicBezierCurve.isCubicBezierCurve should be true");

        // OTHERS
        var expectedPoints = [
            new Vector2(-10, 0),
            new Vector2(-3.359375, 8.4375),
            new Vector2(5.625, 11.25),
            new Vector2(11.796875, 8.4375),
            new Vector2(10, 0)
        ];

        var points = curve.getPoints(expectedPoints.length - 1);

        Lib.assert(points.length == expectedPoints.length, "Correct number of points");
        Lib.assert(points == expectedPoints, "Correct points calculated");

        // ... 其他测试代码 ...
    }
}