package three.js.test.unit.src.extras.curves;

import haxe.unit.TestCase;
import three.math.Vector2;
import three.extras.curves.LineCurve;
import three.extras.core.Curve;

class LineCurveTest extends TestCase
{
    var _points:Array<Vector2>;
    var _curve:LineCurve;

    override public function setup():Void
    {
        _points = [
            new Vector2(0, 0),
            new Vector2(10, 10),
            new Vector2(-10, 10),
            new Vector2(-8, 5)
        ];

        _curve = new LineCurve(_points[0], _points[1]);
    }

    public function testExtending():Void
    {
        var object:LineCurve = new LineCurve();
        assertTrue(object instanceof Curve, 'LineCurve extends from Curve');
    }

    public function testInstancing():Void
    {
        var object:LineCurve = new LineCurve();
        assertNotNull(object, 'Can instantiate a LineCurve.');
    }

    public function testType():Void
    {
        var object:LineCurve = new LineCurve();
        assertEquals(object.type, 'LineCurve', 'LineCurve.type should be LineCurve');
    }

    public function testIsLineCurve():Void
    {
        var object:LineCurve = new LineCurve();
        assertTrue(object.isLineCurve, 'LineCurve.isLineCurve should be true');
    }

    public function testGetPointAt():Void
    {
        var curve:LineCurve = new LineCurve(_points[0], _points[3]);

        var expectedPoints:Array<Vector2> = [
            new Vector2(0, 0),
            new Vector2(-2.4, 1.5),
            new Vector2(-4, 2.5),
            new Vector2(-8, 5)
        ];

        var points:Array<Vector2> = [
            curve.getPointAt(0, new Vector2()),
            curve.getPointAt(0.3, new Vector2()),
            curve.getPointAt(0.5, new Vector2()),
            curve.getPointAt(1, new Vector2())
        ];

        assertEquals(points, expectedPoints, 'Correct points');
    }

    public function testGetTangentGetTangentAt():Void
    {
        var curve:LineCurve = _curve;
        var tangent:Vector2 = new Vector2();

        curve.getTangent(0, tangent);
        var expectedTangent:Float = Math.sqrt(0.5);

        assertEquals(tangent.x, expectedTangent, 'tangent.x correct');
        assertEquals(tangent.y, expectedTangent, 'tangent.y correct');

        curve.getTangentAt(0, tangent);

        assertEquals(tangent.x, expectedTangent, 'tangentAt.x correct');
        assertEquals(tangent.y, expectedTangent, 'tangentAt.y correct');
    }

    public function testSimpleCurve():Void
    {
        var curve:LineCurve = _curve;

        var expectedPoints:Array<Vector2> = [
            new Vector2(0, 0),
            new Vector2(2, 2),
            new Vector2(4, 4),
            new Vector2(6, 6),
            new Vector2(8, 8),
            new Vector2(10, 10)
        ];

        var points:Array<Vector2> = curve.getPoints();

        assertEquals(points, expectedPoints, 'Correct points for first curve');

        //

        curve = new LineCurve(_points[1], _points[2]);

        expectedPoints = [
            new Vector2(10, 10),
            new Vector2(6, 10),
            new Vector2(2, 10),
            new Vector2(-2, 10),
            new Vector2(-6, 10),
            new Vector2(-10, 10)
        ];

        points = curve.getPoints();

        assertEquals(points, expectedPoints, 'Correct points for second curve');
    }

    public function testGetLengthGetLengths():Void
    {
        var curve:LineCurve = _curve;

        var length:Float = curve.getLength();
        var expectedLength:Float = Math.sqrt(200);

        assertEquals(length, expectedLength, 'Correct length of curve');

        var lengths:Array<Float> = curve.getLengths(5);
        var expectedLengths:Array<Float> = [
            0.0,
            Math.sqrt(8),
            Math.sqrt(32),
            Math.sqrt(72),
            Math.sqrt(128),
            Math.sqrt(200)
        ];

        assertEquals(lengths.length, expectedLengths.length, 'Correct number of segments');

        for (i in 0...lengths.length)
        {
            assertEquals(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
        }
    }

    public function testGetUtoTmapping():Void
    {
        var curve:LineCurve = _curve;

        var start:Float = curve.getUtoTmapping(0, 0);
        var end:Float = curve.getUtoTmapping(0, curve.getLength());
        var somewhere:Float = curve.getUtoTmapping(0.3, 0);

        assertEquals(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
        assertEquals(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
        assertEquals(somewhere, 0.3, 'getUtoTmapping( 0.3, 0 ) is correct');
    }

    public function testGetSpacedPoints():Void
    {
        var curve:LineCurve = _curve;

        var expectedPoints:Array<Vector2> = [
            new Vector2(0, 0),
            new Vector2(2.5, 2.5),
            new Vector2(5, 5),
            new Vector2(7.5, 7.5),
            new Vector2(10, 10)
        ];

        var points:Array<Vector2> = curve.getSpacedPoints(4);

        assertEquals(points.length, expectedPoints.length, 'Correct number of points');
        assertEquals(points, expectedPoints, 'Correct points calculated');
    }
}