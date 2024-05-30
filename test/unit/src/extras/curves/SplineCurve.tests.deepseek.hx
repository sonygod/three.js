package three.js.test.unit.src.extras.curves;

import three.js.src.extras.curves.SplineCurve;
import three.js.src.extras.core.Curve;
import three.js.src.math.Vector2;

class SplineCurveTests {
    static function main() {
        var _curve:SplineCurve;
        _curve = new SplineCurve([
            new Vector2(-10, 0),
            new Vector2(-5, 5),
            new Vector2(0, 0),
            new Vector2(5, -5),
            new Vector2(10, 0)
        ]);

        // INHERITANCE
        var object = new SplineCurve();
        unittest.assert(object instanceof Curve);

        // INSTANCING
        object = new SplineCurve();
        unittest.assert(object != null);

        // PROPERTIES
        object = new SplineCurve();
        unittest.assert(object.type == "SplineCurve");

        // PUBLIC
        object = new SplineCurve();
        unittest.assert(object.isSplineCurve);

        // OTHERS
        var curve = _curve;
        var expectedPoints = [
            new Vector2(-10, 0),
            new Vector2(-6.08, 4.56),
            new Vector2(-2, 2.48),
            new Vector2(2, -2.48),
            new Vector2(6.08, -4.56),
            new Vector2(10, 0)
        ];
        var points = curve.getPoints(5);
        unittest.assert(points.length == expectedPoints.length);
        for (i in 0...points.length) {
            unittest.assert(points[i].x == expectedPoints[i].x);
            unittest.assert(points[i].y == expectedPoints[i].y);
        }

        // ... 其他测试代码 ...
    }
}