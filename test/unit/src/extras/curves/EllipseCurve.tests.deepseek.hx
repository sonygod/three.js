package;

import three.extras.curves.EllipseCurve;
import three.extras.core.Curve;
import three.math.Vector2;

class EllipseCurveTests {

    static function main() {
        var curve:EllipseCurve;

        // INHERITANCE
        var object = new EllipseCurve();
        unittest.assert(object instanceof Curve);

        // INSTANCING
        var object = new EllipseCurve();
        unittest.assert(object != null);

        // PROPERTIES
        var object = new EllipseCurve();
        unittest.assert(object.type == "EllipseCurve");

        // PUBLIC
        var object = new EllipseCurve();
        unittest.assert(object.isEllipseCurve);

        // OTHERS
        var expectedPoints = [
            new Vector2(10, 0),
            new Vector2(0, 10),
            new Vector2(-10, 0),
            new Vector2(0, -10),
            new Vector2(10, 0)
        ];

        var points = curve.getPoints(expectedPoints.length - 1);

        unittest.assert(points.length == expectedPoints.length);

        for (p in points) {
            unittest.assert(p.x == expectedPoints[i].x);
            unittest.assert(p.y == expectedPoints[i].y);
        }

        // ... 其他测试代码 ...
    }
}