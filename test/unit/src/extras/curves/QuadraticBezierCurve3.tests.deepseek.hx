package;

import three.extras.curves.QuadraticBezierCurve3;
import three.extras.core.Curve;
import three.math.Vector3;

class QuadraticBezierCurve3Tests {

    static function main() {

        var _curve:QuadraticBezierCurve3 = new QuadraticBezierCurve3(
            new Vector3( - 10, 0, 2 ),
            new Vector3( 20, 15, - 5 ),
            new Vector3( 10, 0, 10 )
        );

        // INHERITANCE
        var object = new QuadraticBezierCurve3();
        unittest.assert(object instanceof Curve);

        // INSTANCING
        object = new QuadraticBezierCurve3();
        unittest.assert(object != null);

        // PROPERTIES
        object = new QuadraticBezierCurve3();
        unittest.assert(object.type == "QuadraticBezierCurve3");

        // PUBLIC
        object = new QuadraticBezierCurve3();
        unittest.assert(object.isQuadraticBezierCurve3);

        // OTHERS
        var curve = _curve;

        var expectedPoints = [
            new Vector3( - 10, 0, 2 ),
            new Vector3( 2.5, 5.625, - 0.125 ),
            new Vector3( 10, 7.5, 0.5 ),
            new Vector3( 12.5, 5.625, 3.875 ),
            new Vector3( 10, 0, 10 )
        ];

        var points = curve.getPoints(expectedPoints.length - 1);

        unittest.assert(points.length == expectedPoints.length);
        unittest.assert(points == expectedPoints);

        // symmetry
        var curveRev = new QuadraticBezierCurve3(
            curve.v2, curve.v1, curve.v0
        );

        points = curveRev.getPoints(expectedPoints.length - 1);

        unittest.assert(points.length == expectedPoints.length);
        unittest.assert(points == expectedPoints.reverse());

        // ... 其他测试代码 ...

    }

}