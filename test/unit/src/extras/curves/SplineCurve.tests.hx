package three.js.test.unit.src.extras.curves;

import haxe.unit.TestCase;
import three.extras.curves.SplineCurve;
import three.math.Vector2;
import three.core.Curve;

class SplineCurveTest extends TestCase {
    var _curve:SplineCurve;

    override public function setUp():Void {
        _curve = new SplineCurve([
            new Vector2(-10, 0),
            new Vector2(-5, 5),
            new Vector2(0, 0),
            new Vector2(5, -5),
            new Vector2(10, 0)
        ]);
    }

    public function testExtending():Void {
        var object:SplineCurve = new SplineCurve();
        assertTrue(object instanceof Curve, 'SplineCurve extends from Curve');
    }

    public function testInstancing():Void {
        var object:SplineCurve = new SplineCurve();
        assertTrue(object != null, 'Can instantiate a SplineCurve.');
    }

    public function testType():Void {
        var object:SplineCurve = new SplineCurve();
        assertEquals(object.type, 'SplineCurve', 'SplineCurve.type should be SplineCurve');
    }

    // TODO: implement todo tests
    public function testPoints():Void {
        fail('TODO: implement points test');
    }

    public function testIsSplineCurve():Void {
        var object:SplineCurve = new SplineCurve();
        assertTrue(object.isSplineCurve, 'SplineCurve.isSplineCurve should be true');
    }

    // TODO: implement todo tests
    public function testGetPoint():Void {
        fail('TODO: implement getPoint test');
    }

    public function testCopy():Void {
        fail('TODO: implement copy test');
    }

    public function testToJSON():Void {
        fail('TODO: implement toJSON test');
    }

    public function testFromJSON():Void {
        fail('TODO: implement fromJSON test');
    }

    public function testSimpleCurve():Void {
        var curve:SplineCurve = _curve;
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-6.08, 4.56),
            new Vector2(-2, 2.48),
            new Vector2(2, -2.48),
            new Vector2(6.08, -4.56),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getPoints(5);
        assertEquals(points.length, expectedPoints.length, '1st: Correct number of points');

        for (i in 0...points.length) {
            assertEquals(points[i].x, expectedPoints[i].x, 'points[' + i + '].x');
            assertEquals(points[i].y, expectedPoints[i].y, 'points[' + i + '].y');
        }

        points = curve.getPoints(4);
        assertEquals(points, curve.points, '2nd: Returned points are identical to control points');
    }

    public function testGetLengthGetLengths():Void {
        var curve:SplineCurve = _curve;
        var length:Float = curve.getLength();
        assertEquals(length, 28.876950901868135, 'Correct length of curve');

        var expectedLengths:Array<Float> = [
            0.0,
            Math.sqrt(50),
            Math.sqrt(200),
            Math.sqrt(450),
            Math.sqrt(800)
        ];

        var lengths:Array<Float> = curve.getLengths(4);
        assertEquals(lengths, expectedLengths, 'Correct segment lengths');
    }

    public function testGetPointAt():Void {
        var curve:SplineCurve = _curve;
        var point:Vector2 = new Vector2();

        assertTrue(curve.getPointAt(0, point).equals(curve.points[0]), 'PointAt 0.0 correct');
        assertTrue(curve.getPointAt(1, point).equals(curve.points[4]), 'PointAt 1.0 correct');

        curve.getPointAt(0.5, point);
        assertEquals(point.x, 0.0, 'PointAt 0.5 x correct');
        assertEquals(point.y, 0.0, 'PointAt 0.5 y correct');
    }

    public function testGetTangent():Void {
        var curve:SplineCurve = _curve;

        var expectedTangent:Array<Vector2> = [
            new Vector2(0.7068243340243188, 0.7073891155729485), // 0
            new Vector2(0.7069654305325396, -0.7072481035902046), // 0.5
            new Vector2(0.7068243340245123, 0.7073891155727552)  // 1
        ];

        var tangents:Array<Vector2> = [
            curve.getTangent(0, new Vector2()),
            curve.getTangent(0.5, new Vector2()),
            curve.getTangent(1, new Vector2())
        ];

        for (i in 0...tangents.length) {
            assertEquals(tangents[i].x, expectedTangent[i].x, 'tangent[' + i + '].x');
            assertEquals(tangents[i].y, expectedTangent[i].y, 'tangent[' + i + '].y');
        }
    }

    public function testGetUtoTmapping():Void {
        var curve:SplineCurve = _curve;

        var start:Float = curve.getUtoTmapping(0, 0);
        var end:Float = curve.getUtoTmapping(0, curve.getLength());
        var middle:Float = curve.getUtoTmapping(0.5, 0);

        assertEquals(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
        assertEquals(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
        assertEquals(middle, 0.5, 'getUtoTmapping( 0.5, 0 ) is the middle');
    }

    public function testGetSpacedPoints():Void {
        var curve:SplineCurve = _curve;

        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-4.996509634683014, 4.999995128640857),
            new Vector2(0, 0),
            new Vector2(4.996509634683006, -4.999995128640857),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getSpacedPoints(4);
        assertEquals(points.length, expectedPoints.length, 'Correct number of points');

        for (i in 0...points.length) {
            assertEquals(points[i].x, expectedPoints[i].x, 'points[' + i + '].x');
            assertEquals(points[i].y, expectedPoints[i].y, 'points[' + i + '].y');
        }
    }
}