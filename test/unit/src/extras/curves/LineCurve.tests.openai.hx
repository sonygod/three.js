import haxe.unit.TestCase;

import three.extras.curves.LineCurve;
import three.extras.core.Curve;
import three.math.Vector2;

class LineCurveTests extends TestCase {
    var _points:Array<Vector2>;
    var _curve:LineCurve;

    override public function setup() {
        _points = [
            new Vector2(0, 0),
            new Vector2(10, 10),
            new Vector2(-10, 10),
            new Vector2(-8, 5)
        ];

        _curve = new LineCurve(_points[0], _points[1]);
    }

    public function testExtending() {
        var object = new LineCurve();
        assertTrue(object instanceof Curve, 'LineCurve extends from Curve');
    }

    public function testInstancing() {
        var object = new LineCurve();
        assertNotNull(object, 'Can instantiate a LineCurve.');
    }

    public function testType() {
        var object = new LineCurve();
        assertEquals(object.type, 'LineCurve', 'LineCurve.type should be LineCurve');
    }

    public function testIsLineCurve() {
        var object = new LineCurve();
        assertTrue(object.isLineCurve, 'LineCurve.isLineCurve should be true');
    }

    public function testGetPointAt() {
        var curve = new LineCurve(_points[0], _points[3]);

        var expectedPoints = [
            new Vector2(0, 0),
            new Vector2(-2.4, 1.5),
            new Vector2(-4, 2.5),
            new Vector2(-8, 5)
        ];

        var points = [
            curve.getPointAt(0, new Vector2()),
            curve.getPointAt(0.3, new Vector2()),
            curve.getPointAt(0.5, new Vector2()),
            curve.getPointAt(1, new Vector2())
        ];

        assertDeepEquals(points, expectedPoints, 'Correct points');
    }

    public function testGetTangentGetTangentAt() {
        var curve = _curve;
        var tangent = new Vector2();

        curve.getTangent(0, tangent);
        var expectedTangent = Math.sqrt(0.5);

        assertEquals(tangent.x, expectedTangent, 'tangent.x correct');
        assertEquals(tangent.y, expectedTangent, 'tangent.y correct');

        curve.getTangentAt(0, tangent);

        assertEquals(tangent.x, expectedTangent, 'tangentAt.x correct');
        assertEquals(tangent.y, expectedTangent, 'tangentAt.y correct');
    }

    public function testSimpleCurve() {
        var curve = _curve;

        var expectedPoints = [
            new Vector2(0, 0),
            new Vector2(2, 2),
            new Vector2(4, 4),
            new Vector2(6, 6),
            new Vector2(8, 8),
            new Vector2(10, 10)
        ];

        var points = curve.getPoints();

        assertDeepEquals(points, expectedPoints, 'Correct points for first curve');

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

        assertDeepEquals(points, expectedPoints, 'Correct points for second curve');
    }

    public function testGetLengthGetLengths() {
        var curve = _curve;

        var length = curve.getLength();
        var expectedLength = Math.sqrt(200);

        assertEquals(length, expectedLength, 'Correct length of curve');

        var lengths = curve.getLengths(5);
        var expectedLengths = [
            0.0,
            Math.sqrt(8),
            Math.sqrt(32),
            Math.sqrt(72),
            Math.sqrt(128),
            Math.sqrt(200)
        ];

        assertEquals(lengths.length, expectedLengths.length, 'Correct number of segments');

        for (i in 0...lengths.length) {
            assertEquals(lengths[i], expectedLengths[i], 'segment[' + i + '] correct');
        }
    }

    public function testGetUtoTmapping() {
        var curve = _curve;

        var start = curve.getUtoTmapping(0, 0);
        var end = curve.getUtoTmapping(0, curve.getLength());
        var somewhere = curve.getUtoTmapping(0.3, 0);

        assertEquals(start, 0, 'getUtoTmapping( 0, 0 ) is the starting point');
        assertEquals(end, 1, 'getUtoTmapping( 0, length ) is the ending point');
        assertEquals(somewhere, 0.3, 'getUtoTmapping( 0.3, 0 ) is correct');
    }

    public function testGetSpacedPoints() {
        var curve = _curve;

        var expectedPoints = [
            new Vector2(0, 0),
            new Vector2(2.5, 2.5),
            new Vector2(5, 5),
            new Vector2(7.5, 7.5),
            new Vector2(10, 10)
        ];

        var points = curve.getSpacedPoints(4);

        assertEquals(points.length, expectedPoints.length, 'Correct number of points');
        assertDeepEquals(points, expectedPoints, 'Correct points calculated');
    }
}