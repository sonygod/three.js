package three.js.test.unit.src.extras.curves;

import haxe.unit.TestCase;
import three.js.extras.curves.QuadraticBezierCurve;
import three.js.extras.core.Curve;
import three.js.math.Vector2;

class QuadraticBezierCurveTest extends TestCase {

    private var _curve:QuadraticBezierCurve;

    override public function setup():Void {
        _curve = new QuadraticBezierCurve(
            new Vector2(-10, 0),
            new Vector2(20, 15),
            new Vector2(10, 0)
        );
    }

    public function testExtending():Void {
        var object:QuadraticBezierCurve = new QuadraticBezierCurve();
        assertTrue(object instanceof Curve, 'QuadraticBezierCurve extends from Curve');
    }

    public function testInstancing():Void {
        var object:QuadraticBezierCurve = new QuadraticBezierCurve();
        assertNotNull(object, 'Can instantiate a QuadraticBezierCurve.');
    }

    public function testType():Void {
        var object:QuadraticBezierCurve = new QuadraticBezierCurve();
        assertEquals(object.type, 'QuadraticBezierCurve', 'QuadraticBezierCurve.type should be QuadraticBezierCurve');
    }

    public function testV0():Void {
        // todo: implement test
        assertTrue(false, 'todo: implement test');
    }

    public function testV1():Void {
        // todo: implement test
        assertTrue(false, 'todo: implement test');
    }

    public function testV2():Void {
        // todo: implement test
        assertTrue(false, 'todo: implement test');
    }

    public function testIsQuadraticBezierCurve():Void {
        var object:QuadraticBezierCurve = new QuadraticBezierCurve();
        assertTrue(object.isQuadraticBezierCurve, 'QuadraticBezierCurve.isQuadraticBezierCurve should be true');
    }

    public function testGetPoint():Void {
        // todo: implement test
        assertTrue(false, 'todo: implement test');
    }

    public function testCopy():Void {
        // todo: implement test
        assertTrue(false, 'todo: implement test');
    }

    public function testToJson():Void {
        // todo: implement test
        assertTrue(false, 'todo: implement test');
    }

    public function testFromJson():Void {
        // todo: implement test
        assertTrue(false, 'todo: implement test');
    }

    public function testSimpleCurve():Void {
        var curve:QuadraticBezierCurve = _curve;
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(2.5, 5.625),
            new Vector2(10, 7.5),
            new Vector2(12.5, 5.625),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getPoints(expectedPoints.length - 1);

        assertEquals(points.length, expectedPoints.length, 'Correct number of points');
        assertEquals(points, expectedPoints, 'Correct points calculated');

        // symmetry
        var curveRev:QuadraticBezierCurve = new QuadraticBezierCurve(curve.v2, curve.v1, curve.v0);

        points = curveRev.getPoints(expectedPoints.length - 1);

        assertEquals(points.length, expectedPoints.length, 'Reversed: Correct number of points');
        assertEquals(points, expectedPoints.reverse(), 'Reversed: Correct points curve');
    }

    public function testGetLengthGetLengths():Void {
        var curve:QuadraticBezierCurve = _curve;

        var length:Float = curve.getLength();
        var expectedLength:Float = 31.269026549416683;

        assertEquals(length, expectedLength, 'Correct length of curve');

        var expectedLengths:Array<Float> = [
            0,
            13.707320124663317,
            21.43814317269643,
            24.56314317269643,
            30.718679298818998
        ];
        var lengths:Array<Float> = curve.getLengths(expectedLengths.length - 1);

        assertEquals(lengths.length, expectedLengths.length, 'Correct number of segments');

        for (i in 0...lengths.length) {
            assertEquals(lengths[i], expectedLengths[i], 'segment[$i] correct');
        }
    }

    public function testGetPointAt():Void {
        var curve:QuadraticBezierCurve = _curve;

        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-1.5127849599387615, 3.993582003773624),
            new Vector2(4.310076165722796, 6.269921971403917),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = [
            curve.getPointAt(0, new Vector2()),
            curve.getPointAt(0.3, new Vector2()),
            curve.getPointAt(0.5, new Vector2()),
            curve.getPointAt(1, new Vector2())
        ];

        assertEquals(points, expectedPoints, 'Correct points');
    }

    public function testGetTangentGetTangentAt():Void {
        var curve:QuadraticBezierCurve = _curve;

        var expectedTangents:Array<Vector2> = [
            new Vector2(0.89443315420562, 0.44720166888975904),
            new Vector2(0.936329177569021, 0.3511234415884543),
            new Vector2(1, 0),
            new Vector2(-5.921189464667277e-13, -1),
            new Vector2(-0.5546617882904897, -0.8320758983472577)
        ];

        var tangents:Array<Vector2> = [
            curve.getTangent(0, new Vector2()),
            curve.getTangent(0.25, new Vector2()),
            curve.getTangent(0.5, new Vector2()),
            curve.getTangent(0.75, new Vector2()),
            curve.getTangent(1, new Vector2())
        ];

        for (i in 0...expectedTangents.length) {
            var tangent:Vector2 = tangents[i];
            assertEquals(tangent.x, expectedTangents[i].x, 'getTangent #$i: x correct');
            assertEquals(tangent.y, expectedTangents[i].y, 'getTangent #$i: y correct');
        }

        // ...

        expectedTangents = [
            new Vector2(0.89443315420562, 0.44720166888975904),
            new Vector2(0.9125211423360805, 0.40902954024086674),
            new Vector2(0.9480289098765387, 0.3181842014278863),
            new Vector2(0.7969127189169473, -0.6040944615111106),
            new Vector2(-0.5546617882904897, -0.8320758983472577)
        ];

        tangents = [
            curve.getTangentAt(0, new Vector2()),
            curve.getTangentAt(0.25, new Vector2()),
            curve.getTangentAt(0.5, new Vector2()),
            curve.getTangentAt(0.75, new Vector2()),
            curve.getTangentAt(1, new Vector2())
        ];

        for (i in 0...expectedTangents.length) {
            var tangent:Vector2 = tangents[i];
            assertEquals(tangent.x, expectedTangents[i].x, 'getTangentAt #$i: x correct');
            assertEquals(tangent.y, expectedTangents[i].y, 'getTangentAt #$i: y correct');
        }
    }

    public function testGetUtoTmapping():Void {
        var curve:QuadraticBezierCurve = _curve;

        var start:Float = curve.getUtoTmapping(0, 0);
        var end:Float = curve.getUtoTmapping(0, curve.getLength());
        var somewhere:Float = curve.getUtoTmapping(0.5, 1);

        var expectedSomewhere:Float = 0.015073978276116116;

        assertEquals(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
        assertEquals(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
        assertEquals(somewhere, expectedSomewhere, 'getUtoTmapping( 0.5, 1 ) is correct');
    }

    public function testGetSpacedPoints():Void {
        var curve:QuadraticBezierCurve = _curve;

        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-4.366603655406173, 2.715408933540383),
            new Vector2(1.3752241477827831, 5.191972084404416),
            new Vector2(7.312990279153634, 7.136310044848586),
            new Vector2(12.499856644824826, 5.653289188715387),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getSpacedPoints();

        assertEquals(points.length, expectedPoints.length, 'Correct number of points');
        assertEquals(points, expectedPoints, 'Correct points calculated');
    }
}