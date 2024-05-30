import haxe.unit.TestCase;
import three.extras.curves.QuadraticBezierCurve;
import three.math.Vector2;

class QuadraticBezierCurveTests {
    static var _curve:QuadraticBezierCurve;

    public static function main() {
        TestCase.createTestSuite(QuadraticBezierCurveTests);
    }

    public function new() {}

    @Before
    public function setup() {
        _curve = new QuadraticBezierCurve(
            new Vector2(-10, 0),
            new Vector2(20, 15),
            new Vector2(10, 0)
        );
    }

    // INHERITANCE
    public function testExtending() {
        var object = new QuadraticBezierCurve();
        assertTrue(object instanceof Curve);
    }

    // INSTANCING
    public function testInstancing() {
        var object = new QuadraticBezierCurve();
        assertNotNull(object);
    }

    // PROPERTIES
    public function testType() {
        var object = new QuadraticBezierCurve();
        assertEquals(object.type, 'QuadraticBezierCurve');
    }

    // TODO: implement these tests
    public function testV0() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testV1() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testV2() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    // PUBLIC
    public function testIsQuadraticBezierCurve() {
        var object = new QuadraticBezierCurve();
        assertTrue(object.isQuadraticBezierCurve);
    }

    // TODO: implement these tests
    public function testGetPoint() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testCopy() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testToJSON() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    public function testFromJSON() {
        assertTrue(false, 'everything\'s gonna be alright');
    }

    // OTHERS
    public function testSimpleCurve() {
        var curve = _curve;
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(2.5, 5.625),
            new Vector2(10, 7.5),
            new Vector2(12.5, 5.625),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getPoints(expectedPoints.length - 1);

        assertEquals(points.length, expectedPoints.length);
        deepEquals(points, expectedPoints);

        var curveRev = new QuadraticBezierCurve(curve.v2, curve.v1, curve.v0);
        points = curveRev.getPoints(expectedPoints.length - 1);

        assertEquals(points.length, expectedPoints.length);
        deepEquals(points, expectedPoints.reverse());
    }

    public function testGetLength() {
        var curve = _curve;
        var length = curve.getLength();
        var expectedLength = 31.269026549416683;

        assertEquals(length, expectedLength);

        var expectedLengths:Array<Float> = [
            0,
            13.707320124663317,
            21.43814317269643,
            24.56314317269643,
            30.718679298818998
        ];

        var lengths:Array<Float> = curve.getLengths(expectedLengths.length - 1);

        assertEquals(lengths.length, expectedLengths.length);

        for (i in 0...lengths.length) {
            assertEquals(lengths[i], expectedLengths[i]);
        }
    }

    public function testGetPointAt() {
        var curve = _curve;
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

        deepEquals(points, expectedPoints);
    }

    public function testGetTangent() {
        var curve = _curve;
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

        for (i in 0...tangents.length) {
            assertEquals(tangents[i].x, expectedTangents[i].x);
            assertEquals(tangents[i].y, expectedTangents[i].y);
        }

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

        for (i in 0...tangents.length) {
            assertEquals(tangents[i].x, expectedTangents[i].x);
            assertEquals(tangents[i].y, expectedTangents[i].y);
        }
    }

    public function testGetUtoTmapping() {
        var curve = _curve;
        var start = curve.getUtoTmapping(0, 0);
        var end = curve.getUtoTmapping(0, curve.getLength());
        var somewhere = curve.getUtoTmapping(0.5, 1);

        assertEquals(start, 0);
        assertEquals(end, 1);
        assertEquals(somewhere, 0.015073978276116116);
    }

    public function testGetSpacedPoints() {
        var curve = _curve;
        var expectedPoints:Array<Vector2> = [
            new Vector2(-10, 0),
            new Vector2(-4.366603655406173, 2.715408933540383),
            new Vector2(1.3752241477827831, 5.191972084404416),
            new Vector2(7.312990279153634, 7.136310044848586),
            new Vector2(12.499856644824826, 5.653289188715387),
            new Vector2(10, 0)
        ];

        var points:Array<Vector2> = curve.getSpacedPoints();

        assertEquals(points.length, expectedPoints.length);
        deepEquals(points, expectedPoints);
    }
}