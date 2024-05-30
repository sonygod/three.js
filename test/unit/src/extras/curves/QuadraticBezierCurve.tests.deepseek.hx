package;

import three.extras.curves.QuadraticBezierCurve;
import three.extras.core.Curve;
import three.math.Vector2;

class QuadraticBezierCurveTests {

    static function main() {
        var _curve:QuadraticBezierCurve = new QuadraticBezierCurve(
            new Vector2( - 10, 0 ),
            new Vector2( 20, 15 ),
            new Vector2( 10, 0 )
        );

        // INHERITANCE
        var object = new QuadraticBezierCurve();
        unittest.assert(object instanceof Curve);

        // INSTANCING
        object = new QuadraticBezierCurve();
        unittest.assert(object != null);

        // PROPERTIES
        object = new QuadraticBezierCurve();
        unittest.assert(object.type == "QuadraticBezierCurve");

        // PUBLIC
        object = new QuadraticBezierCurve();
        unittest.assert(object.isQuadraticBezierCurve);

        // OTHERS
        var curve = _curve;
        var expectedPoints = [
            new Vector2( - 10, 0 ),
            new Vector2( 2.5, 5.625 ),
            new Vector2( 10, 7.5 ),
            new Vector2( 12.5, 5.625 ),
            new Vector2( 10, 0 )
        ];
        var points = curve.getPoints(expectedPoints.length - 1);
        unittest.assert(points.length == expectedPoints.length);
        unittest.assert(points == expectedPoints);

        // ... 其他测试代码 ...
    }
}