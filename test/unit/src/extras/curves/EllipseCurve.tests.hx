package three.js.test.unit.src.extras.curves;

import haxe.unit.TestCase;
import three.js.extras.curves.EllipseCurve;
import three.js.extras.core.Curve;
import three.js.math.Vector2;

class EllipseCurveTest extends TestCase
{
    var curve:EllipseCurve;

    override public function setup():Void
    {
        curve = new EllipseCurve(
            0, 0, // ax, aY
            10, 10, // xRadius, yRadius
            0, 2 * Math.PI, // aStartAngle, aEndAngle
            false, // aClockwise
            0 // aRotation
        );
    }

    public function testExtending():Void
    {
        var object:EllipseCurve = new EllipseCurve();
        assertTrue(object instanceof Curve);
    }

    public function testInstancing():Void
    {
        var object:EllipseCurve = new EllipseCurve();
        assertNotNull(object);
    }

    public function testType():Void
    {
        var object:EllipseCurve = new EllipseCurve();
        assertEquals(object.type, 'EllipseCurve');
    }

    // TODO: Implement tests for aX, aY, xRadius, yRadius, aStartAngle, aEndAngle, aClockwise, aRotation

    public function testIsEllipseCurve():Void
    {
        var object:EllipseCurve = new EllipseCurve();
        assertTrue(object.isEllipseCurve);
    }

    // TODO: Implement tests for getPoint, copy, toJSON, fromJSON

    public function testSimpleCurve():Void
    {
        var expectedPoints:Array<Vector2> = [
            new Vector2(10, 0),
            new Vector2(0, 10),
            new Vector2(-10, 0),
            new Vector2(0, -10),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getPoints(expectedPoints.length - 1);

        assertEquals(points.length, expectedPoints.length);

        for (i in 0...points.length)
        {
            assertEquals(points[i].x, expectedPoints[i].x);
            assertEquals(points[i].y, expectedPoints[i].y);
        }
    }

    public function testGetLengthGetLengths():Void
    {
        var length:Float = curve.getLength();
        var expectedLength:Float = 62.829269247282795;

        assertEquals(length, expectedLength);

        var lengths:Array<Float> = curve.getLengths(5);
        var expectedLengths:Array<Float> = [
            0,
            11.755705045849462,
            23.51141009169892,
            35.26711513754839,
            47.02282018339785,
            58.77852522924731
        ];

        assertEquals(lengths.length, expectedLengths.length);

        for (i in 0...lengths.length)
        {
            assertEquals(lengths[i], expectedLengths[i]);
        }
    }

    public function testGetPointGetPointAt():Void
    {
        var testValues:Array<Float> = [0, 0.3, 0.5, 0.7, 1];

        var p:Vector2 = new Vector2();
        var a:Vector2 = new Vector2();

        for (val in testValues)
        {
            var expectedX:Float = Math.cos(val * Math.PI * 2) * 10;
            var expectedY:Float = Math.sin(val * Math.PI * 2) * 10;

            curve.getPoint(val, p);
            curve.getPointAt(val, a);

            assertEquals(p.x, expectedX);
            assertEquals(p.y, expectedY);

            assertEquals(a.x, expectedX);
            assertEquals(a.y, expectedY);
        }
    }

    public function testGetTangent():Void
    {
        var expectedTangents:Array<Vector2> = [
            new Vector2(-0.000314159260186071, 0.9999999506519786),
            new Vector2(-1, 0),
            new Vector2(0, -1),
            new Vector2(1, 0),
            new Vector2(0.00031415926018600165, 0.9999999506519784)
        ];

        var tangents:Array<Vector2> = [
            curve.getTangent(0, new Vector2()),
            curve.getTangent(0.25, new Vector2()),
            curve.getTangent(0.5, new Vector2()),
            curve.getTangent(0.75, new Vector2()),
            curve.getTangent(1, new Vector2())
        ];

        for (i in 0...expectedTangents.length)
        {
            var tangent:Vector2 = tangents[i];
            var exp:Vector2 = expectedTangents[i];

            assertEquals(tangent.x, exp.x);
            assertEquals(tangent.y, exp.y);
        }
    }

    public function testGetUtoTmapping():Void
    {
        var start:Float = curve.getUtoTmapping(0, 0);
        var end:Float = curve.getUtoTmapping(0, curve.getLength());
        var somewhere:Float = curve.getUtoTmapping(0.7, 1);

        assertEquals(start, 0);
        assertEquals(end, 1);
        assertEquals(somewhere, 0.01591614882650014);
    }

    public function testGetSpacedPoints():Void
    {
        var expectedPoints:Array<Vector2> = [
            new Vector2(10, 0),
            new Vector2(3.0901699437494603, 9.51056516295154),
            new Vector2(-8.090169943749492, 5.877852522924707),
            new Vector2(-8.090169943749459, -5.877852522924751),
            new Vector2(3.0901699437494807, -9.510565162951533),
            new Vector2(10, -2.4492935982947065e-15)
        ];

        var points:Array<Vector2> = curve.getSpacedPoints();

        assertEquals(points.length, expectedPoints.length);

        for (i in 0...points.length)
        {
            assertEquals(points[i].x, expectedPoints[i].x);
            assertEquals(points[i].y, expectedPoints[i].y);
        }
    }
}