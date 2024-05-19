package three.js.test.unit.src.extras.curves;

import haxe.unit.TestCase;
import three.CubicBezierCurve;
import three.Curve;
import three.Vector2;

class CubicBezierCurveTest {
    var curve:CubicBezierCurve;

    public function new() {
        super();
    }

    override public function setUp():Void {
        curve = new CubicBezierCurve(
            new Vector2(-10, 0),
            new Vector2(-5, 15),
            new Vector2(20, 15),
            new Vector2(10, 0)
        );
    }

    public function testExtending():Void {
        var object:CubicBezierCurve = new CubicBezierCurve();
        assertEquals(object instanceof Curve, true, 'CubicBezierCurve extends from Curve');
    }

    public function testInstancing():Void {
        var object:CubicBezierCurve = new CubicBezierCurve();
        assertTrue(object != null, 'Can instantiate a CubicBezierCurve.');
    }

    public function testType():Void {
        var object:CubicBezierCurve = new CubicBezierCurve();
        assertEquals(object.type, 'CubicBezierCurve', 'CubicBezierCurve.type should be CubicBezierCurve');
    }

    public function todoV0():Void {
        // Vector2 exists
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoV1():Void {
        // Vector2 exists
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoV2():Void {
        // Vector2 exists
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoV3():Void {
        // Vector2 exists
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testIsCubicBezierCurve():Void {
        var object:CubicBezierCurve = new CubicBezierCurve();
        assertTrue(object.isCubicBezierCurve, 'CubicBezierCurve.isCubicBezierCurve should be true');
    }

    public function todoGetPoint():Void {
        // getPoint( t, optionalTarget = new Vector2() )
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoCopy():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoToJSON():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function todoFromJSON():Void {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testSimpleCurve():Void {
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-3.359375, 8.4375),
            new Vector2(5.625, 11.25),
            new Vector2(11.796875, 8.4375),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getPoints(expectedPoints.length - 1);

        assertEquals(points.length, expectedPoints.length, 'Correct number of points');
        assertEquals(points, expectedPoints, 'Correct points calculated');

        // symmetry
        var curveRev:CubicBezierCurve = new CubicBezierCurve(curve.v3, curve.v2, curve.v1, curve.v0);

        points = curveRev.getPoints(expectedPoints.length - 1);

        assertEquals(points.length, expectedPoints.length, 'Reversed: Correct number of points');
        assertEquals(points, expectedPoints.reverse(), 'Reversed: Correct points curve');
    }

    public function testGetLengthGetLengths():Void {
        var length:Float = curve.getLength();
        var expectedLength:Float = 36.64630888504102;

        assertEquals(length, expectedLength, 'Correct length of curve');

        var expectedLengths:Array<Float> = [
            0,
            10.737285813492393,
            20.15159143794633,
            26.93408340370825,
            35.56079575637337
        ];
        var lengths:Array<Float> = curve.getLengths(expectedLengths.length - 1);

        assertEquals(lengths.length, expectedLengths.length, 'Correct number of segments');

        for (i in 0...lengths.length) {
            assertEquals(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
        }
    }

    public function testGetPointAt():Void {
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-3.3188282598022596, 8.463722639089221),
            new Vector2(3.4718554735926617, 11.07899406116314),
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
        var expectedTangents:Array<Vector2> = [
            new Vector2(0.316370061632252, 0.9486358543207215),
            new Vector2(0.838961283088303, 0.5441911111721949),
            new Vector2(1, 0),
            new Vector2(0.47628313192245453, -0.8792919755383518),
            new Vector2(-0.5546041767829665, -0.8321142992972107)
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
            assertEquals(tangent.x, expectedTangents[i].x, 'getTangent #' + i + ': x correct');
            assertEquals(tangent.y, expectedTangents[i].y, 'getTangent #' + i + ': y correct');
        }

        //

        expectedTangents = [
            new Vector2(0.316370061632252, 0.9486358543207215),
            new Vector2(0.7794223085548987, 0.6264988945935596),
            new Vector2(0.988266153082452, 0.15274164681452052),
            new Vector2(0.5004110404199416, -0.8657879593906534),
            new Vector2(-0.5546041767829665, -0.8321142992972107)
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
            assertEquals(tangent.x, expectedTangents[i].x, 'getTangentAt #' + i + ': x correct');
            assertEquals(tangent.y, expectedTangents[i].y, 'getTangentAt #' + i + ': y correct');
        }
    }

    public function testGetUtoTmapping():Void {
        var start:Float = curve.getUtoTmapping(0, 0);
        var end:Float = curve.getUtoTmapping(0, curve.getLength());
        var somewhere:Float = curve.getUtoTmapping(0.5, 1);

        var expectedSomewhere:Float = 0.02130029182257093;

        assertEquals(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
        assertEquals(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
        assertEquals(somewhere, expectedSomewhere, 'getUtoTmapping( 0.5, 1 ) is correct');
    }

    public function testGetSpacedPoints():Void {
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-6.16826457740703, 6.17025727295411),
            new Vector2(-0.058874033259857184, 10.1240558653185),
            new Vector2(7.123523032625162, 11.154913869041575),
            new Vector2(12.301846885754463, 6.808865855469985),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getSpacedPoints();

        assertEquals(points.length, expectedPoints.length, 'Correct number of points');
        assertEquals(points, expectedPoints, 'Correct points calculated');
    }
}